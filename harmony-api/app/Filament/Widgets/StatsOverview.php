<?php

namespace App\Filament\Widgets;

use App\Enums\ApartmentStatus;
use App\Enums\BookingStatus;
use App\Enums\PaymentKind;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Filament\Widgets\Concerns\ScopesToOwner;
use App\Models\Apartment;
use App\Models\Booking;
use App\Models\Payment;
use App\Support\Fcfa;
use Carbon\CarbonImmutable;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

/** Indicateurs clés : occupation, encaissements, séjours à venir, virements à valider. */
class StatsOverview extends StatsOverviewWidget
{
    use ScopesToOwner;

    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $from = CarbonImmutable::now()->startOfDay();
        $to = $from->addDays(30);

        // Occupation des 30 prochains jours : nuits réservées / nuits disponibles.
        $apartments = $this->scopeApartments(Apartment::query(), '')
            ->where('status', ApartmentStatus::Available)->count();
        $booked = (int) $this->scopeApartments(Booking::query())
            ->whereIn('status', [BookingStatus::Confirmed, BookingStatus::Completed])
            ->where('start_at', '<', $to)->where('end_at', '>', $from)
            ->get(['start_at', 'end_at'])
            ->sum(fn (Booking $b) => max(0, (int) floor($b->start_at->max($from)->diffInDays($b->end_at->min($to), true))));
        $occupancy = $apartments > 0 ? min(100, (int) round(100 * $booked / ($apartments * 30))) : 0;

        $month = CarbonImmutable::now()->startOfMonth();
        $payments = fn () => $this->scopeApartments(Payment::query(), 'booking.apartment')
            ->where('status', PaymentStatus::Succeeded)->where('paid_at', '>=', $month);
        $revenue = (int) $payments()->where('kind', '!=', PaymentKind::Refund)->sum('amount')
            - (int) $payments()->where('kind', PaymentKind::Refund)->sum('amount');

        $upcoming = $this->scopeApartments(Booking::query())
            ->where('status', BookingStatus::Confirmed)->where('start_at', '>=', now())->count();

        $stats = [
            Stat::make('Occupation (30 prochains jours)', "{$occupancy} %")
                ->description("{$booked} nuits réservées · {$apartments} biens disponibles")->color('primary'),
            Stat::make('Encaissé ce mois-ci', Fcfa::format($revenue))
                ->description('Paiements reçus, remboursements déduits')->color('success'),
            Stat::make('Séjours à venir', (string) $upcoming)->description('Réservations confirmées'),
        ];

        if (auth()->user()?->isStaff()) {
            $transfers = Payment::query()->where('status', PaymentStatus::Pending)
                ->where('method', PaymentMethod::BankTransfer)->where('kind', '!=', PaymentKind::Refund)->count();
            $stats[] = Stat::make('Virements à valider', (string) $transfers)
                ->description('À rapprocher du relevé bancaire')->color($transfers > 0 ? 'warning' : 'gray');
        }

        return $stats;
    }
}
