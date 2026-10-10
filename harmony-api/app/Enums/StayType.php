<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

enum StayType: string implements HasLabel
{
    case Night = 'night';
    case Day = 'day';
    case ThreeHours = 'three_hours';

    public function label(): string
    {
        return match ($this) {
            self::Night => 'Nuitée',
            self::Day => 'Journée',
            self::ThreeHours => 'Créneau de 3 heures',
        };
    }

    public function getLabel(): string
    {
        return $this->label();
    }
}
