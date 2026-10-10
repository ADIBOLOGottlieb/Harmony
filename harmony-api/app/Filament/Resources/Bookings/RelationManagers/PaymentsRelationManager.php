<?php

namespace App\Filament\Resources\Bookings\RelationManagers;

use App\Enums\PaymentKind;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Models\Payment;
use App\Services\Payments\PaymentService;
use App\Support\Fcfa;
use Filament\Actions\Action;
use Filament\Notifications\Notification;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

/** Paiements d'une réservation : validation des virements reçus et des remboursements effectués. */
class PaymentsRelationManager extends RelationManager
{
    protected static string $relationship = 'payments';

    protected static ?string $title = 'Paiements';

    protected static ?string $modelLabel = 'paiement';

    public function isReadOnly(): bool
    {
        return false;
    }

    private static function staff(): bool
    {
        return (bool) auth()->user()?->isStaff();
    }

    public function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at')
            ->columns([
                TextColumn::make('kind')->label('Nature')->badge(),
                TextColumn::make('method')->label('Moyen'),
                TextColumn::make('amount')->label('Montant')->formatStateUsing(fn ($state) => Fcfa::format($state)),
                TextColumn::make('status')->label('Statut')->badge(),
                TextColumn::make('gateway')->label('Prestataire')->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('created_at')->label('Créé le')->dateTime('d/m/Y H:i'),
                TextColumn::make('paid_at')->label('Réglé le')->dateTime('d/m/Y H:i')->placeholder('—'),
            ])
            ->recordActions([
                Action::make('received')->label('Virement reçu')->icon('heroicon-o-check-circle')->color('success')
                    ->visible(fn (Payment $record) => static::staff()
                        && $record->status === PaymentStatus::Pending
                        && $record->method === PaymentMethod::BankTransfer
                        && $record->kind !== PaymentKind::Refund)
                    ->requiresConfirmation()
                    ->action(function (Payment $record) {
                        app(PaymentService::class)->validateTransfer($record, auth()->user());
                        Notification::make()->title('Paiement validé')->success()->send();
                    }),
                Action::make('refunded')->label('Remboursement effectué')->icon('heroicon-o-arrow-uturn-left')->color('warning')
                    ->visible(fn (Payment $record) => static::staff()
                        && $record->status === PaymentStatus::Pending
                        && $record->kind === PaymentKind::Refund)
                    ->requiresConfirmation()
                    ->modalDescription('Confirmez que le client a bien été remboursé (virement ou Mobile Money).')
                    ->action(function (Payment $record) {
                        app(PaymentService::class)->applyOutcome($record, PaymentStatus::Succeeded, auth()->user());
                        Notification::make()->title('Remboursement enregistré')->success()->send();
                    }),
            ]);
    }
}
