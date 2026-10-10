<?php

namespace App\Http\Resources;

use App\Enums\BookingStatus;
use App\Models\Booking;
use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Booking */
class BookingResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $apartment = $this->apartment;
        $exact = $this->revealsExactLocation();

        return [
            'reference' => $this->reference,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'stay_type' => $this->stay_type->value,
            'stay_type_label' => $this->stay_type->label(),
            'start_at' => $this->start_at->toIso8601String(),
            'end_at' => $this->end_at->toIso8601String(),
            'nights' => $this->nights,
            'guests' => $this->guests,
            'apartment' => [
                'slug' => $apartment->slug,
                'title' => $apartment->title,
                'zone' => $apartment->zone?->name,
                'cover' => Media::url($apartment->photos()->orderBy('position')->value('path')),
                // Adresse exacte et position précise réservées aux séjours confirmés.
                'address' => $exact ? $apartment->address : null,
                'latitude' => $exact ? $apartment->latitude : null,
                'longitude' => $exact ? $apartment->longitude : null,
            ],
            'amounts' => [
                'accommodation' => $this->accommodation_amount,
                'service_fee' => $this->service_fee,
                'total' => $this->total_amount,
                'advance' => $this->advance_amount,
                'paid' => (int) $this->amount_paid,
                'balance_due' => $this->balanceDue(),
                'security_deposit' => $this->security_deposit,
                'currency' => 'XOF',
            ],
            'price_breakdown' => $this->price_breakdown,
            'cancellation_deadline' => $this->cancellation_deadline?->toIso8601String(),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'confirmed_at' => $this->confirmed_at?->toIso8601String(),
            'cancelled_at' => $this->cancelled_at?->toIso8601String(),
            'payments' => PaymentResource::collection($this->whenLoaded('payments')),
            'review' => $this->review ? ['rating' => $this->review->rating, 'comment' => $this->review->comment] : null,
            'can_review' => $this->status === BookingStatus::Completed && ! $this->review,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
