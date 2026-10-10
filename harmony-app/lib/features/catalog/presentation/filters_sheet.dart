import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/fcfa.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_sheet.dart';
import '../application/search_criteria.dart';
import '../domain/apartment.dart';

/// Feuille « Filtres » : budget par nuit et équipements indispensables.
Future<void> showFiltersSheet(BuildContext context) {
  return showHarmonySheet<void>(
    context,
    title: 'Filtres',
    builder: (_) => const _FiltersBody(),
  );
}

class _FiltersBody extends ConsumerStatefulWidget {
  const _FiltersBody();

  @override
  ConsumerState<_FiltersBody> createState() => _FiltersBodyState();
}

class _FiltersBodyState extends ConsumerState<_FiltersBody> {
  static const _step = 5000;

  late RangeValues _budget;
  late Set<Amenity> _amenities;

  @override
  void initState() {
    super.initState();
    final c = ref.read(searchCriteriaProvider);
    _budget = RangeValues((c.minPrice ?? budgetFloor).toDouble(), (c.maxPrice ?? budgetCeiling).toDouble());
    _amenities = {...c.amenities};
  }

  String _label(double v) => v >= budgetCeiling ? '${fcfa(budgetCeiling)} et +' : fcfa(v.round());

  void _apply() {
    HapticFeedback.selectionClick();
    ref.read(searchCriteriaProvider.notifier).setAdvanced(
          minPrice: _budget.start.round(),
          maxPrice: _budget.end.round(),
          amenities: _amenities,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Budget par nuit', style: context.tt.titleMedium),
          Semantics(
            liveRegion: true,
            child: Text('${_label(_budget.start)} – ${_label(_budget.end)}', style: context.tt.bodyMedium),
          ),
          RangeSlider(
            values: _budget,
            min: budgetFloor.toDouble(),
            max: budgetCeiling.toDouble(),
            divisions: (budgetCeiling - budgetFloor) ~/ _step,
            labels: RangeLabels(_label(_budget.start), _label(_budget.end)),
            onChanged: (v) => setState(() => _budget = v),
          ),
          const SizedBox(height: HSpace.md),
          Text('Équipements', style: context.tt.titleMedium),
          const SizedBox(height: HSpace.xs),
          Wrap(
            spacing: HSpace.xs,
            runSpacing: HSpace.xs,
            children: [
              for (final a in Amenity.values)
                FilterChip(
                  label: Text(a.label),
                  selected: _amenities.contains(a),
                  onSelected: (on) => setState(() => on ? _amenities.add(a) : _amenities.remove(a)),
                ),
            ],
          ),
          const SizedBox(height: HSpace.lg),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _budget = RangeValues(budgetFloor.toDouble(), budgetCeiling.toDouble());
                  _amenities.clear();
                }),
                child: const Text('Effacer'),
              ),
              const SizedBox(width: HSpace.sm),
              Expanded(child: FilledButton(onPressed: _apply, child: const Text('Appliquer'))),
            ],
          ),
        ],
      ),
    );
  }
}
