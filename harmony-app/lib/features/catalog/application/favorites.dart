import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Biens mis en favori (identifiants). En mémoire pour l'instant ;
/// persistance locale puis synchronisation avec le compte aux étapes suivantes.
final favoritesProvider = NotifierProvider<Favorites, Set<String>>(Favorites.new);

class Favorites extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String apartmentId) {
    state = state.contains(apartmentId)
        ? ({...state}..remove(apartmentId))
        : {...state, apartmentId};
  }
}
