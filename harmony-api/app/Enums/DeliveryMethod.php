<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

enum DeliveryMethod: string implements HasLabel
{
    case Pickup = 'pickup';
    case Delivery = 'delivery';

    public function label(): string
    {
        return match ($this) {
            self::Pickup => 'Retrait à la galerie',
            self::Delivery => 'Livraison à Lomé',
        };
    }

    public function getLabel(): string
    {
        return $this->label();
    }
}
