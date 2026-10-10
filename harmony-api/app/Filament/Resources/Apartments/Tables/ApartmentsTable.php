<?php

namespace App\Filament\Resources\Apartments\Tables;

use App\Enums\ApartmentStatus;
use App\Enums\ApartmentType;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class ApartmentsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('title')->label('Bien')->searchable()->sortable()
                    ->description(fn ($record) => $record->area),
                TextColumn::make('zone.name')->label('Zone')->sortable(),
                TextColumn::make('type')->label('Type')->badge(),
                TextColumn::make('price_per_night')->label('Nuit')->numeric(thousandsSeparator: ' ')->suffix(' FCFA')->sortable(),
                TextColumn::make('status')->label('Statut')->badge(),
                IconColumn::make('featured')->label('Une')->boolean(),
                TextColumn::make('owner.name')->label('Propriétaire')->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('zone')->label('Zone')->relationship('zone', 'name'),
                SelectFilter::make('type')->label('Type')->options(ApartmentType::class),
                SelectFilter::make('status')->label('Statut')->options(ApartmentStatus::class),
            ])
            ->defaultSort('title')
            ->recordActions([EditAction::make()]);
    }
}
