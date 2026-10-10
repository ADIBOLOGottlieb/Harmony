<?php

use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(fn () => config(['harmony.otp.expose_code' => true]));

it('envoie un code puis connecte le client avec un jeton', function () {
    $code = $this->postJson('/api/v1/auth/otp', ['phone' => '+228 90 12 34 56'])
        ->assertStatus(202)
        ->json('debug_code');

    expect($code)->toMatch('/^\d{6}$/');
    $this->assertDatabaseMissing('otp_codes', ['code_hash' => $code]);

    $response = $this->postJson('/api/v1/auth/verify', ['phone' => '+22890123456', 'code' => $code, 'name' => 'Afi'])
        ->assertOk();

    expect($response->json('user.phone'))->toBe('+22890123456')
        ->and($response->json('user.role'))->toBe('client');

    $this->withToken($response->json('token'))->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.name', 'Afi');
});

it('n’expose jamais le code hors démonstration', function () {
    config(['harmony.otp.expose_code' => false]);

    $this->postJson('/api/v1/auth/otp', ['phone' => '+22890000001'])
        ->assertStatus(202)
        ->assertJsonMissingPath('debug_code');
});

it('refuse un code faux et bloque après cinq essais', function () {
    $code = $this->postJson('/api/v1/auth/otp', ['phone' => '+22890000099'])->json('debug_code');
    $wrong = $code === '000000' ? '111111' : '000000';

    foreach (range(1, 5) as $_) {
        $this->postJson('/api/v1/auth/verify', ['phone' => '+22890000099', 'code' => $wrong])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('code');
    }

    // Même le bon code est refusé une fois le quota d'essais atteint.
    $this->postJson('/api/v1/auth/verify', ['phone' => '+22890000099', 'code' => $code])->assertUnprocessable();
});

it('valide le format international du numéro', function () {
    $this->postJson('/api/v1/auth/otp', ['phone' => '90123456'])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('phone');
});

it('limite les demandes de code par numéro', function () {
    foreach (range(1, 3) as $_) {
        $this->postJson('/api/v1/auth/otp', ['phone' => '+22890000077'])->assertStatus(202);
    }

    $this->postJson('/api/v1/auth/otp', ['phone' => '+22890000077'])->assertStatus(429);
});
