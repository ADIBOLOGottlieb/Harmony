<?php

namespace App\Policies;

use App\Models\MaintenanceTask;
use App\Models\User;

/** Ménage et maintenance : le personnel gère, le propriétaire consulte celles de ses biens. */
class MaintenanceTaskPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isStaff() || $user->isOwner();
    }

    public function view(User $user, MaintenanceTask $task): bool
    {
        return $user->isStaff() || ($user->isOwner() && $task->apartment?->owner_id === $user->id);
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
