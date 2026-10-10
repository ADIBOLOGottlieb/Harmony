<?php

namespace App\Services\Payments;

use App\Enums\BookingStatus;
use App\Enums\PaymentKind;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Models\Booking;
use App\Models\Payment;
use App\Models\PaymentEvent;
use App\Models\User;
use App\Notifications\BookingConfirmed;
use App\Services\Booking\BookingException;
use App\Services\Payments\Gateways\BankTransferGateway;
use App\Services\Payments\Gateways\FedaPayGateway;
use App\Services\Payments\Gateways\SandboxGateway;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/** Paiements : choix de la passerelle, webhooks idempotents, validation manuelle, remboursements. */
class PaymentService
{
    public function gatewayFor(PaymentMethod $method): PaymentGateway
    {
        if ($method === PaymentMethod::BankTransfer) {
            return app(BankTransferGateway::class);
        }
        if (filled(config('services.fedapay.secret_key'))) {
            return app(FedaPayGateway::class);
        }
        if (config('harmony.payments.sandbox_enabled')) {
            return app(SandboxGateway::class);
        }

        throw BookingException::paymentUnavailable();
    }

    public function gatewayNamed(string $name): PaymentGateway
    {
        return match ($name) {
            'fedapay' => app(FedaPayGateway::class),
            'sandbox' => app(SandboxGateway::class),
            'bank_transfer' => app(BankTransferGateway::class),
        };
    }

    public function start(Booking $booking, PaymentKind $kind, PaymentMethod $method): Payment
    {
        $amount = match ($kind) {
            PaymentKind::Advance => $booking->advance_amount,
            PaymentKind::Balance => $booking->balanceDue(),
            PaymentKind::Full => $booking->total_amount,
            PaymentKind::Refund => 0,
        };
        if ($amount <= 0) {
            throw BookingException::nothingToPay();
        }

        $gateway = $this->gatewayFor($method);

        $payment = $booking->payments()->create([
            'gateway' => $gateway->name(),
            'method' => $method,
            'kind' => $kind,
            'amount' => $amount,
            'status' => PaymentStatus::Pending,
        ]);

        $init = $gateway->initiate($payment, $booking);
        $payment->update([
            'checkout_url' => $init->checkoutUrl,
            'instructions' => $init->instructions,
            'provider_reference' => $init->providerReference,
        ]);

        return $payment;
    }

    /** Traite un webhook : signature vérifiée, puis une seule fois par identifiant d'événement. */
    public function handleWebhook(string $gatewayName, Request $request): void
    {
        $event = $this->gatewayNamed($gatewayName)->parseWebhook($request);

        DB::transaction(function () use ($gatewayName, $event) {
            // INSERT … ON CONFLICT DO NOTHING : sous PostgreSQL, une violation d'unicité
            // interceptée laisserait la transaction en échec ; on ne la provoque donc pas.
            $inserted = PaymentEvent::query()->insertOrIgnore([
                'gateway' => $gatewayName,
                'event_id' => $event->eventId,
                'type' => $event->type,
                'payload' => json_encode($event->payload),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            if ($inserted === 0) {
                return; // Déjà reçu : rien à refaire.
            }
            $record = PaymentEvent::query()
                ->where('gateway', $gatewayName)
                ->where('event_id', $event->eventId)
                ->firstOrFail();

            if ($event->outcome !== null && $event->providerReference !== null) {
                $payment = Payment::query()
                    ->where('gateway', $gatewayName)
                    ->where('provider_reference', $event->providerReference)
                    ->first();

                if ($payment) {
                    $this->applyOutcome($payment, $event->outcome);
                } else {
                    Log::warning('Webhook de paiement sans transaction correspondante.', ['gateway' => $gatewayName, 'type' => $event->type]);
                }
            }

            $record->update(['processed_at' => now()]);
        });
    }

    /** Applique le résultat d'un paiement. Idempotent : un paiement déjà réglé n'est plus modifié. */
    public function applyOutcome(Payment $payment, PaymentStatus $outcome, ?User $validatedBy = null): void
    {
        DB::transaction(function () use ($payment, $outcome, $validatedBy) {
            $payment = Payment::query()->whereKey($payment->id)->lockForUpdate()->firstOrFail();
            if ($payment->status !== PaymentStatus::Pending) {
                return;
            }

            $payment->update([
                'status' => $outcome,
                'paid_at' => $outcome === PaymentStatus::Succeeded ? now() : null,
                'validated_by' => $validatedBy?->id,
            ]);

            if ($outcome !== PaymentStatus::Succeeded) {
                return;
            }

            $booking = Booking::query()->whereKey($payment->booking_id)->lockForUpdate()->firstOrFail();

            if ($payment->kind === PaymentKind::Refund) {
                $booking->update([
                    'status' => BookingStatus::Refunded,
                    'amount_paid' => max(0, $booking->amount_paid - $payment->amount),
                ]);

                return;
            }

            $booking->amount_paid += $payment->amount;

            if ($booking->status === BookingStatus::Pending) {
                $booking->status = BookingStatus::Confirmed;
                $booking->confirmed_at = now();
                $booking->expires_at = null;
                $booking->save();
                DB::afterCommit(fn () => $booking->user->notify(new BookingConfirmed($booking)));

                return;
            }

            $booking->save();

            // Paiement reçu après annulation ou expiration : il est remboursé.
            if ($booking->status === BookingStatus::Cancelled) {
                DB::afterCommit(fn () => $this->refund($booking->refresh(), $payment->amount));
            }
        });
    }

    /** Validation manuelle d'un virement par la conciergerie. */
    public function validateTransfer(Payment $payment, User $staff): void
    {
        $this->applyOutcome($payment, PaymentStatus::Succeeded, $staff);
    }

    public function refund(Booking $booking, int $amount): Payment
    {
        $original = $booking->payments()
            ->where('status', PaymentStatus::Succeeded)
            ->where('kind', '!=', PaymentKind::Refund)
            ->first();

        $gateway = $this->gatewayNamed($original->gateway ?? 'bank_transfer');

        $refund = $booking->payments()->create([
            'gateway' => $gateway->name(),
            'method' => $original->method ?? PaymentMethod::BankTransfer,
            'kind' => PaymentKind::Refund,
            'amount' => $amount,
            'status' => PaymentStatus::Pending,
        ]);

        $status = $original ? $gateway->refund($refund, $original) : PaymentStatus::Pending;
        if ($status === PaymentStatus::Succeeded) {
            $this->applyOutcome($refund, PaymentStatus::Succeeded);
        }

        return $refund->refresh();
    }
}
