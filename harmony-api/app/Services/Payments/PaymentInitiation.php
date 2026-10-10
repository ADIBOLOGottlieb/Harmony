<?php

namespace App\Services\Payments;

/** Ce que le client doit faire pour payer : ouvrir une page, ou suivre des instructions. */
final class PaymentInitiation
{
    public function __construct(
        public readonly ?string $checkoutUrl = null,
        public readonly ?string $instructions = null,
        public readonly ?string $providerReference = null,
    ) {}
}
