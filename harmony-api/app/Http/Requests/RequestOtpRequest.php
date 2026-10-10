<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RequestOtpRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            // Format international E.164 (ex. +22890123456).
            'phone' => ['required', 'string', 'regex:/^\+[1-9]\d{7,14}$/'],
        ];
    }

    /** @return array<string, string> */
    public function messages(): array
    {
        return ['phone.regex' => 'Saisissez un numéro au format international, par exemple +228 90 12 34 56.'];
    }

    protected function prepareForValidation(): void
    {
        $this->merge(['phone' => preg_replace('/[\s.-]/', '', (string) $this->input('phone'))]);
    }
}
