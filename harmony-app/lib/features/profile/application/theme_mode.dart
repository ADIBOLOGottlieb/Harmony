import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage.dart';

/// Apparence choisie dans le profil : système (par défaut), clair ou sombre. Mémorisée sur l'appareil.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'prefs.theme.v1';

  @override
  ThemeMode build() {
    final saved = ref.read(preferencesProvider).getString(_key);
    return ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(preferencesProvider).setString(_key, mode.name);
  }
}
