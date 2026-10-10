<?php

namespace App\Filament\Resources\Bookings\Pages;

use App\Enums\BookingStatus;
use App\Enums\PaymentKind;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Filament\Resources\Bookings\BookingResource;
use App\Models\Booking;
use App\Models\Payment;
use App\Services\Booking\BookingException;
use App\Services\Booking\BookingService;
use App\Services\Payments\PaymentService;
use Barryvdh\DomPDF\Facade\Pdf;
use Filament\Actions\Action;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Icons\Heroicon;

class ViewBooking extends ViewRecord
{
    protected static string $resource = BookingResource::class;

    private function pendingTransfer(): ?Payment
    {
        /** @var Booking $booking */
        $booking = $this->record;

        return $booking->payments()
            ->where('status', PaymentStatus::Pending)
            ->where('method', PaymentMethod::BankTransfer)
            ->where('kind', '!=', PaymentKind::Refund)
            ->first();
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('validateTransfer')->label('Valider le virement')->icon(Heroicon::OutlinedBanknotes)->color('success')
                ->visible(fn () => BookingResource::staff() && $this->pendingTransfer() !== null)
                ->requiresConfirmation()
                ->modalDescription('Confirmez que le virement a bien été reçu sur le compte de la conciergerie. La réservation sera confirmée et le client prévenu.')
                ->action(function () {
                    app(PaymentService::class)->validateTransfer($this->pendingTransfer(), auth()->user());
                    $this->record->refresh();
                    Notification::make()->title('Virement validé')->success()->send();
                }),
            Action::make('cancel')->label('Annuler')->icon(Heroicon::OutlinedXCircle)->color('danger')
                ->visible(fn () => BookingResource::staff()
                    && in_array($this->record->status, [BookingStatus::Pending, BookingStatus::Confirmed], true))
                ->schema([Textarea::make('reason')->label('Motif')->required()->maxLength(255)])
                ->modalDescription('Avant l’échéance d’annulation gratuite, les sommes versées sont remboursées automatiquement.')
                ->action(function (array $data) {
                    try {
                        app(BookingService::class)->cancel($this->record, $data['reason']);
                        $this->record->refresh();
                        Notification::make()->title('Réservation annulée')->success()->send();
                    } catch (BookingException $e) {
                        Notification::make()->title($e->getMessage())->danger()->send();
                    }
                }),
            Action::make('receipt')->label('Reçu PDF')->icon(Heroicon::OutlinedDocumentText)->color('gray')
                ->action(function () {
                    $booking = $this->record->load(['apartment.zone', 'user', 'payments']);
                    $pdf = Pdf::loadView('receipts.booking', ['booking' => $booking]);

                    return response()->streamDownload(fn () => print ($pdf->output()), "recu-{$booking->reference}.pdf");
                }),
        ];
    }
}
