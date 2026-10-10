<?php

use Illuminate\Support\Facades\DB;

it('répond sur la sonde de santé versionnée', function () {
    $this->getJson('/api/v1/health')
        ->assertOk()
        ->assertJsonPath('status', 'ok')
        ->assertJsonPath('service', 'harmony-api')
        ->assertJsonPath('database', 'ok');
});

it('signale une base injoignable sans divulguer l\'erreur', function () {
    $connection = config('database.default');
    config(["database.connections.{$connection}.host" => 'hote-inexistant.invalid']);
    config(["database.connections.{$connection}.database" => '/chemin/inexistant/base.sqlite']);
    DB::purge($connection);

    $this->getJson('/api/v1/health')
        ->assertStatus(503)
        ->assertJsonPath('status', 'degraded')
        ->assertJsonPath('database', 'unavailable')
        ->assertJsonMissingPath('message');
});

it('utilise le fuseau de Lomé', function () {
    expect(config('app.timezone'))->toBe('Africa/Lome');
});

it('refuse l\'accès au profil sans jeton', function () {
    $this->getJson('/api/v1/auth/me')->assertUnauthorized();
});

it('fournit les taux d’affichage des devises', function () {
    config(['harmony.currencies.USD' => 605.5]);
    $this->getJson('/api/v1/settings')->assertOk()
        ->assertJsonPath('data.currencies.XOF', 1)
        ->assertJsonPath('data.currencies.EUR', 655.957)
        ->assertJsonPath('data.currencies.USD', 605.5);
});
