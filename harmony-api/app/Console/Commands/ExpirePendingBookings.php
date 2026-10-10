<?php

namespace App\Console\Commands;

use App\Services\Booking\BookingService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('harmony:expire-bookings')]
#[Description('Annule les réservations non payées dans le délai imparti')]
class ExpirePendingBookings extends Command
{
    public function handle(BookingService $bookings): int
    {
        $count = $bookings->expireStale();
        $this->info("{$count} réservation(s) expirée(s).");

        return self::SUCCESS;
    }
}
