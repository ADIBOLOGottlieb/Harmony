<?php

namespace App\Policies;

use App\Models\User;

/** Avis : modérés par le personnel (publication, suppression). */
class ReviewPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isStaff();
    }

    public function view(User $user): bool
    {
        return $user->isStaff();
    }

    public function create(User $user): bool
    {
        return false;
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
