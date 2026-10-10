<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

enum UserRole: string implements HasLabel
{
    case Client = 'client';
    case Owner = 'owner';
    case Concierge = 'concierge';
    case Admin = 'admin';

    /** Personnel de la conciergerie (accès à l'espace de gestion complet). */
    public function isStaff(): bool
    {
        return $this === self::Concierge || $this === self::Admin;
    }

    public function label(): string
    {
        return match ($this) {
            self::Client => 'Client',
            self::Owner => 'Propriétaire',
            self::Concierge => 'Concierge',
            self::Admin => 'Administrateur',
        };
    }

    public function getLabel(): string
    {
        return $this->label();
    }
}
