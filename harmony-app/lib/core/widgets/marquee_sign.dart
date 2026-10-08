import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import '../theme/design_tokens.dart';

/// Enseigne de cinéma : un cadre d'ampoules dorées qui « chassent » autour du texte.
class MarqueeSign extends StatefulWidget {
  const MarqueeSign({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: HSpace.lg, vertical: HSpace.md)});

  final Widget child;
  final EdgeInsets padding;

  @override
  State<MarqueeSign> createState() => _MarqueeSignState();
}

class _MarqueeSignState extends State<MarqueeSign> with SingleTickerProviderStateMixin {
  late final AnimationController _chase = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _chase.stop();
    } else if (!_chase.isAnimating) {
      _chase.repeat();
    }
  }

  @override
  void dispose() {
    _chase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return AnimatedBuilder(
      animation: _chase,
      builder: (context, child) => CustomPaint(
        painter: _BulbFramePainter(phase: still ? -1 : (_chase.value * 3).floor()),
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.all(HSpace.sm),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: HColors.velvetDeep.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(HRadius.sm),
          border: Border.all(color: HColors.hairline),
        ),
        child: widget.child,
      ),
    );
  }
}

class _BulbFramePainter extends CustomPainter {
  _BulbFramePainter({required this.phase});

  /// -1 : toutes les ampoules allumées, sans chenillard.
  final int phase;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(HSize.bulb),
      const Radius.circular(HRadius.md),
    );
    final metric = (Path()..addRRect(frame)).computeMetrics().first;
    const spacing = 15.0;
    final count = (metric.length / spacing).floor();

    final glow = Paint()
      ..color = HColors.gold.withValues(alpha: .55)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    final lit = Paint()..color = HColors.goldLight;
    final dim = Paint()..color = HColors.goldDeep.withValues(alpha: .35);

    for (var i = 0; i < count; i++) {
      final pos = metric.getTangentForOffset(i * metric.length / count)!.position;
      final on = phase < 0 || (i + phase) % 3 == 0;
      if (on) canvas.drawCircle(pos, HSize.bulb * 1.6, glow);
      canvas.drawCircle(pos, on ? HSize.bulb * .7 : HSize.bulb * .55, on ? lit : dim);
    }
  }

  @override
  bool shouldRepaint(_BulbFramePainter old) => old.phase != phase;
}
