<?php

namespace App\Console\Commands;

use App\Services\Booking\BookingService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('harmony:complete-bookings')]
#[Description('Passe en « terminée » les séjours dont la date de fin est passée')]
class CompleteFinishedBookings extends Command
{
    public function handle(BookingService $bookings): int
    {
        $count = $bookings->completeFinished();
        $this->info("{$count} séjour(s) terminé(s).");

        return self::SUCCESS;
    }
}
