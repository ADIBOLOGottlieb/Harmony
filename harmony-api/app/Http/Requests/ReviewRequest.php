<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ReviewRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'rating' => ['required', 'integer', 'between:1,5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ];
    }

    /** @return array<string, string> */
    public function messages(): array
    {
        return [
            'rating.required' => __('Choisissez une note de 1 à 5.'),
            'rating.between' => __('Choisissez une note de 1 à 5.'),
            'comment.max' => __('Votre commentaire ne doit pas dépasser 1 000 caractères.'),
        ];
    }
}
