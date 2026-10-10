<?php

namespace App\Services\Booking;

/** Devis d'un séjour. Tous les montants sont des entiers FCFA. */
final class Quote
{
    /**
     * @param  list<array{label: string, amount: int}>  $lines
     */
    public function __construct(
        public readonly StayWindow $window,
        public readonly int $accommodation,
        public readonly int $serviceFee,
        public readonly int $total,
        public readonly int $securityDeposit,
        public readonly int $advance,
        public readonly array $lines,
    ) {}

    public function balance(): int
    {
        return $this->total - $this->advance;
    }

    /** @return array<string, mixed> */
    public function toArray(): array
    {
        return [
            'stay_type' => $this->window->type->value,
            'start_at' => $this->window->start->toIso8601String(),
            'end_at' => $this->window->end->toIso8601String(),
            'nights' => $this->window->nights,
            'lines' => $this->lines,
            'accommodation' => $this->accommodation,
            'service_fee' => $this->serviceFee,
            'total' => $this->total,
            'advance' => $this->advance,
            'balance' => $this->balance(),
            // Caution réglée à l'arrivée auprès du concierge, restituée après l'état des lieux.
            'security_deposit' => $this->securityDeposit,
            'currency' => 'XOF',
        ];
    }
}
