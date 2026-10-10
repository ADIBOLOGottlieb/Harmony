<?php

namespace App\Filament\Resources\Zones\Tables;

use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class ZonesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')->label('Nom')->searchable()->sortable(),
                TextColumn::make('city')->label('Ville'),
                TextColumn::make('apartments_count')->label('Biens')->counts('apartments')->sortable(),
            ])
            ->defaultSort('name')
            ->recordActions([EditAction::make()]);
    }
}
