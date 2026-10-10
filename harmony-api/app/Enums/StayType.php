<?php

namespace App\Enums;

enum StayType: string
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
}
