import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage.dart';

/// Langue de l'interface, mémorisée sur l'appareil.
final languageProvider = NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);

class LanguageController extends Notifier<AppLanguage> {
  static const _key = 'prefs.language.v1';

  @override
  AppLanguage build() => AppLanguage.fromCode(ref.read(preferencesProvider).getString(_key));

  Future<void> set(AppLanguage language) async {
    state = language;
    await ref.read(preferencesProvider).setString(_key, language.name);
  }
}

/// Devise d'affichage, mémorisée sur l'appareil.
final currencyProvider = NotifierProvider<CurrencyController, DisplayCurrency>(CurrencyController.new);

class CurrencyController extends Notifier<DisplayCurrency> {
  static const _key = 'prefs.currency.v1';
  static const _usdKey = 'prefs.usd_rate.v1';

  @override
  DisplayCurrency build() {
    final prefs = ref.read(preferencesProvider);
    final usd = prefs.getDouble(_usdKey);
    if (usd != null && usd > 0) Money.xofPerUnit[DisplayCurrency.usd] = usd;
    Future.microtask(_refreshRates);
    return DisplayCurrency.fromCode(prefs.getString(_key));
  }

  Future<void> set(DisplayCurrency currency) async {
    state = currency;
    await ref.read(preferencesProvider).setString(_key, currency.name);
  }

  /// Taux indicatif du dollar fourni par l'API (repli : dernier taux connu, sinon 600).
  Future<void> _refreshRates() async {
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/settings');
      final usd = ((response.data?['data'] as Map?)?['currencies'] as Map?)?['USD'];
      if (usd is num && usd > 0) {
        Money.xofPerUnit[DisplayCurrency.usd] = usd.toDouble();
        await ref.read(preferencesProvider).setDouble(_usdKey, usd.toDouble());
      }
    } catch (_) {
      // Hors connexion : on garde le dernier taux connu.
    }
  }
}
