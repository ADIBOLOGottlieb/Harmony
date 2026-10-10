<?php

namespace App\Services\Payments\Gateways;

use App\Enums\PaymentStatus;
use App\Models\Booking;
use App\Models\Payment;
use App\Services\Payments\InvalidWebhook;
use App\Services\Payments\PaymentGateway;
use App\Services\Payments\PaymentInitiation;
use App\Services\Payments\WebhookEvent;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

/**
 * FedaPay : Mobile Money (TMoney, Flooz) et cartes bancaires, en FCFA (XOF).
 * Clés lues dans config/services.php (variables d'environnement), jamais en dur.
 *
 * Flux : création de la transaction, puis jeton → URL de paiement hébergée.
 * Webhook : en-tête X-FEDAPAY-SIGNATURE « t=<horodatage>,s=<HMAC-SHA256> »
 * calculé sur « <horodatage>.<corps brut> » avec le secret du webhook.
 * À valider en sandbox contre la documentation FedaPay à jour avant la production.
 */
class FedaPayGateway implements PaymentGateway
{
    private const SIGNATURE_TOLERANCE_SECONDS = 300;

    public function __construct(
        private readonly string $secretKey,
        private readonly string $webhookSecret,
        private readonly string $environment,
    ) {}

    public function name(): string
    {
        return 'fedapay';
    }

    public function initiate(Payment $payment, Booking $booking): PaymentInitiation
    {
        $customer = $booking->user->phone
            ? ['phone_number' => ['number' => $booking->user->phone, 'country' => 'tg']]
            : null;

        $transaction = $this->client()->post('/transactions', array_filter([
            'description' => "HARMONY HOME – réservation {$booking->reference}",
            'amount' => $payment->amount,
            'currency' => ['iso' => 'XOF'],
            'callback_url' => rtrim((string) config('app.url'), '/').'/paiement/retour?ref='.$booking->reference,
            'custom_metadata' => ['payment_id' => $payment->id, 'booking' => $booking->reference],
            'customer' => $customer,
        ]))->throw()->json();

        $id = data_get($transaction, 'v1/transaction.id') ?? data_get($transaction, 'transaction.id') ?? data_get($transaction, 'id');

        $token = $this->client()->post("/transactions/{$id}/token")->throw()->json();

        return new PaymentInitiation(checkoutUrl: $token['url'] ?? null, providerReference: (string) $id);
    }

    public function parseWebhook(Request $request): WebhookEvent
    {
        $body = $request->getContent();
        $header = (string) $request->header('X-FEDAPAY-SIGNATURE');

        parse_str(str_replace(',', '&', $header), $parts);
        $timestamp = (int) ($parts['t'] ?? 0);
        $signature = (string) ($parts['s'] ?? '');

        if ($this->webhookSecret === '' || $timestamp === 0 || $signature === ''
            || abs(time() - $timestamp) > self::SIGNATURE_TOLERANCE_SECONDS
            || ! hash_equals(hash_hmac('sha256', $timestamp.'.'.$body, $this->webhookSecret), $signature)) {
            throw new InvalidWebhook('Signature FedaPay invalide.');
        }

        $payload = json_decode($body, true) ?: [];
        $type = (string) ($payload['name'] ?? 'unknown');
        $transactionId = data_get($payload, 'entity.id');

        $outcome = match ($type) {
            'transaction.approved', 'transaction.transferred' => PaymentStatus::Succeeded,
            'transaction.declined', 'transaction.canceled', 'transaction.expired' => PaymentStatus::Failed,
            default => null,
        };

        return new WebhookEvent(
            eventId: (string) ($payload['id'] ?? sha1($body)),
            type: $type,
            providerReference: $transactionId !== null ? (string) $transactionId : null,
            outcome: $outcome,
            payload: $payload,
        );
    }

    /** Remboursement traité par la conciergerie depuis le tableau de bord FedaPay. */
    public function refund(Payment $refund, Payment $original): PaymentStatus
    {
        return PaymentStatus::Pending;
    }

    private function client(): PendingRequest
    {
        $base = $this->environment === 'live' ? 'https://api.fedapay.com/v1' : 'https://sandbox-api.fedapay.com/v1';

        return Http::baseUrl($base)->withToken($this->secretKey)->acceptJson()->timeout(20);
    }
}
