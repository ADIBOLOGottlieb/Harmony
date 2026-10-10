<?php

namespace App\Filament\Resources\Reviews;

use App\Filament\Resources\Reviews\Pages\ListReviews;
use App\Models\Review;
use BackedEnum;
use Filament\Actions\DeleteAction;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ToggleColumn;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use UnitEnum;

/** Modération des avis : seuls les avis publiés comptent dans la note affichée. */
class ReviewResource extends Resource
{
    protected static ?string $model = Review::class;

    protected static ?string $slug = 'avis';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedStar;

    protected static string|UnitEnum|null $navigationGroup = 'Clients';

    protected static ?int $navigationSort = 2;

    protected static ?string $modelLabel = 'avis';

    protected static ?string $pluralModelLabel = 'avis';

    public static function getNavigationBadge(): ?string
    {
        $waiting = Review::query()->where('published', false)->count();

        return $waiting > 0 ? (string) $waiting : null;
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with(['apartment', 'user']))
            ->columns([
                TextColumn::make('created_at')->label('Reçu le')->dateTime('d/m/Y')->sortable(),
                TextColumn::make('apartment.title')->label('Bien')->limit(26),
                TextColumn::make('user.name')->label('Client')->placeholder('Client'),
                TextColumn::make('rating')->label('Note')
                    ->formatStateUsing(fn ($state) => str_repeat('★', (int) $state).str_repeat('☆', 5 - (int) $state)),
                TextColumn::make('comment')->label('Commentaire')->wrap()->limit(160)->placeholder('—'),
                ToggleColumn::make('published')->label('Publié'),
            ])
            ->filters([TernaryFilter::make('published')->label('Publié')])
            ->defaultSort('created_at', 'desc')
            ->recordActions([DeleteAction::make()]);
    }

    public static function getPages(): array
    {
        return ['index' => ListReviews::route('/')];
    }
}
