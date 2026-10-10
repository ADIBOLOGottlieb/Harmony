<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Review extends Model
{
    protected $fillable = ['booking_id', 'apartment_id', 'user_id', 'rating', 'comment', 'published'];

    protected function casts(): array
    {
        return [
            'rating' => 'integer',
            'published' => 'boolean',
        ];
    }

    /** Recalcule la note affichée d'un bien à partir des avis publiés. */
    public static function refreshApartmentRating(int $apartmentId): void
    {
        $published = static::query()->where('apartment_id', $apartmentId)->where('published', true);
        Apartment::query()->whereKey($apartmentId)->update([
            'rating' => round((float) ($published->clone()->avg('rating') ?? 0), 1),
            'review_count' => $published->clone()->count(),
        ]);
    }

    protected static function booted(): void
    {
        static::saved(fn (Review $review) => static::refreshApartmentRating($review->apartment_id));
        static::deleted(fn (Review $review) => static::refreshApartmentRating($review->apartment_id));
    }

    /** @return BelongsTo<Booking, $this> */
    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }

    /** @return BelongsTo<Apartment, $this> */
    public function apartment(): BelongsTo
    {
        return $this->belongsTo(Apartment::class);
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
