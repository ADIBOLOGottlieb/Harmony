import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../core/theme/design_tokens.dart';

enum SceneKind { reel, bulbs, route }

/// Illustration au trait doré, tracée progressivement ([progress] de 0 à 1).
class SceneArt extends StatelessWidget {
  const SceneArt({super.key, required this.kind, required this.progress});

  final SceneKind kind;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(painter: _SceneArtPainter(kind, progress)),
    );
  }
}

class _SceneArtPainter extends CustomPainter {
  _SceneArtPainter(this.kind, this.progress);

  final SceneKind kind;
  final double progress;

  late Paint _stroke;
  late Size _size;

  double _p(double start, double end) => ((progress - start) / (end - start)).clamp(0.0, 1.0);

  void _trace(Canvas canvas, Path path, double p) {
    if (p <= 0) return;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * p), _stroke);
    }
  }

  void _glow(Canvas canvas, Offset at, double radius, double strength) {
    if (strength <= 0) return;
    canvas.drawCircle(at, radius, Paint()
      ..color = HColors.gold.withValues(alpha: .45 * strength)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, radius * .8));
  }

  Offset _at(double x, double y) => Offset(x * _size.width, y * _size.height);

  @override
  void paint(Canvas canvas, Size size) {
    _size = size;
    _stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = HGradients.goldSheen.createShader(Offset.zero & size);
    switch (kind) {
      case SceneKind.reel:
        _reel(canvas);
      case SceneKind.bulbs:
        _bulbs(canvas);
      case SceneKind.route:
        _route(canvas);
    }
  }

  void _reel(Canvas canvas) {
    final c = _at(.42, .42);
    final r = _size.width * .32;
    _glow(canvas, c, r * .9, _p(.7, 1) * .6);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(progress * pi * .8);
    canvas.translate(-c.dx, -c.dy);
    _trace(canvas, Path()..addOval(Rect.fromCircle(center: c, radius: r)), _p(0, .45));
    _trace(canvas, Path()..addOval(Rect.fromCircle(center: c, radius: r * .2)), _p(.2, .5));
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5;
      final hole = c + Offset(cos(a), sin(a)) * r * .58;
      _trace(canvas, Path()..addOval(Rect.fromCircle(center: hole, radius: r * .2)), _p(.3 + i * .05, .6 + i * .05));
    }
    canvas.restore();

    // La pellicule qui se déroule hors de la bobine.
    final top = Path()
      ..moveTo(c.dx + r * .7, c.dy + r * .72)
      ..quadraticBezierTo(_at(.75, .95).dx, _at(.75, .95).dy, _at(1, .78).dx, _at(1, .78).dy);
    final bottom = top.shift(const Offset(0, 22));
    _trace(canvas, top, _p(.45, .8));
    _trace(canvas, bottom, _p(.5, .85));
    final strip = top.computeMetrics().first;
    final shown = _p(.55, .95);
    for (var d = 12.0; d < strip.length * shown; d += 16) {
      final pos = strip.getTangentForOffset(d)!.position + const Offset(0, 11);
      canvas.drawRect(Rect.fromCenter(center: pos, width: 5, height: 5), _stroke);
    }
  }

  void _bulbs(Canvas canvas) {
    const strings = [(.22, .38), (.5, .56), (.78, .44)];
    for (var i = 0; i < strings.length; i++) {
      final (x, len) = strings[i];
      final start = i * .12;
      final cord = Path()
        ..moveTo(_at(x, 0).dx, 0)
        ..lineTo(_at(x, len).dx, _at(x, len).dy);
      _trace(canvas, cord, _p(start, start + .35));
      final bulb = _at(x, len + .07);
      _glow(canvas, bulb, _size.width * .12, _p(.7, 1));
      _trace(canvas, Path()..addOval(Rect.fromCircle(center: bulb, radius: _size.width * .065)), _p(start + .3, start + .55));
      if (progress > .75) {
        canvas.drawCircle(bulb, _size.width * .03, Paint()..color = HColors.goldLight.withValues(alpha: _p(.75, 1)));
      }
    }
    // Étincelles.
    const sparks = [(.12, .78), (.38, .86), (.66, .8), (.9, .9), (.5, .95)];
    for (var i = 0; i < sparks.length; i++) {
      final (x, y) = sparks[i];
      final s = _p(.78 + i * .03, .95 + i * .01) * _size.width * .035;
      if (s <= 0) continue;
      final o = _at(x, y);
      final star = Path()
        ..moveTo(o.dx, o.dy - s * 2)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + s * 2, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + s * 2)
        ..quadraticBezierTo(o.dx, o.dy, o.dx - s * 2, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - s * 2);
      canvas.drawPath(star, Paint()..color = HColors.goldLight);
    }
  }

  void _route(Canvas canvas) {
    final from = _at(.14, .9);
    final to = _at(.76, .34);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(_at(.7, .95).dx, _at(.7, .95).dy, _at(.1, .45).dx, _at(.1, .45).dy, to.dx, to.dy);
    final metric = path.computeMetrics().first;
    final shown = metric.length * _p(0, .65);
    for (var d = 0.0; d < shown; d += 14) {
      canvas.drawPath(metric.extractPath(d, min(d + 8, shown)), _stroke);
    }
    canvas.drawCircle(from, 5, Paint()..color = HColors.ivory);

    // Repères visuels le long du trajet.
    for (final (i, f) in [.3, .62].indexed) {
      final p = _p(.25 + i * .15, .4 + i * .15);
      if (p == 0) continue;
      final pos = metric.getTangentForOffset(metric.length * f)!.position;
      canvas.drawCircle(pos, 6 * p, Paint()..color = HColors.gold.withValues(alpha: .9));
    }

    // Épingle d'arrivée.
    final pin = Offset(to.dx, to.dy - _size.width * .1);
    final r = _size.width * .085;
    _glow(canvas, pin, r * 2, _p(.85, 1));
    final drop = Path()
      ..moveTo(to.dx, to.dy)
      ..quadraticBezierTo(pin.dx - r * 1.3, pin.dy + r * .4, pin.dx - r, pin.dy)
      ..arcToPoint(Offset(pin.dx + r, pin.dy), radius: Radius.circular(r))
      ..quadraticBezierTo(pin.dx + r * 1.3, pin.dy + r * .4, to.dx, to.dy);
    _trace(canvas, drop, _p(.6, .9));
    _trace(canvas, Path()..addOval(Rect.fromCircle(center: pin, radius: r * .38)), _p(.8, 1));
  }

  @override
  bool shouldRepaint(_SceneArtPainter old) => old.progress != progress || old.kind != kind;
}
