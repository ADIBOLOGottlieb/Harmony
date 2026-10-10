<?php

namespace App\Filament\Widgets;

use App\Enums\BookingStatus;
use App\Filament\Resources\Bookings\BookingResource;
use App\Filament\Widgets\Concerns\ScopesToOwner;
use App\Models\Booking;
use App\Support\Fcfa;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;

/** Réservations des 14 prochains jours (y compris celles en attente de paiement). */
class UpcomingBookings extends TableWidget
{
    use ScopesToOwner;

    protected static ?int $sort = 3;

    protected int|string|array $columnSpan = 'full';

    protected static ?string $heading = 'Prochains séjours (14 jours)';

    public function table(Table $table): Table
    {
        return $table
            ->query(fn () => $this->scopeApartments(Booking::query()->with(['apartment']))
                ->whereIn('status', [BookingStatus::Pending, BookingStatus::Confirmed])
                ->where('start_at', '>', now()->endOfDay())
                ->where('start_at', '<=', now()->addDays(14)))
            ->defaultSort('start_at')
            ->paginated([10])
            ->emptyStateHeading('Aucun séjour prévu')
            ->columns([
                TextColumn::make('start_at')->label('Arrivée')->dateTime('d/m H:i'),
                TextColumn::make('end_at')->label('Départ')->dateTime('d/m H:i'),
                TextColumn::make('apartment.title')->label('Bien'),
                TextColumn::make('total_amount')->label('Total')->formatStateUsing(fn ($state) => Fcfa::format($state)),
                TextColumn::make('status')->label('Statut')->badge(),
            ])
            ->recordUrl(fn (Booking $record) => BookingResource::getUrl('view', ['record' => $record]));
    }
}
