<?php

namespace App\Enums;

enum ApartmentStatus: string
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
}
