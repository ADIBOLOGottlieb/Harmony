<?php

namespace App\Http\Resources;

use App\Models\Artwork;
use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Artwork */
class ArtworkResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'slug' => $this->slug,
            'title' => $this->title,
            'description' => $this->description,
            'medium' => $this->medium,
            'dimensions' => $this->dimensions,
            'year' => $this->year,
            'price' => (int) $this->price,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'featured' => $this->featured,
            'artist' => new ArtistResource($this->whenLoaded('artist')),
            'photos' => $this->whenLoaded('photos', fn () => $this->photos->map(fn ($p) => Media::url($p->path))->values()),
        ];
    }
}
