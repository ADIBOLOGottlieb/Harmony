<?php

namespace App\Enums;

enum PaymentMethod: string
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
}
