<?php

namespace App\Models;

use App\Enums\UserRole;
use Database\Factories\UserFactory;
use Filament\Models\Contracts\FilamentUser;
use Filament\Models\Contracts\HasName;
use Filament\Panel;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'phone', 'role', 'avatar_path'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable implements FilamentUser, HasName
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected $attributes = [
        'role' => 'client',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'role' => UserRole::class,
        ];
    }

    /** Biens dont l'utilisateur est propriétaire. @return HasMany<Apartment, $this> */
    public function apartments(): HasMany
    {
        return $this->hasMany(Apartment::class, 'owner_id');
    }

    public function isStaff(): bool
    {
        return $this->role->isStaff();
    }

    public function isOwner(): bool
    {
        return $this->role === UserRole::Owner;
    }

    /** Espace de gestion : personnel et propriétaires disposant d'un mot de passe. */
    public function canAccessPanel(Panel $panel): bool
    {
        return ($this->isStaff() || $this->isOwner()) && filled($this->password);
    }

    public function getFilamentName(): string
    {
        return $this->name ?: ($this->email ?: $this->phone ?: 'Compte');
    }
}
