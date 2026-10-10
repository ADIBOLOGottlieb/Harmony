import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Barres système transparentes ; la couleur des icônes suit chaque écran
  // (AppBarTheme, ou AnnotatedRegion sur les écrans à photo plein cadre).
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(ProviderScope(
    overrides: [preferencesProvider.overrideWithValue(preferences)],
    child: const HarmonyApp(),
  ));
}
