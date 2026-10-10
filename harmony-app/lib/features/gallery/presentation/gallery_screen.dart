import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/harmony_image.dart';
import '../data/gallery_api.dart';
import '../domain/artwork.dart';
import 'artwork_card.dart';

/// Galerie d'art : œuvres originales à acquérir, filtrables par artiste et par disponibilité.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  static const _textHeight = 84.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artworks = ref.watch(artworksProvider);
    final artistFilter = ref.watch(galleryArtistFilterProvider);
    final availableOnly = ref.watch(galleryAvailableOnlyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('La galerie')),
        actions: [
          IconButton(
            tooltip: t('Mes acquisitions'),
            onPressed: () => context.push('/acquisitions'),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: artworks.when(
        loading: () => _grid(context, itemCount: 4, builder: (_) => const Skeleton(radius: HRadius.md)),
        error: (e, _) {
          final error = ApiError.from(e);
          return EmptyState(
            icon: error.offline ? Icons.cloud_off_outlined : Icons.error_outline_rounded,
            title: error.offline ? t('Hors connexion') : t('Impossible de charger la galerie'),
            message: error.message,
            actionLabel: t('Réessayer'),
            onAction: () => ref.invalidate(artworksProvider),
          );
        },
        data: (all) {
          final artists = <String, Artist>{
            for (final a in all)
              if (a.artist != null) a.artist!.slug: a.artist!,
          };
          final visible = [
            for (final a in all)
              if ((artistFilter == null || a.artist?.slug == artistFilter) && (!availableOnly || a.isAvailable)) a,
          ];

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(artworksProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.sm),
                    child: Text(
                      t('Œuvres originales d’artistes du Togo et d’Afrique de l’Ouest, livrées avec un certificat d’authenticité.'),
                      style: context.tt.bodyMedium,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: HSize.touch,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
                      children: [
                        _Chip(
                          label: t('Disponibles'),
                          selected: availableOnly,
                          onSelected: (_) => ref.read(galleryAvailableOnlyProvider.notifier).toggle(),
                        ),
                        _Chip(
                          label: t('Tous les artistes'),
                          selected: artistFilter == null,
                          onSelected: (_) => ref.read(galleryArtistFilterProvider.notifier).set(null),
                        ),
                        for (final artist in artists.values)
                          _Chip(
                            label: artist.name,
                            selected: artistFilter == artist.slug,
                            onSelected: (on) => ref.read(galleryArtistFilterProvider.notifier).set(on ? artist.slug : null),
                          ),
                      ],
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.palette_outlined,
                      title: t('Aucune œuvre pour ce choix'),
                      message: t('Élargissez la sélection pour découvrir toute la galerie.'),
                      actionLabel: t('Tout afficher'),
                      onAction: () {
                        ref.read(galleryArtistFilterProvider.notifier).set(null);
                        if (availableOnly) ref.read(galleryAvailableOnlyProvider.notifier).toggle();
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.md, HSpace.gutter, HSpace.xl),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = (constraints.crossAxisExtent - HSpace.md) / 2;
                        return SliverGrid.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: HSpace.md,
                            mainAxisSpacing: HSpace.lg,
                            mainAxisExtent: width / ArtworkCard.aspect + _textHeight,
                          ),
                          itemCount: visible.length,
                          itemBuilder: (context, i) => ArtworkCard(
                            artwork: visible[i],
                            onTap: () => context.push('/galerie/${visible[i].slug}'),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _grid(BuildContext context, {required int itemCount, required WidgetBuilder builder}) => GridView.builder(
        padding: const EdgeInsets.all(HSpace.gutter),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: HSpace.md,
          mainAxisSpacing: HSpace.lg,
          childAspectRatio: ArtworkCard.aspect,
        ),
        itemCount: itemCount,
        itemBuilder: (context, _) => builder(context),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: HSpace.xs),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (on) {
            HapticFeedback.selectionClick();
            onSelected(on);
          },
        ),
      );
}
