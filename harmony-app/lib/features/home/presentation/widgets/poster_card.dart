import 'package:flutter/material.dart';

import '../../../../core/format/fcfa.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/poster_art.dart';
import '../../domain/room.dart';

/// Affiche d'une chambre dans le carrousel. [delta] = distance à la page
/// centrale (0 = au centre) : pilote rotation 3D, échelle, lumière et parallaxe.
class PosterCard extends StatelessWidget {
  const PosterCard({super.key, required this.room, required this.stay, required this.delta, required this.onTap});

  final Room room;
  final StayType stay;
  final double delta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final focus = (1 - delta.abs()).clamp(0.0, 1.0);
    final price = room.priceFor(stay);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, .0012)
        ..rotateY(delta * -.42)
        ..scaleByDouble(.84 + .16 * focus, .84 + .16 * focus, 1, 1),
      child: Semantics(
        button: true,
        label: '${room.name}. ${room.tagline} ${stay.label} : ${fcfa(price)}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: HSpace.xs, vertical: HSpace.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HRadius.card),
              boxShadow: focus > .6 ? HShadows.poster : HShadows.soft,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(HRadius.card),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: room.heroTag,
                    child: PosterArt(mood: room.mood, seed: room.posterSeed, parallax: delta),
                  ),
                  const DecoratedBox(decoration: BoxDecoration(gradient: HGradients.posterScrim)),
                  // Les affiches latérales restent dans la pénombre.
                  IgnorePointer(child: ColoredBox(color: HColors.night.withValues(alpha: (1 - focus) * .55))),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(HRadius.card),
                      border: Border.all(color: HColors.gold.withValues(alpha: .15 + .35 * focus)),
                    ),
                  ),
                  Positioned(
                    left: HSpace.lg,
                    right: HSpace.lg,
                    bottom: HSpace.lg,
                    child: Opacity(
                      opacity: .35 + .65 * focus,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(room.category.toUpperCase(), style: HText.credit),
                          const SizedBox(height: HSpace.xs),
                          Text(room.name, style: HText.headline),
                          const SizedBox(height: HSpace.xxs),
                          Text(room.tagline, style: HText.tagline.copyWith(fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: HSpace.md),
                          Text(stay.screening.toUpperCase(), style: HText.creditSmall.copyWith(color: HColors.ivoryMuted)),
                          const SizedBox(height: HSpace.xxs),
                          _RollingPrice(price: price),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le prix « défile » verticalement comme un tableau d'affichage quand il change.
class _RollingPrice extends StatelessWidget {
  const _RollingPrice({required this.price});

  final int price;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: HMotion.base,
      switchInCurve: HMotion.enter,
      switchOutCurve: HMotion.exit,
      transitionBuilder: (child, animation) => ClipRect(
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .8), end: Offset.zero).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
      ),
      child: FittedBox(
        key: ValueKey(price),
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(fcfa(price), style: HText.price),
      ),
    );
  }
}
