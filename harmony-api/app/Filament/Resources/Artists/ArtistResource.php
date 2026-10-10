<?php

namespace App\Filament\Resources\Artists;

use App\Filament\Resources\Artists\Pages\CreateArtist;
use App\Filament\Resources\Artists\Pages\EditArtist;
use App\Filament\Resources\Artists\Pages\ListArtists;
use App\Models\Artist;
use App\Support\Media;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Support\Str;
use UnitEnum;

class ArtistResource extends Resource
{
    protected static ?string $model = Artist::class;

    protected static ?string $slug = 'artistes';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUserCircle;

    protected static string|UnitEnum|null $navigationGroup = 'Galerie';

    protected static ?int $navigationSort = 2;

    protected static ?string $modelLabel = 'artiste';

    protected static ?string $recordTitleAttribute = 'name';

    public static function form(Schema $schema): Schema
    {
        return $schema->columns(2)->components([
            TextInput::make('name')->label('Nom')->required()->maxLength(120)
                ->live(onBlur: true)
                ->afterStateUpdated(fn ($state, $set, $get) => $get('slug') ? null : $set('slug', Str::slug((string) $state))),
            TextInput::make('slug')->label('Identifiant d’URL')->required()->alphaDash()->unique(ignoreRecord: true),
            TextInput::make('country')->label('Pays')->required()->default('Togo'),
            FileUpload::make('portrait_path')->label('Portrait')->image()->avatar()
                ->disk(Media::disk())->directory('artists')->visibility('public')->maxSize(4096),
            Textarea::make('bio')->label('Biographie')->rows(5)->columnSpanFull(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')->label('Nom')->searchable()->sortable(),
                TextColumn::make('country')->label('Pays'),
                TextColumn::make('artworks_count')->label('Œuvres')->counts('artworks')->sortable(),
            ])
            ->defaultSort('name')
            ->recordActions([EditAction::make()]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListArtists::route('/'),
            'create' => CreateArtist::route('/create'),
            'edit' => EditArtist::route('/{record}/edit'),
        ];
    }
}
