import 'package:flutter/material.dart';
import '../../../core/format/dates.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_image.dart';
import '../../catalog/domain/zone.dart';

/// Vignette de quartier : photo, voile dégradé, nom et nombre de biens.
class ZoneCard extends StatelessWidget {
  const ZoneCard({super.key, required this.zone, required this.count, required this.onTap});

  final Zone zone;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${zone.name}, ${plural(count, 'bien')}',
      excludeSemantics: true,
      child: SizedBox(
        width: HSize.zoneCardWidth,
        height: HSize.zoneCardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HRadius.md),
          child: Material(
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HarmonyImage(zone.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [HPalette.photoScrimClear, HPalette.photoScrimDark],
                        stops: [.35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: HSpace.sm,
                    right: HSpace.sm,
                    bottom: HSpace.sm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(zone.name, style: HText.title.copyWith(color: HPalette.white, fontSize: 18)),
                        Text('$count bien${count > 1 ? 's' : ''}', style: HText.bodySmall.copyWith(color: HPalette.champagneSoft)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
