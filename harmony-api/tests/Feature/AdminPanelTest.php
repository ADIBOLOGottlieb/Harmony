<?php

use App\Enums\BookingStatus;
use App\Enums\MaintenanceStatus;
use App\Enums\MaintenanceType;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Filament\Resources\Apartments\Pages\ListApartments;
use App\Filament\Resources\Bookings\Pages\ListBookings;
use App\Filament\Resources\Bookings\Pages\ViewBooking;
use App\Models\Apartment;
use App\Models\Booking;
use App\Models\Review;
use App\Models\User;
use Carbon\CarbonImmutable;
use Database\Seeders\CatalogSeeder;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Livewire\Livewire;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->seed(CatalogSeeder::class);
    $this->travelTo(CarbonImmutable::parse('2026-10-10 08:00:00', 'Africa/Lome'));
    Filament::setCurrentPanel('admin');

    $this->staff = fn (UserRole $role = UserRole::Concierge, array $attrs = []) => User::factory()->create($attrs + [
        'role' => $role,
        'phone' => '+2289'.random_int(1000000, 9999999),
        'password' => 'mot-de-passe-solide',
    ]);

    // Réservation par virement (reste en attente jusqu'à validation par la conciergerie).
    $this->transferBooking = function (): Booking {
        $client = User::factory()->create(['phone' => '+22890000077', 'password' => null]);
        Sanctum::actingAs($client);
        $reference = $this->postJson('/api/v1/bookings', bookingPayload(['payment_method' => 'bank_transfer']))
            ->assertCreated()->json('data.reference');
        // Sanctum::actingAs bascule la garde par défaut ; Filament utilise la garde web.
        auth()->forgetGuards();
        auth()->shouldUse('web');

        return Booking::query()->where('reference', $reference)->firstOrFail();
    };
});

it('réserve l’espace de gestion au personnel et aux propriétaires', function () {
    $client = User::factory()->create(['phone' => '+22890000001', 'password' => 'mot-de-passe-solide']);
    $this->actingAs($client)->get('/gestion')->assertForbidden();
    $this->flushSession();

    $this->actingAs(($this->staff)(UserRole::Admin))->get('/gestion')->assertOk()->assertSee('HARMONY HOME');
    // Nouvelle session : AuthenticateSession lie la session au mot de passe du compte connecté.
    $this->flushSession();
    $this->actingAs(($this->staff)(UserRole::Concierge))->get('/gestion/reservations')->assertOk();
});

it('refuse un compte du personnel sans mot de passe', function () {
    $staff = ($this->staff)(UserRole::Concierge, ['password' => null]);
    $this->actingAs($staff)->get('/gestion')->assertForbidden();
});

it('limite un propriétaire à ses biens et lui ferme les zones et les comptes', function () {
    $owner = ($this->staff)(UserRole::Owner);
    $mine = Apartment::query()->where('slug', 'villa-lagune')->firstOrFail();
    $mine->update(['owner_id' => $owner->id]);
    $other = Apartment::query()->where('slug', '!=', 'villa-lagune')->firstOrFail();

    $this->actingAs($owner);
    Livewire::test(ListApartments::class)
        ->assertCanSeeTableRecords([$mine])
        ->assertCanNotSeeTableRecords([$other]);

    $this->get('/gestion/zones')->assertForbidden();
    $this->get('/gestion/comptes')->assertForbidden();
    $this->get('/gestion/biens/'.$other->slug.'/edit')->assertNotFound();
});

it('valide un virement : réservation confirmée et ménage de sortie planifié', function () {
    $booking = ($this->transferBooking)();
    expect($booking->status)->toBe(BookingStatus::Pending);

    $this->actingAs(($this->staff)());
    Livewire::test(ViewBooking::class, ['record' => $booking->getRouteKey()])
        ->callAction('validateTransfer')
        ->assertHasNoActionErrors();

    $booking->refresh();
    expect($booking->status)->toBe(BookingStatus::Confirmed)
        ->and($booking->amount_paid)->toBe($booking->advance_amount)
        ->and($booking->payments()->value('validated_by'))->not->toBeNull();

    $task = $booking->maintenanceTasks()->sole();
    expect($task->type)->toBe(MaintenanceType::Cleaning)
        ->and($task->due_at->equalTo($booking->end_at))->toBeTrue();
});

it('annule une réservation depuis l’espace de gestion et annule le ménage prévu', function () {
    $booking = ($this->transferBooking)();
    $this->actingAs(($this->staff)());
    Livewire::test(ViewBooking::class, ['record' => $booking->getRouteKey()])->callAction('validateTransfer');

    Livewire::test(ViewBooking::class, ['record' => $booking->getRouteKey()])
        ->callAction('cancel', data: ['reason' => 'Demande du client par téléphone'])
        ->assertHasNoActionErrors();

    $booking->refresh();
    expect($booking->status)->toBe(BookingStatus::Cancelled)
        ->and($booking->maintenanceTasks()->value('status'))->toBe(MaintenanceStatus::Cancelled)
        ->and($booking->payments()->where('kind', 'refund')->value('status'))->toBe(PaymentStatus::Pending);
});

it('n’offre pas la validation des virements à un propriétaire', function () {
    $booking = ($this->transferBooking)();
    $owner = ($this->staff)(UserRole::Owner);
    $booking->apartment->update(['owner_id' => $owner->id]);

    $this->actingAs($owner);
    Livewire::test(ViewBooking::class, ['record' => $booking->getRouteKey()])
        ->assertActionHidden('validateTransfer')
        ->assertActionHidden('cancel')
        ->assertDontSee('+22890000077');
});

it('exporte les réservations en CSV', function () {
    ($this->transferBooking)();
    $this->actingAs(($this->staff)());

    Livewire::test(ListBookings::class)->callAction('export')->assertFileDownloaded('reservations-2026-10-10.csv');
});

it('recalcule la note du bien à la publication d’un avis', function () {
    $booking = ($this->transferBooking)();
    $apartment = $booking->apartment;
    $apartment->reviews()->delete();

    $review = Review::query()->create([
        'booking_id' => $booking->id, 'apartment_id' => $apartment->id, 'user_id' => $booking->user_id,
        'rating' => 4, 'comment' => 'Très bel appartement', 'published' => false,
    ]);
    expect($apartment->refresh()->review_count)->toBe(0);

    $review->update(['published' => true]);
    expect($apartment->refresh()->review_count)->toBe(1)->and($apartment->rating)->toBe(4.0);
});

it('ne révèle jamais l’adresse exacte dans le catalogue public', function () {
    Apartment::query()->where('slug', 'villa-lagune')->update(['address' => 'Lot 12, rue 245, Baguida']);

    $this->getJson('/api/v1/apartments/villa-lagune')
        ->assertOk()
        ->assertDontSee('Lot 12')
        ->assertJsonPath('data.location.area', 'Route d’Aného, Baguida');
});

it('crée le premier administrateur depuis l’environnement sans écraser un compte existant', function () {
    putenv('HARMONY_ADMIN_EMAIL=direction@harmony.test');
    putenv('HARMONY_ADMIN_PASSWORD=un-mot-de-passe-long');

    $this->artisan('harmony:bootstrap-admin')->assertSuccessful();
    $admin = User::query()->where('email', 'direction@harmony.test')->sole();
    expect($admin->role)->toBe(UserRole::Admin)->and($admin->canAccessPanel(Filament::getPanel('admin')))->toBeTrue();

    putenv('HARMONY_ADMIN_PASSWORD=autre-mot-de-passe-long');
    $hash = $admin->password;
    $this->artisan('harmony:bootstrap-admin')->assertSuccessful();
    expect($admin->refresh()->password)->toBe($hash);

    putenv('HARMONY_ADMIN_EMAIL');
    putenv('HARMONY_ADMIN_PASSWORD');
});

it('charge le catalogue de démonstration une seule fois', function () {
    $count = Apartment::query()->count();
    $this->artisan('harmony:seed-demo')->assertSuccessful();
    expect(Apartment::query()->count())->toBe($count);
});
