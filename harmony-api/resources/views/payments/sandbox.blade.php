<!doctype html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Paiement de démonstration · HARMONY HOME</title>
    <style>
        :root { --navy: #14213D; --champagne: #C8A96A; --ivory: #F7F3EC; --ink: #1D1B18; --muted: #5C574F; }
        body { margin: 0; font-family: system-ui, sans-serif; background: var(--ivory); color: var(--ink); }
        main { max-width: 420px; margin: 0 auto; padding: 32px 20px; }
        .brand { color: var(--navy); letter-spacing: 4px; font-weight: 700; font-size: 20px; }
        .brand small { display: block; color: #7A5F2A; letter-spacing: 7px; font-size: 10px; }
        .card { background: #fff; border: 1px solid #E2DBCF; border-radius: 12px; padding: 20px; margin-top: 24px; }
        .amount { font-size: 28px; font-weight: 700; color: var(--navy); margin: 8px 0; }
        .badge { display: inline-block; background: #F1E7D2; color: var(--navy); border-radius: 999px; padding: 4px 12px; font-size: 13px; }
        p { color: var(--muted); line-height: 1.5; }
        button { width: 100%; min-height: 52px; border-radius: 12px; font-size: 16px; font-weight: 600; margin-top: 12px; cursor: pointer; }
        .ok { background: var(--navy); color: #fff; border: 0; }
        .ko { background: #fff; color: var(--ink); border: 1px solid #E2DBCF; }
    </style>
</head>
<body>
<main>
    <div class="brand">HARMONY<small>HOME</small></div>
    <div class="card">
        <span class="badge">Mode démonstration — aucun débit réel</span>
        <p>{{ $payment->kind->label() }} · réservation {{ $payment->booking->reference }}<br>{{ $payment->booking->apartment->title }}</p>
        <div class="amount">{{ number_format($payment->amount, 0, ',', ' ') }} FCFA</div>

        @if ($done)
            <p><strong>Paiement {{ mb_strtolower($payment->status->label()) }}.</strong> Vous pouvez revenir dans l’application HARMONY HOME.</p>
        @else
            <form method="post" action="{{ $action }}">
                @csrf
                <button class="ok" name="outcome" value="success">Simuler un paiement réussi</button>
                <button class="ko" name="outcome" value="failure">Simuler un refus</button>
            </form>
        @endif
    </div>
</main>
</body>
</html>
