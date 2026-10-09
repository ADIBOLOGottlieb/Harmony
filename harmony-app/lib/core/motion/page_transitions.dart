import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import 'motion.dart';

/// Transition douce entre écrans : fondu et léger glissement vers le haut.
/// Les images partagées (Hero) volent par-dessus. Fondu seul si l'utilisateur
/// réduit les animations.
CustomTransitionPage<void> softPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: HMotion.slow,
    reverseTransitionDuration: HMotion.base,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: HMotion.enter, reverseCurve: HMotion.exit);
      final fade = FadeTransition(opacity: curved, child: child);
      if (reduceMotion(context)) return fade;
      return SlideTransition(
        position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(curved),
        child: fade,
      );
    },
  );
}
