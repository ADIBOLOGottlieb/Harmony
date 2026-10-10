<?php

namespace App\Console\Commands;

use App\Models\Apartment;
use App\Models\Artwork;
use Database\Seeders\CatalogSeeder;
use Database\Seeders\GallerySeeder;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('harmony:seed-demo')]
#[Description('Charge le catalogue et la galerie de démonstration, chacun seulement s’il est encore vide')]
class SeedDemo extends Command
{
    public function handle(): int
    {
        $this->seedIfEmpty(Apartment::query()->withTrashed()->exists(), CatalogSeeder::class, 'Catalogue');
        $this->seedIfEmpty(Artwork::query()->withTrashed()->exists(), GallerySeeder::class, 'Galerie');

        return self::SUCCESS;
    }

    private function seedIfEmpty(bool $exists, string $seeder, string $label): void
    {
        if ($exists) {
            $this->info("{$label} déjà présent : rien à faire.");

            return;
        }

        $this->call('db:seed', ['--class' => $seeder, '--force' => true]);
        $this->info("{$label} de démonstration chargé.");
    }
}
