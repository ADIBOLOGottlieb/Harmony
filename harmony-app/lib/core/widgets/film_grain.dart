import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import '../theme/design_tokens.dart';

/// Grain de pellicule animé à 12 images/s, avec rayures occasionnelles.
/// Figé (une seule image) quand l'utilisateur réduit les animations.
class FilmGrain extends StatefulWidget {
  const FilmGrain({super.key, this.intensity = 1});

  final double intensity;

  @override
  State<FilmGrain> createState() => _FilmGrainState();
}

class _FilmGrainState extends State<FilmGrain> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastFrame = Duration.zero;
  int _seed = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !reduceMotion(context);
    if (animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!animate && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    if (elapsed - _lastFrame >= HMotion.grainFrame) {
      _lastFrame = elapsed;
      setState(() => _seed++);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _GrainPainter(_seed, widget.intensity),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.seed, this.intensity);

  final int seed;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rnd = Random(seed);
    final count = (size.width * size.height / 700).clamp(150, 3000).toInt();

    Float32List points(int n) {
      final list = Float32List(n * 2);
      for (var i = 0; i < n; i++) {
        list[i * 2] = rnd.nextDouble() * size.width;
        list[i * 2 + 1] = rnd.nextDouble() * size.height;
      }
      return list;
    }

    final light = Paint()
      ..color = HColors.ivory.withValues(alpha: .05 * intensity)
      ..strokeWidth = 1.2;
    final dark = Paint()
      ..color = HColors.shadow.withValues(alpha: .18 * intensity)
      ..strokeWidth = 1.4;
    canvas.drawRawPoints(ui.PointMode.points, points(count ~/ 2), light);
    canvas.drawRawPoints(ui.PointMode.points, points(count ~/ 2), dark);

    // Rayure verticale fugace, comme une copie d'exploitation.
    if (rnd.nextDouble() < .18) {
      final x = rnd.nextDouble() * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + rnd.nextDouble() * 6 - 3, size.height),
        Paint()
          ..color = HColors.ivory.withValues(alpha: .05 * intensity)
          ..strokeWidth = .8,
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.seed != seed || old.intensity != intensity;
}

/// Vignette sombre sur les bords : concentre le regard au centre de l'écran.
class Vignette extends StatelessWidget {
  const Vignette({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.1,
            colors: [HColors.night.withValues(alpha: 0), HColors.night.withValues(alpha: .75)],
            stops: const [.55, 1],
          ),
        ),
      ),
    );
  }
}
