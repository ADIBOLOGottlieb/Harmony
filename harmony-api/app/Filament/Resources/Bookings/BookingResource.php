<?php

namespace App\Filament\Resources\Bookings;

use App\Enums\BookingStatus;
use App\Filament\Resources\Bookings\Pages\ListBookings;
use App\Filament\Resources\Bookings\Pages\ViewBooking;
use App\Filament\Resources\Bookings\RelationManagers\PaymentsRelationManager;
use App\Models\Booking;
use App\Support\Fcfa;
use BackedEnum;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DatePicker;
use Filament\Infolists\Components\RepeatableEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use UnitEnum;

class BookingResource extends Resource
{
    protected static ?string $model = Booking::class;

    protected static ?string $slug = 'reservations';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCalendarDays;

    protected static string|UnitEnum|null $navigationGroup = 'Activité';

    protected static ?int $navigationSort = 1;

    protected static ?string $modelLabel = 'réservation';

    protected static ?string $recordTitleAttribute = 'reference';

    /** Un propriétaire ne voit que les réservations de ses biens. */
    public static function getEloquentQuery(): Builder
    {
        $query = parent::getEloquentQuery()->with(['apartment', 'user']);
        $user = auth()->user();

        return $user?->isOwner()
            ? $query->whereHas('apartment', fn (Builder $q) => $q->where('owner_id', $user->id))
            : $query;
    }

    public static function getNavigationBadge(): ?string
    {
        $pending = static::getEloquentQuery()->where('status', BookingStatus::Pending)->count();

        return $pending > 0 ? (string) $pending : null;
    }

    /** Coordonnées du client : réservées au personnel de la conciergerie. */
    public static function staff(): bool
    {
        return (bool) auth()->user()?->isStaff();
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('reference')->label('Référence')->searchable()->copyable()->weight('bold'),
                TextColumn::make('apartment.title')->label('Bien')->searchable()->limit(28),
                TextColumn::make('user.name')->label('Client')
                    ->formatStateUsing(fn ($state, Booking $record) => $record->user?->name ?: 'Client')
                    ->description(fn (Booking $record) => static::staff() ? $record->user?->phone : null)
                    ->searchable(['name', 'phone']),
                TextColumn::make('start_at')->label('Arrivée')->dateTime('d/m/Y H:i')->sortable(),
                TextColumn::make('end_at')->label('Départ')->dateTime('d/m/Y H:i')->sortable()->toggleable(),
                TextColumn::make('stay_type')->label('Séjour')->badge()->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('total_amount')->label('Total')->formatStateUsing(fn ($state) => Fcfa::format($state))->sortable(),
                TextColumn::make('amount_paid')->label('Réglé')->formatStateUsing(fn ($state) => Fcfa::format($state)),
                TextColumn::make('status')->label('Statut')->badge(),
            ])
            ->filters([
                SelectFilter::make('status')->label('Statut')->options(BookingStatus::class),
                SelectFilter::make('apartment')->label('Bien')->relationship('apartment', 'title')->searchable()->preload(),
                Filter::make('period')->label('Période')
                    ->schema([
                        DatePicker::make('from')->label('Arrivée à partir du')->native(false),
                        DatePicker::make('until')->label('Arrivée jusqu’au')->native(false),
                    ])
                    ->query(fn (Builder $query, array $data) => $query
                        ->when($data['from'] ?? null, fn (Builder $q, $d) => $q->whereDate('start_at', '>=', $d))
                        ->when($data['until'] ?? null, fn (Builder $q, $d) => $q->whereDate('start_at', '<=', $d))),
                Filter::make('upcoming')->label('À venir')->toggle()
                    ->query(fn (Builder $q) => $q->where('start_at', '>=', now()->startOfDay())),
            ])
            ->defaultSort('start_at', 'desc')
            ->recordActions([ViewAction::make()]);
    }

    public static function infolist(Schema $schema): Schema
    {
        $money = fn ($state) => Fcfa::format($state);

        return $schema->columns(3)->components([
            Section::make('Séjour')->columnSpan(2)->columns(2)->schema([
                TextEntry::make('reference')->label('Référence')->copyable(),
                TextEntry::make('status')->label('Statut')->badge(),
                TextEntry::make('apartment.title')->label('Bien'),
                TextEntry::make('stay_type')->label('Type de séjour')->badge(),
                TextEntry::make('start_at')->label('Arrivée')->dateTime('d/m/Y à H:i'),
                TextEntry::make('end_at')->label('Départ')->dateTime('d/m/Y à H:i'),
                TextEntry::make('guests')->label('Voyageurs'),
                TextEntry::make('nights')->label('Nuits'),
                TextEntry::make('cancellation_deadline')->label('Annulation gratuite jusqu’au')->dateTime('d/m/Y H:i')->placeholder('—'),
                TextEntry::make('cancel_reason')->label('Motif d’annulation')->placeholder('—')
                    ->formatStateUsing(fn ($state) => $state === 'expired' ? 'Paiement non reçu dans le délai' : $state),
            ]),
            Section::make('Client')->columnSpan(1)->schema([
                TextEntry::make('user.name')->label('Nom')->placeholder('Non renseigné'),
                TextEntry::make('user.phone')->label('Téléphone')->visible(fn () => static::staff())->copyable(),
                TextEntry::make('user.email')->label('E-mail')->visible(fn () => static::staff())->placeholder('—'),
            ]),
            Section::make('Montants')->columnSpanFull()->columns(4)->schema([
                RepeatableEntry::make('price_breakdown')->label('Détail')->columnSpanFull()->columns(2)->schema([
                    TextEntry::make('label')->hiddenLabel(),
                    TextEntry::make('amount')->hiddenLabel()->formatStateUsing($money),
                ]),
                TextEntry::make('total_amount')->label('Total')->formatStateUsing($money)->weight('bold'),
                TextEntry::make('advance_amount')->label('Acompte')->formatStateUsing($money),
                TextEntry::make('amount_paid')->label('Déjà réglé')->formatStateUsing($money),
                TextEntry::make('security_deposit')->label('Caution (à l’arrivée)')->formatStateUsing($money),
            ]),
        ]);
    }

    public static function getRelations(): array
    {
        return [PaymentsRelationManager::class];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListBookings::route('/'),
            'view' => ViewBooking::route('/{record}'),
        ];
    }
}
