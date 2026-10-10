<?php

namespace App\Filament\Resources\Zones\Schemas;

use App\Support\Media;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;
use Illuminate\Support\Str;

class ZoneForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            TextInput::make('name')->label('Nom')->required()->maxLength(80)
                ->live(onBlur: true)
                ->afterStateUpdated(fn ($state, $set, $get) => $get('slug') ? null : $set('slug', Str::slug((string) $state))),
            TextInput::make('slug')->label('Identifiant d’URL')->required()->alphaDash()->unique(ignoreRecord: true),
            TextInput::make('city')->label('Ville')->required()->default('Lomé'),
            TextInput::make('country')->label('Pays')->required()->default('Togo'),
            FileUpload::make('cover_path')->label('Photo de couverture')->image()
                ->disk(Media::disk())->directory('zones')->visibility('public')->maxSize(4096),
        ]);
    }
}
