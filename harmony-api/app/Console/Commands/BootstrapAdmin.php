<?php

namespace App\Console\Commands;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

/**
 * Premier compte administrateur sur un hébergement sans console (Render gratuit) :
 * lu dans HARMONY_ADMIN_EMAIL et HARMONY_ADMIN_PASSWORD, à retirer une fois le compte créé.
 * N'écrase jamais le mot de passe d'un compte existant.
 */
#[Signature('harmony:bootstrap-admin')]
#[Description('Crée le compte administrateur défini par les variables d’environnement, s’il n’existe pas')]
class BootstrapAdmin extends Command
{
    public function handle(): int
    {
        $email = (string) config('harmony.admin.email');
        $password = (string) config('harmony.admin.password');

        if ($email === '' || $password === '') {
            return self::SUCCESS;
        }
        if (! filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($password) < 12) {
            $this->error('HARMONY_ADMIN_EMAIL invalide ou mot de passe de moins de 12 caractères : compte non créé.');

            return self::FAILURE;
        }
        if (User::query()->where('email', $email)->exists()) {
            $this->info('Compte administrateur déjà présent.');

            return self::SUCCESS;
        }

        User::query()->create([
            'name' => 'Administrateur',
            'email' => $email,
            'password' => $password,
            'role' => UserRole::Admin,
        ]);
        $this->info('Compte administrateur créé. Retirez HARMONY_ADMIN_PASSWORD des variables d’environnement.');

        return self::SUCCESS;
    }
}
