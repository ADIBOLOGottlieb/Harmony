<?php

namespace App\Models;

use App\Enums\ListingType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/** Annonce immobilière générique (phase 2). Voir la migration create_properties_table. */
class Property extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'slug', 'listing_type', 'status', 'title', 'description', 'price', 'zone_id', 'apartment_id',
        'delivery_expected_on',
    ];

    protected function casts(): array
    {
        return [
            'listing_type' => ListingType::class,
            'price' => 'integer',
            'delivery_expected_on' => 'date',
        ];
    }

    /** @return BelongsTo<Zone, $this> */
    public function zone(): BelongsTo
    {
        return $this->belongsTo(Zone::class);
    }

    /** @return BelongsTo<Apartment, $this> */
    public function apartment(): BelongsTo
    {
        return $this->belongsTo(Apartment::class);
    }
}
