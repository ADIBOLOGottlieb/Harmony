<?php

namespace App\Models;

use App\Enums\MaintenanceStatus;
use App\Enums\MaintenanceType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MaintenanceTask extends Model
{
    protected $fillable = [
        'apartment_id', 'booking_id', 'assigned_to', 'type', 'status', 'title', 'notes', 'due_at', 'completed_at', 'cost',
    ];

    protected $attributes = [
        'status' => 'todo',
    ];

    protected function casts(): array
    {
        return [
            'type' => MaintenanceType::class,
            'status' => MaintenanceStatus::class,
            'due_at' => 'immutable_datetime',
            'completed_at' => 'immutable_datetime',
            'cost' => 'integer',
        ];
    }

    /** @return BelongsTo<Apartment, $this> */
    public function apartment(): BelongsTo
    {
        return $this->belongsTo(Apartment::class);
    }

    /** @return BelongsTo<Booking, $this> */
    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }

    /** @return BelongsTo<User, $this> */
    public function assignee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }
}
