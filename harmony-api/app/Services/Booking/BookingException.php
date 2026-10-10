<?php

namespace App\Services\Booking;

use Illuminate\Http\JsonResponse;
use RuntimeException;

/** Erreur métier de réservation, rendue en JSON avec un code stable pour l'app. */
class BookingException extends RuntimeException
{
    public function __construct(string $message, public readonly string $errorCode, public readonly int $status = 422)
    {
        parent::__construct($message);
    }

    public static function unavailable(): self
    {
        return new self(__('Ces dates ne sont plus disponibles. Choisissez un autre créneau.'), 'dates_unavailable', 409);
    }

    public static function apartmentUnavailable(): self
    {
        return new self(__('Ce logement n’est pas ouvert à la réservation pour le moment.'), 'apartment_unavailable', 409);
    }

    public static function invalidDates(string $detail): self
    {
        return new self(__($detail), 'invalid_dates');
    }

    public static function stayTypeUnavailable(): self
    {
        return new self(__('Ce logement ne propose pas ce type de séjour.'), 'stay_type_unavailable');
    }

    public static function tooManyGuests(int $capacity): self
    {
        return new self(__('Ce logement accueille au maximum :count voyageurs.', ['count' => $capacity]), 'too_many_guests');
    }

    public static function notCancellable(): self
    {
        return new self(__('Cette réservation ne peut plus être annulée.'), 'not_cancellable', 409);
    }

    public static function nothingToPay(): self
    {
        return new self(__('Aucun montant n’est dû pour cette réservation.'), 'nothing_to_pay', 409);
    }

    public static function paymentUnavailable(): self
    {
        return new self(__('Ce moyen de paiement n’est pas disponible pour le moment.'), 'payment_unavailable', 503);
    }

    public function render(): JsonResponse
    {
        return response()->json(['message' => $this->getMessage(), 'code' => $this->errorCode], $this->status);
    }
}
