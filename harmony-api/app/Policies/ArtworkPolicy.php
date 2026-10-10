<?php

namespace App\Policies;

use App\Models\User;

/** Œuvres : gérées par le personnel de la galerie (la consultation publique passe par l'API). */
class ArtworkPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isStaff();
    }

    public function create(User $user): bool
    {
        return $user->isStaff();
    }

    public function update(User $user): bool
    {
        return $user->isStaff();
    }

    public function delete(User $user): bool
    {
        return $user->isStaff();
    }
}
