<?php

namespace App\Http\Resources;

use App\Models\Zone;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Zone */
class ZoneResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'slug' => $this->slug,
            'name' => $this->name,
            'city' => $this->city,
            'country' => $this->country,
            'cover' => $this->cover_path,
            'apartments_count' => $this->whenCounted('apartments'),
        ];
    }
}
