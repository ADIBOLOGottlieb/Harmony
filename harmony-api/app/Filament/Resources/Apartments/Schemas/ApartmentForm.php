<?php

namespace App\Filament\Resources\Apartments\Schemas;

use App\Enums\Amenity;
use App\Enums\ApartmentStatus;
use App\Enums\ApartmentType;
use App\Enums\UserRole;
use Filament\Forms\Components\CheckboxList;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TagsInput;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Str;

class ApartmentForm
{
    public static function configure(Schema $schema): Schema
    {
        $staff = fn (): bool => (bool) auth()->user()?->isStaff();
        $fcfa = fn (TextInput $input): TextInput => $input->integer()->minValue(0)->suffix('FCFA');

        return $schema->columns(2)->components([
            Section::make('Présentation')->columnSpanFull()->columns(2)->schema([
                TextInput::make('title')->label('Titre')->required()->maxLength(120)
                    ->live(onBlur: true)
                    ->afterStateUpdated(fn ($state, $set, $get) => $get('slug') ? null : $set('slug', Str::slug((string) $state))),
                TextInput::make('slug')->label('Identifiant d’URL')->required()->alphaDash()->unique(ignoreRecord: true),
                Select::make('type')->label('Type')->options(ApartmentType::class)->required(),
                Select::make('zone_id')->label('Zone')->relationship('zone', 'name')->required()->preload(),
                Textarea::make('description')->label('Description')->required()->rows(5)->columnSpanFull(),
            ]),
            Section::make('Capacité')->columns(4)->columnSpanFull()->schema([
                TextInput::make('bedrooms')->label('Chambres')->integer()->minValue(0)->required(),
                TextInput::make('bathrooms')->label('Salles de bain')->integer()->minValue(0)->required(),
                TextInput::make('capacity')->label('Voyageurs max.')->integer()->minValue(1)->required(),
                TextInput::make('surface_m2')->label('Surface')->integer()->minValue(1)->suffix('m²')->required(),
            ]),
            Section::make('Tarifs')->columns(2)->columnSpanFull()
                ->description('Montants entiers en FCFA. Les prix saisonniers se gèrent plus bas, une fois le bien enregistré.')
                ->schema([
                    $fcfa(TextInput::make('price_per_night')->label('Prix par nuit')->required()),
                    $fcfa(TextInput::make('deposit')->label('Caution (réglée à l’arrivée)')->required()),
                    $fcfa(TextInput::make('short_stay_day_price')->label('Journée 10 h – 18 h (facultatif)')),
                    $fcfa(TextInput::make('short_stay_three_hours_price')->label('Créneau de 3 heures (facultatif)')),
                ]),
            Section::make('Emplacement')->columns(2)->columnSpanFull()->schema([
                TextInput::make('area')->label('Quartier (affiché publiquement)')->required()->maxLength(120),
                TextInput::make('address')->label('Adresse exacte')->required()->maxLength(255)
                    ->helperText('Communiquée au client uniquement après confirmation de sa réservation.'),
                TextInput::make('latitude')->label('Latitude')->numeric()->required()->minValue(-90)->maxValue(90),
                TextInput::make('longitude')->label('Longitude')->numeric()->required()->minValue(-180)->maxValue(180),
            ]),
            Section::make('Équipements et règles')->columnSpanFull()->schema([
                CheckboxList::make('amenities')->label('Équipements')->columns(3)
                    ->options(collect(Amenity::cases())->mapWithKeys(fn (Amenity $a) => [$a->value => $a->label()])->all()),
                TagsInput::make('rules')->label('Règles de la maison')->placeholder('Ajouter une règle'),
            ]),
            Section::make('Publication')->columns(3)->columnSpanFull()->schema([
                Select::make('status')->label('Statut')->options(ApartmentStatus::class)->required()->default(ApartmentStatus::Available),
                Toggle::make('featured')->label('À la une')->visible($staff),
                Select::make('owner_id')->label('Propriétaire')->visible($staff)->searchable()->preload()
                    ->relationship('owner', 'name', fn (Builder $q) => $q->where('role', UserRole::Owner->value)),
            ]),
        ]);
    }
}
