import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Monogramme HARMONY HOME : un « H » sous une double arche, comme une porte
/// d'entrée. [progress] (0 à 1) trace l'arche progressivement (écran d'accueil).
class HarmonyMark extends StatelessWidget {
  const HarmonyMark({super.key, this.size = HSize.logoMark, this.progress = 1, this.color});

  final double size;
  final double progress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.hc.accent;
    return Semantics(
      label: 'HARMONY HOME',
      child: SizedBox(
        width: size * .78,
        height: size,
        child: CustomPaint(
          painter: _ArchPainter(progress: progress, color: c),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: size * .16),
              child: Opacity(
                opacity: ((progress - .55) / .45).clamp(0.0, 1.0),
                child: Text(
                  'H',
                  style: HText.headline.copyWith(fontSize: size * .44, color: c, height: 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchPainter extends CustomPainter {
  _ArchPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  Path _arch(Rect r) => Path()
    ..moveTo(r.left, r.bottom)
    ..lineTo(r.left, r.top + r.width / 2)
    ..arcToPoint(Offset(r.right, r.top + r.width / 2), radius: Radius.circular(r.width / 2))
    ..lineTo(r.right, r.bottom)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 40 + .6
      ..strokeCap = StrokeCap.round
      ..color = color;
    final rect = Offset.zero & size;
    for (final path in [_arch(rect.deflate(paint.strokeWidth)), _arch(rect.deflate(size.width * .12))]) {
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ArchPainter old) => old.progress != progress || old.color != color;
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
