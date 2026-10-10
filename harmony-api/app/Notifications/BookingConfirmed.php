<?php

namespace App\Notifications;

use App\Models\Booking;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Confirmation de réservation. E-mail si le client en a renseigné un ;
 * SMS et notification push à brancher dès que les prestataires seront choisis.
 */
class BookingConfirmed extends Notification
{
    use Queueable;

    public function __construct(public readonly Booking $booking) {}

    /** @return list<string> */
    public function via(object $notifiable): array
    {
        return filled($notifiable->email ?? null) ? ['mail'] : [];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $b = $this->booking;

        return (new MailMessage)
            ->subject("Réservation {$b->reference} confirmée")
            ->greeting('Bonjour,')
            ->line("Votre réservation {$b->reference} est confirmée : {$b->apartment->title}.")
            ->line('Arrivée : '.$b->start_at->format('d/m/Y à H:i').' · Départ : '.$b->end_at->format('d/m/Y à H:i').'.')
            ->line('L’adresse exacte et l’itinéraire sont disponibles dans l’application HARMONY HOME.')
            ->salutation('La conciergerie HARMONY HOME');
    }
}
