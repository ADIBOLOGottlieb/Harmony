<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ArtworkPhoto extends Model
{
    protected $fillable = ['artwork_id', 'path', 'position'];

    /** @return BelongsTo<Artwork, $this> */
    public function artwork(): BelongsTo
    {
        return $this->belongsTo(Artwork::class);
    }
}
