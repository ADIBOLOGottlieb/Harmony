import 'package:flutter/widgets.dart';

import 'en.dart';

/// Langues de l'interface. Le français est la langue source : chaque texte de l'app
/// est écrit en français et sert de clé de traduction (à la manière de gettext).
enum AppLanguage {
  fr('Français', Locale('fr')),
  en('English', Locale('en'));

  const AppLanguage(this.label, this.locale);
  final String label;
  final Locale locale;

  static AppLanguage fromCode(String? code) => values.firstWhere((l) => l.name == code, orElse: () => fr);
}

/// Langue courante, fixée par `HarmonyApp` à partir de la préférence de l'utilisateur.
abstract final class I18n {
  static AppLanguage current = AppLanguage.fr;
}

/// Traduit un texte écrit en français ; `{nom}` est remplacé par `args['nom']`.
/// Un texte sans traduction s'affiche en français (repli sûr).
String t(String fr, [Map<String, Object?> args = const {}]) {
  var text = I18n.current == AppLanguage.en ? (enStrings[fr] ?? fr) : fr;
  args.forEach((key, value) => text = text.replaceAll('{$key}', '$value'));
  return text;
}
