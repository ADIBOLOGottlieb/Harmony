<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

enum PaymentMethod: string implements HasLabel
{
    case MobileMoney = 'mobile_money';
    case Card = 'card';
    case BankTransfer = 'bank_transfer';

    public function label(): string
    {
        return match ($this) {
            self::MobileMoney => 'Mobile Money (TMoney, Flooz)',
            self::Card => 'Carte bancaire',
            self::BankTransfer => 'Virement bancaire',
        };
    }

    public function getLabel(): string
    {
        return $this->label();
    }
}
