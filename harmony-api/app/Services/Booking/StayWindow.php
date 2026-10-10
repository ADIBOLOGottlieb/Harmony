<?php

namespace App\Services\Booking;

use App\Enums\StayType;
use Carbon\CarbonImmutable;

/**
 * Début et fin exacts d'un séjour, dérivés du type de séjour et des horaires
 * de la maison (config/harmony.php). Fuseau : celui de l'application (Lomé).
 */
final class StayWindow
{
    public function __construct(
        public readonly StayType $type,
        public readonly CarbonImmutable $start,
        public readonly CarbonImmutable $end,
        public readonly int $nights,
    ) {}

    /** Fin du séjour plus le battement de ménage : la chambre est indisponible jusque-là. */
    public function blockedUntil(): CarbonImmutable
    {
        return $this->end->addMinutes((int) config('harmony.turnover_minutes'));
    }

    public static function for(StayType $type, string $checkIn, ?string $checkOut = null, ?string $startTime = null): self
    {
        $tz = config('app.timezone');
        $day = CarbonImmutable::createFromFormat('!Y-m-d', $checkIn, $tz);

        return match ($type) {
            StayType::Night => self::nights($day, $checkOut, $tz),
            StayType::Day => new self(
                $type,
                $day->setTimeFromTimeString(config('harmony.day_stay.start')),
                $day->setTimeFromTimeString(config('harmony.day_stay.end')),
                0,
            ),
            StayType::ThreeHours => self::threeHours($day, $startTime),
        };
    }

    private static function nights(CarbonImmutable $day, ?string $checkOut, string $tz): self
    {
        if ($checkOut === null) {
            throw BookingException::invalidDates('Indiquez une date de départ.');
        }

        $out = CarbonImmutable::createFromFormat('!Y-m-d', $checkOut, $tz);
        $nights = (int) round($day->diffInDays($out, false));

        if ($nights < 1) {
            throw BookingException::invalidDates('La date de départ doit suivre la date d’arrivée.');
        }
        if ($nights > (int) config('harmony.max_nights')) {
            throw BookingException::invalidDates('Durée de séjour trop longue : contactez la conciergerie.');
        }

        return new self(
            StayType::Night,
            $day->setTimeFromTimeString(config('harmony.check_in_time')),
            $out->setTimeFromTimeString(config('harmony.check_out_time')),
            $nights,
        );
    }

    private static function threeHours(CarbonImmutable $day, ?string $startTime): self
    {
        if ($startTime === null || ! preg_match('/^(0[89]|1\d|20):00$/', $startTime)) {
            throw BookingException::invalidDates('Choisissez une heure pleine entre 08:00 et 20:00.');
        }

        $start = $day->setTimeFromTimeString($startTime);

        return new self(StayType::ThreeHours, $start, $start->addHours(3), 0);
    }
}
