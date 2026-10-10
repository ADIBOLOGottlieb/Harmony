<?php

namespace App\Services\Reviews;

use App\Models\Booking;
use App\Models\Review;

/** Avis client : un seul par séjour terminé, publié après modération par la conciergerie. */
class ReviewService
{
    public function submit(Booking $booking, int $rating, ?string $comment): Review
    {
        return Review::query()->create([
            'booking_id' => $booking->id,
            'apartment_id' => $booking->apartment_id,
            'user_id' => $booking->user_id,
            'rating' => $rating,
            'comment' => filled($comment) ? trim($comment) : null,
            'published' => false,
        ]);
    }
}
