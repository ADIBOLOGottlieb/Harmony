<?php

namespace App\Http\Requests;

use App\Enums\Amenity;
use App\Enums\ApartmentType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ApartmentIndexRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'zone' => ['nullable', 'string', 'max:80'],
            'guests' => ['nullable', 'integer', 'min:1', 'max:30'],
            'type' => ['nullable', Rule::enum(ApartmentType::class)],
            'min_price' => ['nullable', 'integer', 'min:0'],
            'max_price' => ['nullable', 'integer', 'min:0', Rule::when($this->filled('min_price'), 'gte:min_price')],
            'amenities' => ['nullable', 'array', 'max:10'],
            'amenities.*' => [Rule::in(Amenity::values())],
        ];
    }
}
