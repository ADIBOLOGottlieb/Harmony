<?php

use App\Enums\BookingStatus;
use App\Models\Booking;
use App\Models\User;
use Carbon\CarbonImmutable;
use Database\Seeders\CatalogSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->seed(CatalogSeeder::class);
    $this->travelTo(CarbonImmutable::parse('2026-10-10 08:00:00', 'Africa/Lome'));
    $this->user = User::factory()->create(['phone' => '+22890000030']);
    Sanctum::actingAs($this->user);

    $reference = $this->postJson('/api/v1/bookings', bookingPayload())->assertCreated()->json('data.reference');
    $this->booking = Booking::query()->where('reference', $reference)->firstOrFail();
});

it('refuse un avis tant que le séjour n’est pas terminé', function () {
    $this->postJson("/api/v1/bookings/{$this->booking->reference}/review", ['rating' => 5])->assertForbidden();
});

it('enregistre un avis non publié après le séjour, une seule fois', function () {
    $this->booking->update(['status' => BookingStatus::Completed]);
    $this->getJson("/api/v1/bookings/{$this->booking->reference}")->assertJsonPath('data.can_review', true);

    $this->postJson("/api/v1/bookings/{$this->booking->reference}/review", ['rating' => 5, 'comment' => '  Parfait  '])
        ->assertOk()
        ->assertJsonPath('data.review.rating', 5)
        ->assertJsonPath('data.review.comment', 'Parfait')
        ->assertJsonPath('data.can_review', false);

    expect($this->booking->review->published)->toBeFalse();
    $this->postJson("/api/v1/bookings/{$this->booking->reference}/review", ['rating' => 4])->assertForbidden();
});

it('valide la note entre 1 et 5', function () {
    $this->booking->update(['status' => BookingStatus::Completed]);
    $this->postJson("/api/v1/bookings/{$this->booking->reference}/review", ['rating' => 9])
        ->assertUnprocessable()->assertJsonValidationErrors('rating');
});

it('interdit de noter le séjour d’un autre client', function () {
    $this->booking->update(['status' => BookingStatus::Completed]);
    Sanctum::actingAs(User::factory()->create(['phone' => '+22890000031']));
    $this->postJson("/api/v1/bookings/{$this->booking->reference}/review", ['rating' => 1])->assertForbidden();
});
