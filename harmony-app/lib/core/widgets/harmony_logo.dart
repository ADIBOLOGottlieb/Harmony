import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Monogramme HARMONY HOME : une arche (la porte d'entrée) dont les piliers encadrent
/// un « H » à empattements, coiffée d'une clé de voûte en losange. Même dessin que
/// l'icône de l'application (brand/harmony-mark.svg).
/// [progress] (0 à 1) trace l'arche puis fait apparaître le H (écran d'ouverture).
class HarmonyMark extends StatelessWidget {
  const HarmonyMark({super.key, this.size = HSize.logoMark, this.progress = 1, this.color});

  final double size;
  final double progress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'HARMONY HOME',
      child: SizedBox(
        width: size * _MarkPainter.aspect,
        height: size,
        child: CustomPaint(painter: _MarkPainter(progress: progress, color: color ?? context.hc.accent)),
      ),
    );
  }
}

/// Dessin vectoriel de la marque, dans le repère de l'icône (512 × 512) recadré sur la marque.
class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.progress, required this.color});

  static const _box = Rect.fromLTRB(148, 114, 364, 406);
  static final aspect = _box.width / _box.height;

  final double progress;
  final Color color;

  static Path _arch(double left, double right, double springLine, double bottom) => Path()
    ..moveTo(left, bottom)
    ..lineTo(left, springLine)
    ..arcToPoint(Offset(right, springLine), radius: Radius.circular((right - left) / 2))
    ..lineTo(right, bottom);

  /// « H » didone : fûts épais, empattements fins.
  static final Path _h = Path()
    ..addPolygon(const [
      Offset(205, 268), Offset(245, 268), Offset(245, 273), Offset(234, 273), Offset(234, 315), Offset(278, 315),
      Offset(278, 273), Offset(267, 273), Offset(267, 268), Offset(307, 268), Offset(307, 273), Offset(296, 273),
      Offset(296, 379), Offset(307, 379), Offset(307, 384), Offset(267, 384), Offset(267, 379), Offset(278, 379),
      Offset(278, 329), Offset(234, 329), Offset(234, 379), Offset(245, 379), Offset(245, 384), Offset(205, 384),
      Offset(205, 379), Offset(216, 379), Offset(216, 273), Offset(205, 273),
    ], true);

  static final Path _keystone = Path()
    ..addPolygon(const [Offset(256, 119), Offset(273, 136), Offset(256, 153), Offset(239, 136)], true);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    canvas
      ..scale(size.height / _box.height)
      ..translate(-_box.left, -_box.top);

    // Dorure : plus claire en haut, plus profonde en bas, quelle que soit la teinte choisie.
    final gold = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color.lerp(color, Colors.white, .35)!, color, Color.lerp(color, Colors.black, .2)!],
    ).createShader(_box);

    void trace(Path path, Paint paint) {
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0)), paint);
      }
    }

    trace(
      _arch(160, 352, 250, 396),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..shader = gold,
    );
    trace(
      _arch(190, 322, 254, 396),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: .45),
    );

    // Le H et la clé de voûte apparaissent en fondu une fois l'arche tracée.
    final reveal = ((progress - .55) / .45).clamp(0.0, 1.0);
    if (reveal > 0) {
      final fill = Paint()..shader = gold;
      canvas
        ..saveLayer(_box, Paint()..color = Colors.black.withValues(alpha: reveal))
        ..drawPath(_h, fill)
        ..drawPath(_keystone, fill)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.progress != progress || old.color != color;
}

/// Logotype « HARMONY / HOME ».
class HarmonyWordmark extends StatelessWidget {
  const HarmonyWordmark({super.key, this.scale = 1, this.color, this.accentColor});

  final double scale;
  final Color? color;

  /// Couleur de « HOME » (par défaut : champagne, ou [color] si fourni).
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.cs.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HARMONY',
          style: HText.title.copyWith(fontSize: 20 * scale, letterSpacing: 4 * scale, color: ink, height: 1),
        ),
        SizedBox(height: 2 * scale),
        Text(
          'HOME',
          style: HText.overline.copyWith(fontSize: 10 * scale, letterSpacing: 7 * scale, color: accentColor ?? color ?? context.hc.accentText),
        ),
      ],
    );
  }
}

/// Monogramme + logotype, pour les en-têtes.
class HarmonyLogo extends StatelessWidget {
  const HarmonyLogo({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HarmonyMark(size: 34, color: color),
        const SizedBox(width: HSpace.sm),
        HarmonyWordmark(scale: .85, color: color),
      ],
    );
  }
}
