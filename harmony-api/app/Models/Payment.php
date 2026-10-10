<?php

namespace App\Models;

use App\Enums\PaymentKind;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payment extends Model
{
    protected $fillable = [
        'booking_id', 'gateway', 'method', 'kind', 'amount', 'currency', 'status', 'provider_reference',
        'checkout_url', 'instructions', 'meta', 'paid_at', 'validated_by',
    ];

    protected function casts(): array
    {
        return [
            'method' => PaymentMethod::class,
            'kind' => PaymentKind::class,
            'status' => PaymentStatus::class,
            'amount' => 'integer',
            'meta' => 'array',
            'paid_at' => 'immutable_datetime',
        ];
    }

    /** @return BelongsTo<Booking, $this> */
    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }
}
