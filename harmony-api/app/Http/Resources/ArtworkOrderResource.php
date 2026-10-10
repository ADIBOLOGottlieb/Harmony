<?php

namespace App\Http\Resources;

use App\Models\ArtworkOrder;
use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin ArtworkOrder */
class ArtworkOrderResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $artwork = $this->artwork;

        return [
            'reference' => $this->reference,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'artwork' => [
                'slug' => $artwork?->slug,
                'title' => $artwork?->title,
                'artist' => $artwork?->artist?->name,
                'cover' => Media::url($artwork?->photos()->value('path')),
            ],
            'price' => (int) $this->price,
            'delivery_method' => $this->delivery_method->value,
            'delivery_label' => $this->delivery_method->label(),
            'delivery_fee' => (int) $this->delivery_fee,
            'total' => (int) $this->total,
            'delivery_address' => $this->delivery_address,
            'note' => $this->note,
            'expires_at' => $this->expires_at?->toIso8601String(),
            'paid_at' => $this->paid_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'payment_instructions' => $this->status->value === 'pending'
                ? (string) config('harmony.gallery.payment_instructions')
                : null,
        ];
    }
}
