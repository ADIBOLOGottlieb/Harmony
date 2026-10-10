<?php

namespace App\Filament\Widgets;

use App\Enums\BookingStatus;
use App\Filament\Resources\Bookings\BookingResource;
use App\Filament\Widgets\Concerns\ScopesToOwner;
use App\Models\Booking;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Illuminate\Database\Eloquent\Builder;

/** Arrivées et départs du jour, pour organiser accueil et ménage. */
class TodayMovements extends TableWidget
{
    use ScopesToOwner;

    protected static ?int $sort = 2;

    protected int|string|array $columnSpan = 'full';

    protected static ?string $heading = 'Arrivées et départs du jour';

    public function table(Table $table): Table
    {
        $start = now()->startOfDay();
        $end = now()->endOfDay();

        return $table
            ->query(fn () => $this->scopeApartments(Booking::query()->with(['apartment', 'user']))
                ->where('status', BookingStatus::Confirmed)
                ->where(fn (Builder $q) => $q->whereBetween('start_at', [$start, $end])->orWhereBetween('end_at', [$start, $end])))
            ->defaultSort('start_at')
            ->paginated(false)
            ->emptyStateHeading('Aucun mouvement aujourd’hui')
            ->columns([
                TextColumn::make('movement')->label('Mouvement')->badge()
                    ->state(fn (Booking $record) => $record->start_at->isToday() ? 'Arrivée' : 'Départ')
                    ->color(fn (string $state) => $state === 'Arrivée' ? 'success' : 'info'),
                TextColumn::make('time')->label('Heure')
                    ->state(fn (Booking $record) => ($record->start_at->isToday() ? $record->start_at : $record->end_at)->format('H:i')),
                TextColumn::make('apartment.title')->label('Bien'),
                TextColumn::make('user.name')->label('Client')->placeholder('Client')
                    ->description(fn (Booking $record) => BookingResource::staff() ? $record->user?->phone : null),
                TextColumn::make('reference')->label('Référence'),
            ])
            ->recordUrl(fn (Booking $record) => BookingResource::getUrl('view', ['record' => $record]));
    }
}
