<?php

use App\Enums\BookingStatus;
use App\Enums\PaymentKind;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Models\Booking;
use App\Models\PaymentEvent;
use App\Models\User;
use App\Services\Payments\PaymentService;
use Carbon\CarbonImmutable;
use Database\Seeders\CatalogSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\URL;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->seed(CatalogSeeder::class);
    $this->travelTo(CarbonImmutable::parse('2026-10-10 08:00:00', 'Africa/Lome'));
    config(['harmony.payments.sandbox_enabled' => true, 'services.fedapay.secret_key' => null]);
    $this->user = User::factory()->create(['phone' => '+22890000020']);
    Sanctum::actingAs($this->user);

    $this->book = function (array $overrides = []): Booking {
        $reference = $this->postJson('/api/v1/bookings', bookingPayload($overrides))->assertCreated()->json('data.reference');

        return Booking::query()->where('reference', $reference)->firstOrFail();
    };

    $this->paySandbox = function (Booking $booking): void {
        $payment = $booking->payments()->where('status', PaymentStatus::Pending)->firstOrFail();
        $url = URL::temporarySignedRoute('payments.sandbox.complete', now()->addHour(), ['payment' => $payment->id]);
        $this->post($url, ['outcome' => 'success'])->assertOk();
    };
});

it('confirme la réservation après un paiement réussi et révèle l’adresse', function () {
    $booking = ($this->book)();
    ($this->paySandbox)($booking);

    $booking->refresh();
    expect($booking->status)->toBe(BookingStatus::Confirmed)
        ->and($booking->amount_paid)->toBe(89775)
        ->and($booking->expires_at)->toBeNull();

    $this->getJson("/api/v1/bookings/{$booking->reference}")
        ->assertJsonPath('data.apartment.address', 'Boulevard du Mono, Kodjoviakopé')
        ->assertJsonPath('data.amounts.balance_due', 209475);
});

it('refuse la page de paiement simulé sans signature', function () {
    $booking = ($this->book)();
    $this->get('/paiement/sandbox/'.$booking->payments()->value('id'))->assertForbidden();
});

it('traite un webhook FedaPay signé une seule fois', function () {
    config(['services.fedapay.webhook_secret' => 'whsec_test']);
    $booking = ($this->book)();
    $booking->payments()->first()->update(['gateway' => 'fedapay', 'provider_reference' => '777']);

    $body = json_encode(['id' => 'evt_1', 'name' => 'transaction.approved', 'entity' => ['id' => 777, 'status' => 'approved']]);
    $t = time();
    $send = fn (string $signature) => $this->call('POST', '/api/v1/payments/webhooks/fedapay', [], [], [], [
        'CONTENT_TYPE' => 'application/json',
        'HTTP_X_FEDAPAY_SIGNATURE' => "t={$t},s={$signature}",
    ], $body);
    $valid = hash_hmac('sha256', "{$t}.{$body}", 'whsec_test');

    $send($valid)->assertOk();
    $send($valid)->assertOk();

    $booking->refresh();
    expect($booking->status)->toBe(BookingStatus::Confirmed)
        ->and($booking->amount_paid)->toBe(89775)
        ->and(PaymentEvent::query()->count())->toBe(1);
});

it('rejette un webhook mal signé', function () {
    config(['services.fedapay.webhook_secret' => 'whsec_test']);
    $booking = ($this->book)();

    $this->call('POST', '/api/v1/payments/webhooks/fedapay', [], [], [], [
        'CONTENT_TYPE' => 'application/json',
        'HTTP_X_FEDAPAY_SIGNATURE' => 't='.time().',s=falsifiee',
    ], json_encode(['id' => 'evt_2', 'name' => 'transaction.approved', 'entity' => ['id' => 1]]))->assertStatus(400);

    expect($booking->refresh()->status)->toBe(BookingStatus::Pending);
});

it('confirme un virement après validation par la conciergerie', function () {
    $booking = ($this->book)(['payment_method' => 'bank_transfer']);
    $payment = $booking->payments()->firstOrFail();

    expect($payment->instructions)->toContain($booking->reference)
        ->and($booking->expires_at->diffInHours(now(), true))->toBeGreaterThan(40);

    app(PaymentService::class)->validateTransfer($payment, User::factory()->create(['role' => UserRole::Admin]));

    expect($booking->refresh()->status)->toBe(BookingStatus::Confirmed)
        ->and($payment->refresh()->validated_by)->not->toBeNull();
});

it('encaisse le solde après l’acompte', function () {
    $booking = ($this->book)();
    ($this->paySandbox)($booking);

    $this->postJson("/api/v1/bookings/{$booking->reference}/pay-balance", ['payment_method' => 'card'])
        ->assertOk()
        ->assertJsonPath('data.payments.0.kind', 'balance')
        ->assertJsonPath('data.payments.0.amount', 209475);

    ($this->paySandbox)($booking->refresh());

    expect($booking->refresh()->amount_paid)->toBe(299250)
        ->and($booking->balanceDue())->toBe(0);
});

it('rembourse l’acompte en cas d’annulation avant l’échéance', function () {
    $booking = ($this->book)();
    ($this->paySandbox)($booking);

    $this->postJson("/api/v1/bookings/{$booking->reference}/cancel")
        ->assertOk()
        ->assertJsonPath('data.status', 'refunded');

    expect($booking->refresh()->amount_paid)->toBe(0)
        ->and($booking->payments()->where('kind', PaymentKind::Refund)->value('status'))->toBe(PaymentStatus::Succeeded);
});

it('conserve l’acompte en cas d’annulation tardive', function () {
    $booking = ($this->book)(['check_in' => '2026-10-12', 'check_out' => '2026-10-14']);
    ($this->paySandbox)($booking);

    $this->postJson("/api/v1/bookings/{$booking->reference}/cancel")
        ->assertOk()
        ->assertJsonPath('data.status', 'cancelled');

    expect($booking->payments()->where('kind', PaymentKind::Refund)->exists())->toBeFalse();
});

it('fournit le reçu PDF de la réservation', function () {
    $booking = ($this->book)();

    $this->get("/api/v1/bookings/{$booking->reference}/receipt")
        ->assertOk()
        ->assertHeader('content-type', 'application/pdf');
});
