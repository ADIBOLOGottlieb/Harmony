<?php

namespace App\Enums;

use Filament\Support\Contracts\HasColor;
use Filament\Support\Contracts\HasLabel;

enum ArtworkStatus: string implements HasColor, HasLabel
{
    case Available = 'available';
    case Reserved = 'reserved';
    case Sold = 'sold';

    public function label(): string
    {
        return match ($this) {
            self::Available => 'Disponible',
            self::Reserved => 'Réservée',
            self::Sold => 'Vendue',
        };
    }

    public function getLabel(): string
    {
        return $this->label();
    }

    public function getColor(): string
    {
        return match ($this) {
            self::Available => 'success',
            self::Reserved => 'warning',
            self::Sold => 'gray',
        };
    }
}
