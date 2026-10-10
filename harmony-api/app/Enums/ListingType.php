<?php

namespace App\Enums;

/** Nature d'une annonce de bien (phase 2 : vente et programmes neufs). */
enum ListingType: string
{
    case Rental = 'rental';
    case Sale = 'sale';
    case Development = 'development';

    public function label(): string
    {
        return match ($this) {
            self::Rental => 'Location',
            self::Sale => 'Vente',
            self::Development => 'Programme en construction',
        };
    }
}
