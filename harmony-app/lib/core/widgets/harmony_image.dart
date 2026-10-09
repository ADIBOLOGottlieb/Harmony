import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../motion/motion.dart';
import '../theme/design_tokens.dart';

/// Photo avec chargement progressif : squelette animé, puis fondu à l'arrivée
/// de l'image. Repli sobre si l'image est introuvable.
class HarmonyImage extends StatelessWidget {
  const HarmonyImage(this.asset, {super.key, this.fit = BoxFit.cover, this.semanticLabel});

  final String asset;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      asset,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: width.round(), // décode à la taille d'affichage : mémoire maîtrisée
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            const Skeleton(),
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: HMotion.slow,
              curve: HMotion.standard,
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (context, error, stack) => ColoredBox(
        color: context.hc.surfaceAlt,
        child: Center(child: Icon(Icons.image_not_supported_outlined, color: context.hc.textMuted)),
      ),
    );
  }
}

/// Bloc de chargement. Le reflet animé est coupé si l'utilisateur réduit les animations.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height, this.radius = 0});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.hc.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (reduceMotion(context)) return box;
    return box
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: context.cs.surfaceContainerLowest.withValues(alpha: .6));
  }
}
