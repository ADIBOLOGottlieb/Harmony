/// Configuration injectée à la compilation (`--dart-define`), jamais de secret ici.
///
/// Exemple : `flutter build apk --dart-define=CONCIERGE_PHONE=+228XXXXXXXX`
abstract final class AppConfig {
  /// Base de l'API REST.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://harmony-api-sfap.onrender.com/api/v1',
  );

  /// Numéro du concierge (format international E.164), pour l'appel et WhatsApp.
  /// Vide tant que l'agence ne l'a pas fourni : les boutons l'expliquent.
  static const conciergePhone = String.fromEnvironment('CONCIERGE_PHONE');

  /// Phase 2 : section « À vendre / Projets ». Masquée par défaut.
  static const salesSectionEnabled = bool.fromEnvironment('FEATURE_SALES');
}
