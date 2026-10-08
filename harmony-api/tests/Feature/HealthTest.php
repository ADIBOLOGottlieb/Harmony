<?php

it('répond sur la sonde de santé versionnée', function () {
    $this->getJson('/api/v1/health')
        ->assertOk()
        ->assertJsonPath('status', 'ok')
        ->assertJsonPath('service', 'harmony-api');
});

it('utilise le fuseau de Lomé', function () {
    expect(config('app.timezone'))->toBe('Africa/Lome');
});

it('refuse l\'accès au profil sans jeton', function () {
    $this->getJson('/api/v1/user')->assertUnauthorized();
});
