<?php

use App\Http\Controllers\Api\V1\ApartmentController;
use App\Http\Controllers\Api\V1\ZoneController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Catalogue public.
    Route::middleware('throttle:api')->group(function () {
        Route::get('/zones', [ZoneController::class, 'index']);
        Route::get('/apartments', [ApartmentController::class, 'index']);
        Route::get('/apartments/{apartment}', [ApartmentController::class, 'show']);
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

    Route::get('/user', fn (Request $request) => $request->user())->middleware('auth:sanctum');
});
