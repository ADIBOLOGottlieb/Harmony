<?php

namespace App\Services\Payments\Gateways;

use App\Enums\PaymentStatus;
use App\Models\Booking;
use App\Models\Payment;
use App\Services\Payments\InvalidWebhook;
use App\Services\Payments\PaymentGateway;
use App\Services\Payments\PaymentInitiation;
use App\Services\Payments\WebhookEvent;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\URL;

/**
 * Paiement simulé pour la démonstration et les tests : une page signée
 * permet de valider ou refuser le paiement. Désactivé par défaut en production
 * (PAYMENTS_SANDBOX) : sans cela, n'importe qui pourrait « payer » gratuitement.
 */
class SandboxGateway implements PaymentGateway
{
    public function name(): string
    {
        return 'sandbox';
    }

    public function initiate(Payment $payment, Booking $booking): PaymentInitiation
    {
        return new PaymentInitiation(
            checkoutUrl: URL::temporarySignedRoute('payments.sandbox.show', now()->addHours(2), ['payment' => $payment->id]),
            providerReference: 'sbx_'.$payment->id,
        );
    }

    public function parseWebhook(Request $request): WebhookEvent
    {
        throw new InvalidWebhook('La sandbox n’utilise pas de webhook.');
    }

    public function refund(Payment $refund, Payment $original): PaymentStatus
    {
        return PaymentStatus::Succeeded;
    }
}
