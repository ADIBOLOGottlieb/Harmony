<!doctype html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <title>Reçu {{ $booking->reference }}</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; color: #1D1B18; font-size: 12px; margin: 32px; }
        .brand { color: #14213D; font-size: 22px; letter-spacing: 4px; font-weight: bold; }
        .brand small { display: block; color: #7A5F2A; font-size: 10px; letter-spacing: 6px; }
        h1 { font-size: 16px; color: #14213D; margin: 24px 0 4px; }
        .muted { color: #5C574F; }
        table { width: 100%; border-collapse: collapse; margin-top: 12px; }
        th, td { padding: 8px 6px; border-bottom: 1px solid #E2DBCF; text-align: left; }
        td.amount, th.amount { text-align: right; white-space: nowrap; }
        tr.total td { font-weight: bold; border-top: 2px solid #14213D; }
        .status { display: inline-block; padding: 3px 10px; border-radius: 10px; background: #F1E7D2; color: #14213D; }
        .footer { margin-top: 32px; font-size: 10px; color: #5C574F; }
    </style>
</head>
<body>
@php($f = fn (int $n) => number_format($n, 0, ',', ' ').' FCFA')
<div class="brand">HARMONY<small>HOME</small></div>
<p class="muted">Conciergerie immobilière · Lomé, Togo</p>

<h1>Reçu de réservation {{ $booking->reference }}</h1>
<p>
    <span class="status">{{ $booking->status->label() }}</span>
    <span class="muted">· émis le {{ now()->format('d/m/Y à H:i') }}</span>
</p>

<table>
    <tr><th>Logement</th><td>{{ $booking->apartment->title }} — {{ $booking->apartment->zone?->name }}</td></tr>
    <tr><th>Séjour</th><td>{{ $booking->stay_type->label() }} : du {{ $booking->start_at->format('d/m/Y H:i') }} au {{ $booking->end_at->format('d/m/Y H:i') }}@if($booking->nights) ({{ $booking->nights }} nuit{{ $booking->nights > 1 ? 's' : '' }})@endif</td></tr>
    <tr><th>Voyageurs</th><td>{{ $booking->guests }}</td></tr>
    <tr><th>Client</th><td>{{ $booking->user->name ?? 'Client' }} · {{ $booking->user->phone }}</td></tr>
</table>

<table>
    <tr><th>Détail</th><th class="amount">Montant</th></tr>
    @foreach ($booking->price_breakdown as $line)
        <tr><td>{{ $line['label'] }}</td><td class="amount">{{ $f($line['amount']) }}</td></tr>
    @endforeach
    <tr class="total"><td>Total du séjour</td><td class="amount">{{ $f($booking->total_amount) }}</td></tr>
    <tr><td>Déjà réglé</td><td class="amount">{{ $f($booking->amount_paid) }}</td></tr>
    <tr><td>Reste à payer</td><td class="amount">{{ $f($booking->balanceDue()) }}</td></tr>
    <tr><td class="muted">Caution (réglée à l’arrivée, restituée après l’état des lieux)</td><td class="amount muted">{{ $f($booking->security_deposit) }}</td></tr>
</table>

@if ($booking->payments->isNotEmpty())
    <table>
        <tr><th>Paiement</th><th>Moyen</th><th>Statut</th><th class="amount">Montant</th></tr>
        @foreach ($booking->payments as $payment)
            <tr>
                <td>{{ $payment->kind->label() }}</td>
                <td>{{ $payment->method->label() }}</td>
                <td>{{ $payment->status->label() }}</td>
                <td class="amount">{{ $f($payment->amount) }}</td>
            </tr>
        @endforeach
    </table>
@endif

<p class="footer">
    Annulation gratuite jusqu’au {{ $booking->cancellation_deadline?->format('d/m/Y à H:i') ?? '—' }}.
    Au-delà, l’acompte reste acquis. Document généré automatiquement par HARMONY HOME.
</p>
</body>
</html>
