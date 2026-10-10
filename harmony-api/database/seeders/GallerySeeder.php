<?php

namespace Database\Seeders;

use App\Models\Artist;
use App\Models\Artwork;
use Illuminate\Database\Seeder;

/** Galerie de démonstration : 3 artistes, 8 œuvres (visuels embarqués dans l'app, « demo/art/… »). */
class GallerySeeder extends Seeder
{
    public function run(): void
    {
        $artists = [
            'afi-kouassi' => ['Afi Kouassi', 'Peintre loméenne, elle travaille la couleur en grands aplats inspirés des pagnes et des marchés de la ville.'],
            'kodjo-mensah' => ['Kodjo Mensah', 'Plasticien formé à Accra et Lomé ; ses compositions géométriques dialoguent avec l’architecture côtière.'],
            'esi-adjovi' => ['Esi Adjovi', 'Artiste pluridisciplinaire : encre, masques et calligraphies gestuelles autour de la mémoire du Golfe.'],
        ];
        $ids = [];
        foreach ($artists as $slug => [$name, $bio]) {
            $ids[$slug] = Artist::query()->updateOrCreate(['slug' => $slug], ['name' => $name, 'bio' => $bio, 'country' => 'Togo'])->id;
        }

        $works = [
            ['terre-et-lagune', 'afi-kouassi', 'Terre et lagune', 'Acrylique sur toile', '100 × 125 cm', 2025, 850000, 'a01', true],
            ['kente-du-matin', 'afi-kouassi', 'Kente du matin', 'Acrylique et feuille d’or sur toile', '80 × 100 cm', 2024, 650000, 'a02', true],
            ['soleil-sur-be', 'kodjo-mensah', 'Soleil sur Bè', 'Huile sur toile', '90 × 112 cm', 2025, 720000, 'a03', false],
            ['nuit-a-kodjoviakope', 'kodjo-mensah', 'Nuit à Kodjoviakopé', 'Technique mixte sur panneau', '60 × 75 cm', 2023, 480000, 'a04', false],
            ['les-gardiens', 'esi-adjovi', 'Les gardiens', 'Acrylique sur toile de lin', '120 × 150 cm', 2024, 1200000, 'a05', true],
            ['grand-marche', 'afi-kouassi', 'Grand marché', 'Collage et acrylique', '70 × 90 cm', 2025, 390000, 'a06', false],
            ['horizon-de-baguida', 'kodjo-mensah', 'Horizon de Baguida', 'Huile sur toile', '50 × 65 cm', 2025, 290000, 'a07', false],
            ['rythmes', 'esi-adjovi', 'Rythmes', 'Encre de Chine sur papier coton', '56 × 76 cm', 2024, 260000, 'a08', false],
        ];

        foreach ($works as [$slug, $artist, $title, $medium, $dimensions, $year, $price, $image, $featured]) {
            $artwork = Artwork::query()->updateOrCreate(['slug' => $slug], [
                'artist_id' => $ids[$artist],
                'title' => $title,
                'description' => "{$title} : pièce unique signée par l’artiste, livrée avec un certificat d’authenticité. "
                    .'Encadrement possible sur demande auprès de la galerie.',
                'medium' => $medium,
                'dimensions' => $dimensions,
                'year' => $year,
                'price' => $price,
                'featured' => $featured,
                'published' => true,
            ]);
            $artwork->photos()->delete();
            $artwork->photos()->create(['path' => "demo/art/{$image}.webp", 'position' => 0]);
        }
    }
}
