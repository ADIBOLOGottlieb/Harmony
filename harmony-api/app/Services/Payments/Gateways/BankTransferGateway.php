<?php

namespace App\Services\Payments\Gateways;

use App\Enums\PaymentStatus;
use App\Models\Booking;
use App\Models\Payment;
use App\Services\Payments\InvalidWebhook;
use App\Services\Payments\PaymentGateway;
use App\Services\Payments\PaymentInitiation;
use App\Services\Payments\WebhookEvent;
use Illuminate\Http\Request;

/** Virement bancaire : instructions au client, validation manuelle par la conciergerie. */
class BankTransferGateway implements PaymentGateway
{
    public function name(): string
    {
        return 'bank_transfer';
    }

    public function initiate(Payment $payment, Booking $booking): PaymentInitiation
    {
        $amount = number_format($payment->amount, 0, ',', ' ');

        return new PaymentInitiation(
            instructions: trim((string) config('harmony.bank_transfer.instructions'))
                ."\nMontant : {$amount} FCFA\nRéférence à indiquer : {$booking->reference}"
                ."\nVotre réservation est confirmée dès réception du virement par la conciergerie.",
        );
    }

    public function parseWebhook(Request $request): WebhookEvent
    {
        throw new InvalidWebhook('Le virement est validé manuellement.');
    }

    public function refund(Payment $refund, Payment $original): PaymentStatus
    {
        return PaymentStatus::Pending;
    }
}
