import 'package:flutter/material.dart';

/// Source unique du design HARMONY HOME — agence immobilière haut de gamme :
/// sobre, rassurante, photographie d'abord. Aucune couleur, taille ou durée
/// en dur ailleurs : les widgets lisent le thème (ColorScheme, TextTheme,
/// [HarmonyColors]) ou ces constantes.
abstract final class HPalette {
  // Marque
  static const navy = Color(0xFF14213D);
  static const navyDeep = Color(0xFF0B1426);
  static const navySoft = Color(0xFF2A3A5C);
  static const champagne = Color(0xFFC8A96A);
  static const champagneText = Color(0xFF7A5F2A); // champagne lisible sur fond clair (5,3:1 sur ivoire)
  static const champagneSoft = Color(0xFFF1E7D2);

  // Neutres chauds (clair)
  static const ivory = Color(0xFFF7F3EC);
  static const white = Color(0xFFFFFFFF);
  static const sand = Color(0xFFEFE9DF);
  static const ink = Color(0xFF1D1B18);
  static const inkMuted = Color(0xFF5C574F); // 6,5:1 sur ivoire
  static const hairline = Color(0xFFE2DBCF);

  // Neutres (sombre)
  static const night = Color(0xFF0C1220);
  static const nightSurface = Color(0xFF141C2E);
  static const nightRaised = Color(0xFF1C2640);
  static const paper = Color(0xFFF2EDE4);
  static const paperMuted = Color(0xFFB8B1A5);
  static const nightHairline = Color(0xFF2A3450);

  // États
  static const success = Color(0xFF2F7A57);
  static const successOnDark = Color(0xFF7CC9A2);
  static const warning = Color(0xFF8F5D10);
  static const warningOnDark = Color(0xFFE7B661);
  static const error = Color(0xFFB3261E);
  static const errorOnDark = Color(0xFFF2B8B5);

  // Voiles sur photo
  static const photoScrimClear = Color(0x00000000);
  static const photoScrimDark = Color(0xB3000000);
  static const photoGlass = Color(0x66000000);
}

/// Couleurs propres à HARMONY HOME, absentes du ColorScheme Material.
/// Accès : `context.hc` (voir [HarmonyColorsX]).
@immutable
class HarmonyColors extends ThemeExtension<HarmonyColors> {
  const HarmonyColors({
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.surfaceAlt,
    required this.hairline,
    required this.textMuted,
    required this.success,
    required this.warning,
  });

  /// Champagne décoratif (filets, étoiles, puces).
  final Color accent;

  /// Champagne utilisé pour du texte : contraste AA garanti sur le fond.
  final Color accentText;
  final Color accentSoft;
  final Color surfaceAlt;
  final Color hairline;
  final Color textMuted;
  final Color success;
  final Color warning;

  static const light = HarmonyColors(
    accent: HPalette.champagne,
    accentText: HPalette.champagneText,
    accentSoft: HPalette.champagneSoft,
    surfaceAlt: HPalette.sand,
    hairline: HPalette.hairline,
    textMuted: HPalette.inkMuted,
    success: HPalette.success,
    warning: HPalette.warning,
  );

  static const dark = HarmonyColors(
    accent: HPalette.champagne,
    accentText: HPalette.champagne,
    accentSoft: HPalette.navySoft,
    surfaceAlt: HPalette.nightRaised,
    hairline: HPalette.nightHairline,
    textMuted: HPalette.paperMuted,
    success: HPalette.successOnDark,
    warning: HPalette.warningOnDark,
  );

  @override
  HarmonyColors copyWith({
    Color? accent,
    Color? accentText,
    Color? accentSoft,
    Color? surfaceAlt,
    Color? hairline,
    Color? textMuted,
    Color? success,
    Color? warning,
  }) {
    return HarmonyColors(
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      accentSoft: accentSoft ?? this.accentSoft,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      hairline: hairline ?? this.hairline,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  HarmonyColors lerp(HarmonyColors? other, double t) {
    if (other == null) return this;
    return HarmonyColors(
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension HarmonyColorsX on BuildContext {
  HarmonyColors get hc => Theme.of(this).extension<HarmonyColors>()!;
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
}

abstract final class HSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Marge latérale des écrans.
  static const gutter = 20.0;
}

abstract final class HRadius {
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const sheet = 24.0;
  static const pill = 999.0;
}

abstract final class HSize {
  static const touch = 48.0;
  static const button = 52.0;
  static const icon = 20.0;
  static const iconSm = 16.0;
  static const avatar = 64.0;
  static const navBar = 72.0;
  static const bookingBar = 84.0;
  static const featuredCardWidth = 280.0;
  static const zoneCardWidth = 150.0;
  static const zoneCardHeight = 190.0;
  static const photoAspect = 4 / 3;
  static const mapHeight = 200.0;
  static const mapZoneRadius = 350.0; // mètres : quartier approximatif avant confirmation
  static const logoMark = 44.0;
}

abstract final class HShadows {
  static const card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const floating = [
    BoxShadow(color: Color(0x26000000), blurRadius: 32, offset: Offset(0, 12)),
  ];
}

abstract final class HMotion {
  static const quick = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const logo = Duration(milliseconds: 1400);
  static const standard = Cubic(0.2, 0, 0, 1);
  static const enter = Cubic(0.05, 0.7, 0.1, 1);
  static const exit = Cubic(0.3, 0, 0.8, 0.15);
}

abstract final class HFonts {
  static const serif = 'PlayfairDisplay';
  static const sans = 'Manrope';
}

/// Échelle typographique (sans couleur : le thème l'applique).
abstract final class HText {
  static const display = TextStyle(fontFamily: HFonts.serif, fontSize: 34, fontWeight: FontWeight.w600, height: 1.15);
  static const headline = TextStyle(fontFamily: HFonts.serif, fontSize: 26, fontWeight: FontWeight.w600, height: 1.2);
  static const title = TextStyle(fontFamily: HFonts.serif, fontSize: 20, fontWeight: FontWeight.w600, height: 1.25);
  static const titleSans = TextStyle(fontFamily: HFonts.sans, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35);
  static const body = TextStyle(fontFamily: HFonts.sans, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static const bodySmall = TextStyle(fontFamily: HFonts.sans, fontSize: 14, fontWeight: FontWeight.w400, height: 1.45);
  static const label = TextStyle(fontFamily: HFonts.sans, fontSize: 15, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: .2);
  static const labelSmall = TextStyle(fontFamily: HFonts.sans, fontSize: 13, fontWeight: FontWeight.w600, height: 1.2);

  /// Petites capitales espacées : catégories, surtitres.
  static const overline = TextStyle(fontFamily: HFonts.sans, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: 1.4);

  static const price = TextStyle(
    fontFamily: HFonts.sans,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
