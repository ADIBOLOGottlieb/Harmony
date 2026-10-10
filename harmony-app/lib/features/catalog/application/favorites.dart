import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage.dart';

/// Biens mis en favori (identifiants), conservés sur l'appareil.
final favoritesProvider = NotifierProvider<Favorites, Set<String>>(Favorites.new);

class Favorites extends Notifier<Set<String>> {
  static const _key = 'favorites.v1';

  @override
  Set<String> build() => (ref.read(preferencesProvider).getStringList(_key) ?? const []).toSet();

  void toggle(String apartmentId) {
    state = state.contains(apartmentId) ? ({...state}..remove(apartmentId)) : {...state, apartmentId};
    ref.read(preferencesProvider).setStringList(_key, state.toList());
  }
}
