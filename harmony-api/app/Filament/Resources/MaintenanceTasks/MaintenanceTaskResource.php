<?php

namespace App\Filament\Resources\MaintenanceTasks;

use App\Enums\MaintenanceStatus;
use App\Enums\MaintenanceType;
use App\Enums\UserRole;
use App\Filament\Resources\MaintenanceTasks\Pages\CreateMaintenanceTask;
use App\Filament\Resources\MaintenanceTasks\Pages\EditMaintenanceTask;
use App\Filament\Resources\MaintenanceTasks\Pages\ListMaintenanceTasks;
use App\Models\MaintenanceTask;
use App\Support\Fcfa;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use UnitEnum;

class MaintenanceTaskResource extends Resource
{
    protected static ?string $model = MaintenanceTask::class;

    protected static ?string $slug = 'menage-maintenance';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedWrenchScrewdriver;

    protected static string|UnitEnum|null $navigationGroup = 'Activité';

    protected static ?int $navigationSort = 2;

    protected static ?string $navigationLabel = 'Ménage et maintenance';

    protected static ?string $modelLabel = 'intervention';

    protected static ?string $recordTitleAttribute = 'title';

    /** Un propriétaire ne voit que les interventions sur ses biens. */
    public static function getEloquentQuery(): Builder
    {
        $query = parent::getEloquentQuery()->with(['apartment', 'assignee']);
        $user = auth()->user();

        return $user?->isOwner()
            ? $query->whereHas('apartment', fn (Builder $q) => $q->where('owner_id', $user->id))
            : $query;
    }

    public static function getNavigationBadge(): ?string
    {
        $due = static::getEloquentQuery()
            ->where('status', MaintenanceStatus::Todo)
            ->where('due_at', '<=', now()->endOfDay())
            ->count();

        return $due > 0 ? (string) $due : null;
    }

    public static function form(Schema $schema): Schema
    {
        return $schema->columns(2)->components([
            Select::make('apartment_id')->label('Bien')->relationship('apartment', 'title')->required()->searchable()->preload(),
            Select::make('type')->label('Type')->options(MaintenanceType::class)->required()->default(MaintenanceType::Repair),
            TextInput::make('title')->label('Intitulé')->required()->maxLength(160)->columnSpanFull(),
            Textarea::make('notes')->label('Notes')->rows(4)->columnSpanFull(),
            DateTimePicker::make('due_at')->label('À faire pour le')->native(false)->seconds(false),
            Select::make('status')->label('Statut')->options(MaintenanceStatus::class)->required()->default(MaintenanceStatus::Todo),
            Select::make('assigned_to')->label('Confiée à')->searchable()->preload()
                ->relationship('assignee', 'name', fn (Builder $q) => $q->whereIn('role', [UserRole::Concierge->value, UserRole::Admin->value])),
            TextInput::make('cost')->label('Coût')->integer()->minValue(0)->suffix('FCFA'),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('due_at')->label('Échéance')->dateTime('d/m/Y H:i')->sortable()->placeholder('—'),
                TextColumn::make('apartment.title')->label('Bien')->searchable()->limit(26),
                TextColumn::make('type')->label('Type')->badge(),
                TextColumn::make('title')->label('Intitulé')->searchable()->limit(40),
                TextColumn::make('status')->label('Statut')->badge(),
                TextColumn::make('assignee.name')->label('Confiée à')->placeholder('—'),
                TextColumn::make('cost')->label('Coût')->formatStateUsing(fn ($state) => $state === null ? '—' : Fcfa::format($state))
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('status')->label('Statut')->options(MaintenanceStatus::class)
                    ->default(MaintenanceStatus::Todo->value),
                SelectFilter::make('type')->label('Type')->options(MaintenanceType::class),
                SelectFilter::make('apartment')->label('Bien')->relationship('apartment', 'title'),
            ])
            ->defaultSort('due_at')
            ->recordActions([
                Action::make('done')->label('Terminée')->icon(Heroicon::OutlinedCheck)->color('success')
                    ->visible(fn (MaintenanceTask $record) => auth()->user()?->isStaff()
                        && in_array($record->status, [MaintenanceStatus::Todo, MaintenanceStatus::InProgress], true))
                    ->action(fn (MaintenanceTask $record) => $record->update([
                        'status' => MaintenanceStatus::Done,
                        'completed_at' => now(),
                    ])),
                EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListMaintenanceTasks::route('/'),
            'create' => CreateMaintenanceTask::route('/create'),
            'edit' => EditMaintenanceTask::route('/{record}/edit'),
        ];
    }
}
