import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/film_grain.dart';
import 'scene_art.dart';

class _Scene {
  const _Scene(this.number, this.kind, this.title, this.body);

  final int number;
  final SceneKind kind;
  final String title;
  final String body;
}

const _scenes = [
  _Scene(1, SceneKind.reel, 'Choisissez\nvotre séance',
      'Trois heures, une nuit ou tout un week-end : réservez l’instant exact, parmi les disponibilités réelles.'),
  _Scene(2, SceneKind.bulbs, 'Composez\nl’ambiance',
      'Essentiel, Romantique, Gourmand ou Prestige : décor, lumière et dîner servis à l’heure que vous choisissez.'),
  _Scene(3, SceneKind.route, 'Arrivez\nsans détour',
      'Itinéraire, repères en photos et code d’accès : vous trouvez la porte sans passer un seul appel.'),
];

/// Trois scènes d'introduction. Changement de scène = flash de pellicule,
/// tic haptique, et parallaxe entre l'illustration (lente) et le texte (rapide).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _pager = PageController();
  late final AnimationController _flash = AnimationController(vsync: this, duration: HMotion.base);
  int _index = 0;

  bool get _isLast => _index == _scenes.length - 1;

  void _onPageChanged(int i) {
    setState(() => _index = i);
    HapticFeedback.selectionClick();
    if (!reduceMotion(context)) _flash.forward(from: 0);
  }

  void _next() {
    if (_isLast) {
      context.go('/home');
    } else {
      _pager.nextPage(duration: HMotion.scene, curve: HMotion.emphasized);
    }
  }

  @override
  void dispose() {
    _pager.dispose();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: HGradients.projectorBeam)),
          PageView.builder(
            controller: _pager,
            itemCount: _scenes.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _pager,
              builder: (context, _) {
                final page = _pager.hasClients && _pager.position.haveDimensions ? _pager.page! : _index.toDouble();
                return _SceneView(scene: _scenes[i], offset: page - i, active: i == _index);
              },
            ),
          ),
          AnimatedBuilder(
            animation: _flash,
            builder: (context, _) => _flash.isAnimating
                ? IgnorePointer(child: ColoredBox(color: HColors.ivory.withValues(alpha: (1 - _flash.value) * .14)))
                : const SizedBox.shrink(),
          ),
          const Vignette(),
          const FilmGrain(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(HSpace.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      _FilmStrip(count: _scenes.length, index: _index),
                      const Spacer(),
                      if (!_isLast)
                        TextButton(
                          onPressed: () => context.go('/home'),
                          style: TextButton.styleFrom(minimumSize: const Size(HSize.touch, HSize.touch)),
                          child: Text('Passer', style: HText.label.copyWith(color: HColors.ivoryMuted)),
                        ),
                    ],
                  ),
                  const Spacer(),
                  GoldPillButton(
                    label: _isLast ? 'Entrer dans la salle' : 'Scène suivante',
                    icon: _isLast ? Icons.theaters_rounded : Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneView extends StatelessWidget {
  const _SceneView({required this.scene, required this.offset, required this.active});

  final _Scene scene;
  final double offset;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final reduced = reduceMotion(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(HSpace.lg, HSpace.xxxl + HSpace.lg, HSpace.lg, HSize.buttonHeight + HSpace.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Transform.translate(
                offset: Offset(reduced ? 0 : offset * width * .45, 0),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: active ? 1 : 0),
                    duration: reduced ? Duration.zero : const Duration(milliseconds: 1800),
                    curve: Curves.easeInOutCubic,
                    builder: (context, p, _) => SceneArt(kind: scene.kind, progress: p),
                  ),
                ),
              ),
            ),
            const SizedBox(height: HSpace.xl),
            Transform.translate(
              offset: Offset(reduced ? 0 : -offset * width * .2, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SCÈNE 0${scene.number}', style: HText.credit),
                  const SizedBox(height: HSpace.sm),
                  Text(scene.title, style: HText.displayLarge),
                  const SizedBox(height: HSpace.md),
                  Text(scene.body, style: HText.body),
                ],
              )
                  .animate(target: active ? 1 : 0)
                  .fadeIn(duration: HMotion.scene, curve: HMotion.enter)
                  .slideY(begin: .35, end: 0, duration: HMotion.scene, curve: HMotion.enter),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicateur façon bande de film : une image par scène, la courante éclairée.
class _FilmStrip extends StatelessWidget {
  const _FilmStrip({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Scène ${index + 1} sur $count',
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: HMotion.base,
              curve: HMotion.emphasized,
              margin: const EdgeInsets.only(right: HSpace.xs),
              width: i == index ? HSpace.xxl : HSpace.lg,
              height: HSpace.md,
              decoration: BoxDecoration(
                gradient: i == index ? HGradients.goldSheen : null,
                borderRadius: BorderRadius.circular(HSpace.xxs),
                border: Border.all(color: i == index ? HColors.goldLight : HColors.hairline),
                boxShadow: i == index ? HShadows.goldGlow : null,
              ),
            ),
        ],
      ),
    );
  }
}
