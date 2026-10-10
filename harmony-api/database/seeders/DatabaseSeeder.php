<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Données de démonstration (catalogue de Lomé). Aucun compte administrateur
     * n'est créé ici : utiliser `php artisan harmony:make-admin`.
     */
    public function run(): void
    {
        $this->call(CatalogSeeder::class);
        $this->call(GallerySeeder::class);
    }
}
