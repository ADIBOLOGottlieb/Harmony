<?php

namespace App\Filament\Resources\ArtworkOrders\Pages;

use App\Enums\ArtworkOrderStatus;
use App\Filament\Resources\ArtworkOrders\ArtworkOrderResource;
use App\Services\Gallery\GalleryService;
use Filament\Actions\Action;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Icons\Heroicon;

class ViewArtworkOrder extends ViewRecord
{
    protected static string $resource = ArtworkOrderResource::class;

    protected function getHeaderActions(): array
    {
        $pending = fn () => $this->record->status === ArtworkOrderStatus::Pending;

        return [
            Action::make('markPaid')->label('Règlement reçu')->icon(Heroicon::OutlinedBanknotes)->color('success')
                ->visible($pending)
                ->requiresConfirmation()
                ->modalDescription('L’œuvre passera en « Vendue » et sera retirée de la vente.')
                ->action(function () {
                    app(GalleryService::class)->markPaid($this->record, auth()->user());
                    $this->record->refresh();
                    Notification::make()->title('Œuvre vendue')->success()->send();
                }),
            Action::make('cancel')->label('Annuler')->icon(Heroicon::OutlinedXCircle)->color('danger')
                ->visible($pending)
                ->schema([Textarea::make('reason')->label('Motif')->required()->maxLength(255)])
                ->modalDescription('L’œuvre redeviendra disponible à la vente.')
                ->action(function (array $data) {
                    app(GalleryService::class)->cancel($this->record, $data['reason']);
                    $this->record->refresh();
                    Notification::make()->title('Demande annulée')->success()->send();
                }),
        ];
    }
}
