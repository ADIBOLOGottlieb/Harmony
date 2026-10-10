<?php

namespace App\Services\Booking;

use App\Enums\StayType;
use App\Models\Apartment;
use App\Models\SeasonalPrice;
use Carbon\CarbonImmutable;

/** Calcul du prix d'un séjour : nuits (avec prix saisonniers) ou séjour court, frais, acompte. */
class PricingService
{
    public function quote(Apartment $apartment, StayWindow $window): Quote
    {
        [$accommodation, $lines] = match ($window->type) {
            StayType::Night => $this->nights($apartment, $window),
            StayType::Day => $this->flat($apartment->short_stay_day_price, __('Journée')),
            StayType::ThreeHours => $this->flat($apartment->short_stay_three_hours_price, __('Créneau de 3 heures')),
        };

        $serviceFee = (int) round($accommodation * (float) config('harmony.service_fee_rate'));
        $total = $accommodation + $serviceFee;

        // Séjours courts : payés en totalité à la réservation.
        $advance = $window->type === StayType::Night
            ? (int) round($total * (float) config('harmony.advance_rate'))
            : $total;

        $lines[] = ['label' => __('Frais de service'), 'amount' => $serviceFee];

        return new Quote($window, $accommodation, $serviceFee, $total, $apartment->deposit, $advance, $lines);
    }

    /** @return array{0: int, 1: list<array{label: string, amount: int}>} */
    private function flat(?int $price, string $label): array
    {
        if (! $price) {
            throw BookingException::stayTypeUnavailable();
        }

        return [$price, [['label' => $label, 'amount' => $price]]];
    }

    /** @return array{0: int, 1: list<array{label: string, amount: int}>} */
    private function nights(Apartment $apartment, StayWindow $window): array
    {
        $first = $window->start->startOfDay();
        $last = $first->addDays($window->nights - 1);

        $seasons = SeasonalPrice::query()
            ->where('apartment_id', $apartment->id)
            ->whereDate('starts_on', '<=', $last->toDateString())
            ->whereDate('ends_on', '>=', $first->toDateString())
            ->orderByDesc('id')
            ->get();

        // Nombre de nuits par prix, dans l'ordre d'apparition.
        $perPrice = [];
        for ($night = $first; $night->lte($last); $night = $night->addDay()) {
            $price = $this->priceFor($night, $seasons->all()) ?? $apartment->price_per_night;
            $perPrice[$price] = ($perPrice[$price] ?? 0) + 1;
        }

        $total = 0;
        $lines = [];
        foreach ($perPrice as $price => $count) {
            $amount = $price * $count;
            $total += $amount;
            $lines[] = [
                'label' => __($count > 1 ? ':count nuits × :price FCFA' : ':count nuit × :price FCFA', [
                    'count' => $count,
                    'price' => number_format($price, 0, ',', ' '),
                ]),
                'amount' => $amount,
            ];
        }

        return [$total, $lines];
    }

    /** @param  list<SeasonalPrice>  $seasons */
    private function priceFor(CarbonImmutable $night, array $seasons): ?int
    {
        foreach ($seasons as $season) {
            if ($night->betweenIncluded($season->starts_on, $season->ends_on)) {
                return $season->price_per_night;
            }
        }

        return null;
    }
}
