<?php

namespace App\Filament\Resources\Apartments;

use App\Filament\Resources\Apartments\Pages\CreateApartment;
use App\Filament\Resources\Apartments\Pages\EditApartment;
use App\Filament\Resources\Apartments\Pages\ListApartments;
use App\Filament\Resources\Apartments\RelationManagers\BlocksRelationManager;
use App\Filament\Resources\Apartments\RelationManagers\PhotosRelationManager;
use App\Filament\Resources\Apartments\RelationManagers\SeasonalPricesRelationManager;
use App\Filament\Resources\Apartments\Schemas\ApartmentForm;
use App\Filament\Resources\Apartments\Tables\ApartmentsTable;
use App\Models\Apartment;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use UnitEnum;

class ApartmentResource extends Resource
{
    protected static ?string $model = Apartment::class;

    protected static ?string $slug = 'biens';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedHomeModern;

    protected static string|UnitEnum|null $navigationGroup = 'Catalogue';

    protected static ?int $navigationSort = 1;

    protected static ?string $modelLabel = 'bien';

    protected static ?string $pluralModelLabel = 'biens';

    protected static ?string $recordTitleAttribute = 'title';

    /** Un propriétaire ne voit que ses biens. */
    public static function getEloquentQuery(): Builder
    {
        $query = parent::getEloquentQuery();
        $user = auth()->user();

        return $user?->isOwner() ? $query->where('owner_id', $user->id) : $query;
    }

    public static function form(Schema $schema): Schema
    {
        return ApartmentForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return ApartmentsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            PhotosRelationManager::class,
            BlocksRelationManager::class,
            SeasonalPricesRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListApartments::route('/'),
            'create' => CreateApartment::route('/create'),
            'edit' => EditApartment::route('/{record}/edit'),
        ];
    }
}
