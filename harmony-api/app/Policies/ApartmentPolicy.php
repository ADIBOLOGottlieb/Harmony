<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\Apartment;
use App\Models\User;

/**
 * Catalogue : lecture publique. Gestion réservée au personnel de la
 * conciergerie, ou au propriétaire pour ses propres biens.
 * (Les administrateurs passent tous les contrôles via Gate::before.)
 */
class ApartmentPolicy
{
    public function viewAny(?User $user): bool
    {
        return true;
    }

    public function view(?User $user, Apartment $apartment): bool
    {
        return true;
    }

    public function create(User $user): bool
    {
        return $user->role->isStaff() || $user->role === UserRole::Owner;
    }

    public function update(User $user, Apartment $apartment): bool
    {
        return $user->role->isStaff() || $this->owns($user, $apartment);
    }

    public function delete(User $user, Apartment $apartment): bool
    {
        return $user->role->isStaff();
    }

    private function owns(User $user, Apartment $apartment): bool
    {
        return $user->role === UserRole::Owner && $apartment->owner_id === $user->id;
    }
}
