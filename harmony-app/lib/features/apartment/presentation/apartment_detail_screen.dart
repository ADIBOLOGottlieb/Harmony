import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/fcfa.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/harmony_image.dart';
import '../../../core/widgets/status_badge.dart';
import '../../catalog/application/search_criteria.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/apartment.dart';
import '../../catalog/presentation/property_card.dart';
import '../../catalog/presentation/spec_row.dart';

/// Fiche bien : carrousel plein écran, informations, équipements, règlement,
/// localisation, avis, concierge, et barre de réservation collante.
class ApartmentDetailScreen extends ConsumerWidget {
  const ApartmentDetailScreen({super.key, required this.apartmentId});

  final String apartmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(apartmentByIdProvider(apartmentId));
    if (a == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.home_work_outlined,
          title: 'Bien introuvable',
          message: 'Ce logement n’est plus proposé à la location.',
          actionLabel: 'Retour à l’accueil',
          onAction: () => context.go('/accueil'),
        ),
      );
    }
    final zone = ref.watch(zoneByIdProvider(a.zoneId));
    final dates = ref.watch(searchCriteriaProvider).dates;
    final galleryHeight = MediaQuery.sizeOf(context).height * .46;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Gallery(apartment: a, height: galleryHeight)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.lg, HSpace.gutter, 0),
              sliver: SliverList.list(
                children: [
                  Text('${a.type.label} · ${zone?.name ?? ''}'.toUpperCase(), style: context.tt.labelSmall),
                  const SizedBox(height: HSpace.xs),
                  Text(a.title, style: context.tt.headlineMedium),
                  const SizedBox(height: HSpace.xs),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: HSize.icon, color: context.hc.accent),
                      const SizedBox(width: HSpace.xxs),
                      Text(
                        '${a.rating.toStringAsFixed(1).replaceAll('.', ',')} · ${plural(a.reviewCount, 'avis', 'avis')}',
                        style: HText.labelSmall.copyWith(color: context.cs.onSurface),
                      ),
                      const SizedBox(width: HSpace.sm),
                      StatusBadge(label: a.status.label, tone: toneOf(a.status)),
                    ],
                  ),
                  const SizedBox(height: HSpace.md),
                  SpecRow(apartment: a),
                  const _SectionDivider(),
                  Text(a.description, style: context.tt.bodyLarge),
                  const _SectionDivider(),
                  _SectionTitle('Équipements'),
                  Wrap(
                    spacing: HSpace.xs,
                    runSpacing: HSpace.xs,
                    children: [
                      for (final amenity in a.amenities)
                        Chip(
                          avatar: Icon(amenity.icon, size: HSize.iconSm, color: context.hc.accentText),
                          label: Text(amenity.label),
                        ),
                    ],
                  ),
                  if (a.shortStays != null) ...[
                    const _SectionDivider(),
                    _SectionTitle('Séjours courts'),
                    Text('Ce logement accepte aussi des séjours de quelques heures.', style: context.tt.bodyMedium),
                    const SizedBox(height: HSpace.sm),
                    if (a.shortStays!.threeHours != null)
                      _PriceLine(label: 'Créneau de 3 heures', amount: a.shortStays!.threeHours!),
                    if (a.shortStays!.day != null) _PriceLine(label: 'Journée (sans nuitée)', amount: a.shortStays!.day!),
                  ],
                  const _SectionDivider(),
                  _SectionTitle('Tarifs et caution'),
                  _PriceLine(label: 'Prix par nuit', amount: a.pricePerNight),
                  _PriceLine(label: 'Caution (restituée après l’état des lieux)', amount: a.deposit),
                  const _SectionDivider(),
                  _SectionTitle('Règlement'),
                  for (final rule in a.rules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: HSpace.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: HSpace.xs),
                            child: Icon(Icons.circle, size: 6, color: context.hc.accent),
                          ),
                          const SizedBox(width: HSpace.sm),
                          Expanded(child: Text(rule, style: context.tt.bodyLarge)),
                        ],
                      ),
                    ),
                  const _SectionDivider(),
                  _SectionTitle('Localisation'),
                  _LocationCard(apartment: a, zoneName: zone?.name),
                  const _SectionDivider(),
                  _SectionTitle('Avis'),
                  _ReviewsSummary(apartment: a),
                  const _SectionDivider(),
                  _SectionTitle('Votre concierge'),
                  const _ConciergeCard(),
                  const SizedBox(height: HSize.bookingBar + HSpace.xl),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BookingBar(apartment: a, dates: dates),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.apartment, required this.height});

  final Apartment apartment;
  final double height;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final a = widget.apartment;
    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: a.photos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final image = HarmonyImage(a.photos[i], semanticLabel: 'Photo ${i + 1} sur ${a.photos.length} de ${a.title}');
              return i == 0 ? Hero(tag: a.heroTag, child: image) : image;
            },
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [HPalette.photoScrimDark, HPalette.photoScrimClear],
                  stops: [0, .3],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: HSpace.md, vertical: HSpace.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GlassButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Retour',
                    onTap: () => context.canPop() ? context.pop() : context.go('/accueil'),
                  ),
                  const Spacer(),
                  FavoriteButton(apartmentId: a.id, title: a.title),
                ],
              ),
            ),
          ),
          Positioned(
            right: HSpace.md,
            bottom: HSpace.md,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: HSpace.sm, vertical: HSpace.xxs),
              decoration: BoxDecoration(color: HPalette.photoGlass, borderRadius: BorderRadius.circular(HRadius.pill)),
              child: Text(
                '${_page + 1} / ${a.photos.length}',
                style: HText.labelSmall.copyWith(color: HPalette.white),
                semanticsLabel: 'Photo ${_page + 1} sur ${a.photos.length}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: HPalette.photoGlass,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(dimension: HSize.touch - 8, child: Icon(icon, color: HPalette.white, size: HSize.icon)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: HSpace.lg),
        child: Divider(),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: HSpace.sm),
        child: Semantics(header: true, child: Text(text, style: context.tt.titleLarge)),
      );
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: HSpace.xs),
        child: Row(
          children: [
            Expanded(child: Text(label, style: context.tt.bodyLarge)),
            Text(fcfa(amount), style: HText.titleSans.copyWith(color: context.cs.onSurface)),
          ],
        ),
      );
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.apartment, required this.zoneName});

  final Apartment apartment;
  final String? zoneName;

  Future<void> _openMaps(BuildContext context) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${apartment.latitude},${apartment.longitude}',
    });
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d’ouvrir la carte.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: HSize.touch,
                  height: HSize.touch,
                  decoration: BoxDecoration(color: context.hc.accentSoft, borderRadius: BorderRadius.circular(HRadius.sm)),
                  child: Icon(Icons.place_outlined, color: context.hc.accentText),
                ),
                const SizedBox(width: HSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zoneName ?? 'Lomé', style: context.tt.titleMedium),
                      Text(apartment.address, style: context.tt.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: HSpace.sm),
            Text(
              'L’adresse exacte et l’itinéraire détaillé vous sont communiqués après confirmation de la réservation.',
              style: context.tt.bodyMedium,
            ),
            const SizedBox(height: HSpace.sm),
            OutlinedButton.icon(
              onPressed: () => _openMaps(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Voir le quartier sur la carte'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsSummary extends StatelessWidget {
  const _ReviewsSummary({required this.apartment});

  final Apartment apartment;

  @override
  Widget build(BuildContext context) {
    final full = apartment.rating.floor();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HSpace.md),
        child: Row(
          children: [
            Text(apartment.rating.toStringAsFixed(1).replaceAll('.', ','), style: context.tt.displaySmall),
            const SizedBox(width: HSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Icon(
                          i < full ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: HSize.icon,
                          color: context.hc.accent,
                        ),
                    ],
                  ),
                  const SizedBox(height: HSpace.xxs),
                  Text('${plural(apartment.reviewCount, 'avis', 'avis')} de voyageurs après leur séjour', style: context.tt.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConciergeCard extends StatelessWidget {
  const _ConciergeCard();

  Future<void> _contact(BuildContext context, {required bool whatsapp}) async {
    const phone = AppConfig.conciergePhone;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le numéro du concierge sera bientôt disponible.')),
      );
      return;
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = whatsapp ? Uri.https('wa.me', '/$digits') : Uri(scheme: 'tel', path: phone);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d’ouvrir l’application.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Une question avant de réserver ? Notre concierge vous répond 7 j/7.', style: context.tt.bodyLarge),
            const SizedBox(height: HSpace.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contact(context, whatsapp: false),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Appeler'),
                  ),
                ),
                const SizedBox(width: HSpace.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _contact(context, whatsapp: true),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre collante : prix (et total si des dates sont choisies) + « Réserver ».
class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.apartment, required this.dates});

  final Apartment apartment;
  final DateTimeRange? dates;

  @override
  Widget build(BuildContext context) {
    final nights = dates == null ? 0 : nightsIn(dates!);
    final subtitle = nights > 0
        ? '${plural(nights, 'nuit')} · ${fcfa(apartment.pricePerNight * nights)}'
        : 'par nuit · caution ${fcfa(apartment.deposit)}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLowest,
        border: Border(top: BorderSide(color: context.hc.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.sm, HSpace.gutter, HSpace.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fcfa(apartment.pricePerNight), style: HText.price.copyWith(color: context.cs.onSurface)),
                    Text(subtitle, style: context.tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: HSpace.sm),
              FilledButton(
                onPressed: apartment.isBookable
                    ? () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(
                            content: Text('La réservation en ligne arrive à la prochaine étape : calendrier, récapitulatif et paiement.'),
                          ));
                      }
                    : null,
                child: Text(apartment.isBookable ? 'Réserver' : apartment.status.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
