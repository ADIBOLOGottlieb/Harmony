<?php

namespace App\Filament\Resources\Apartments\RelationManagers;

use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\TextInput;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

/** Prix par nuit spécifiques à une période (fêtes, haute saison). Les réservations existantes ne changent pas. */
class SeasonalPricesRelationManager extends RelationManager
{
    protected static string $relationship = 'seasonalPrices';

    protected static ?string $title = 'Prix saisonniers';

    protected static ?string $modelLabel = 'prix saisonnier';

    protected static ?string $pluralModelLabel = 'prix saisonniers';

    public function form(Schema $schema): Schema
    {
        return $schema->columns(2)->components([
            TextInput::make('label')->label('Libellé')->placeholder('Fêtes de fin d’année')->maxLength(80)->columnSpanFull(),
            DatePicker::make('starts_on')->label('Du')->required()->native(false),
            DatePicker::make('ends_on')->label('Au (inclus)')->required()->native(false)->afterOrEqual('starts_on'),
            TextInput::make('price_per_night')->label('Prix par nuit')->integer()->minValue(0)->suffix('FCFA')->required(),
        ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->defaultSort('starts_on', 'desc')
            ->columns([
                TextColumn::make('label')->label('Libellé')->placeholder('—'),
                TextColumn::make('starts_on')->label('Du')->date('d/m/Y'),
                TextColumn::make('ends_on')->label('Au')->date('d/m/Y'),
                TextColumn::make('price_per_night')->label('Nuit')->numeric(thousandsSeparator: ' ')->suffix(' FCFA'),
            ])
            ->headerActions([CreateAction::make()])
            ->recordActions([EditAction::make(), DeleteAction::make()]);
    }
}
