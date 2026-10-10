<?php

namespace App\Models;

use Database\Factories\ZoneFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Zone extends Model
{
    /** @use HasFactory<ZoneFactory> */
    use HasFactory;

    protected $fillable = ['slug', 'name', 'city', 'country', 'cover_path'];

    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    /** @return HasMany<Apartment, $this> */
    public function apartments(): HasMany
    {
        return $this->hasMany(Apartment::class);
    }
}
