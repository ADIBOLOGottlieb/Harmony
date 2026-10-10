<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ApartmentPhoto extends Model
{
    protected $fillable = ['apartment_id', 'path', 'position', 'caption'];

    /** @return BelongsTo<Apartment, $this> */
    public function apartment(): BelongsTo
    {
        return $this->belongsTo(Apartment::class);
    }
}
