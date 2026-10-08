<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Sonde de disponibilité utilisée par l'app mobile et la CI.
    Route::get('/health', fn () => response()->json([
        'status' => 'ok',
        'service' => 'harmony-api',
        'time' => now()->toIso8601String(),
    ]));

    Route::get('/user', fn (Request $request) => $request->user())->middleware('auth:sanctum');
});
