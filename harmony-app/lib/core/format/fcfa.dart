/// Formate un montant FCFA (entier) : 15000 → « 15 000 FCFA ».
/// Espace fine insécable entre les milliers, comme l'usage typographique français.
String fcfa(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer(amount < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '$buffer FCFA';
}
