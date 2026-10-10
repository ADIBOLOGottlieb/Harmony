import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage.dart';
import '../data/auth_api.dart';

class Session {
  const Session(this.user);

  final AppUser user;
}

/// Session du client : profil en préférences, jeton chiffré dans le TokenStore.
final sessionProvider = NotifierProvider<SessionController, Session?>(SessionController.new);

class SessionController extends Notifier<Session?> {
  static const _userKey = 'session.user.v1';

  @override
  Session? build() {
    final raw = ref.read(preferencesProvider).getString(_userKey);
    if (raw == null) return null;
    try {
      final user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      Future.microtask(_dropIfTokenMissing);
      return Session(user);
    } catch (_) {
      return null;
    }
  }

  Future<void> signIn(String token, AppUser user) async {
    await ref.read(tokenStoreProvider).write(token);
    await ref.read(preferencesProvider).setString(_userKey, jsonEncode(user.toJson()));
    state = Session(user);
  }

  /// Profil mis à jour (photo, nom) : la session garde le même jeton.
  Future<void> updateUser(AppUser user) async {
    await ref.read(preferencesProvider).setString(_userKey, jsonEncode(user.toJson()));
    state = Session(user);
  }

  Future<void> signOut() async {
    await ref.read(authApiProvider).logout();
    await _clear();
  }

  /// Jeton refusé par l'API (expiré) : on oublie la session localement.
  Future<void> expire() => _clear();

  Future<void> _clear() async {
    await ref.read(tokenStoreProvider).clear();
    await ref.read(preferencesProvider).remove(_userKey);
    state = null;
  }

  Future<void> _dropIfTokenMissing() async {
    if (await ref.read(tokenStoreProvider).read() == null) await _clear();
  }
}
