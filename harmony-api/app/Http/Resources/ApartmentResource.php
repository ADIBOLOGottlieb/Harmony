<?php

namespace App\Http\Resources;

use App\Enums\Amenity;
use App\Models\Apartment;
use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Apartment */
class ApartmentResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'slug' => $this->slug,
            'title' => $this->title,
            'description' => $this->description,
            'type' => $this->type->value,
            'type_label' => $this->type->label(),
            'zone' => new ZoneResource($this->whenLoaded('zone')),
            'bedrooms' => $this->bedrooms,
            'bathrooms' => $this->bathrooms,
            'capacity' => $this->capacity,
            'surface_m2' => $this->surface_m2,
            'amenities' => collect($this->amenities)
                ->map(fn (string $a) => ['code' => $a, 'label' => Amenity::tryFrom($a)?->label() ?? $a])
                ->values(),
            'price_per_night' => $this->price_per_night,
            'deposit' => $this->deposit,
            'short_stays' => $this->short_stay_three_hours_price || $this->short_stay_day_price ? [
                'three_hours' => $this->short_stay_three_hours_price,
                'day' => $this->short_stay_day_price,
            ] : null,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            // Position publique arrondie (~100 m) : l'adresse exacte n'est
            // communiquée qu'après confirmation d'une réservation.
            'location' => [
                'latitude' => round($this->latitude, 3),
                'longitude' => round($this->longitude, 3),
                'area' => $this->area ?? $this->zone?->name,
            ],
            'rules' => $this->rules,
            'rating' => $this->rating,
            'review_count' => $this->review_count,
            'featured' => $this->featured,
            'listed_at' => $this->listed_at?->toIso8601String(),
            'photos' => $this->whenLoaded('photos', fn () => $this->photos->map(fn ($p) => [
                'path' => Media::url($p->path),
                'caption' => $p->caption,
            ])->values()),
        ];
    }
}
