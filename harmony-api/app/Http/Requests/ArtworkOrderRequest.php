<?php

namespace App\Http\Requests;

use App\Enums\DeliveryMethod;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ArtworkOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'delivery_method' => ['required', Rule::enum(DeliveryMethod::class)],
            'delivery_address' => ['nullable', 'required_if:delivery_method,delivery', 'string', 'max:255'],
            'note' => ['nullable', 'string', 'max:1000'],
        ];
    }

    /** @return array<string, string> */
    public function messages(): array
    {
        return [
            'delivery_address.required_if' => 'Indiquez l’adresse de livraison.',
        ];
    }
}
