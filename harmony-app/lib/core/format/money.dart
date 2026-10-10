import 'fcfa.dart';

/// Devises d'affichage. Les prix et les paiements restent en FCFA (XOF) ;
/// l'euro (parité fixe) et le dollar (taux indicatif fourni par l'API) ne servent qu'à l'affichage.
enum DisplayCurrency {
  xof('FCFA', 'XOF'),
  eur('Euro', 'EUR'),
  usd('Dollar US', 'USD');

  const DisplayCurrency(this.label, this.code);
  final String label;
  final String code;

  static DisplayCurrency fromCode(String? code) => values.firstWhere((c) => c.name == code, orElse: () => xof);
}

/// Devise courante et taux (FCFA pour une unité), fixés par `HarmonyApp`.
abstract final class Money {
  static DisplayCurrency current = DisplayCurrency.xof;

  /// 1 € = 655,957 FCFA (parité fixe) ; le dollar est mis à jour depuis l'API.
  static final Map<DisplayCurrency, double> xofPerUnit = {
    DisplayCurrency.xof: 1,
    DisplayCurrency.eur: 655.957,
    DisplayCurrency.usd: 600,
  };
}

/// Prix d'affichage dans la devise choisie : « 150 000 FCFA », « ≈ 229 € », « ≈ $250 ».
String price(int fcfaAmount) {
  final currency = Money.current;
  if (currency == DisplayCurrency.xof) return fcfa(fcfaAmount);
  return '≈ ${converted(fcfaAmount, currency)}';
}

/// Montant FCFA suivi de son équivalent si une autre devise est choisie : « 94 500 FCFA (≈ 144 €) ».
/// Utilisé là où l'on paie : le montant réglé reste toujours en FCFA.
String fcfaWithEquivalent(int fcfaAmount) {
  final currency = Money.current;
  if (currency == DisplayCurrency.xof) return fcfa(fcfaAmount);
  return '${fcfa(fcfaAmount)} (≈ ${converted(fcfaAmount, currency)})';
}

/// Conversion arrondie à l'unité, avec séparateur de milliers.
String converted(int fcfaAmount, DisplayCurrency currency) {
  final value = (fcfaAmount / (Money.xofPerUnit[currency] ?? 1)).round();
  final digits = _group(value);
  return switch (currency) {
    DisplayCurrency.eur => '$digits €',
    DisplayCurrency.usd => '\$$digits',
    DisplayCurrency.xof => fcfa(fcfaAmount),
  };
}

String _group(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
