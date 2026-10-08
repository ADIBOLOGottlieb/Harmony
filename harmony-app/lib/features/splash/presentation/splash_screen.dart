import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/film_grain.dart';
import '../../../core/widgets/velvet_curtains.dart';

/// Ouverture : amorce 3-2-1 → flash du projecteur → rideaux qui s'ouvrent →
/// monogramme qui se dessine → titre HARMONY balayé de lumière.
/// Un toucher passe l'introduction.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;
  bool _done = false;
  int _lastCount = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _c
      ..duration = reduceMotion(context) ? const Duration(milliseconds: 1200) : const Duration(milliseconds: 6400)
      ..addListener(_haptics)
      ..forward().whenComplete(_finish);
  }

  /// Un léger « tic » à chaque chiffre de l'amorce.
  void _haptics() {
    if (_c.value > _Timeline.leaderEnd) return;
    final count = _Timeline.countAt(_c.value);
    if (count != _lastCount) {
      _lastCount = count;
      HapticFeedback.selectionClick();
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    context.go('/onboarding');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    return Scaffold(
      backgroundColor: HColors.night,
      body: Semantics(
        button: true,
        label: 'Passer l’introduction',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _c.stop();
            _finish();
          },
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => reduced ? _reducedStage(_c.value) : _fullStage(_c.value),
          ),
        ),
      ),
    );
  }

  Widget _reducedStage(double t) => Opacity(
        opacity: Curves.easeOut.transform((t * 2).clamp(0, 1)),
        child: const Center(child: _TitleBlock(draw: 1, letters: 1, shimmer: 1, tagline: 1)),
      );

  Widget _fullStage(double t) {
    final flash = (1 - ((t - _Timeline.flashPeak).abs() / .03)).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (t < _Timeline.leaderEnd)
          Opacity(
            opacity: .86 + .14 * sin(t * 140),
            child: CustomPaint(painter: _LeaderPainter(t / _Timeline.leaderEnd)),
          )
        else ...[
          const DecoratedBox(decoration: BoxDecoration(gradient: HGradients.projectorBeam)),
          Center(
            child: _TitleBlock(
              draw: _Timeline.local(t, .58, .76),
              letters: _Timeline.local(t, .66, .86),
              shimmer: _Timeline.local(t, .78, .97),
              tagline: _Timeline.local(t, .84, .95),
            ),
          ),
          VelvetCurtains(openness: HMotion.curtainCurve.transform(_Timeline.local(t, .5, .72))),
        ],
        if (flash > 0) ColoredBox(color: HColors.ivory.withValues(alpha: flash * .9)),
        const Vignette(),
        const FilmGrain(intensity: 1.4),
        Positioned(
          left: 0,
          right: 0,
          bottom: HSpace.xl,
          child: SafeArea(
            child: Opacity(
              opacity: _Timeline.local(t, .05, .15) * .8,
              child: Text('TOUCHER POUR PASSER', textAlign: TextAlign.center, style: HText.credit.copyWith(color: HColors.ivoryFaint)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Repères temporels de l'ouverture, en fraction de la durée totale.
abstract final class _Timeline {
  static const leaderEnd = .42;
  static const flashPeak = .43;

  static double local(double t, double start, double end) => ((t - start) / (end - start)).clamp(0.0, 1.0);

  static int countAt(double t) => 3 - ((t / leaderEnd) * 3).floor().clamp(0, 2);
}

/// Amorce de film « Academy leader » : cercles, réticule, balayage et chiffre.
class _LeaderPainter extends CustomPainter {
  _LeaderPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide * .34;
    final phase = (progress * 3) % 1;
    final number = 3 - (progress * 3).floor().clamp(0, 2);

    canvas.drawRect(Offset.zero & size, Paint()..color = HColors.nightHigh);

    final line = Paint()
      ..color = HColors.ivoryFaint.withValues(alpha: .6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), line);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), line);

    // Balayage façon radar.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 1.6),
      -pi / 2,
      phase * 2 * pi,
      true,
      Paint()..color = HColors.gold.withValues(alpha: .16),
    );
    final hand = Offset(cos(-pi / 2 + phase * 2 * pi), sin(-pi / 2 + phase * 2 * pi)) * r * 1.6;
    canvas.drawLine(center, center + hand, Paint()
      ..color = HColors.goldLight.withValues(alpha: .7)
      ..strokeWidth = 2);

    canvas.drawCircle(center, r, line..strokeWidth = 2.5);
    canvas.drawCircle(center, r * .82, line..strokeWidth = 1.5);

    final text = TextPainter(
      text: TextSpan(text: '$number', style: HText.marquee.copyWith(fontSize: r * 1.15, letterSpacing: 0, color: HColors.ivory)),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(_LeaderPainter old) => old.progress != progress;
}

/// Monogramme en arche + titre + slogan. Chaque paramètre va de 0 à 1.
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.draw, required this.letters, required this.shimmer, required this.tagline});

  final double draw;
  final double letters;
  final double shimmer;
  final double tagline;

  static const _word = 'HARMONY';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 96,
          height: 124,
          child: CustomPaint(
            painter: _MonogramPainter(draw),
            child: Center(
              child: Opacity(
                opacity: _Timeline.local(draw, .6, 1),
                child: Padding(
                  padding: const EdgeInsets.only(top: HSpace.md),
                  child: Text('H', style: HText.marquee.copyWith(color: HColors.gold, fontSize: 52, letterSpacing: 0)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: HSpace.lg),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) {
            final s = -.2 + shimmer * 1.4;
            return LinearGradient(
              colors: const [HColors.gold, HColors.gold, HColors.ivory, HColors.gold, HColors.gold],
              stops: [0, (s - .15).clamp(0, 1), s.clamp(0, 1), (s + .15).clamp(0, 1), 1],
            ).createShader(rect);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _word.length; i++)
                Builder(builder: (context) {
                  final p = Curves.easeOutCubic.transform(_Timeline.local(letters, i / 10, i / 10 + .4));
                  return Opacity(
                    opacity: p,
                    child: Transform.translate(
                      offset: Offset(0, (1 - p) * 18),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3 + (1 - p) * 10),
                        child: Text(_word[i], style: HText.marquee.copyWith(letterSpacing: 0)),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: HSpace.sm),
        Opacity(
          opacity: tagline,
          child: Text('Séance privée · Lomé', style: HText.tagline.copyWith(color: HColors.goldLight)),
        ),
      ],
    );
  }
}

/// Double arche dorée tracée progressivement.
class _MonogramPainter extends CustomPainter {
  _MonogramPainter(this.progress);

  final double progress;

  Path _arch(Rect r) => Path()
    ..moveTo(r.left, r.bottom)
    ..lineTo(r.left, r.top + r.width / 2)
    ..arcToPoint(Offset(r.right, r.top + r.width / 2), radius: Radius.circular(r.width / 2))
    ..lineTo(r.right, r.bottom)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final outer = _arch(Offset.zero & size);
    final inner = _arch((Offset.zero & size).deflate(7));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..shader = HGradients.goldSheen.createShader(Offset.zero & size);
    for (final path in [outer, inner]) {
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
      }
    }
    if (progress > .9) {
      final top = Offset(size.width / 2, -6);
      final diamond = Path()
        ..moveTo(top.dx, top.dy - 5)
        ..lineTo(top.dx + 5, top.dy)
        ..lineTo(top.dx, top.dy + 5)
        ..lineTo(top.dx - 5, top.dy)
        ..close();
      canvas.drawPath(diamond, Paint()..color = HColors.goldLight.withValues(alpha: (progress - .9) * 10));
    }
  }

  @override
  bool shouldRepaint(_MonogramPainter old) => old.progress != progress;
}
