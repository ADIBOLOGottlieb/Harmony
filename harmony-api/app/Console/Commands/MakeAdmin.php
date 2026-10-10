<?php

namespace App\Console\Commands;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('harmony:make-admin {phone : Numéro au format +228…} {--role=admin : admin ou concierge} {--name=} {--email=} {--password=}')]
#[Description('Crée ou promeut un compte de la conciergerie (admin ou concierge)')]
class MakeAdmin extends Command
{
    public function handle(): int
    {
        $role = UserRole::tryFrom((string) $this->option('role'));
        if (! $role || ! $role->isStaff()) {
            $this->error('Rôle attendu : admin ou concierge.');

            return self::FAILURE;
        }

        $password = $this->option('password') ?: $this->secret('Mot de passe pour l’espace de gestion (12 caractères minimum)');
        if (strlen((string) $password) < 12) {
            $this->error('Mot de passe trop court.');

            return self::FAILURE;
        }

        $user = User::query()->updateOrCreate(
            ['phone' => $this->argument('phone')],
            array_filter([
                'role' => $role,
                'name' => $this->option('name'),
                'email' => $this->option('email'),
                'password' => $password,
            ]),
        );

        $this->info("Compte {$role->label()} prêt (id {$user->id}).");

        return self::SUCCESS;
    }
}
