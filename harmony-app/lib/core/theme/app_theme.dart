import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Thème Material 3 dérivé exclusivement de [design_tokens.dart].
abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: HColors.gold,
      onPrimary: HColors.night,
      primaryContainer: HColors.velvet,
      onPrimaryContainer: HColors.ivory,
      secondary: HColors.velvetLight,
      onSecondary: HColors.ivory,
      tertiary: HColors.goldLight,
      onTertiary: HColors.night,
      error: HColors.error,
      onError: HColors.night,
      surface: HColors.night,
      onSurface: HColors.ivory,
      onSurfaceVariant: HColors.ivoryMuted,
      surfaceContainerLowest: HColors.night,
      surfaceContainerLow: HColors.nightRaised,
      surfaceContainer: HColors.nightRaised,
      surfaceContainerHigh: HColors.nightHigh,
      surfaceContainerHighest: HColors.nightHigh,
      outline: HColors.ivoryFaint,
      outlineVariant: HColors.hairline,
      shadow: HColors.shadow,
      scrim: HColors.scrim,
      inverseSurface: HColors.ivory,
      onInverseSurface: HColors.night,
      inversePrimary: HColors.velvet,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: HColors.night,
      fontFamily: HFonts.body,
      textTheme: const TextTheme(
        displayLarge: HText.displayLarge,
        headlineMedium: HText.headline,
        titleLarge: HText.title,
        bodyLarge: HText.body,
        bodyMedium: HText.body,
        labelLarge: HText.label,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: HColors.nightHigh,
        contentTextStyle: HText.label,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(HRadius.md)),
          side: BorderSide(color: HColors.hairline),
        ),
      ),
    );
  }
}
