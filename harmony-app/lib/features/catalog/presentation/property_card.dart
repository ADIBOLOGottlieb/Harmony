import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_image.dart';
import '../../../core/widgets/status_badge.dart';
import '../application/favorites.dart';
import '../data/catalog_repository.dart';
import '../domain/apartment.dart';
import 'spec_row.dart';

BadgeTone toneOf(ApartmentStatus s) => switch (s) {
      ApartmentStatus.available => BadgeTone.positive,
      ApartmentStatus.occupied => BadgeTone.caution,
      ApartmentStatus.maintenance => BadgeTone.neutral,
    };

/// Carte de bien : grande photo, statut, favori, zone, caractéristiques, prix.
class PropertyCard extends ConsumerWidget {
  const PropertyCard({super.key, required this.apartment, required this.onTap});

  final Apartment apartment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = ref.watch(zoneByIdProvider(apartment.zoneId));
    final nightly = price(apartment.pricePerNight);
    // `container` : le bouton favori reste un nœud distinct pour les lecteurs
    // d'écran, au lieu d'être fusionné avec la carte (qui ouvrirait la fiche).
    return Semantics(
      container: true,
      button: true,
      label: t('{title}, {type} à {zone}. {status}. {price} par nuit.', {
        'title': apartment.title,
        'type': apartment.type.label,
        'zone': zone?.name ?? '',
        'status': apartment.status.label,
        'price': nightly,
      }),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: HSize.photoAspect,
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(HRadius.md), boxShadow: HShadows.card),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(HRadius.md),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(tag: apartment.heroTag, child: HarmonyImage(apartment.cover)),
                      Positioned(
                        left: HSpace.sm,
                        top: HSpace.sm,
                        child: ExcludeSemantics(
                          child: StatusBadge(label: apartment.status.label, tone: toneOf(apartment.status)),
                        ),
                      ),
                      Positioned(
                        right: HSpace.xs,
                        top: HSpace.xs,
                        child: FavoriteButton(apartmentId: apartment.id, title: apartment.title),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: HSpace.sm),
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${apartment.type.label} · ${zone?.name ?? ''}'.toUpperCase(),
                          style: context.tt.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.star_rounded, size: HSize.iconSm, color: context.hc.accent),
                      const SizedBox(width: 2),
                      Text(apartment.rating.toStringAsFixed(1).replaceAll('.', ','), style: HText.labelSmall.copyWith(color: context.cs.onSurface)),
                    ],
                  ),
                  const SizedBox(height: HSpace.xxs),
                  Text(apartment.title, style: context.tt.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: HSpace.xs),
                  SpecRow(apartment: apartment),
                  const SizedBox(height: HSpace.xs),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: nightly, style: HText.price.copyWith(fontSize: 18, color: context.cs.onSurface)),
                        TextSpan(text: t(' / nuit'), style: context.tt.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton cœur en verre dépoli, posé sur les photos.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.apartmentId, required this.title});

  final String apartmentId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider.select((f) => f.contains(apartmentId)));
    return Semantics(
      container: true,
      button: true,
      toggled: isFavorite,
      label: isFavorite ? t('Retirer {title} des favoris', {'title': title}) : t('Ajouter {title} aux favoris', {'title': title}),
      excludeSemantics: true,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: HPalette.photoGlass,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(favoritesProvider.notifier).toggle(apartmentId);
              },
              child: SizedBox.square(
                dimension: HSize.touch - 8,
                child: AnimatedSwitcher(
                  duration: HMotion.base,
                  transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                  child: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(isFavorite),
                    size: HSize.icon,
                    color: isFavorite ? HPalette.champagne : HPalette.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
