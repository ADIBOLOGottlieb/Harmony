<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

enum MaintenanceType: string implements HasLabel
{
    case Cleaning = 'cleaning';
    case Repair = 'repair';
    case Inspection = 'inspection';

    public function label(): string
    {
        return match ($this) {
            self::Cleaning => 'Ménage',
            self::Repair => 'Maintenance',
            self::Inspection => 'État des lieux',
        };
    }

    public function getLabel(): string
    {
        return $this->label();
    }
}
