import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Charge les vraies polices embarquées (Playfair Display, Manrope) avant les
/// tests : les débordements détectés correspondent alors au rendu réel, et non
/// à la police de test « Ahem » où chaque glyphe est un carré.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const families = {
    'PlayfairDisplay': ['400', '400italic', '600', '700'],
    'Manrope': ['400', '500', '600', '700'],
  };
  for (final MapEntry(key: family, value: variants) in families.entries) {
    final loader = FontLoader(family);
    for (final v in variants) {
      loader.addFont(rootBundle.load('assets/fonts/$family-$v.ttf'));
    }
    await loader.load();
  }
  await testMain();
}
