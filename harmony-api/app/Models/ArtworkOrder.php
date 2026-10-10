<?php

namespace App\Models;

use App\Enums\ArtworkOrderStatus;
use App\Enums\DeliveryMethod;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ArtworkOrder extends Model
{
    protected $fillable = [
        'reference', 'artwork_id', 'user_id', 'status', 'price', 'delivery_method', 'delivery_fee', 'total',
        'delivery_address', 'note', 'expires_at', 'paid_at', 'cancelled_at', 'cancel_reason', 'handled_by',
    ];

    protected $attributes = [
        'status' => 'pending',
        'delivery_fee' => 0,
    ];

    protected function casts(): array
    {
        return [
            'status' => ArtworkOrderStatus::class,
            'delivery_method' => DeliveryMethod::class,
            'price' => 'integer',
            'delivery_fee' => 'integer',
            'total' => 'integer',
            'expires_at' => 'immutable_datetime',
            'paid_at' => 'immutable_datetime',
            'cancelled_at' => 'immutable_datetime',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'reference';
    }

    /** @return BelongsTo<Artwork, $this> */
    public function artwork(): BelongsTo
    {
        return $this->belongsTo(Artwork::class)->withTrashed();
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
