<?php

namespace App\Enums;

use Filament\Support\Contracts\HasColor;
use Filament\Support\Contracts\HasLabel;

enum BookingStatus: string implements HasColor, HasLabel
{
    case Pending = 'pending';
    case Confirmed = 'confirmed';
    case Cancelled = 'cancelled';
    case Completed = 'completed';
    case Refunded = 'refunded';

    public function label(): string
    {
        return match ($this) {
            self::Pending => 'En attente de paiement',
            self::Confirmed => 'Confirmée',
            self::Cancelled => 'Annulée',
            self::Completed => 'Terminée',
            self::Refunded => 'Remboursée',
        };
    }

    /** Statuts qui occupent le calendrier (miroir de la contrainte d'exclusion). @return list<string> */
    public static function blocking(): array
    {
        return [self::Pending->value, self::Confirmed->value];
    }

    public function getLabel(): string
    {
        return $this->label();
    }

    public function getColor(): string
    {
        return match ($this) {
            self::Pending => 'warning',
            self::Confirmed => 'success',
            self::Cancelled => 'gray',
            self::Completed => 'info',
            self::Refunded => 'danger',
        };
    }
}
