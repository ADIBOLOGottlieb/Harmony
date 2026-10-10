<?php

namespace App\Services\Auth;

use App\Enums\UserRole;
use App\Models\OtpCode;
use App\Models\User;
use App\Services\Sms\SmsSender;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/** Connexion par numéro de téléphone et code à usage unique. */
class OtpService
{
    public function __construct(private SmsSender $sms) {}

    /**
     * Génère et envoie un code. Renvoie le code en clair uniquement si
     * `harmony.otp.expose_code` est actif (démonstration sans prestataire SMS).
     */
    public function send(string $phone): ?string
    {
        $code = (string) random_int(100000, 999999);

        OtpCode::query()->where('phone', $phone)->whereNull('consumed_at')->delete();
        OtpCode::query()->create([
            'phone' => $phone,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes((int) config('harmony.otp.ttl_minutes')),
        ]);

        $this->sms->send($phone, "HARMONY HOME : votre code de connexion est {$code}. Il expire dans "
            .config('harmony.otp.ttl_minutes').' minutes.');

        return config('harmony.otp.expose_code') ? $code : null;
    }

    public function verify(string $phone, string $code): User
    {
        $otp = OtpCode::query()->where('phone', $phone)->whereNull('consumed_at')->latest('id')->first();

        if (! $otp || $otp->expires_at->isPast() || $otp->attempts >= (int) config('harmony.otp.max_attempts')) {
            throw ValidationException::withMessages(['code' => __('Ce code a expiré. Demandez-en un nouveau.')]);
        }

        if (! Hash::check($code, $otp->code_hash)) {
            $otp->increment('attempts');

            throw ValidationException::withMessages(['code' => __('Code incorrect.')]);
        }

        $otp->update(['consumed_at' => now()]);

        return User::query()->firstOrCreate(['phone' => $phone], ['role' => UserRole::Client]);
    }
}
