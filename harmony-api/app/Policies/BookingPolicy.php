<?php

namespace App\Policies;

use App\Enums\BookingStatus;
use App\Enums\UserRole;
use App\Models\Booking;
use App\Models\User;

/** Réservations : le client voit les siennes, le propriétaire celles de ses biens, le personnel tout. */
class BookingPolicy
{
    /** Liste de l'espace de gestion (filtrée par propriétaire dans la ressource). */
    public function viewAny(User $user): bool
    {
        return $user->isStaff() || $user->isOwner();
    }

    /** Les réservations naissent uniquement du parcours client (BookingService). */
    public function create(User $user): bool
    {
        return false;
    }

    public function update(User $user, Booking $booking): bool
    {
        return false;
    }

    public function delete(User $user, Booking $booking): bool
    {
        return false;
    }

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

    /** Un avis par séjour terminé, déposé par le client lui-même. */
    public function review(User $user, Booking $booking): bool
    {
        return $booking->user_id === $user->id
            && $booking->status === BookingStatus::Completed
            && ! $booking->review()->exists();
    }

    /** Validation des virements et remboursements : personnel uniquement. */
    public function manage(User $user, Booking $booking): bool
    {
        return $user->role->isStaff();
    }
}
