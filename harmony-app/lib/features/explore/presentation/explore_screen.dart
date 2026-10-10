import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../catalog/application/search_criteria.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/apartment.dart';
import '../../catalog/presentation/filters_sheet.dart';
import '../../catalog/presentation/property_card.dart';
import '../../catalog/presentation/search_sheets.dart';

/// Explorer : critères en puces modifiables, filtre par type, résultats.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criteria = ref.watch(searchCriteriaProvider);
    final results = ref.watch(searchResultsProvider);
    final zone = criteria.zoneId == null ? null : ref.watch(zoneByIdProvider(criteria.zoneId!));
    final notifier = ref.read(searchCriteriaProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
        actions: [
          if (!criteria.isEmpty)
            TextButton(onPressed: notifier.reset, child: const Text('Réinitialiser')),
          const SizedBox(width: HSpace.xs),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: HSize.touch,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
              children: [
                _CriteriaChip(
                  icon: Icons.tune_rounded,
                  label: criteria.advancedCount == 0 ? 'Filtres' : 'Filtres · ${criteria.advancedCount}',
                  active: criteria.advancedCount > 0,
                  onTap: () => showFiltersSheet(context),
                ),
                _CriteriaChip(
                  icon: Icons.place_outlined,
                  label: zone?.name ?? 'Toutes les zones',
                  active: zone != null,
                  onTap: () => pickZone(context, ref),
                ),
                _CriteriaChip(
                  icon: Icons.calendar_today_outlined,
                  label: criteria.dates == null ? 'Dates' : dateRangeLabel(criteria.dates!),
                  active: criteria.dates != null,
                  onTap: () => pickDates(context, ref),
                ),
                _CriteriaChip(
                  icon: Icons.people_outline_rounded,
                  label: plural(criteria.guests, 'voyageur'),
                  active: criteria.guests > 1,
                  onTap: () => pickGuests(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: HSpace.xs),
          SizedBox(
            height: HSize.touch,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
              children: [
                for (final type in ApartmentType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: HSpace.xs),
                    child: ChoiceChip(
                      label: Text(type.label),
                      selected: criteria.type == type,
                      onSelected: (on) {
                        HapticFeedback.selectionClick();
                        notifier.setType(on ? type : null);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.sm, HSpace.gutter, 0),
            child: Semantics(
              liveRegion: true,
              child: Text(
                results.isEmpty ? 'Aucun bien' : '${plural(results.length, 'bien')} à Lomé',
                style: context.tt.bodyMedium,
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? EmptyState(
                    icon: Icons.travel_explore_rounded,
                    title: 'Aucun bien ne correspond',
                    message: 'Élargissez la zone, le budget, les équipements ou le nombre de voyageurs.',
                    actionLabel: 'Réinitialiser les filtres',
                    onAction: notifier.reset,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.md, HSpace.gutter, HSpace.xl),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: HSpace.lg),
                    itemBuilder: (context, i) => PropertyCard(
                      apartment: results[i],
                      onTap: () => context.push('/bien/${results[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CriteriaChip extends StatelessWidget {
  const _CriteriaChip({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: HSpace.xs),
      child: ActionChip(
        avatar: Icon(icon, size: HSize.iconSm, color: active ? context.cs.onPrimary : context.hc.accentText),
        label: Text(label, style: HText.labelSmall.copyWith(color: active ? context.cs.onPrimary : context.cs.onSurface)),
        backgroundColor: active ? context.cs.primary : null,
        onPressed: onTap,
      ),
    );
  }
}
