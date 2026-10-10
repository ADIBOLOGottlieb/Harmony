import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/design_tokens.dart';
import '../../catalog/application/search_criteria.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/presentation/search_sheets.dart';

/// Bloc de recherche du bandeau d'accueil : zone, dates, voyageurs.
class SearchPanel extends ConsumerWidget {
  const SearchPanel({super.key, required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(searchCriteriaProvider);
    final zone = c.zoneId == null ? null : ref.watch(zoneByIdProvider(c.zoneId!));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainer,
        borderRadius: BorderRadius.circular(HRadius.lg),
        boxShadow: HShadows.floating,
      ),
      child: Padding(
        padding: const EdgeInsets.all(HSpace.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Field(
              icon: Icons.place_outlined,
              label: t('Destination'),
              value: zone?.name ?? t('Toutes les zones de Lomé'),
              onTap: () => pickZone(context, ref),
            ),
            const Divider(indent: HSpace.xxl + HSpace.xs),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    icon: Icons.calendar_today_outlined,
                    label: t('Dates'),
                    value: c.dates == null ? 'Choisir' : dateRangeLabel(c.dates!),
                    onTap: () => pickDates(context, ref),
                  ),
                ),
                Container(width: 1, height: HSpace.xl, color: context.hc.hairline),
                Expanded(
                  child: _Field(
                    icon: Icons.people_outline_rounded,
                    label: t('Voyageurs'),
                    value: plural(c.guests, 'voyageur'),
                    onTap: () => pickGuests(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: HSpace.xs),
            FilledButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
              label: Text(t('Rechercher')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label : $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: HSize.touch + HSpace.xs),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HSpace.sm, vertical: HSpace.xs),
            child: Row(
              children: [
                Icon(icon, size: HSize.icon, color: context.hc.accentText),
                const SizedBox(width: HSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label.toUpperCase(), style: HText.overline.copyWith(fontSize: 10, color: context.hc.textMuted)),
                      const SizedBox(height: 2),
                      Text(value, style: context.tt.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
