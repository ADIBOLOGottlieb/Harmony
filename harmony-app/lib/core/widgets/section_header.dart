import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Titre de section : surtitre doré facultatif, titre serif, action « Tout voir ».
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.overline, this.actionLabel, this.onAction});

  final String title;
  final String? overline;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) ...[
                  Text(overline!.toUpperCase(), style: context.tt.labelSmall),
                  const SizedBox(height: HSpace.xxs),
                ],
                Semantics(header: true, child: Text(title, style: context.tt.titleLarge)),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
