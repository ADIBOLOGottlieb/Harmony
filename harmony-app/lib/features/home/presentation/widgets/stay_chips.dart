import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/rooms_repository.dart';
import '../../domain/room.dart';

/// Sélecteur de séance : la puce active s'illumine d'or.
class StayChips extends ConsumerWidget {
  const StayChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedStayProvider);
    return SizedBox(
      height: HSize.buttonHeight + HSpace.xs,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: HSpace.lg),
        itemCount: StayType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: HSpace.xs),
        itemBuilder: (context, i) {
          final stay = StayType.values[i];
          return _StayChip(
            stay: stay,
            selected: stay == selected,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(selectedStayProvider.notifier).select(stay);
            },
          );
        },
      ),
    );
  }
}

class _StayChip extends StatelessWidget {
  const _StayChip({required this.stay, required this.selected, required this.onTap});

  final StayType stay;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${stay.label}, ${stay.screening}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: HMotion.base,
          curve: HMotion.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: HSpace.md),
          margin: const EdgeInsets.symmetric(vertical: HSpace.xxs),
          decoration: BoxDecoration(
            gradient: selected ? HGradients.goldSheen : null,
            color: selected ? null : HColors.nightRaised,
            borderRadius: BorderRadius.circular(HRadius.pill),
            border: Border.all(color: selected ? HColors.goldLight : HColors.hairline),
            boxShadow: selected ? HShadows.goldGlow : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: HMotion.base,
                style: HText.label.copyWith(color: selected ? HColors.night : HColors.ivory),
                child: Text(stay.label),
              ),
              AnimatedDefaultTextStyle(
                duration: HMotion.base,
                style: HText.creditSmall.copyWith(color: selected ? HColors.velvetDeep : HColors.ivoryFaint),
                child: Text(stay.screening.toUpperCase()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
