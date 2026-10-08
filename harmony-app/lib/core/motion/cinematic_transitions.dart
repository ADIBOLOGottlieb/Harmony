import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import '../widgets/velvet_curtains.dart';
import 'motion.dart';

/// Transitions de page « grand écran ». Toutes retombent sur un fondu simple
/// quand l'utilisateur a demandé de réduire les animations.
abstract final class CinematicTransitions {
  /// Entracte : les rideaux se ferment sur l'écran courant, le monogramme
  /// apparaît, puis les rideaux s'ouvrent sur la nouvelle scène.
  static CustomTransitionPage<void> intermission({required LocalKey key, required Widget child}) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 2000),
      reverseTransitionDuration: HMotion.base,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (reduceMotion(context)) return FadeTransition(opacity: animation, child: child);
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final t = animation.value;
            final closing = HMotion.curtainCurve.transform((t / .4).clamp(0, 1));
            final opening = HMotion.curtainCurve.transform(((t - .6) / .4).clamp(0, 1));
            final openness = t < .5 ? 1 - closing : opening;
            final monogram = t < .3 || t > .75 ? 0.0 : sin((t - .3) / .45 * pi);
            return Stack(
              fit: StackFit.expand,
              children: [
                Opacity(opacity: t < .5 ? 0 : 1, child: child),
                VelvetCurtains(openness: openness),
                if (monogram > 0)
                  Center(
                    child: Opacity(
                      opacity: monogram,
                      child: Transform.scale(
                        scale: .85 + .15 * monogram,
                        child: Container(
                          width: HSpace.xxxl * 1.5,
                          height: HSpace.xxxl * 1.5,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: HColors.velvetDeep,
                            border: Border.all(color: HColors.gold, width: 1.5),
                            boxShadow: HShadows.goldGlow,
                          ),
                          // DefaultTextStyle : on est hors de tout Scaffold pendant la transition.
                          child: DefaultTextStyle(
                            style: HText.marquee.copyWith(color: HColors.gold, fontSize: 48, letterSpacing: 0),
                            child: const Text('H'),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Ouverture à l'iris, comme dans le cinéma muet : un cercle de lumière
  /// cerclé d'or s'agrandit depuis [origin] jusqu'à couvrir l'écran.
  static CustomTransitionPage<void> iris({required LocalKey key, required Widget child, Alignment origin = const Alignment(0, .8)}) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 1100),
      reverseTransitionDuration: HMotion.scene,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (reduceMotion(context)) return FadeTransition(opacity: animation, child: child);
        final curved = CurvedAnimation(parent: animation, curve: HMotion.emphasized, reverseCurve: HMotion.exit);
        return AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) {
            final t = curved.value;
            if (t >= 1) return child!;
            return LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final center = origin.alongSize(size);
                final reach = _farthestCorner(center, size);
                final radius = reach * t;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipPath(clipper: _CircleClipper(center, radius), child: child),
                    IgnorePointer(
                      child: CustomPaint(painter: _IrisRingPainter(center, radius, 1 - t)),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Fondu enchaîné court : laisse les Hero (affiches) voler d'un écran à l'autre.
  static CustomTransitionPage<void> crossFade({required LocalKey key, required Widget child}) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: HMotion.scene,
      reverseTransitionDuration: HMotion.base,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: HMotion.emphasized),
        child: child,
      ),
    );
  }

  static double _farthestCorner(Offset c, Size s) => [
        c.distance,
        (c - Offset(s.width, 0)).distance,
        (c - Offset(0, s.height)).distance,
        (c - Offset(s.width, s.height)).distance,
      ].reduce(max);
}

class _CircleClipper extends CustomClipper<Path> {
  _CircleClipper(this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) => Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleClipper old) => old.radius != radius || old.center != center;
}

class _IrisRingPainter extends CustomPainter {
  _IrisRingPainter(this.center, this.radius, this.strength);

  final Offset center;
  final double radius;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = HColors.goldLight.withValues(alpha: strength.clamp(0, 1))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_IrisRingPainter old) => old.radius != radius || old.strength != strength;
}
