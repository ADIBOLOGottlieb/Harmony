<?php

namespace Database\Factories;

use App\Enums\Amenity;
use App\Enums\ApartmentStatus;
use App\Enums\ApartmentType;
use App\Models\Apartment;
use App\Models\Zone;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/** @extends Factory<Apartment> */
class ApartmentFactory extends Factory
{
    public function definition(): array
    {
        $title = 'Appartement '.fake()->unique()->lastName();

        return [
            'slug' => Str::slug($title),
            'zone_id' => Zone::factory(),
            'title' => $title,
            'description' => fake()->paragraph(),
            'type' => ApartmentType::TwoRooms,
            'bedrooms' => 1,
            'bathrooms' => 1,
            'capacity' => 2,
            'surface_m2' => 50,
            'amenities' => [Amenity::Wifi->value, Amenity::AirConditioning->value],
            'price_per_night' => 30000,
            'deposit' => 40000,
            'status' => ApartmentStatus::Available,
            'latitude' => 6.13,
            'longitude' => 1.22,
            'address' => 'Lomé',
            'area' => 'Lomé',
            'rules' => ['Non-fumeur à l’intérieur'],
            'listed_at' => now(),
        ];
    }
}
