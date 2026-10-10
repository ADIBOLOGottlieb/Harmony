<?php

namespace App\Console\Commands;

use App\Models\Apartment;
use Database\Seeders\CatalogSeeder;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('harmony:seed-demo')]
#[Description('Charge le catalogue de démonstration si la base n’a encore aucun bien (sans effet sinon)')]
class SeedDemo extends Command
{
    public function handle(): int
    {
        if (Apartment::query()->withTrashed()->exists()) {
            $this->info('Catalogue déjà présent : rien à faire.');

            return self::SUCCESS;
        }

        $this->call('db:seed', ['--class' => CatalogSeeder::class, '--force' => true]);
        $this->info('Catalogue de démonstration chargé.');

        return self::SUCCESS;
    }
}
