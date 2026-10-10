<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AvailabilityRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'from' => ['required', 'date_format:Y-m-d'],
            'to' => ['required', 'date_format:Y-m-d', 'after_or_equal:from', 'before_or_equal:'.$this->maxTo()],
        ];
    }

    private function maxTo(): string
    {
        $from = strtotime((string) $this->input('from')) ?: time();

        return date('Y-m-d', strtotime('+120 days', $from));
    }
}
