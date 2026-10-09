import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Ouvre une feuille du bas au style HARMONY HOME : titre serif, contenu,
/// bouton d'action principal collé en bas.
Future<T?> showHarmonySheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.md),
            child: Text(title, style: context.tt.titleLarge),
          ),
          Flexible(child: builder(context)),
        ],
      ),
    ),
  );
}
