import 'package:flutter/material.dart';

/// Source unique de vérité du design HARMONY.
///
/// Direction artistique : « boutique hotel de nuit », mise en scène comme une
/// salle de cinéma privée — velours bordeaux, lumière de projecteur dorée,
/// grain de pellicule. Aucune couleur, taille ou durée en dur ailleurs.
abstract final class HColors {
  // Salle obscure
  static const night = Color(0xFF0E0A0C);
  static const nightRaised = Color(0xFF171114);
  static const nightHigh = Color(0xFF211A1D);

  // Velours
  static const velvet = Color(0xFF5A0F2E);
  static const velvetDeep = Color(0xFF3A0A1E);
  static const velvetLight = Color(0xFF7A1A42);

  // Lumière de projecteur
  static const gold = Color(0xFFC9A24D);
  static const goldLight = Color(0xFFE6C77E);
  static const goldDeep = Color(0xFF9C7A2E);

  // Écran
  static const ivory = Color(0xFFF4EDE4);
  static const ivoryMuted = Color(0xFFBFB4A8);
  static const ivoryFaint = Color(0xFF8A7F76);

  static const error = Color(0xFFE5806B);
  static const scrim = Color(0xCC0E0A0C);
  static const glass = Color(0x99171114);
  static const hairline = Color(0x33C9A24D);
  static const shadow = Color(0xFF000000);
}

/// Palette d'une affiche de chambre (fond, accent, lueur).
final class PosterPalette {
  const PosterPalette(this.base, this.accent, this.glow);
  final Color base;
  final Color accent;
  final Color glow;
}

/// Une « humeur » d'affiche par chambre, toutes ancrées dans la nuit HARMONY.
abstract final class HPoster {
  static const moods = [
    PosterPalette(Color(0xFF5A0F2E), Color(0xFF9E2A55), Color(0xFFE6C77E)), // velours
    PosterPalette(Color(0xFF0F3A44), Color(0xFF1F6E7A), Color(0xFFBFE3DD)), // lagune
    PosterPalette(Color(0xFF1B1F4A), Color(0xFF3A3F8F), Color(0xFFC9B8FF)), // indigo
    PosterPalette(Color(0xFF4A2A0F), Color(0xFF8F5A1F), Color(0xFFF2C77E)), // ambre
    PosterPalette(Color(0xFF0F3A2A), Color(0xFF1F6E4F), Color(0xFFD9E8B0)), // émeraude
    PosterPalette(Color(0xFF3A0F44), Color(0xFF6E1F7A), Color(0xFFF0B8E6)), // prune
    PosterPalette(Color(0xFF4A1A12), Color(0xFF8F3A24), Color(0xFFFFC9A0)), // terre cuite
    PosterPalette(Color(0xFF101A33), Color(0xFF24406E), Color(0xFFE6C77E)), // minuit
  ];
}

abstract final class HGradients {
  static const goldSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [HColors.goldLight, HColors.gold, HColors.goldDeep],
    stops: [0, .55, 1],
  );

  static const velvetFold = LinearGradient(
    colors: [HColors.velvetDeep, HColors.velvet, HColors.velvetLight, HColors.velvet, HColors.velvetDeep],
    stops: [0, .3, .5, .7, 1],
  );

  /// Fondu bas d'affiche : garantit la lisibilité du titre sur l'image.
  static const posterScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000E0A0C), Color(0x660E0A0C), Color(0xF20E0A0C)],
    stops: [.35, .6, 1],
  );

  static const projectorBeam = RadialGradient(
    center: Alignment.topCenter,
    radius: 1.2,
    colors: [Color(0x33E6C77E), Color(0x0AC9A24D), Color(0x000E0A0C)],
    stops: [0, .45, 1],
  );
}

abstract final class HSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
}

abstract final class HRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const card = 24.0;
  static const sheet = 32.0;
  static const pill = 999.0;
}

abstract final class HSize {
  static const touch = 48.0;
  static const buttonHeight = 56.0;
  static const letterbox = 56.0;
  static const bulb = 5.0;
  static const icon = 22.0;
}

abstract final class HShadows {
  static const soft = [
    BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 16)),
  ];

  /// Lueur dorée des éléments actifs.
  static const goldGlow = [
    BoxShadow(color: Color(0x55C9A24D), blurRadius: 24, spreadRadius: -4),
    BoxShadow(color: Color(0x22E6C77E), blurRadius: 48, spreadRadius: 4),
  ];

  static const poster = [
    BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 24)),
    BoxShadow(color: Color(0x225A0F2E), blurRadius: 60, spreadRadius: 8),
  ];
}

abstract final class HMotion {
  static const quick = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 320);
  static const scene = Duration(milliseconds: 650);
  static const curtain = Duration(milliseconds: 1100);
  static const title = Duration(milliseconds: 1400);
  static const grainFrame = Duration(milliseconds: 83); // ~12 i/s, cadence de pellicule

  static const enter = Cubic(0.05, 0.7, 0.1, 1);
  static const exit = Cubic(0.3, 0, 0.8, 0.15);
  static const emphasized = Cubic(0.2, 0, 0, 1);
  static const curtainCurve = Cubic(0.7, 0, 0.2, 1);
}

abstract final class HFonts {
  static const display = 'PlayfairDisplay';
  static const body = 'Manrope';
}

abstract final class HText {
  static const marquee = TextStyle(
    fontFamily: HFonts.display,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    letterSpacing: 10,
    height: 1.05,
    color: HColors.ivory,
  );

  static const displayLarge = TextStyle(
    fontFamily: HFonts.display,
    fontSize: 38,
    fontWeight: FontWeight.w600,
    height: 1.1,
    color: HColors.ivory,
  );

  static const headline = TextStyle(
    fontFamily: HFonts.display,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: HColors.ivory,
  );

  static const title = TextStyle(
    fontFamily: HFonts.display,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: HColors.ivory,
  );

  static const tagline = TextStyle(
    fontFamily: HFonts.display,
    fontSize: 18,
    fontStyle: FontStyle.italic,
    height: 1.4,
    color: HColors.ivoryMuted,
  );

  static const body = TextStyle(
    fontFamily: HFonts.body,
    fontSize: 16,
    height: 1.5,
    color: HColors.ivoryMuted,
  );

  static const label = TextStyle(
    fontFamily: HFonts.body,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: .4,
    height: 1.3,
    color: HColors.ivory,
  );

  /// Petites capitales espacées, façon générique de film.
  static const credit = TextStyle(
    fontFamily: HFonts.body,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 3.2,
    height: 1.4,
    color: HColors.gold,
  );

  static const creditSmall = TextStyle(
    fontFamily: HFonts.body,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    height: 1.3,
    color: HColors.gold,
  );

  static const price = TextStyle(
    fontFamily: HFonts.body,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
    color: HColors.goldLight,
  );
}
