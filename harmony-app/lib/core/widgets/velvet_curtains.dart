import 'package:flutter/widgets.dart';

import '../theme/design_tokens.dart';

/// Rideaux de velours bordeaux. [openness] : 0 = fermés, 1 = ouverts.
/// En s'ouvrant, chaque pan se ramasse vers le bord : les plis se resserrent
/// naturellement puisque leur nombre reste constant sur une largeur réduite.
class VelvetCurtains extends StatelessWidget {
  const VelvetCurtains({super.key, required this.openness});

  final double openness;

  @override
  Widget build(BuildContext context) {
    if (openness >= 1) return const SizedBox.shrink();
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final half = constraints.maxWidth / 2;
          final panel = half * (1 - .9 * openness);
          return Stack(
            children: [
              Positioned(left: 0, top: 0, bottom: 0, width: panel, child: const _Panel(innerEdgeRight: true)),
              Positioned(right: 0, top: 0, bottom: 0, width: panel, child: const _Panel(innerEdgeRight: false)),
              const Positioned(left: 0, right: 0, top: 0, height: 34, child: _Valance()),
            ],
          );
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.innerEdgeRight});

  final bool innerEdgeRight;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PanelPainter(innerEdgeRight), size: Size.infinite);
  }
}

class _PanelPainter extends CustomPainter {
  _PanelPainter(this.innerEdgeRight);

  final bool innerEdgeRight;
  static const _folds = 7;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;

    // Plis : alternance ombre / velours / reflet.
    final colors = <Color>[];
    final stops = <double>[];
    for (var i = 0; i < _folds; i++) {
      final start = i / _folds;
      final step = 1 / _folds;
      colors.addAll([HColors.velvetDeep, HColors.velvet, HColors.velvetLight, HColors.velvet]);
      stops.addAll([start, start + step * .3, start + step * .55, start + step * .85]);
    }
    colors.add(HColors.velvetDeep);
    stops.add(1);
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: colors, stops: stops).createShader(rect),
    );

    // Modelé vertical : plus sombre en haut (sous la cantonnière) et au sol.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HColors.shadow.withValues(alpha: .55),
            HColors.shadow.withValues(alpha: 0),
            HColors.shadow.withValues(alpha: 0),
            HColors.shadow.withValues(alpha: .45),
          ],
          stops: const [0, .18, .78, 1],
        ).createShader(rect),
    );

    // Galon doré sur le bord intérieur.
    final x = innerEdgeRight ? size.width - 2 : 2.0;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..shader = HGradients.goldSheen.createShader(rect)
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_PanelPainter old) => old.innerEdgeRight != innerEdgeRight;
}

/// Cantonnière festonnée qui reste en place quand les rideaux s'ouvrent.
class _Valance extends StatelessWidget {
  const _Valance();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _ValancePainter(), size: Size.infinite);
}

class _ValancePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const scallop = 28.0;
    final body = size.height - 10;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, body);
    for (var x = size.width; x > 0; x -= scallop) {
      path.quadraticBezierTo(x - scallop / 2, size.height + 4, x - scallop, body);
    }
    path.close();
    final rect = Offset.zero & size;
    canvas.drawPath(path, Paint()..shader = HGradients.velvetFold.createShader(rect));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = HGradients.goldSheen.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ValancePainter old) => false;
}
