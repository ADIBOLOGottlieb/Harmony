import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_image.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/artwork.dart';

BadgeTone artworkTone(ArtworkStatus s) => switch (s) {
      ArtworkStatus.available => BadgeTone.positive,
      ArtworkStatus.reserved => BadgeTone.caution,
      ArtworkStatus.sold => BadgeTone.neutral,
    };

/// Carte d'œuvre : visuel au format portrait, statut, titre, artiste, prix.
class ArtworkCard extends StatelessWidget {
  const ArtworkCard({super.key, required this.artwork, required this.onTap});

  static const aspect = 4 / 5;

  final Artwork artwork;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final artist = artwork.artist?.name ?? '';
    return Semantics(
      button: true,
      label: t('{title}, {artist}. {status}. {price}.', {
        'title': artwork.title,
        'artist': artist,
        'status': artwork.status.label,
        'price': price(artwork.price),
      }),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: aspect,
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(HRadius.md), boxShadow: HShadows.card),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(HRadius.md),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(tag: artwork.heroTag, child: HarmonyImage(artwork.cover)),
                      if (!artwork.isAvailable)
                        Positioned(
                          left: HSpace.xs,
                          top: HSpace.xs,
                          child: StatusBadge(label: artwork.status.label, tone: artworkTone(artwork.status)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: HSpace.xs),
            Text(artwork.title, style: context.tt.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(artist, style: context.tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: HSpace.xxs),
            Text(price(artwork.price), style: HText.titleSans.copyWith(color: context.cs.onSurface)),
          ],
        ),
      ),
    );
  }
}
