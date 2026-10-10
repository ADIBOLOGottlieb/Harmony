import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harmony_app/core/format/dates.dart';
import 'package:harmony_app/core/format/money.dart';
import 'package:harmony_app/core/i18n/en.dart';
import 'package:harmony_app/core/i18n/i18n.dart';

/// Textes passés littéralement à `t('…')` dans le code de l'app.
Set<String> _translatableTexts() {
  final call = RegExp(r"\bt\('((?:[^'\\]|\\.)*)'");
  final keys = <String>{};
  for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart') || file.path.contains('i18n')) continue;
    for (final m in call.allMatches(file.readAsStringSync())) {
      keys.add(m.group(1)!.replaceAll(r"\'", "'").replaceAll(r'\n', '\n'));
    }
  }
  return keys;
}

void main() {
  tearDown(() {
    I18n.current = AppLanguage.fr;
    Money.current = DisplayCurrency.xof;
  });

  test('chaque texte de l’app a sa traduction anglaise', () {
    final missing = _translatableTexts().where((k) => !enStrings.containsKey(k)).toList()..sort();
    expect(missing, isEmpty, reason: 'Ajoutez ces textes à lib/core/i18n/en.dart');
  });

  test('les traductions gardent les mêmes variables', () {
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final MapEntry(key: fr, value: en) in enStrings.entries) {
      final a = placeholder.allMatches(fr).map((m) => m[1]).toSet();
      final b = placeholder.allMatches(en).map((m) => m[1]).toSet();
      expect(b, a, reason: fr);
    }
  });

  test('t() traduit, interpole et retombe sur le français', () {
    expect(t('Réserver'), 'Réserver');
    I18n.current = AppLanguage.en;
    expect(t('Réserver'), 'Book');
    expect(t('Payer {amount}', {'amount': '10 €'}), 'Pay 10 €');
    expect(t('Texte inconnu'), 'Texte inconnu');
  });

  test('pluriels et dates suivent la langue', () {
    expect(plural(1, 'nuit'), '1 nuit');
    expect(plural(3, 'avis', 'avis'), '3 avis');
    I18n.current = AppLanguage.en;
    expect(plural(1, 'nuit'), '1 night');
    expect(plural(0, 'nuit'), '0 nights');
    expect(plural(3, 'avis', 'avis'), '3 reviews');
    expect(fullDate(DateTime.utc(2026, 10, 20)), 'Tue, Oct 20, 2026');
  });

  test('les prix se convertissent pour l’affichage, le FCFA reste la référence', () {
    expect(price(655957), fcfaOf(655957));
    Money.current = DisplayCurrency.eur;
    expect(price(655957), '≈ 1 000 €');
    expect(fcfaWithEquivalent(655957), '${fcfaOf(655957)} (≈ 1 000 €)');
    Money.current = DisplayCurrency.usd;
    Money.xofPerUnit[DisplayCurrency.usd] = 600;
    expect(price(60000), '≈ \$100');
  });
}

String fcfaOf(int amount) {
  final saved = Money.current;
  Money.current = DisplayCurrency.xof;
  final text = price(amount);
  Money.current = saved;
  return text;
}
