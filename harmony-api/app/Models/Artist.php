<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Artist extends Model
{
    protected $fillable = ['slug', 'name', 'bio', 'country', 'portrait_path'];

    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    /** @return HasMany<Artwork, $this> */
    public function artworks(): HasMany
    {
        return $this->hasMany(Artwork::class);
    }
}
