<?php

namespace App\Enums;

enum PaymentKind: string
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
}
