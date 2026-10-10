import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_image.dart';
import '../../../core/widgets/section_header.dart';
import '../data/gallery_api.dart';
import 'artwork_card.dart';

/// Section « La galerie » de l'accueil : quelques œuvres disponibles et l'accès à la galerie.
class GalleryTeaser extends ConsumerWidget {
  const GalleryTeaser({super.key});

  static const _cardWidth = 168.0;
  static const _textHeight = 84.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artworks = ref.watch(artworksProvider);
    final height = _cardWidth / ArtworkCard.aspect + _textHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          overline: t('Art contemporain'),
          title: t('La galerie'),
          actionLabel: t('Découvrir'),
          onAction: () => context.push('/galerie'),
        ),
        artworks.when(
          loading: () => SizedBox(
            height: height + HSpace.md * 2,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(HSpace.gutter),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: HSpace.md),
              itemBuilder: (_, _) => const SizedBox(
                width: _cardWidth,
                child: Skeleton(radius: HRadius.md),
              ),
            ),
          ),
          // Hors connexion : un simple accès à la galerie plutôt qu'une erreur sur l'accueil.
          error: (_, _) => Padding(
            padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.sm, HSpace.gutter, 0),
            child: OutlinedButton.icon(
              onPressed: () => context.push('/galerie'),
              icon: const Icon(Icons.palette_outlined),
              label: Text(t('Découvrir les œuvres de la galerie')),
            ),
          ),
          data: (all) {
            final shown = all.where((a) => a.isAvailable).take(6).toList();
            if (shown.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: height + HSpace.md * 2,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: HSpace.gutter, vertical: HSpace.md),
                itemCount: shown.length,
                separatorBuilder: (_, _) => const SizedBox(width: HSpace.md),
                itemBuilder: (context, i) => SizedBox(
                  width: _cardWidth,
                  child: ArtworkCard(artwork: shown[i], onTap: () => context.push('/galerie/${shown[i].slug}')),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
