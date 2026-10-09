import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// État vide soigné : pictogramme, titre, explication et action suivante.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(HSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: HSize.avatar + HSpace.md,
              height: HSize.avatar + HSpace.md,
              decoration: BoxDecoration(color: context.hc.accentSoft, shape: BoxShape.circle),
              child: Icon(icon, size: HSize.icon * 1.6, color: context.hc.accentText),
            ),
            const SizedBox(height: HSpace.lg),
            Text(title, style: context.tt.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: HSpace.xs),
            Text(message, style: context.tt.bodyMedium, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: HSpace.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
