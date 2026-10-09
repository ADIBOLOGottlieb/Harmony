import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_tokens.dart';

/// Thèmes clair (par défaut) et sombre, dérivés exclusivement des tokens.
/// Tous les composants Material (boutons, champs, cartes, chips, feuilles,
/// barre de navigation, sélecteur de dates) sont stylés ici : les écrans
/// n'ont pas à les redécorer.
abstract final class AppTheme {
  static ThemeData light() => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme(
          brightness: Brightness.light,
          primary: HPalette.navy,
          onPrimary: HPalette.white,
          primaryContainer: HPalette.champagneSoft,
          onPrimaryContainer: HPalette.navyDeep,
          secondary: HPalette.champagne,
          onSecondary: HPalette.navyDeep,
          tertiary: HPalette.navySoft,
          onTertiary: HPalette.white,
          error: HPalette.error,
          onError: HPalette.white,
          surface: HPalette.ivory,
          onSurface: HPalette.ink,
          onSurfaceVariant: HPalette.inkMuted,
          surfaceContainerLowest: HPalette.white,
          surfaceContainerLow: HPalette.white,
          surfaceContainer: HPalette.white,
          surfaceContainerHigh: HPalette.sand,
          surfaceContainerHighest: HPalette.sand,
          outline: HPalette.inkMuted,
          outlineVariant: HPalette.hairline,
          shadow: Color(0xFF000000),
          scrim: Color(0x99000000),
          inverseSurface: HPalette.navy,
          onInverseSurface: HPalette.ivory,
          inversePrimary: HPalette.champagne,
        ),
        extension: HarmonyColors.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: HPalette.champagne,
          onPrimary: HPalette.navyDeep,
          primaryContainer: HPalette.navySoft,
          onPrimaryContainer: HPalette.paper,
          secondary: HPalette.champagne,
          onSecondary: HPalette.navyDeep,
          tertiary: HPalette.paperMuted,
          onTertiary: HPalette.night,
          error: HPalette.errorOnDark,
          onError: HPalette.night,
          surface: HPalette.night,
          onSurface: HPalette.paper,
          onSurfaceVariant: HPalette.paperMuted,
          surfaceContainerLowest: HPalette.night,
          surfaceContainerLow: HPalette.nightSurface,
          surfaceContainer: HPalette.nightSurface,
          surfaceContainerHigh: HPalette.nightRaised,
          surfaceContainerHighest: HPalette.nightRaised,
          outline: HPalette.paperMuted,
          outlineVariant: HPalette.nightHairline,
          shadow: Color(0xFF000000),
          scrim: Color(0xB3000000),
          inverseSurface: HPalette.paper,
          onInverseSurface: HPalette.night,
          inversePrimary: HPalette.navy,
        ),
        extension: HarmonyColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required HarmonyColors extension,
  }) {
    final ink = scheme.onSurface;
    final muted = extension.textMuted;
    final textTheme = TextTheme(
      displaySmall: HText.display.copyWith(color: ink),
      headlineMedium: HText.headline.copyWith(color: ink),
      titleLarge: HText.title.copyWith(color: ink),
      titleMedium: HText.titleSans.copyWith(color: ink),
      bodyLarge: HText.body.copyWith(color: ink),
      bodyMedium: HText.bodySmall.copyWith(color: muted),
      labelLarge: HText.label.copyWith(color: ink),
      labelMedium: HText.labelSmall.copyWith(color: ink),
      labelSmall: HText.overline.copyWith(color: extension.accentText),
    );
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(HRadius.md));
    final buttonPadding = const EdgeInsets.symmetric(horizontal: HSpace.lg);
    const buttonSize = Size(HSize.touch, HSize.button);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [extension],
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: HFonts.sans,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(color: extension.hairline, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: ink, size: HSize.icon),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: HText.title.copyWith(color: ink),
        systemOverlayStyle: brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: rounded,
          textStyle: HText.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: rounded,
          foregroundColor: ink,
          side: BorderSide(color: extension.hairline),
          textStyle: HText.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(HSize.touch, HSize.touch),
          foregroundColor: scheme.primary,
          textStyle: HText.label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.md, vertical: HSpace.md),
        labelStyle: HText.bodySmall.copyWith(color: muted),
        hintStyle: HText.body.copyWith(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HRadius.md),
          borderSide: BorderSide(color: extension.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HRadius.md),
          borderSide: BorderSide(color: extension.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HRadius.md),
          side: BorderSide(color: extension.hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primary,
        disabledColor: extension.surfaceAlt,
        labelStyle: HText.labelSmall.copyWith(color: ink),
        secondaryLabelStyle: HText.labelSmall.copyWith(color: scheme.onPrimary),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: HSpace.sm, vertical: HSpace.xs),
        side: BorderSide(color: extension.hairline),
        shape: const StadiumBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: extension.hairline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(HRadius.sheet)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: HSize.navBar,
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: extension.accentSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => HText.labelSmall.copyWith(
            fontSize: 11, letterSpacing: 0,
            color: states.contains(WidgetState.selected) ? ink : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: HSize.icon + 2,
            color: states.contains(WidgetState.selected) ? ink : muted,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: ink,
        titleTextStyle: HText.titleSans.copyWith(color: ink),
        subtitleTextStyle: HText.bodySmall.copyWith(color: muted),
        minVerticalPadding: HSpace.sm,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: HText.bodySmall.copyWith(color: scheme.onInverseSurface),
        shape: rounded,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        headerBackgroundColor: HPalette.navy,
        headerForegroundColor: HPalette.ivory,
        rangeSelectionBackgroundColor: extension.accentSoft,
        rangePickerHeaderBackgroundColor: HPalette.navy,
        rangePickerHeaderForegroundColor: HPalette.ivory,
        shape: rounded,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : extension.surfaceAlt,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
