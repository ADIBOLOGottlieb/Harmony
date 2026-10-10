<?php

namespace App\Services\Sms;

/**
 * Envoi de SMS (codes de connexion, confirmations). Le prestataire reste à
 * choisir ; les implémentations ne doivent jamais journaliser le contenu.
 */
interface SmsSender
{
    public function send(string $to, string $message): void;
}
