<?php

namespace App\Policies;

use App\Models\User;

/** Comptes : consultables par le personnel, modifiables par les administrateurs seuls (Gate::before). */
class UserPolicy
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
        return false;
    }

    public function delete(User $user): bool
    {
        return false;
    }
}
