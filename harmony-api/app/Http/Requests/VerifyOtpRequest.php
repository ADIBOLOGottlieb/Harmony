<?php

namespace App\Http\Requests;

class VerifyOtpRequest extends RequestOtpRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        return parent::rules() + [
            'code' => ['required', 'string', 'digits:6'],
            'name' => ['nullable', 'string', 'max:80'],
        ];
    }
}
