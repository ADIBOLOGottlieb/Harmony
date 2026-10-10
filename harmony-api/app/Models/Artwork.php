<?php

namespace App\Models;

use App\Enums\ArtworkStatus;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Artwork extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'slug', 'artist_id', 'title', 'description', 'medium', 'dimensions', 'year', 'price', 'status', 'featured', 'published',
    ];

    protected $attributes = [
        'status' => 'available',
        'featured' => false,
        'published' => true,
    ];

    protected function casts(): array
    {
        return [
            'status' => ArtworkStatus::class,
            'price' => 'integer',
            'year' => 'integer',
            'featured' => 'boolean',
            'published' => 'boolean',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    /** @return BelongsTo<Artist, $this> */
    public function artist(): BelongsTo
    {
        return $this->belongsTo(Artist::class);
    }

    /** @return HasMany<ArtworkPhoto, $this> */
    public function photos(): HasMany
    {
        return $this->hasMany(ArtworkPhoto::class)->orderBy('position');
    }

    /** @return HasMany<ArtworkOrder, $this> */
    public function orders(): HasMany
    {
        return $this->hasMany(ArtworkOrder::class);
    }

    /** @param Builder<Artwork> $query */
    public function scopePublished(Builder $query): Builder
    {
        return $query->where('published', true);
    }
}
