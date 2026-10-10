<?php

namespace App\Http\Resources;

use App\Models\Artist;
use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Artist */
class ArtistResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'slug' => $this->slug,
            'name' => $this->name,
            'bio' => $this->bio,
            'country' => $this->country,
            'portrait' => Media::url($this->portrait_path),
            'artworks_count' => $this->whenCounted('artworks'),
        ];
    }
}
