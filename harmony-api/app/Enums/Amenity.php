<?php

namespace App\Enums;

enum Amenity: string
{
    case Wifi = 'wifi';
    case AirConditioning = 'air_conditioning';
    case Parking = 'parking';
    case HotWater = 'hot_water';
    case Generator = 'generator';
    case Pool = 'pool';
    case Kitchen = 'kitchen';
    case Tv = 'tv';
    case Security = 'security';
    case Washer = 'washer';

    public function label(): string
    {
        return match ($this) {
            self::Wifi => 'Wi-Fi',
            self::AirConditioning => 'Climatisation',
            self::Parking => 'Parking',
            self::HotWater => 'Eau chaude',
            self::Generator => 'Groupe électrogène',
            self::Pool => 'Piscine',
            self::Kitchen => 'Cuisine équipée',
            self::Tv => 'Télévision',
            self::Security => 'Gardiennage 24 h/24',
            self::Washer => 'Lave-linge',
        };
    }

    /** @return list<string> */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
