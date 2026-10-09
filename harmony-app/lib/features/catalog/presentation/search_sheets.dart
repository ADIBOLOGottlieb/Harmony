import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_sheet.dart';
import '../application/search_criteria.dart';
import '../data/catalog_repository.dart';

/// Choix de la zone (ou « Toutes les zones »).
Future<void> pickZone(BuildContext context, WidgetRef ref) {
  return showHarmonySheet<void>(
    context,
    title: 'Où souhaitez-vous séjourner ?',
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final zones = ref.watch(zonesProvider);
        final counts = ref.watch(apartmentCountByZoneProvider);
        final selected = ref.watch(searchCriteriaProvider).zoneId;
        void choose(String? id) {
          HapticFeedback.selectionClick();
          ref.read(searchCriteriaProvider.notifier).setZone(id);
          Navigator.of(context).pop();
        }

        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: HSpace.lg),
          children: [
            _ZoneTile(label: 'Toutes les zones', subtitle: 'Lomé et environs', selected: selected == null, onTap: () => choose(null)),
            for (final z in zones)
              _ZoneTile(
                label: z.name,
                subtitle: '${z.city} · ${counts[z.id] ?? 0} bien${(counts[z.id] ?? 0) > 1 ? 's' : ''}',
                selected: selected == z.id,
                onTap: () => choose(z.id),
              ),
          ],
        );
      },
    ),
  );
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({required this.label, required this.subtitle, required this.selected, required this.onTap});

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
      leading: Icon(Icons.place_outlined, color: context.hc.accentText),
      title: Text(label),
      subtitle: Text(subtitle),
      trailing: selected ? Icon(Icons.check_rounded, color: context.cs.primary) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}

/// Sélecteur de dates d'arrivée et de départ.
Future<void> pickDates(BuildContext context, WidgetRef ref) async {
  final now = DateUtils.dateOnly(DateTime.now());
  final current = ref.read(searchCriteriaProvider).dates;
  final range = await showDateRangePicker(
    context: context,
    firstDate: now,
    lastDate: now.add(const Duration(days: 365)),
    initialDateRange: current,
    helpText: 'Vos dates de séjour',
    saveText: 'Valider',
    fieldStartLabelText: 'Arrivée',
    fieldEndLabelText: 'Départ',
  );
  if (range != null) ref.read(searchCriteriaProvider.notifier).setDates(range);
}

/// Nombre de voyageurs.
Future<void> pickGuests(BuildContext context, WidgetRef ref) {
  return showHarmonySheet<void>(
    context,
    title: 'Voyageurs',
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final guests = ref.watch(searchCriteriaProvider).guests;
        final notifier = ref.read(searchCriteriaProvider.notifier);
        return Padding(
          padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Adultes et enfants', style: context.tt.titleMedium),
                        Text('Capacité maximale du logement', style: context.tt.bodyMedium),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'Retirer un voyageur',
                    onPressed: guests > 1 ? () => notifier.setGuests(guests - 1) : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(
                    width: HSize.touch,
                    child: Text('$guests', textAlign: TextAlign.center, style: context.tt.titleLarge),
                  ),
                  IconButton.outlined(
                    tooltip: 'Ajouter un voyageur',
                    onPressed: guests < 16 ? () => notifier.setGuests(guests + 1) : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: HSpace.lg),
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Valider')),
            ],
          ),
        );
      },
    ),
  );
}
