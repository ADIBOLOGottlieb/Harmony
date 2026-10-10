<?php

namespace App\Models;

use App\Enums\BookingStatus;
use App\Enums\StayType;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Booking extends Model
{
    protected $fillable = [
        'reference', 'apartment_id', 'user_id', 'stay_type', 'start_at', 'end_at', 'blocked_until', 'nights',
        'guests', 'status', 'accommodation_amount', 'service_fee', 'total_amount', 'security_deposit',
        'advance_amount', 'amount_paid', 'price_breakdown', 'cancellation_deadline', 'expires_at',
        'confirmed_at', 'cancelled_at', 'cancel_reason',
    ];

    /** Valeurs par défaut de la base, connues dès la création (sinon null avant relecture). */
    protected $attributes = [
        'amount_paid' => 0,
    ];

    protected function casts(): array
    {
        return [
            'stay_type' => StayType::class,
            'status' => BookingStatus::class,
            'start_at' => 'immutable_datetime',
            'end_at' => 'immutable_datetime',
            'blocked_until' => 'immutable_datetime',
            'cancellation_deadline' => 'immutable_datetime',
            'expires_at' => 'immutable_datetime',
            'confirmed_at' => 'immutable_datetime',
            'cancelled_at' => 'immutable_datetime',
            'price_breakdown' => 'array',
            'nights' => 'integer',
            'guests' => 'integer',
            'accommodation_amount' => 'integer',
            'service_fee' => 'integer',
            'total_amount' => 'integer',
            'security_deposit' => 'integer',
            'advance_amount' => 'integer',
            'amount_paid' => 'integer',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'reference';
    }

    /** @return BelongsTo<Apartment, $this> */
    public function apartment(): BelongsTo
    {
        return $this->belongsTo(Apartment::class)->withTrashed();
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** @return HasOne<Review, $this> */
    public function review(): HasOne
    {
        return $this->hasOne(Review::class);
    }

    /** @return HasMany<MaintenanceTask, $this> */
    public function maintenanceTasks(): HasMany
    {
        return $this->hasMany(MaintenanceTask::class);
    }

    /** @return HasMany<Payment, $this> */
    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class)->latest('id');
    }

    public function balanceDue(): int
    {
        return max(0, $this->total_amount - $this->amount_paid);
    }

    /** Réservations qui occupent réellement le calendrier (en attente non expirées, ou confirmées). */
    public function scopeOccupying(Builder $query): Builder
    {
        return $query->where(fn (Builder $q) => $q
            ->where('status', BookingStatus::Confirmed)
            ->orWhere(fn (Builder $p) => $p->where('status', BookingStatus::Pending)->where('expires_at', '>', now())));
    }

    /** Le client voit l'adresse exacte seulement une fois la réservation confirmée. */
    public function revealsExactLocation(): bool
    {
        return in_array($this->status, [BookingStatus::Confirmed, BookingStatus::Completed], true);
    }
}
