<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

beforeEach(function () {
    Storage::fake('public');
    config(['harmony.media_disk' => 'public']);
    $this->user = User::factory()->create(['phone' => '+22890000060']);
    Sanctum::actingAs($this->user);
});

it('enregistre la photo de profil et remplace l’ancienne', function () {
    $first = $this->post('/api/v1/auth/me/avatar', ['photo' => UploadedFile::fake()->image('a.jpg', 400, 400)], ['Accept' => 'application/json'])
        ->assertOk()->json('data.avatar');
    $oldPath = $this->user->refresh()->avatar_path;
    expect($first)->toContain('avatars/');
    Storage::disk('public')->assertExists($oldPath);

    $this->post('/api/v1/auth/me/avatar', ['photo' => UploadedFile::fake()->image('b.png', 300, 300)], ['Accept' => 'application/json'])->assertOk();
    Storage::disk('public')->assertMissing($oldPath);
    Storage::disk('public')->assertExists($this->user->refresh()->avatar_path);
});

it('refuse un fichier qui n’est pas une image', function () {
    $this->post('/api/v1/auth/me/avatar', ['photo' => UploadedFile::fake()->create('doc.pdf', 100, 'application/pdf')], ['Accept' => 'application/json'])
        ->assertUnprocessable()->assertJsonValidationErrors('photo');
});

it('supprime la photo de profil', function () {
    $this->post('/api/v1/auth/me/avatar', ['photo' => UploadedFile::fake()->image('a.jpg', 400, 400)], ['Accept' => 'application/json']);
    $path = $this->user->refresh()->avatar_path;

    $this->deleteJson('/api/v1/auth/me/avatar')->assertOk()->assertJsonPath('data.avatar', null);
    Storage::disk('public')->assertMissing($path);
});
