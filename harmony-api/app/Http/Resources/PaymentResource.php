<?php

namespace App\Http\Resources;

use App\Enums\PaymentStatus;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Payment */
class PaymentResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $pending = $this->status === PaymentStatus::Pending;

        return [
            'id' => $this->id,
            'kind' => $this->kind->value,
            'kind_label' => $this->kind->label(),
            'method' => $this->method->value,
            'method_label' => $this->method->label(),
            'gateway' => $this->gateway,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'amount' => $this->amount,
            'currency' => $this->currency,
            // Lien et instructions utiles seulement tant que le paiement est en attente.
            'checkout_url' => $pending ? $this->checkout_url : null,
            'instructions' => $pending ? $this->instructions : null,
            'paid_at' => $this->paid_at?->toIso8601String(),
        ];
    }
}
