<?php

use App\Http\Controllers\Api\V1\ApartmentController;
use App\Http\Controllers\Api\V1\ArtworkOrderController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\AvailabilityController;
use App\Http\Controllers\Api\V1\AvatarController;
use App\Http\Controllers\Api\V1\BookingController;
use App\Http\Controllers\Api\V1\GalleryController;
use App\Http\Controllers\Api\V1\PaymentWebhookController;
use App\Http\Controllers\Api\V1\ZoneController;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Catalogue public.
    Route::middleware('throttle:api')->group(function () {
        Route::get('/zones', [ZoneController::class, 'index']);
        Route::get('/apartments', [ApartmentController::class, 'index']);
        Route::get('/apartments/{apartment}', [ApartmentController::class, 'show']);
        Route::get('/apartments/{apartment}/availability', [AvailabilityController::class, 'show']);
        Route::post('/bookings/quote', [BookingController::class, 'quote'])->name('bookings.quote');

        // Taux d'affichage des devises (les paiements restent en FCFA).
        Route::get('/settings', fn () => response()->json(['data' => [
            'currencies' => ['XOF' => 1] + config('harmony.currencies'),
        ]]));

        // Galerie d'art.
        Route::get('/gallery/artists', [GalleryController::class, 'artists']);
        Route::get('/gallery/artworks', [GalleryController::class, 'index']);
        Route::get('/gallery/artworks/{artwork}', [GalleryController::class, 'show']);
    });

    // Connexion par téléphone et code à usage unique.
    Route::middleware('throttle:otp')->group(function () {
        Route::post('/auth/otp', [AuthController::class, 'requestOtp']);
    });
    Route::post('/auth/verify', [AuthController::class, 'verifyOtp'])->middleware('throttle:otp-verify');

    // Webhooks des passerelles de paiement (signature vérifiée dans le service).
    Route::post('/payments/webhooks/fedapay', [PaymentWebhookController::class, 'fedapay'])->middleware('throttle:api');

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::patch('/auth/me', [AuthController::class, 'updateProfile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        Route::get('/bookings', [BookingController::class, 'index']);
        Route::get('/bookings/{booking}', [BookingController::class, 'show']);
        Route::get('/bookings/{booking}/receipt', [BookingController::class, 'receipt']);
        Route::post('/auth/me/avatar', [AvatarController::class, 'store'])->middleware('throttle:booking');
        Route::delete('/auth/me/avatar', [AvatarController::class, 'destroy']);

        // Galerie : acquisitions du client.
        Route::get('/gallery/orders', [ArtworkOrderController::class, 'index']);
        Route::middleware('throttle:booking')->group(function () {
            Route::post('/gallery/artworks/{artwork}/orders', [ArtworkOrderController::class, 'store']);
            Route::post('/gallery/orders/{order}/cancel', [ArtworkOrderController::class, 'cancel']);
        });
        Route::middleware('throttle:booking')->group(function () {
            Route::post('/bookings', [BookingController::class, 'store'])->name('bookings.store');
            Route::post('/bookings/{booking}/cancel', [BookingController::class, 'cancel']);
            Route::post('/bookings/{booking}/pay-balance', [BookingController::class, 'payBalance']);
            Route::post('/bookings/{booking}/review', [BookingController::class, 'review']);
        });
    });

    // Sonde de santé : vérifie aussi la base. Appelée chaque jour par la CI
    // (.github/workflows/keepalive.yml), ce qui évite la mise en pause du
    // projet Supabase gratuit après 7 jours sans activité.
    Route::get('/health', function () {
        try {
            DB::select('select 1');
            $database = 'ok';
        } catch (Throwable) {
            // Aucun détail renvoyé : le message d'erreur pourrait exposer l'hôte ou l'utilisateur.
            $database = 'unavailable';
        }

        return response()->json([
            'status' => $database === 'ok' ? 'ok' : 'degraded',
            'service' => 'harmony-api',
            'database' => $database,
            'time' => now()->toIso8601String(),
        ], $database === 'ok' ? 200 : 503);
    });

});
