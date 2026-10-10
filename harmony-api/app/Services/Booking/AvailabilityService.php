<?php

namespace App\Services\Booking;

use App\Models\Apartment;
use App\Models\ApartmentBlock;
use App\Models\Booking;
use App\Models\SeasonalPrice;
use Carbon\CarbonImmutable;

/** Disponibilités d'un appartement : réservations actives et jours bloqués. */
class AvailabilityService
{
    /** Vrai si l'intervalle [start, blockedUntil) croise une réservation active ou un blocage. */
    public function conflicts(Apartment $apartment, CarbonImmutable $start, CarbonImmutable $blockedUntil): bool
    {
        $booked = Booking::query()
            ->where('apartment_id', $apartment->id)
            ->occupying()
            ->where('start_at', '<', $blockedUntil)
            ->where('blocked_until', '>', $start)
            ->exists();

        if ($booked) {
            return true;
        }

        // Un blocage couvre des journées entières, bornes incluses.
        return ApartmentBlock::query()
            ->where('apartment_id', $apartment->id)
            ->whereDate('starts_on', '<=', $blockedUntil->subSecond()->toDateString())
            ->whereDate('ends_on', '>=', $start->toDateString())
            ->exists();
    }

    /**
     * Calendrier des nuits : pour chaque date, la nuit qui commence ce jour-là
     * est « free », « booked », « blocked » ou « past », avec son prix.
     *
     * @return list<array{date: string, status: string, price: int}>
     */
    public function calendar(Apartment $apartment, CarbonImmutable $from, CarbonImmutable $to): array
    {
        $checkIn = config('harmony.check_in_time');
        $checkOut = config('harmony.check_out_time');
        $rangeStart = $from->setTimeFromTimeString($checkIn);
        $rangeEnd = $to->addDay()->setTimeFromTimeString($checkOut);

        $bookings = Booking::query()
            ->where('apartment_id', $apartment->id)
            ->occupying()
            ->where('start_at', '<', $rangeEnd)
            ->where('blocked_until', '>', $rangeStart)
            ->get(['start_at', 'blocked_until']);

        $blocks = ApartmentBlock::query()
            ->where('apartment_id', $apartment->id)
            ->whereDate('starts_on', '<=', $to->toDateString())
            ->whereDate('ends_on', '>=', $from->toDateString())
            ->get(['starts_on', 'ends_on']);

        $seasons = SeasonalPrice::query()
            ->where('apartment_id', $apartment->id)
            ->whereDate('starts_on', '<=', $to->toDateString())
            ->whereDate('ends_on', '>=', $from->toDateString())
            ->orderByDesc('id')
            ->get();

        $today = now()->startOfDay();
        $days = [];
        for ($day = $from; $day->lte($to); $day = $day->addDay()) {
            $nightStart = $day->setTimeFromTimeString($checkIn);
            $nightEnd = $day->addDay()->setTimeFromTimeString($checkOut);

            $status = match (true) {
                $day->lt($today) => 'past',
                $blocks->contains(fn ($b) => $day->betweenIncluded($b->starts_on, $b->ends_on)) => 'blocked',
                $bookings->contains(fn ($b) => $b->start_at->lt($nightEnd) && $b->blocked_until->gt($nightStart)) => 'booked',
                default => 'free',
            };

            $season = $seasons->first(fn ($s) => $day->betweenIncluded($s->starts_on, $s->ends_on));

            $days[] = [
                'date' => $day->toDateString(),
                'status' => $status,
                'price' => $season?->price_per_night ?? $apartment->price_per_night,
            ];
        }

        return $days;
    }
}
