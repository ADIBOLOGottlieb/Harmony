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

/** Périodes bloquées (usage du propriétaire, travaux…) : le bien n'est pas réservable ces jours-là. */
class BlocksRelationManager extends RelationManager
{
    protected static string $relationship = 'blocks';

    protected static ?string $title = 'Blocages du calendrier';

    protected static ?string $modelLabel = 'blocage';

    public function form(Schema $schema): Schema
    {
        return $schema->columns(2)->components([
            DatePicker::make('starts_on')->label('Du')->required()->native(false),
            DatePicker::make('ends_on')->label('Au (inclus)')->required()->native(false)->afterOrEqual('starts_on'),
            TextInput::make('reason')->label('Motif (interne)')->maxLength(120)->columnSpanFull(),
        ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->defaultSort('starts_on', 'desc')
            ->columns([
                TextColumn::make('starts_on')->label('Du')->date('d/m/Y'),
                TextColumn::make('ends_on')->label('Au')->date('d/m/Y'),
                TextColumn::make('reason')->label('Motif')->placeholder('—'),
            ])
            ->headerActions([
                CreateAction::make()->mutateDataUsing(fn (array $data): array => $data + ['created_by' => auth()->id()]),
            ])
            ->recordActions([EditAction::make(), DeleteAction::make()]);
    }
}
