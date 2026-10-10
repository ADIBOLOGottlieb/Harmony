<?php

namespace App\Filament\Resources\Bookings\Pages;

use App\Filament\Resources\Bookings\BookingResource;
use App\Models\Booking;
use Filament\Actions\Action;
use Filament\Resources\Pages\ListRecords;
use Filament\Support\Icons\Heroicon;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ListBookings extends ListRecords
{
    protected static string $resource = BookingResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('export')->label('Exporter (CSV)')->icon(Heroicon::OutlinedArrowDownTray)->color('gray')
                ->action(fn () => $this->exportCsv()),
        ];
    }

    /** Export des réservations filtrées, séparateur « ; » et BOM UTF-8 pour Excel. */
    public function exportCsv(): StreamedResponse
    {
        $query = $this->getFilteredSortedTableQuery();
        $staff = BookingResource::staff();

        return response()->streamDownload(function () use ($query, $staff) {
            $out = fopen('php://output', 'w');
            fwrite($out, "\xEF\xBB\xBF");
            $header = ['Référence', 'Statut', 'Bien', 'Client', 'Téléphone', 'Type', 'Arrivée', 'Départ',
                'Nuits', 'Voyageurs', 'Total (FCFA)', 'Réglé (FCFA)', 'Reste (FCFA)', 'Créée le'];
            if (! $staff) {
                unset($header[4]);
            }
            fputcsv($out, array_values($header), ';');
            $query->chunk(200, function ($bookings) use ($out, $staff) {
                /** @var Booking $b */
                foreach ($bookings as $b) {
                    $row = [
                        $b->reference, $b->status->label(), $b->apartment?->title, $b->user?->name,
                        $b->user?->phone, $b->stay_type->value,
                        $b->start_at->format('d/m/Y H:i'), $b->end_at->format('d/m/Y H:i'),
                        $b->nights, $b->guests, $b->total_amount, $b->amount_paid, $b->balanceDue(),
                        $b->created_at?->format('d/m/Y H:i'),
                    ];
                    if (! $staff) {
                        unset($row[4]);
                    }
                    fputcsv($out, array_values($row), ';');
                }
            });
            fclose($out);
        }, 'reservations-'.now()->format('Y-m-d').'.csv', ['Content-Type' => 'text/csv; charset=UTF-8']);
    }
}
