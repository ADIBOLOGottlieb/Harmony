<?php

namespace App\Filament\Resources\Users;

use App\Enums\UserRole;
use App\Filament\Resources\Users\Pages\EditUser;
use App\Filament\Resources\Users\Pages\ListUsers;
use App\Models\User;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use UnitEnum;

/** Clients et comptes. Seuls les administrateurs modifient un rôle ou un mot de passe. */
class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $slug = 'comptes';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUsers;

    protected static string|UnitEnum|null $navigationGroup = 'Clients';

    protected static ?int $navigationSort = 1;

    protected static ?string $navigationLabel = 'Clients et comptes';

    protected static ?string $modelLabel = 'compte';

    public static function form(Schema $schema): Schema
    {
        return $schema->columns(2)->components([
            TextInput::make('name')->label('Nom')->maxLength(120),
            TextInput::make('phone')->label('Téléphone')->tel()->maxLength(20)->unique(ignoreRecord: true)
                ->regex('/^\+[1-9]\d{7,14}$/'),
            TextInput::make('email')->label('E-mail')->email()->unique(ignoreRecord: true),
            Select::make('role')->label('Rôle')->options(UserRole::class)->required(),
            TextInput::make('password')->label('Nouveau mot de passe (espace de gestion)')->password()->revealable()
                ->minLength(12)->dehydrated(fn ($state) => filled($state))->columnSpanFull()
                ->helperText('Laisser vide pour ne pas le changer. Nécessaire pour qu’un propriétaire ou un concierge se connecte ici.'),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')->label('Nom')->searchable()->placeholder('—'),
                TextColumn::make('phone')->label('Téléphone')->searchable()->copyable(),
                TextColumn::make('email')->label('E-mail')->searchable()->toggleable()->placeholder('—'),
                TextColumn::make('role')->label('Rôle')->badge(),
                TextColumn::make('bookings_count')->label('Réservations')->counts('bookings')->sortable(),
                TextColumn::make('created_at')->label('Inscrit le')->date('d/m/Y')->sortable(),
            ])
            ->filters([SelectFilter::make('role')->label('Rôle')->options(UserRole::class)])
            ->defaultSort('created_at', 'desc')
            ->recordActions([EditAction::make()]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListUsers::route('/'),
            'edit' => EditUser::route('/{record}/edit'),
        ];
    }
}
