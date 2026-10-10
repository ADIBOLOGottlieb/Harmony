<?php

namespace App\Policies;

use App\Models\ArtworkOrder;
use App\Models\User;

/** Acquisitions : le client gère les siennes, le personnel de la galerie les traite toutes. */
class ArtworkOrderPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isStaff();
    }

    public function view(User $user, ArtworkOrder $order): bool
    {
        return $order->user_id === $user->id || $user->isStaff();
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

    public function cancel(User $user, ArtworkOrder $order): bool
    {
        return $order->user_id === $user->id || $user->isStaff();
    }
}
