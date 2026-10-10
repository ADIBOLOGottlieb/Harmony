<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ArtworkIndexRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'artist' => ['nullable', 'string', 'max:80'],
            'available' => ['nullable', 'boolean'],
            'max_price' => ['nullable', 'integer', 'min:0'],
        ];
    }
}
