<?php

namespace App\Services\Booking;

use App\Enums\BookingStatus;
use App\Enums\MaintenanceStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Models\Apartment;
use App\Models\Booking;
use App\Models\Payment;
use App\Models\User;
use App\Services\Payments\PaymentService;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

/**
 * Seul point d'entrée pour créer, annuler ou faire évoluer une réservation.
 * Anti double-réservation : transaction + verrou sur l'appartement + contrôle
 * de chevauchement, doublés par la contrainte d'exclusion PostgreSQL.
 */
class BookingService
{
    private const REFERENCE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    public function __construct(
        private PricingService $pricing,
        private AvailabilityService $availability,
        private PaymentService $payments,
    ) {}

    public function quote(Apartment $apartment, StayWindow $window, int $guests): Quote
    {
        $this->assertBookable($apartment, $window, $guests);

        return $this->pricing->quote($apartment, $window);
    }

    public function create(User $user, Apartment $apartment, StayWindow $window, int $guests, PaymentMethod $method): Booking
    {
        $this->assertBookable($apartment, $window, $guests);

        try {
            return DB::transaction(function () use ($user, $apartment, $window, $guests, $method) {
                $locked = Apartment::query()->whereKey($apartment->id)->lockForUpdate()->firstOrFail();

                // Les demandes non payées à temps libèrent leurs dates.
                $this->expireStale($locked->id);

                if ($this->availability->conflicts($locked, $window->start, $window->blockedUntil())) {
                    throw BookingException::unavailable();
                }

                $quote = $this->pricing->quote($locked, $window);
                $expiresAt = $method === PaymentMethod::BankTransfer
                    ? now()->addHours((int) config('harmony.bank_transfer.expiry_hours'))
                    : now()->addMinutes((int) config('harmony.pending_expiry_minutes'));

                return Booking::query()->create([
                    'reference' => $this->newReference(),
                    'apartment_id' => $locked->id,
                    'user_id' => $user->id,
                    'stay_type' => $window->type,
                    'start_at' => $window->start,
                    'end_at' => $window->end,
                    'blocked_until' => $window->blockedUntil(),
                    'nights' => $window->nights,
                    'guests' => $guests,
                    'status' => BookingStatus::Pending,
                    'accommodation_amount' => $quote->accommodation,
                    'service_fee' => $quote->serviceFee,
                    'total_amount' => $quote->total,
                    'security_deposit' => $quote->securityDeposit,
                    'advance_amount' => $quote->advance,
                    'price_breakdown' => $quote->lines,
                    'cancellation_deadline' => $window->start->subDays((int) config('harmony.free_cancellation_days')),
                    'expires_at' => $expiresAt,
                ]);
            });
        } catch (QueryException $e) {
            if ($this->isOverlapViolation($e)) {
                throw BookingException::unavailable();
            }

            throw $e;
        }
    }

    /**
     * Annulation par le client ou la conciergerie. Gratuite jusqu'à l'échéance :
     * les sommes versées sont alors remboursées ; au-delà, l'acompte est conservé.
     */
    public function cancel(Booking $booking, string $reason): Booking
    {
        if (! in_array($booking->status, [BookingStatus::Pending, BookingStatus::Confirmed], true)) {
            throw BookingException::notCancellable();
        }

        $refundable = $booking->amount_paid > 0
            && $booking->cancellation_deadline !== null
            && now()->lte($booking->cancellation_deadline)
                ? $booking->amount_paid
                : 0;

        DB::transaction(function () use ($booking, $reason) {
            $booking->update([
                'status' => BookingStatus::Cancelled,
                'cancelled_at' => now(),
                'cancel_reason' => $reason,
            ]);
            Payment::query()->where('booking_id', $booking->id)->where('status', PaymentStatus::Pending)
                ->update(['status' => PaymentStatus::Cancelled]);
            $booking->maintenanceTasks()->where('status', MaintenanceStatus::Todo)
                ->update(['status' => MaintenanceStatus::Cancelled]);
        });

        if ($refundable > 0) {
            $this->payments->refund($booking, $refundable);
        }

        return $booking->refresh();
    }

    /** Annule les réservations en attente dont le délai de paiement est dépassé. */
    public function expireStale(?int $apartmentId = null): int
    {
        $expired = Booking::query()
            ->where('status', BookingStatus::Pending)
            ->where('expires_at', '<=', now())
            ->when($apartmentId, fn ($q) => $q->where('apartment_id', $apartmentId));

        $ids = (clone $expired)->pluck('id');
        if ($ids->isEmpty()) {
            return 0;
        }

        Payment::query()->whereIn('booking_id', $ids)->where('status', PaymentStatus::Pending)
            ->update(['status' => PaymentStatus::Cancelled]);

        return $expired->update([
            'status' => BookingStatus::Cancelled,
            'cancelled_at' => now(),
            'cancel_reason' => 'expired',
        ]);
    }

    /** Passe en « terminée » les séjours confirmés dont la date de fin est passée. */
    public function completeFinished(): int
    {
        return Booking::query()
            ->where('status', BookingStatus::Confirmed)
            ->where('end_at', '<=', now())
            ->update(['status' => BookingStatus::Completed]);
    }

    private function assertBookable(Apartment $apartment, StayWindow $window, int $guests): void
    {
        if (! $apartment->isBookable()) {
            throw BookingException::apartmentUnavailable();
        }
        if ($guests > $apartment->capacity) {
            throw BookingException::tooManyGuests($apartment->capacity);
        }
        if ($window->start->lte(now())) {
            throw BookingException::invalidDates('Le séjour doit commencer dans le futur.');
        }
    }

    private function newReference(): string
    {
        do {
            $suffix = '';
            for ($i = 0; $i < 6; $i++) {
                $suffix .= self::REFERENCE_ALPHABET[random_int(0, strlen(self::REFERENCE_ALPHABET) - 1)];
            }
            $reference = 'HH-'.$suffix;
        } while (Booking::query()->where('reference', $reference)->exists());

        return $reference;
    }

    private function isOverlapViolation(QueryException $e): bool
    {
        return $e->getCode() === '23P01' || str_contains($e->getMessage(), 'bookings_no_overlap');
    }
}
