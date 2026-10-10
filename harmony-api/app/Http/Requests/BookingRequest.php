<?php

namespace App\Http\Requests;

use App\Enums\PaymentMethod;
use App\Enums\StayType;
use App\Models\Apartment;
use App\Services\Booking\StayWindow;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** Devis (`bookings/quote`) et création de réservation (`bookings`). */
class BookingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        $creating = $this->routeIs('bookings.store');

        return [
            'apartment' => ['required', 'string', Rule::exists('apartments', 'slug')->whereNull('deleted_at')],
            'stay_type' => ['required', Rule::enum(StayType::class)],
            'check_in' => ['required', 'date_format:Y-m-d', 'after_or_equal:today'],
            'check_out' => ['required_if:stay_type,night', 'nullable', 'date_format:Y-m-d', 'after:check_in'],
            'start_time' => ['required_if:stay_type,three_hours', 'nullable', 'date_format:H:i'],
            'guests' => ['required', 'integer', 'min:1', 'max:30'],
            'payment_method' => [$creating ? 'required' : 'nullable', Rule::enum(PaymentMethod::class)],
        ];
    }

    public function apartment(): Apartment
    {
        return Apartment::query()->where('slug', $this->validated('apartment'))->firstOrFail();
    }

    public function window(): StayWindow
    {
        return StayWindow::for(
            StayType::from($this->validated('stay_type')),
            $this->validated('check_in'),
            $this->validated('check_out'),
            $this->validated('start_time'),
        );
    }
}
