<?php

namespace App\Filament\Resources\ArtworkOrders;

use App\Enums\ArtworkOrderStatus;
use App\Filament\Resources\ArtworkOrders\Pages\ListArtworkOrders;
use App\Filament\Resources\ArtworkOrders\Pages\ViewArtworkOrder;
use App\Models\ArtworkOrder;
use App\Support\Fcfa;
use BackedEnum;
use Filament\Actions\ViewAction;
use Filament\Infolists\Components\TextEntry;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use UnitEnum;

class ArtworkOrderResource extends Resource
{
    protected static ?string $model = ArtworkOrder::class;

    protected static ?string $slug = 'acquisitions';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedShoppingBag;

    protected static string|UnitEnum|null $navigationGroup = 'Galerie';

    protected static ?int $navigationSort = 0;

    protected static ?string $navigationLabel = 'Acquisitions';

    protected static ?string $modelLabel = 'acquisition';

    protected static ?string $recordTitleAttribute = 'reference';

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->with(['artwork.artist', 'user']);
    }

    public static function getNavigationBadge(): ?string
    {
        $pending = ArtworkOrder::query()->where('status', ArtworkOrderStatus::Pending)->count();

        return $pending > 0 ? (string) $pending : null;
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('reference')->label('Référence')->searchable()->copyable()->weight('bold'),
                TextColumn::make('artwork.title')->label('Œuvre')->description(fn (ArtworkOrder $record) => $record->artwork?->artist?->name),
                TextColumn::make('user.name')->label('Client')->placeholder('Client')
                    ->description(fn (ArtworkOrder $record) => $record->user?->phone)->searchable(['name', 'phone']),
                TextColumn::make('delivery_method')->label('Remise')->badge(),
                TextColumn::make('total')->label('Total')->formatStateUsing(fn ($state) => Fcfa::format($state))->sortable(),
                TextColumn::make('status')->label('Statut')->badge(),
                TextColumn::make('created_at')->label('Demandée le')->dateTime('d/m/Y H:i')->sortable(),
                TextColumn::make('expires_at')->label('Réservée jusqu’au')->dateTime('d/m/Y H:i')->placeholder('—')->toggleable(),
            ])
            ->filters([SelectFilter::make('status')->label('Statut')->options(ArtworkOrderStatus::class)])
            ->defaultSort('created_at', 'desc')
            ->recordActions([ViewAction::make()]);
    }

    public static function infolist(Schema $schema): Schema
    {
        $money = fn ($state) => Fcfa::format($state);

        return $schema->columns(2)->components([
            Section::make('Demande')->columns(2)->schema([
                TextEntry::make('reference')->label('Référence')->copyable(),
                TextEntry::make('status')->label('Statut')->badge(),
                TextEntry::make('artwork.title')->label('Œuvre'),
                TextEntry::make('artwork.artist.name')->label('Artiste'),
                TextEntry::make('price')->label('Prix')->formatStateUsing($money),
                TextEntry::make('delivery_fee')->label('Livraison')->formatStateUsing($money),
                TextEntry::make('total')->label('Total')->formatStateUsing($money)->weight('bold'),
                TextEntry::make('expires_at')->label('Réservée jusqu’au')->dateTime('d/m/Y H:i')->placeholder('—'),
                TextEntry::make('paid_at')->label('Réglée le')->dateTime('d/m/Y H:i')->placeholder('—'),
                TextEntry::make('cancel_reason')->label('Motif d’annulation')->placeholder('—')
                    ->formatStateUsing(fn ($state) => match ($state) {
                        'expired' => 'Non réglée dans le délai',
                        'cancelled_by_client' => 'Annulée par le client',
                        default => $state,
                    }),
            ]),
            Section::make('Client et remise')->schema([
                TextEntry::make('user.name')->label('Nom')->placeholder('Non renseigné'),
                TextEntry::make('user.phone')->label('Téléphone')->copyable(),
                TextEntry::make('delivery_method')->label('Remise')->badge(),
                TextEntry::make('delivery_address')->label('Adresse de livraison')->placeholder('—'),
                TextEntry::make('note')->label('Message du client')->placeholder('—'),
            ]),
        ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListArtworkOrders::route('/'),
            'view' => ViewArtworkOrder::route('/{record}'),
        ];
    }
}
