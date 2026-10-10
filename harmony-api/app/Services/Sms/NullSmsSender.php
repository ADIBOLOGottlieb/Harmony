<?php

namespace App\Services\Sms;

/**
 * Aucun envoi réel tant qu'aucun prestataire SMS n'est configuré.
 * Volontairement silencieux : un code OTP ne doit jamais apparaître dans les logs.
 */
class NullSmsSender implements SmsSender
{
    public function send(string $to, string $message): void
    {
        //
    }
}
