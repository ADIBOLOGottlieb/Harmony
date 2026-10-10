<?php

namespace Database\Factories;

use App\Models\Zone;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/** @extends Factory<Zone> */
class ZoneFactory extends Factory
{
    public function definition(): array
    {
        $name = fake()->unique()->city();

        return [
            'slug' => Str::slug($name),
            'name' => $name,
            'city' => 'Lomé',
            'country' => 'Togo',
            'cover_path' => 'demo/p01.webp',
        ];
    }
}
