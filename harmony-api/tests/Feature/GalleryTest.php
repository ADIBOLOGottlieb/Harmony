<?php

use App\Enums\ArtworkOrderStatus;
use App\Enums\ArtworkStatus;
use App\Enums\UserRole;
use App\Models\Artwork;
use App\Models\ArtworkOrder;
use App\Models\User;
use App\Services\Gallery\GalleryService;
use Carbon\CarbonImmutable;
use Database\Seeders\GallerySeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->seed(GallerySeeder::class);
    $this->travelTo(CarbonImmutable::parse('2026-10-10 08:00:00', 'Africa/Lome'));
    $this->user = User::factory()->create(['phone' => '+22890000050']);
});

it('liste les œuvres publiées, disponibles d’abord, avec artiste et visuels', function () {
    Artwork::query()->where('slug', 'rythmes')->update(['published' => false]);
    Artwork::query()->where('slug', 'les-gardiens')->update(['status' => ArtworkStatus::Sold]);

    $data = $this->getJson('/api/v1/gallery/artworks')->assertOk()->json('data');

    expect(collect($data)->pluck('slug'))->not->toContain('rythmes')
        ->and(end($data)['slug'])->toBe('les-gardiens')
        ->and($data[0]['artist']['name'])->not->toBeEmpty()
        ->and($data[0]['photos'][0])->toStartWith('demo/art/')
        ->and($data[0]['price'])->toBeInt();
    $this->getJson('/api/v1/gallery/artworks/rythmes')->assertNotFound();
});

it('filtre par artiste et liste les artistes', function () {
    $slugs = collect($this->getJson('/api/v1/gallery/artworks?artist=esi-adjovi')->json('data'))->pluck('slug');
    expect($slugs->sort()->values()->all())->toBe(['les-gardiens', 'rythmes']);

    $this->getJson('/api/v1/gallery/artists')->assertOk()->assertJsonCount(3, 'data');
});

it('réserve l’œuvre au client et calcule les frais de livraison', function () {
    config(['harmony.gallery.delivery_fee' => 10000]);
    Sanctum::actingAs($this->user);

    $this->postJson('/api/v1/gallery/artworks/grand-marche/orders', [
        'delivery_method' => 'delivery',
        'delivery_address' => 'Rue des Cocotiers, Bè',
    ])->assertCreated()
        ->assertJsonPath('data.status', 'pending')
        ->assertJsonPath('data.price', 390000)
        ->assertJsonPath('data.delivery_fee', 10000)
        ->assertJsonPath('data.total', 400000);

    expect(Artwork::query()->where('slug', 'grand-marche')->value('status'))->toBe(ArtworkStatus::Reserved);
});

it('exige une adresse pour une livraison', function () {
    Sanctum::actingAs($this->user);
    $this->postJson('/api/v1/gallery/artworks/grand-marche/orders', ['delivery_method' => 'delivery'])
        ->assertUnprocessable()->assertJsonValidationErrors('delivery_address');
});

it('refuse de vendre deux fois la même œuvre', function () {
    Sanctum::actingAs($this->user);
    $this->postJson('/api/v1/gallery/artworks/rythmes/orders', ['delivery_method' => 'pickup'])->assertCreated();

    Sanctum::actingAs(User::factory()->create(['phone' => '+22890000051']));
    $this->postJson('/api/v1/gallery/artworks/rythmes/orders', ['delivery_method' => 'pickup'])
        ->assertStatus(409)->assertJsonPath('code', 'artwork_unavailable');
});

it('libère l’œuvre si la réservation n’est pas réglée à temps', function () {
    Sanctum::actingAs($this->user);
    $reference = $this->postJson('/api/v1/gallery/artworks/rythmes/orders', ['delivery_method' => 'pickup'])->json('data.reference');

    $this->travel(49)->hours();
    $this->getJson('/api/v1/gallery/artworks/rythmes')->assertJsonPath('data.status', 'available');
    expect(ArtworkOrder::query()->where('reference', $reference)->value('status'))->toBe(ArtworkOrderStatus::Cancelled);
});

it('laisse le client annuler sa demande, pas celle d’un autre', function () {
    Sanctum::actingAs($this->user);
    $reference = $this->postJson('/api/v1/gallery/artworks/rythmes/orders', ['delivery_method' => 'pickup'])->json('data.reference');

    Sanctum::actingAs(User::factory()->create(['phone' => '+22890000052']));
    $this->postJson("/api/v1/gallery/orders/{$reference}/cancel")->assertForbidden();

    Sanctum::actingAs($this->user);
    $this->postJson("/api/v1/gallery/orders/{$reference}/cancel")->assertOk()->assertJsonPath('data.status', 'cancelled');
    expect(Artwork::query()->where('slug', 'rythmes')->value('status'))->toBe(ArtworkStatus::Available);
    $this->getJson('/api/v1/gallery/orders')->assertOk()->assertJsonCount(1, 'data');
});

it('marque l’œuvre vendue une fois le règlement confirmé par la galerie', function () {
    Sanctum::actingAs($this->user);
    $reference = $this->postJson('/api/v1/gallery/artworks/rythmes/orders', ['delivery_method' => 'pickup'])->json('data.reference');

    $order = ArtworkOrder::query()->where('reference', $reference)->firstOrFail();
    app(GalleryService::class)->markPaid($order, User::factory()->create(['role' => UserRole::Concierge, 'phone' => '+22890000053']));

    expect($order->refresh()->status)->toBe(ArtworkOrderStatus::Paid)
        ->and(Artwork::query()->where('slug', 'rythmes')->value('status'))->toBe(ArtworkStatus::Sold);
});

it('exige d’être connecté pour acquérir une œuvre', function () {
    $this->postJson('/api/v1/gallery/artworks/rythmes/orders', ['delivery_method' => 'pickup'])->assertUnauthorized();
});
