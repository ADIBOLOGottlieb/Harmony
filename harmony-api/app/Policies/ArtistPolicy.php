<?php

namespace App\Policies;

use App\Models\User;

/** Artistes : gérés par le personnel de la galerie. */
class ArtistPolicy
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
