<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

enum PaymentKind: string implements HasLabel
{
    case Advance = 'advance';
    case Balance = 'balance';
    case Full = 'full';
    case Refund = 'refund';

    public function label(): string
    {
        return match ($this) {
            self::Advance => 'Acompte',
            self::Balance => 'Solde',
            self::Full => 'Paiement intégral',
            self::Refund => 'Remboursement',
        };
    }

    public function getLabel(): string
    {
        return $this->label();
    }
}
