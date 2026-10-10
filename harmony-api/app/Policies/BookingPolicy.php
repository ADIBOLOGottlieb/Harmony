<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\Booking;
use App\Models\User;

/** Réservations : le client voit les siennes, le propriétaire celles de ses biens, le personnel tout. */
class BookingPolicy
{
    public function view(User $user, Booking $booking): bool
    {
        return $booking->user_id === $user->id
            || $user->role->isStaff()
            || ($user->role === UserRole::Owner && $booking->apartment->owner_id === $user->id);
    }

    public function cancel(User $user, Booking $booking): bool
    {
        return $booking->user_id === $user->id || $user->role->isStaff();
    }

    public function pay(User $user, Booking $booking): bool
    {
        return $booking->user_id === $user->id;
    }

    /** Validation des virements et remboursements : personnel uniquement. */
    public function manage(User $user, Booking $booking): bool
    {
        return $user->role->isStaff();
    }
}
