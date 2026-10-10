<?php

namespace App\Services\Payments;

use App\Enums\PaymentStatus;

/** Webhook vérifié et traduit. `outcome` est null pour les événements sans effet. */
final class WebhookEvent
{
    /** @param  array<string, mixed>  $payload */
    public function __construct(
        public readonly string $eventId,
        public readonly string $type,
        public readonly ?string $providerReference,
        public readonly ?PaymentStatus $outcome,
        public readonly array $payload,
    ) {}
}
