<?php

namespace App\Filament\Resources\Apartments\RelationManagers;

use App\Support\Media;
use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\TextInput;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

/** Photos du bien, réordonnables par glisser-déposer (la première sert de couverture). */
class PhotosRelationManager extends RelationManager
{
    protected static string $relationship = 'photos';

    protected static ?string $title = 'Photos';

    protected static ?string $modelLabel = 'photo';

    public function form(Schema $schema): Schema
    {
        return $schema->components([
            FileUpload::make('path')->label('Photo')->image()->required()
                ->disk(Media::disk())->directory('apartments')->visibility('public')
                ->maxSize(6144)->imageEditor()->columnSpanFull(),
            TextInput::make('caption')->label('Légende')->maxLength(120),
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
                TextColumn::make('caption')->label('Légende')->placeholder('—'),
                TextColumn::make('path')->label('Fichier')->limit(40)->toggleable(isToggledHiddenByDefault: true),
            ])
            ->headerActions([
                CreateAction::make()->mutateDataUsing(function (array $data): array {
                    $data['position'] = (int) $this->getOwnerRecord()->photos()->max('position') + 1;

                    return $data;
                }),
            ])
            ->recordActions([EditAction::make(), DeleteAction::make()]);
    }
}
