<?php

namespace Database\Seeders;

use App\Enums\Amenity;
use App\Enums\ApartmentStatus;
use App\Enums\ApartmentType;
use App\Enums\UserRole;
use App\Models\Apartment;
use App\Models\User;
use App\Models\Zone;
use Illuminate\Database\Seeder;

/**
 * Catalogue de démonstration : 5 quartiers et 8 biens à Lomé, identiques à
 * ceux de l'application (photos « demo/… » embarquées dans l'app).
 * Idempotent : peut être relancé sans créer de doublons.
 */
class CatalogSeeder extends Seeder
{
    private const RULES = [
        'Arrivée à partir de 14 h, départ avant 11 h',
        'Non-fumeur à l’intérieur',
        'Pas de fêtes ni d’événements sans accord',
        'Animaux non admis',
    ];

    public function run(): void
    {
        $owner = User::query()->firstOrCreate(
            ['phone' => '+22800000001'],
            ['name' => 'Propriétaire démo', 'role' => UserRole::Owner],
        );

        $zones = collect([
            ['kodjoviakope', 'Kodjoviakopé', 'demo/p02.webp'],
            ['baguida', 'Baguida', 'demo/p01.webp'],
            ['tokoin', 'Tokoin', 'demo/p04.webp'],
            ['avedji', 'Avédji', 'demo/p07.webp'],
            ['agoe', 'Agoè', 'demo/p11.webp'],
        ])->mapWithKeys(fn (array $z) => [
            $z[0] => Zone::query()->updateOrCreate(
                ['slug' => $z[0]],
                ['name' => $z[1], 'city' => 'Lomé', 'country' => 'Togo', 'cover_path' => $z[2]],
            ),
        ]);

        $all = Amenity::values();
        $a = fn (Amenity ...$list) => array_map(fn (Amenity $x) => $x->value, $list);

        $apartments = [
            [
                'slug' => 'villa-lagune', 'zone' => 'baguida', 'title' => 'Villa Lagune', 'type' => ApartmentType::Villa,
                'description' => 'Villa contemporaine en bord de mer, entièrement climatisée, avec piscine privée, jardin et terrasse ombragée. Idéale pour les familles et les séjours d’affaires prolongés, à 20 minutes du centre.',
                'bedrooms' => 4, 'bathrooms' => 3, 'capacity' => 8, 'surface_m2' => 280, 'amenities' => $all,
                'price_per_night' => 150000, 'deposit' => 300000, 'short_stay_day_price' => 90000,
                'status' => ApartmentStatus::Available, 'latitude' => 6.1630, 'longitude' => 1.3220,
                'address' => 'Route d’Aného, Baguida', 'rating' => 4.9, 'review_count' => 38, 'featured' => true,
                'listed_at' => '2026-08-12', 'photos' => ['p01', 'p05', 'p13', 'p03'],
            ],
            [
                'slug' => 'duplex-horizon', 'zone' => 'kodjoviakope', 'title' => 'Duplex Horizon', 'type' => ApartmentType::Duplex,
                'description' => 'Duplex lumineux avec vue dégagée sur la ville, salon double hauteur et suite parentale. À deux pas de la plage et des restaurants du centre.',
                'bedrooms' => 3, 'bathrooms' => 2, 'capacity' => 6, 'surface_m2' => 160,
                'amenities' => $a(Amenity::Wifi, Amenity::AirConditioning, Amenity::Parking, Amenity::HotWater, Amenity::Generator, Amenity::Kitchen, Amenity::Tv, Amenity::Security, Amenity::Washer),
                'price_per_night' => 95000, 'deposit' => 150000,
                'status' => ApartmentStatus::Available, 'latitude' => 6.1255, 'longitude' => 1.2050,
                'address' => 'Boulevard du Mono, Kodjoviakopé', 'rating' => 4.8, 'review_count' => 52, 'featured' => true,
                'listed_at' => '2026-09-20', 'photos' => ['p02', 'p06', 'p04', 'p14'],
            ],
            [
                'slug' => 'les-cocotiers', 'zone' => 'tokoin', 'title' => 'Appartement Les Cocotiers', 'type' => ApartmentType::ThreeRooms,
                'description' => 'Trois pièces calme et bien agencé, au cœur de Tokoin. Cuisine équipée, groupe électrogène et connexion fibre pour télétravailler sereinement.',
                'bedrooms' => 2, 'bathrooms' => 1, 'capacity' => 4, 'surface_m2' => 95,
                'amenities' => $a(Amenity::Wifi, Amenity::AirConditioning, Amenity::HotWater, Amenity::Kitchen, Amenity::Tv, Amenity::Generator),
                'price_per_night' => 45000, 'deposit' => 60000, 'short_stay_three_hours_price' => 15000, 'short_stay_day_price' => 30000,
                'status' => ApartmentStatus::Available, 'latitude' => 6.1450, 'longitude' => 1.2160,
                'address' => 'Tokoin Hôpital, Lomé', 'rating' => 4.7, 'review_count' => 64, 'featured' => false,
                'listed_at' => '2026-07-02', 'photos' => ['p04', 'p03', 'p12'],
            ],
            [
                'slug' => 'studio-atlantique', 'zone' => 'kodjoviakope', 'title' => 'Studio Atlantique', 'type' => ApartmentType::Studio,
                'description' => 'Studio design et fonctionnel, à 5 minutes à pied de la plage. Parfait pour un voyageur ou un couple.',
                'bedrooms' => 1, 'bathrooms' => 1, 'capacity' => 2, 'surface_m2' => 38,
                'amenities' => $a(Amenity::Wifi, Amenity::AirConditioning, Amenity::HotWater, Amenity::Kitchen, Amenity::Tv),
                'price_per_night' => 25000, 'deposit' => 30000, 'short_stay_three_hours_price' => 10000, 'short_stay_day_price' => 18000,
                'status' => ApartmentStatus::Available, 'latitude' => 6.1240, 'longitude' => 1.2090,
                'address' => 'Rue de la Plage, Kodjoviakopé', 'rating' => 4.6, 'review_count' => 21, 'featured' => false,
                'listed_at' => '2026-10-02', 'photos' => ['p09', 'p13'],
            ],
            [
                'slug' => 'jardin-avedji', 'zone' => 'avedji', 'title' => 'Deux-pièces Jardin', 'type' => ApartmentType::TwoRooms,
                'description' => 'Rez-de-jardin au calme, baigné de lumière, avec parking privé et lave-linge.',
                'bedrooms' => 1, 'bathrooms' => 1, 'capacity' => 3, 'surface_m2' => 60,
                'amenities' => $a(Amenity::Wifi, Amenity::AirConditioning, Amenity::Parking, Amenity::HotWater, Amenity::Kitchen, Amenity::Washer),
                'price_per_night' => 30000, 'deposit' => 40000,
                'status' => ApartmentStatus::Available, 'latitude' => 6.1800, 'longitude' => 1.1700,
                'address' => 'Avédji, Lomé', 'rating' => 4.5, 'review_count' => 17, 'featured' => false,
                'listed_at' => '2026-09-28', 'photos' => ['p07', 'p12'],
            ],
            [
                'slug' => 'appartement-indigo', 'zone' => 'agoe', 'title' => 'Appartement Indigo', 'type' => ApartmentType::TwoRooms,
                'description' => 'Deux-pièces au caractère affirmé, mur indigo et mobilier contemporain. Rénovation en cours.',
                'bedrooms' => 1, 'bathrooms' => 1, 'capacity' => 2, 'surface_m2' => 55,
                'amenities' => $a(Amenity::Wifi, Amenity::AirConditioning, Amenity::HotWater, Amenity::Tv),
                'price_per_night' => 28000, 'deposit' => 35000,
                'status' => ApartmentStatus::Maintenance, 'latitude' => 6.2100, 'longitude' => 1.2000,
                'address' => 'Agoè Nyivé, Lomé', 'rating' => 4.4, 'review_count' => 9, 'featured' => false,
                'listed_at' => '2026-06-10', 'photos' => ['p11', 'p14'],
            ],
            [
                'slug' => 'residence-lumiere', 'zone' => 'tokoin', 'title' => 'Résidence Lumière', 'type' => ApartmentType::ThreeRooms,
                'description' => 'Grand trois-pièces aux finitions soignées, deux salles d’eau et un séjour ouvert sur balcon.',
                'bedrooms' => 2, 'bathrooms' => 2, 'capacity' => 5, 'surface_m2' => 110,
                'amenities' => $a(Amenity::Wifi, Amenity::AirConditioning, Amenity::Parking, Amenity::HotWater, Amenity::Generator, Amenity::Kitchen, Amenity::Tv),
                'price_per_night' => 55000, 'deposit' => 80000, 'short_stay_day_price' => 40000,
                'status' => ApartmentStatus::Occupied, 'latitude' => 6.1480, 'longitude' => 1.2210,
                'address' => 'Tokoin Wuiti, Lomé', 'rating' => 4.8, 'review_count' => 40, 'featured' => true,
                'listed_at' => '2026-05-15', 'photos' => ['p08', 'p10', 'p13'],
            ],
            [
                'slug' => 'villa-baobab', 'zone' => 'agoe', 'title' => 'Villa Baobab', 'type' => ApartmentType::Villa,
                'description' => 'Villa familiale avec grand jardin arboré, gardiennage et groupe électrogène. Calme absolu.',
                'bedrooms' => 3, 'bathrooms' => 3, 'capacity' => 6, 'surface_m2' => 200,
                'amenities' => $a(Amenity::Wifi, Amenity::AirConditioning, Amenity::Parking, Amenity::HotWater, Amenity::Generator, Amenity::Kitchen, Amenity::Tv, Amenity::Security, Amenity::Washer),
                'price_per_night' => 110000, 'deposit' => 200000,
                'status' => ApartmentStatus::Available, 'latitude' => 6.2150, 'longitude' => 1.1950,
                'address' => 'Agoè Assiyéyé, Lomé', 'rating' => 4.7, 'review_count' => 12, 'featured' => false,
                'listed_at' => '2026-09-30', 'photos' => ['p03', 'p05', 'p12'],
            ],
        ];

        foreach ($apartments as $data) {
            $photos = $data['photos'];
            $zone = $zones[$data['zone']];
            unset($data['photos'], $data['zone']);

            $apartment = Apartment::query()->updateOrCreate(
                ['slug' => $data['slug']],
                $data + ['zone_id' => $zone->id, 'owner_id' => $owner->id, 'rules' => self::RULES],
            );

            $apartment->photos()->delete();
            foreach ($photos as $position => $file) {
                $apartment->photos()->create(['path' => "demo/{$file}.webp", 'position' => $position]);
            }
        }
    }
}
