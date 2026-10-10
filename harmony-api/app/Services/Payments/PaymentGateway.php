<?php

namespace App\Services\Payments;

use App\Enums\PaymentStatus;
use App\Models\Booking;
use App\Models\Payment;
use Illuminate\Http\Request;

/**
 * Moyen de paiement. Chaque implémentation (FedaPay, virement, sandbox…)
 * initie une transaction, interprète ses webhooks et sait rembourser.
 */
interface PaymentGateway
{
    /** Identifiant stocké dans payments.gateway. */
    public function name(): string;

    public function initiate(Payment $payment, Booking $booking): PaymentInitiation;

    /**
     * Vérifie la signature et traduit le webhook.
     *
     * @throws InvalidWebhook
     */
    public function parseWebhook(Request $request): WebhookEvent;

    /** Lance un remboursement ; renvoie Succeeded s'il est immédiat, Pending s'il est traité à la main. */
    public function refund(Payment $refund, Payment $original): PaymentStatus;
}
