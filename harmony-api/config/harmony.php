<?php

/*
| Règles métier de HARMONY HOME. Les montants sont des entiers FCFA ; les taux
| sont appliqués puis arrondis à l'unité. Toutes les valeurs sont surchargeables
| par variables d'environnement.
*/

return [
    // Disque des photos téléversées (public en local ; s3 compatible en production).
    'media_disk' => env('MEDIA_DISK', 'public'),

    // Premier administrateur créé au démarrage (hébergement sans console). À retirer ensuite.
    'admin' => [
        'email' => env('HARMONY_ADMIN_EMAIL'),
        'password' => env('HARMONY_ADMIN_PASSWORD'),
    ],

    // Horaires standards (heure de Lomé, UTC+0).
    'check_in_time' => env('HARMONY_CHECK_IN', '14:00'),
    'check_out_time' => env('HARMONY_CHECK_OUT', '11:00'),
    'day_stay' => [
        'start' => env('HARMONY_DAY_STAY_START', '10:00'),
        'end' => env('HARMONY_DAY_STAY_END', '18:00'),
    ],

    // Battement après chaque séjour pour le ménage (minutes).
    'turnover_minutes' => (int) env('HARMONY_TURNOVER_MINUTES', 60),

    // Frais de service facturés au client (part du montant de l'hébergement).
    'service_fee_rate' => (float) env('HARMONY_SERVICE_FEE_RATE', 0.05),

    // Acompte demandé à la réservation ; le solde est payé ensuite.
    'advance_rate' => (float) env('HARMONY_ADVANCE_RATE', 0.30),

    // Une réservation non payée est annulée après ce délai (minutes).
    'pending_expiry_minutes' => (int) env('HARMONY_PENDING_EXPIRY_MINUTES', 30),

    // Politique d'annulation par défaut : gratuite jusqu'à N jours avant l'arrivée.
    'free_cancellation_days' => (int) env('HARMONY_FREE_CANCELLATION_DAYS', 5),

    'otp' => [
        'ttl_minutes' => 10,
        'max_attempts' => 5,
        // Démonstration uniquement : renvoie le code dans la réponse tant qu'aucun prestataire SMS n'est branché.
        'expose_code' => (bool) env('OTP_EXPOSE_CODE', false),
    ],

    'payments' => [
        // Paiement simulé (page signée). Actif hors production par défaut ; en production, à activer
        // explicitement (PAYMENTS_SANDBOX=true) pour une démonstration, jamais avec de vrais clients.
        'sandbox_enabled' => (bool) env('PAYMENTS_SANDBOX', env('APP_ENV', 'production') !== 'production'),
    ],

    'bank_transfer' => [
        'expiry_hours' => (int) env('HARMONY_BANK_TRANSFER_EXPIRY_HOURS', 48),
        'instructions' => env('HARMONY_BANK_TRANSFER_INSTRUCTIONS', 'Les coordonnées bancaires vous sont communiquées par la conciergerie.'),
    ],

    'max_nights' => (int) env('HARMONY_MAX_NIGHTS', 90),

    'features' => [
        // Phase 2 : biens à vendre et programmes neufs.
        'sales' => (bool) env('FEATURE_SALES', false),
    ],
];
