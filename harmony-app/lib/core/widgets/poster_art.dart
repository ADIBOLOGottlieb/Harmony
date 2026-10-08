import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme/design_tokens.dart';

/// Affiche de chambre générée : bokeh, faisceau de lumière et arche dorée,
/// répartis sur trois plans de profondeur. [parallax] (-1 à 1) décale chaque
/// plan à une vitesse différente pour un effet de relief au défilement.
///
/// Remplacée par les vraies photos quand l'API les fournira ; reste le visuel
/// de repli (chargement, hors-ligne).
class PosterArt extends StatelessWidget {
  const PosterArt({super.key, required this.mood, required this.seed, this.parallax = 0});

  final int mood;
  final int seed;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _PosterPainter(HPoster.moods[mood % HPoster.moods.length], seed, parallax),
        size: Size.infinite,
      ),
    );
  }
}

class _PosterPainter extends CustomPainter {
  _PosterPainter(this.palette, this.seed, this.parallax);

  final PosterPalette palette;
  final int seed;
  final double parallax;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rnd = Random(seed);

    // Fond : la couleur de la chambre qui sombre dans la nuit.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.accent, palette.base, HColors.night],
          stops: const [0, .5, 1],
        ).createShader(rect),
    );

    // Plan lointain : bokeh fin.
    _bokeh(canvas, size, rnd, count: 16, minR: 4, maxR: 16, blur: 6, alpha: .45, shift: parallax * 14);

    // Faisceau de projecteur en diagonale.
    canvas.save();
    canvas.translate(-parallax * 22, 0);
    final beam = Path()
      ..moveTo(size.width * .05, 0)
      ..lineTo(size.width * .38, 0)
      ..lineTo(size.width * 1.1, size.height * .85)
      ..lineTo(size.width * .55, size.height * .95)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.glow.withValues(alpha: .28), palette.glow.withValues(alpha: 0)],
        ).createShader(rect)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18),
    );
    canvas.restore();

    // Plan médian : arche dorée, comme une fenêtre sur la nuit.
    canvas.save();
    canvas.translate(parallax * 30, 0);
    final w = size.width * .56;
    final left = (size.width - w) / 2;
    final top = size.height * .12;
    final bottom = size.height * .56; // reste au-dessus du titre de l'affiche
    final arch = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top + w / 2)
      ..arcToPoint(Offset(left + w, top + w / 2), radius: Radius.circular(w / 2))
      ..lineTo(left + w, bottom)
      ..close();
    canvas.drawPath(
      arch,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -.3),
          colors: [palette.glow.withValues(alpha: .22), palette.glow.withValues(alpha: .02)],
        ).createShader(arch.getBounds()),
    );
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = HColors.gold.withValues(alpha: .7),
    );
    // Lune / lustre au sommet de l'arche.
    final moon = Offset(size.width / 2, top + w * .42);
    canvas.drawCircle(moon, w * .16, Paint()
      ..color = palette.glow.withValues(alpha: .35)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 20));
    canvas.drawCircle(moon, w * .07, Paint()..color = palette.glow.withValues(alpha: .9));
    canvas.restore();

    // Premier plan : grosses taches de lumière floues, plus rapides.
    _bokeh(canvas, size, rnd, count: 6, minR: 18, maxR: 42, blur: 16, alpha: .22, shift: parallax * 60);
  }

  void _bokeh(Canvas canvas, Size size, Random rnd,
      {required int count, required double minR, required double maxR, required double blur, required double alpha, required double shift}) {
    final paint = Paint()..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blur);
    for (var i = 0; i < count; i++) {
      final r = minR + rnd.nextDouble() * (maxR - minR);
      final pos = Offset(rnd.nextDouble() * size.width + shift, rnd.nextDouble() * size.height * .8);
      paint.color = (i.isEven ? palette.glow : HColors.gold).withValues(alpha: alpha * (.4 + rnd.nextDouble() * .6));
      canvas.drawCircle(pos, r, paint);
    }
  }

  @override
  bool shouldRepaint(_PosterPainter old) => old.parallax != parallax || old.seed != seed || old.palette != palette;
}
