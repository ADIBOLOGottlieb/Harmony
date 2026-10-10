<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

enum ApartmentStatus: string implements HasLabel
{
    case Available = 'available';
    case Occupied = 'occupied';
    case Maintenance = 'maintenance';

    public function label(): string
    {
        return match ($this) {
            self::Available => 'Disponible',
            self::Occupied => 'Réservé',
            self::Maintenance => 'En maintenance',
        };
    }

    public function getLabel(): string
    {
        return $this->label();
    }
}
