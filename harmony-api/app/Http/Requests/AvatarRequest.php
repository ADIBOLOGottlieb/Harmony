<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AvatarRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'photo' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120', 'dimensions:min_width=100,min_height=100'],
        ];
    }

    /** @return array<string, string> */
    public function messages(): array
    {
        return [
            'photo.required' => 'Choisissez une photo.',
            'photo.image' => 'Le fichier choisi n’est pas une image.',
            'photo.mimes' => 'Formats acceptés : JPEG, PNG ou WebP.',
            'photo.max' => 'La photo ne doit pas dépasser 5 Mo.',
            'photo.dimensions' => 'La photo est trop petite (100 × 100 pixels minimum).',
        ];
    }
}
