<?php

use App\Enums\BookingStatus;
use App\Models\Apartment;
use App\Models\ApartmentBlock;
use App\Models\Booking;
use App\Models\SeasonalPrice;
use App\Models\User;
use Carbon\CarbonImmutable;
use Database\Seeders\CatalogSeeder;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->seed(CatalogSeeder::class);
    $this->travelTo(CarbonImmutable::parse('2026-10-10 08:00:00', 'Africa/Lome'));
    config(['harmony.payments.sandbox_enabled' => true, 'services.fedapay.secret_key' => null]);
    $this->user = User::factory()->create(['phone' => '+22890000010']);
});

it('calcule un devis : nuits, frais de service, acompte et caution', function () {
    $this->postJson('/api/v1/bookings/quote', bookingPayload())
        ->assertOk()
        ->assertJsonPath('data.nights', 3)
        ->assertJsonPath('data.accommodation', 285000)
        ->assertJsonPath('data.service_fee', 14250)
        ->assertJsonPath('data.total', 299250)
        ->assertJsonPath('data.advance', 89775)
        ->assertJsonPath('data.balance', 209475)
        ->assertJsonPath('data.security_deposit', 150000);
});

it('applique les prix saisonniers nuit par nuit', function () {
    SeasonalPrice::query()->create([
        'apartment_id' => Apartment::query()->where('slug', 'duplex-horizon')->value('id'),
        'label' => 'Fête',
        'starts_on' => '2026-10-21',
        'ends_on' => '2026-10-21',
        'price_per_night' => 120000,
    ]);

    $this->postJson('/api/v1/bookings/quote', bookingPayload())
        ->assertOk()
        ->assertJsonPath('data.accommodation', 95000 * 2 + 120000);
});

it('propose les séjours courts seulement quand le bien les accepte', function () {
    $this->postJson('/api/v1/bookings/quote', bookingPayload([
        'apartment' => 'studio-atlantique', 'stay_type' => 'three_hours', 'check_out' => null, 'start_time' => '15:00',
    ]))
        ->assertOk()
        ->assertJsonPath('data.total', 10500)
        ->assertJsonPath('data.advance', 10500);

    $this->postJson('/api/v1/bookings/quote', bookingPayload([
        'stay_type' => 'three_hours', 'check_out' => null, 'start_time' => '15:00',
    ]))
        ->assertUnprocessable()
        ->assertJsonPath('code', 'stay_type_unavailable');
});

it('crée une réservation en attente avec un lien de paiement', function () {
    Sanctum::actingAs($this->user);

    $response = $this->postJson('/api/v1/bookings', bookingPayload())->assertCreated();

    expect($response->json('data.reference'))->toMatch('/^HH-[A-Z2-9]{6}$/')
        ->and($response->json('data.status'))->toBe('pending')
        ->and($response->json('data.payments.0.amount'))->toBe(89775)
        ->and($response->json('data.payments.0.checkout_url'))->toContain('/paiement/sandbox/')
        // L'adresse exacte reste masquée tant que la réservation n'est pas confirmée.
        ->and($response->json('data.apartment.address'))->toBeNull();

    // Régression : l'app lit des entiers ; un montant null faisait échouer la réservation côté client.
    foreach ($response->json('data.amounts') as $key => $value) {
        if ($key !== 'currency') {
            expect($value)->toBeInt();
        }
    }
    expect($response->json('data.amounts.paid'))->toBe(0);
});

it('exige d’être connecté pour réserver', function () {
    $this->postJson('/api/v1/bookings', bookingPayload())->assertUnauthorized();
});

it('refuse des dates qui chevauchent une réservation existante', function () {
    Sanctum::actingAs($this->user);
    $this->postJson('/api/v1/bookings', bookingPayload())->assertCreated();

    Sanctum::actingAs(User::factory()->create());
    $this->postJson('/api/v1/bookings', bookingPayload(['check_in' => '2026-10-22', 'check_out' => '2026-10-25']))
        ->assertStatus(409)
        ->assertJsonPath('code', 'dates_unavailable');
});

it('remplace la demande impayée du même client relancée sur les mêmes dates', function () {
    Sanctum::actingAs($this->user);
    $first = $this->postJson('/api/v1/bookings', bookingPayload())->assertCreated()->json('data.reference');
    $second = $this->postJson('/api/v1/bookings', bookingPayload())->assertCreated()->json('data.reference');

    expect($second)->not->toBe($first)
        ->and(Booking::query()->where('reference', $first)->value('status'))->toBe(BookingStatus::Cancelled)
        ->and(Booking::query()->where('reference', $first)->value('cancel_reason'))->toBe('replaced');
});

it('accepte une arrivée le jour du départ précédent', function () {
    Sanctum::actingAs($this->user);
    $this->postJson('/api/v1/bookings', bookingPayload())->assertCreated();
    $this->postJson('/api/v1/bookings', bookingPayload(['check_in' => '2026-10-23', 'check_out' => '2026-10-25']))->assertCreated();
});

it('respecte le battement de ménage après un départ', function () {
    Sanctum::actingAs($this->user);
    $this->postJson('/api/v1/bookings', bookingPayload([
        'apartment' => 'studio-atlantique', 'check_in' => '2026-10-20', 'check_out' => '2026-10-21',
    ]))->assertCreated();

    $short = fn (string $time) => bookingPayload([
        'apartment' => 'studio-atlantique', 'stay_type' => 'three_hours', 'check_in' => '2026-10-21',
        'check_out' => null, 'start_time' => $time,
    ]);

    // Départ à 11:00 + 60 min de ménage : la chambre est libre à partir de 12:00.
    $this->postJson('/api/v1/bookings', $short('11:00'))->assertStatus(409);
    $this->postJson('/api/v1/bookings', $short('12:00'))->assertCreated();
});

it('refuse des dates bloquées par le propriétaire', function () {
    ApartmentBlock::query()->create([
        'apartment_id' => Apartment::query()->where('slug', 'duplex-horizon')->value('id'),
        'starts_on' => '2026-10-21',
        'ends_on' => '2026-10-21',
        'reason' => 'Travaux',
    ]);

    Sanctum::actingAs($this->user);
    $this->postJson('/api/v1/bookings', bookingPayload())->assertStatus(409);
});

it('affiche les disponibilités jour par jour', function () {
    ApartmentBlock::query()->create([
        'apartment_id' => Apartment::query()->where('slug', 'duplex-horizon')->value('id'),
        'starts_on' => '2026-10-25',
        'ends_on' => '2026-10-25',
    ]);
    Sanctum::actingAs($this->user);
    $this->postJson('/api/v1/bookings', bookingPayload())->assertCreated();

    $days = collect($this->getJson('/api/v1/apartments/duplex-horizon/availability?from=2026-10-09&to=2026-10-26')
        ->assertOk()
        ->json('data'))->pluck('status', 'date');

    expect($days['2026-10-09'])->toBe('past')
        ->and($days['2026-10-19'])->toBe('free')
        ->and($days['2026-10-20'])->toBe('booked')
        ->and($days['2026-10-22'])->toBe('booked')
        ->and($days['2026-10-23'])->toBe('free')
        ->and($days['2026-10-25'])->toBe('blocked');
});

it('refuse un logement en maintenance ou une capacité dépassée', function () {
    Sanctum::actingAs($this->user);

    $this->postJson('/api/v1/bookings', bookingPayload(['apartment' => 'appartement-indigo']))
        ->assertStatus(409)
        ->assertJsonPath('code', 'apartment_unavailable');

    $this->postJson('/api/v1/bookings', bookingPayload(['guests' => 7]))
        ->assertUnprocessable()
        ->assertJsonPath('code', 'too_many_guests');
});

it('libère les dates d’une réservation non payée à temps', function () {
    Sanctum::actingAs($this->user);
    $first = $this->postJson('/api/v1/bookings', bookingPayload())->assertCreated()->json('data.reference');

    $this->travel(31)->minutes();

    Sanctum::actingAs(User::factory()->create());
    $this->postJson('/api/v1/bookings', bookingPayload())->assertCreated();

    expect(Booking::query()->where('reference', $first)->value('status'))->toBe(BookingStatus::Cancelled);
});

it('protège les réservations des autres clients', function () {
    Sanctum::actingAs($this->user);
    $reference = $this->postJson('/api/v1/bookings', bookingPayload())->json('data.reference');

    Sanctum::actingAs(User::factory()->create());
    $this->getJson("/api/v1/bookings/{$reference}")->assertForbidden();
    $this->postJson("/api/v1/bookings/{$reference}/cancel")->assertForbidden();
});

it('garantit en base l’absence de chevauchement (PostgreSQL)', function () {
    if (DB::getDriverName() !== 'pgsql') {
        $this->markTestSkipped('Contrainte d’exclusion propre à PostgreSQL (vérifiée en CI).');
    }

    $base = [
        'apartment_id' => Apartment::query()->where('slug', 'duplex-horizon')->value('id'),
        'user_id' => $this->user->id,
        'stay_type' => 'night',
        'start_at' => '2026-10-20 14:00:00',
        'end_at' => '2026-10-23 11:00:00',
        'blocked_until' => '2026-10-23 12:00:00',
        'nights' => 3,
        'guests' => 2,
        'status' => 'confirmed',
        'accommodation_amount' => 1,
        'service_fee' => 0,
        'total_amount' => 1,
        'security_deposit' => 0,
        'advance_amount' => 1,
        'price_breakdown' => [],
    ];
    Booking::query()->create($base + ['reference' => 'HH-AAAAAA']);

    $overlap = array_merge($base, [
        'reference' => 'HH-BBBBBB',
        'start_at' => '2026-10-22 14:00:00',
        'end_at' => '2026-10-24 11:00:00',
        'blocked_until' => '2026-10-24 12:00:00',
    ]);
    expect(fn () => DB::transaction(fn () => Booking::query()->create($overlap)))->toThrow(QueryException::class);

    // Une réservation annulée ne bloque pas le calendrier.
    Booking::query()->create(array_merge($overlap, ['reference' => 'HH-CCCCCC', 'status' => 'cancelled']));
    expect(Booking::query()->count())->toBe(2);
});
