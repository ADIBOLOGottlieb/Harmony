<?php

namespace App\Models;

use App\Enums\ApartmentStatus;
use App\Enums\ApartmentType;
use Database\Factories\ApartmentFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Apartment extends Model
{
    /** @use HasFactory<ApartmentFactory> */
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'slug', 'owner_id', 'zone_id', 'title', 'description', 'type', 'bedrooms', 'bathrooms', 'capacity',
        'surface_m2', 'amenities', 'price_per_night', 'deposit', 'short_stay_three_hours_price',
        'short_stay_day_price', 'status', 'latitude', 'longitude', 'address', 'area', 'rules', 'rating',
        'review_count', 'featured', 'listed_at',
    ];

    protected function casts(): array
    {
        return [
            'type' => ApartmentType::class,
            'status' => ApartmentStatus::class,
            'amenities' => 'array',
            'rules' => 'array',
            'featured' => 'boolean',
            'latitude' => 'float',
            'longitude' => 'float',
            'rating' => 'float',
            'price_per_night' => 'integer',
            'deposit' => 'integer',
            'short_stay_three_hours_price' => 'integer',
            'short_stay_day_price' => 'integer',
            'listed_at' => 'immutable_datetime',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    /** @return BelongsTo<Zone, $this> */
    public function zone(): BelongsTo
    {
        return $this->belongsTo(Zone::class);
    }

    /** @return BelongsTo<User, $this> */
    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    /** @return HasMany<ApartmentPhoto, $this> */
    public function photos(): HasMany
    {
        return $this->hasMany(ApartmentPhoto::class)->orderBy('position');
    }

    /** @return HasMany<ApartmentBlock, $this> */
    public function blocks(): HasMany
    {
        return $this->hasMany(ApartmentBlock::class);
    }

    /** @return HasMany<SeasonalPrice, $this> */
    public function seasonalPrices(): HasMany
    {
        return $this->hasMany(SeasonalPrice::class);
    }

    /** @return HasMany<Review, $this> */
    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    /** @return HasMany<MaintenanceTask, $this> */
    public function maintenanceTasks(): HasMany
    {
        return $this->hasMany(MaintenanceTask::class);
    }

    /** @return HasMany<Booking, $this> */
    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }

    public function isBookable(): bool
    {
        return $this->status === ApartmentStatus::Available;
    }

    /** Biens à la une d'abord, puis les plus récents. */
    public function scopeShowcaseOrder(Builder $query): Builder
    {
        return $query->orderByDesc('featured')->orderByDesc('listed_at');
    }
}
