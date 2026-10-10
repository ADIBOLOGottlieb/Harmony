<?php

namespace App\Filament\Resources\Artworks;

use App\Enums\ArtworkStatus;
use App\Filament\Resources\Artworks\Pages\CreateArtwork;
use App\Filament\Resources\Artworks\Pages\EditArtwork;
use App\Filament\Resources\Artworks\Pages\ListArtworks;
use App\Filament\Resources\Artworks\RelationManagers\PhotosRelationManager;
use App\Models\Artwork;
use App\Support\Fcfa;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Support\Str;
use UnitEnum;

class ArtworkResource extends Resource
{
    protected static ?string $model = Artwork::class;

    protected static ?string $slug = 'oeuvres';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedPaintBrush;

    protected static string|UnitEnum|null $navigationGroup = 'Galerie';

    protected static ?int $navigationSort = 1;

    protected static ?string $modelLabel = 'œuvre';

    protected static ?string $recordTitleAttribute = 'title';

    public static function form(Schema $schema): Schema
    {
        return $schema->columns(2)->components([
            Section::make('Œuvre')->columnSpanFull()->columns(2)->schema([
                TextInput::make('title')->label('Titre')->required()->maxLength(120)
                    ->live(onBlur: true)
                    ->afterStateUpdated(fn ($state, $set, $get) => $get('slug') ? null : $set('slug', Str::slug((string) $state))),
                TextInput::make('slug')->label('Identifiant d’URL')->required()->alphaDash()->unique(ignoreRecord: true),
                Select::make('artist_id')->label('Artiste')->relationship('artist', 'name')->required()->searchable()->preload(),
                TextInput::make('year')->label('Année')->integer()->minValue(1900)->maxValue((int) date('Y')),
                TextInput::make('medium')->label('Technique')->required()->placeholder('Acrylique sur toile'),
                TextInput::make('dimensions')->label('Dimensions')->required()->placeholder('80 × 100 cm'),
                Textarea::make('description')->label('Description')->required()->rows(5)->columnSpanFull(),
            ]),
            Section::make('Vente')->columnSpanFull()->columns(4)->schema([
                TextInput::make('price')->label('Prix')->integer()->minValue(0)->suffix('FCFA')->required(),
                Select::make('status')->label('Statut')->options(ArtworkStatus::class)->required()->default(ArtworkStatus::Available)
                    ->helperText('« Réservée » et « Vendue » suivent les demandes d’acquisition.'),
                Toggle::make('published')->label('Publiée')->default(true)->inline(false),
                Toggle::make('featured')->label('À la une')->inline(false),
            ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('title')->label('Œuvre')->searchable()->sortable()
                    ->description(fn (Artwork $record) => $record->artist?->name),
                TextColumn::make('medium')->label('Technique')->limit(30)->toggleable(),
                TextColumn::make('price')->label('Prix')->formatStateUsing(fn ($state) => Fcfa::format($state))->sortable(),
                TextColumn::make('status')->label('Statut')->badge(),
                IconColumn::make('published')->label('Publiée')->boolean(),
                IconColumn::make('featured')->label('Une')->boolean(),
            ])
            ->filters([
                SelectFilter::make('status')->label('Statut')->options(ArtworkStatus::class),
                SelectFilter::make('artist')->label('Artiste')->relationship('artist', 'name'),
            ])
            ->defaultSort('created_at', 'desc')
            ->recordActions([EditAction::make()]);
    }

    public static function getRelations(): array
    {
        return [PhotosRelationManager::class];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListArtworks::route('/'),
            'create' => CreateArtwork::route('/create'),
            'edit' => EditArtwork::route('/{record}/edit'),
        ];
    }
}
