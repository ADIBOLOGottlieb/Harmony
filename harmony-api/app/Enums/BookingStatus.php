<?php

namespace App\Enums;

enum BookingStatus: string
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
}
