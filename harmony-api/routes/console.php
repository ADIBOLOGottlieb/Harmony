<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Nécessite un processus « schedule:work » (ou une tâche cron). À défaut, l'expiration est
// aussi appliquée à la volée lors de chaque réservation et de chaque consultation.
Schedule::command('harmony:expire-bookings')->everyMinute()->withoutOverlapping();
Schedule::command('harmony:complete-bookings')->hourly()->withoutOverlapping();
