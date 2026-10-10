<?php

namespace App\Filament\Resources\Artworks\RelationManagers;

use App\Support\Media;
use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Forms\Components\FileUpload;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

/** Visuels de l'œuvre, réordonnables (le premier sert de couverture). */
class PhotosRelationManager extends RelationManager
{
    protected static string $relationship = 'photos';

    protected static ?string $title = 'Visuels';

    protected static ?string $modelLabel = 'visuel';

    public function form(Schema $schema): Schema
    {
        return $schema->components([
            FileUpload::make('path')->label('Visuel')->image()->required()
                ->disk(Media::disk())->directory('artworks')->visibility('public')
                ->maxSize(8192)->imageEditor()->columnSpanFull(),
        ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->reorderable('position')
            ->defaultSort('position')
            ->columns([
                ImageColumn::make('path')->label('Aperçu')->disk(Media::disk())
                    ->getStateUsing(fn ($record) => str_starts_with($record->path, 'demo/') ? null : $record->path),
                TextColumn::make('path')->label('Fichier')->limit(40),
            ])
            ->headerActions([
                CreateAction::make()->mutateDataUsing(function (array $data): array {
                    $data['position'] = (int) $this->getOwnerRecord()->photos()->max('position') + 1;

                    return $data;
                }),
            ])
            ->recordActions([DeleteAction::make()]);
    }
}
