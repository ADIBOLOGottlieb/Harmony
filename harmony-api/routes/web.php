<?php

use App\Http\Controllers\SandboxPaymentController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Paiement simulé (démonstration), accessible uniquement par lien signé.
Route::middleware('signed')->group(function () {
    Route::get('/paiement/sandbox/{payment}', [SandboxPaymentController::class, 'show'])->name('payments.sandbox.show');
    Route::post('/paiement/sandbox/{payment}', [SandboxPaymentController::class, 'complete'])->name('payments.sandbox.complete');
});

// Retour de la page FedaPay : l'app reprend la main, le webhook confirme le paiement.
Route::get('/paiement/retour', fn () => response('<p style="font-family:sans-serif;padding:24px">Paiement transmis. Vous pouvez revenir dans l’application HARMONY HOME.</p>'));
