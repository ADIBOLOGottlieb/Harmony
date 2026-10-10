<?php

namespace App\Enums;

enum ApartmentType: string
{
    case Studio = 'studio';
    case TwoRooms = 'two_rooms';
    case ThreeRooms = 'three_rooms';
    case FourRooms = 'four_rooms';
    case Duplex = 'duplex';
    case Villa = 'villa';

    public function label(): string
    {
        return match ($this) {
            self::Studio => 'Studio',
            self::TwoRooms => '2 pièces',
            self::ThreeRooms => '3 pièces',
            self::FourRooms => '4 pièces',
            self::Duplex => 'Duplex',
            self::Villa => 'Villa',
        };
    }
}
