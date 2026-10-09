import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

enum BadgeTone { positive, caution, neutral }

/// Pastille de statut lisible sur une photo comme sur un fond uni.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final dot = switch (tone) {
      BadgeTone.positive => context.hc.success,
      BadgeTone.caution => context.hc.warning,
      BadgeTone.neutral => context.hc.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HSpace.sm - 2, vertical: HSpace.xxs + 1),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLowest.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(HRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: HSpace.xs - 2),
          Text(label, style: HText.labelSmall.copyWith(fontSize: 12, color: context.cs.onSurface)),
        ],
      ),
    );
  }
}
