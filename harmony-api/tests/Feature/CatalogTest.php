<?php

use App\Enums\UserRole;
use App\Models\Apartment;
use App\Models\User;
use Database\Seeders\CatalogSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Gate;

uses(RefreshDatabase::class);

beforeEach(fn () => $this->seed(CatalogSeeder::class));

it('liste les zones avec leur nombre de biens', function () {
    $this->getJson('/api/v1/zones')
        ->assertOk()
        ->assertJsonCount(5, 'data')
        ->assertJsonFragment(['slug' => 'agoe', 'apartments_count' => 2]);
});

it('liste les biens, à la une d’abord', function () {
    $response = $this->getJson('/api/v1/apartments')->assertOk()->assertJsonCount(8, 'data');

    expect($response->json('data.0.featured'))->toBeTrue()
        ->and($response->json('data.0.price_per_night'))->toBeInt();
});

it('filtre par zone, capacité, type, budget et équipements', function (array $query, array $expected) {
    $slugs = collect($this->getJson('/api/v1/apartments?'.http_build_query($query))->assertOk()->json('data'))
        ->pluck('slug')->sort()->values()->all();

    expect($slugs)->toBe(collect($expected)->sort()->values()->all());
})->with([
    'zone' => [['zone' => 'baguida'], ['villa-lagune']],
    'capacité' => [['guests' => 7], ['villa-lagune']],
    'type' => [['type' => 'villa'], ['villa-baobab', 'villa-lagune']],
    'budget' => [['max_price' => 30000], ['appartement-indigo', 'jardin-avedji', 'studio-atlantique']],
    'équipements' => [['amenities' => ['pool']], ['villa-lagune']],
]);

it('refuse un filtre invalide', function () {
    $this->getJson('/api/v1/apartments?type=chateau')->assertUnprocessable()->assertJsonValidationErrors('type');
    $this->getJson('/api/v1/apartments?amenities[]=jacuzzi')->assertUnprocessable();
});

it('affiche une fiche avec photos et position arrondie', function () {
    $this->getJson('/api/v1/apartments/villa-lagune')
        ->assertOk()
        ->assertJsonPath('data.title', 'Villa Lagune')
        ->assertJsonPath('data.zone.name', 'Baguida')
        ->assertJsonPath('data.photos.0.path', 'demo/p01.webp')
        ->assertJsonPath('data.location.latitude', 6.163)
        ->assertJsonPath('data.short_stays.day', 90000);
});

it('renvoie 404 pour un bien inconnu', function () {
    $this->getJson('/api/v1/apartments/inconnu')->assertNotFound();
});

it('réserve la gestion d’un bien au personnel ou à son propriétaire', function () {
    $apartment = Apartment::query()->where('slug', 'villa-lagune')->firstOrFail();
    $owner = $apartment->owner;
    $otherOwner = User::factory()->create(['role' => UserRole::Owner]);
    $client = User::factory()->create(['role' => UserRole::Client]);
    $concierge = User::factory()->create(['role' => UserRole::Concierge]);
    $admin = User::factory()->create(['role' => UserRole::Admin]);

    expect(Gate::forUser($owner)->allows('update', $apartment))->toBeTrue()
        ->and(Gate::forUser($otherOwner)->allows('update', $apartment))->toBeFalse()
        ->and(Gate::forUser($client)->allows('update', $apartment))->toBeFalse()
        ->and(Gate::forUser($concierge)->allows('update', $apartment))->toBeTrue()
        ->and(Gate::forUser($admin)->allows('delete', $apartment))->toBeTrue()
        ->and(Gate::forUser($owner)->allows('delete', $apartment))->toBeFalse();
});
