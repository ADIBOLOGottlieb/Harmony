import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_image.dart';
import '../../../core/widgets/harmony_logo.dart';
import '../../../core/widgets/section_header.dart';
import '../../catalog/application/search_criteria.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/presentation/property_card.dart';
import 'search_panel.dart';
import 'zone_card.dart';

/// Accueil : bandeau photo et recherche, puis « À la une », « Par zone », « Nouveautés ».
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _heroHeight = 340.0;
  static const _panelOverlap = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredApartmentsProvider);
    final newest = ref.watch(newestApartmentsProvider);
    final zones = ref.watch(zonesProvider);
    final counts = ref.watch(apartmentCountByZoneProvider);
    final heroPhoto = featured.isEmpty ? null : featured.first.cover;
    final reduced = reduceMotion(context);
    final offline = ref.watch(catalogProvider.select((c) => c.offline));

    Widget reveal(Widget child, int order) => reduced
        ? child
        : child
            .animate(delay: (120 * order).ms)
            .fadeIn(duration: HMotion.slow, curve: HMotion.enter)
            .slideY(begin: .08, end: 0, duration: HMotion.slow, curve: HMotion.enter);

    void openApartment(String id) => context.push('/bien/$id');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height: _heroHeight,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (heroPhoto != null) HarmonyImage(heroPhoto),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [HPalette.photoScrimDark, HPalette.photoScrimClear, HPalette.photoScrimDark],
                              stops: [0, .22, .68],
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.sm, HSpace.gutter, _panelOverlap + HSpace.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const HarmonyLogo(color: HPalette.white),
                                    const Spacer(),
                                    if (offline)
                                      _OfflinePill(onRetry: () => ref.read(catalogProvider.notifier).refresh()),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  'CONCIERGERIE IMMOBILIÈRE · LOMÉ',
                                  style: HText.overline.copyWith(color: HPalette.champagneSoft),
                                ),
                                const SizedBox(height: HSpace.xs),
                                Text(
                                  'Votre adresse\nd’exception à Lomé',
                                  style: HText.display.copyWith(color: HPalette.white, fontSize: 30),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(HSpace.gutter, _heroHeight - _panelOverlap, HSpace.gutter, 0),
                    child: reveal(
                      SearchPanel(onSearch: () => context.go('/explorer')),
                      1,
                    ),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: HSpace.xl)),
            SliverToBoxAdapter(
              child: reveal(
                SectionHeader(
                  overline: 'Sélection',
                  title: 'Appartements à la une',
                  actionLabel: 'Tout voir',
                  onAction: () {
                    ref.read(searchCriteriaProvider.notifier).reset();
                    context.go('/explorer');
                  },
                ),
                2,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 372,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.md, HSpace.gutter, HSpace.xs),
                  itemCount: featured.length,
                  separatorBuilder: (_, _) => const SizedBox(width: HSpace.md),
                  itemBuilder: (context, i) => SizedBox(
                    width: HSize.featuredCardWidth,
                    child: PropertyCard(apartment: featured[i], onTap: () => openApartment(featured[i].id)),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: HSpace.lg)),
            const SliverToBoxAdapter(child: SectionHeader(overline: 'Quartiers', title: 'Par zone')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: HSize.zoneCardHeight + HSpace.md * 2,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: HSpace.gutter, vertical: HSpace.md),
                  itemCount: zones.length,
                  separatorBuilder: (_, _) => const SizedBox(width: HSpace.sm),
                  itemBuilder: (context, i) => ZoneCard(
                    zone: zones[i],
                    count: counts[zones[i].id] ?? 0,
                    onTap: () {
                      ref.read(searchCriteriaProvider.notifier).setZone(zones[i].id);
                      context.go('/explorer');
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: HSpace.md)),
            const SliverToBoxAdapter(child: SectionHeader(overline: 'Récemment ajoutés', title: 'Nouveautés')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.md, HSpace.gutter, HSpace.lg),
              sliver: SliverList.separated(
                itemCount: newest.length,
                separatorBuilder: (_, _) => const SizedBox(height: HSpace.lg),
                itemBuilder: (context, i) => PropertyCard(apartment: newest[i], onTap: () => openApartment(newest[i].id)),
              ),
            ),
            if (AppConfig.salesSectionEnabled)
              const SliverToBoxAdapter(child: SectionHeader(overline: 'Bientôt', title: 'À vendre et programmes neufs')),
            const SliverToBoxAdapter(child: SizedBox(height: HSpace.lg)),
          ],
        ),
      ),
    );
  }
}

/// Catalogue servi depuis le cache : on le dit, et on propose de réessayer.
class _OfflinePill extends StatelessWidget {
  const _OfflinePill({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Hors connexion, catalogue enregistré. Toucher pour réessayer.',
      excludeSemantics: true,
      child: Material(
        color: HPalette.photoGlass,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onRetry();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: HSize.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: HSpace.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: HSize.iconSm, color: HPalette.white),
                  const SizedBox(width: HSpace.xxs),
                  Text('Hors connexion', style: HText.labelSmall.copyWith(color: HPalette.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
