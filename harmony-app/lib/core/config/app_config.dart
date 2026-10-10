/// Configuration injectée à la compilation (`--dart-define`), jamais de secret ici.
///
/// Exemple : `flutter build apk --dart-define=CONCIERGE_PHONE=+228XXXXXXXX`
abstract final class AppConfig {
  /// Base de l'API REST.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://harmony-api-sfap.onrender.com/api/v1',
  );

  /// Fichiers publics de l'API (photos téléversées par la conciergerie).
  static String get storageBaseUrl => '${apiBaseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '')}/storage';

  /// Numéro du concierge (format international E.164), pour l'appel et WhatsApp.
  /// Vide tant que l'agence ne l'a pas fourni : les boutons l'expliquent.
  static const conciergePhone = String.fromEnvironment('CONCIERGE_PHONE');

  /// Fond de carte. OSM public par défaut (démonstration uniquement : ses conditions
  /// interdisent l'usage commercial intensif). En production : MapTiler, Stadia ou serveur propre.
  static const mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Attribution exigée par le fournisseur de tuiles.
  static const mapAttribution = String.fromEnvironment('MAP_ATTRIBUTION', defaultValue: '© OpenStreetMap');

  /// Phase 2 : section « À vendre / Projets ». Masquée par défaut.
  static const salesSectionEnabled = bool.fromEnvironment('FEATURE_SALES');
}
