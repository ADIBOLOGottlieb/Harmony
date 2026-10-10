import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/format/money.dart';
import 'core/i18n/i18n.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/application/preferences.dart';
import 'features/profile/application/theme_mode.dart';

class HarmonyApp extends ConsumerWidget {
  const HarmonyApp({super.key});

  /// Textes et prix sont calculés à la construction de chaque écran : après un
  /// changement de langue ou de devise, on reconstruit tout l'arbre (état conservé).
  static void _rebuildAll() {
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => WidgetsBinding.instance.rootElement?.visitChildren(rebuild));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    I18n.current = language;
    Money.current = ref.watch(currencyProvider);
    ref.listen(languageProvider, (_, _) => _rebuildAll());
    ref.listen(currencyProvider, (_, _) => _rebuildAll());

    return MaterialApp.router(
      title: 'HARMONY HOME',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: language.locale,
      supportedLocales: [for (final l in AppLanguage.values) l.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
