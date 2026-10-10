import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_logo.dart';

/// Ouverture : l'arche du monogramme se trace, le logotype apparaît,
/// puis l'accueil. Un toucher passe directement à l'accueil.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _c
      ..duration = reduceMotion(context) ? const Duration(milliseconds: 600) : const Duration(milliseconds: 2000)
      ..forward().whenComplete(_finish);
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    context.go('/accueil');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _interval(double t, double a, double b) => Curves.easeOut.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HPalette.navy,
      body: Semantics(
        button: true,
        label: t('HARMONY HOME. Toucher pour continuer'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _c.stop();
            _finish();
          },
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final progress = reduceMotion(context) ? 1.0 : _c.value;
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HarmonyMark(size: 92, progress: _interval(progress, 0, .6), color: HPalette.champagne),
                    const SizedBox(height: HSpace.lg),
                    Opacity(
                      opacity: _interval(progress, .45, .8),
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - _interval(progress, .45, .8))),
                        child: const HarmonyWordmark(scale: 1.4, color: HPalette.ivory, accentColor: HPalette.champagne),
                      ),
                    ),
                    const SizedBox(height: HSpace.md),
                    Opacity(
                      opacity: _interval(progress, .65, .95),
                      child: Text(
                        t('Conciergerie immobilière · Lomé'),
                        style: HText.bodySmall.copyWith(color: HPalette.champagneSoft),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
