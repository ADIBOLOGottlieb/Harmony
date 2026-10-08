import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/film_grain.dart';
import '../../../core/widgets/marquee_sign.dart';
import '../data/rooms_repository.dart';
import 'widgets/poster_card.dart';
import 'widgets/stay_chips.dart';

/// « À l'affiche » : enseigne lumineuse, choix de la séance, carrousel d'affiches.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _carousel = PageController(viewportFraction: .74);
  int _current = 0;

  @override
  void dispose() {
    _carousel.dispose();
    super.dispose();
  }

  /// Salutation selon l'heure de Lomé (UTC+0, sans heure d'été).
  String get _greeting {
    final hour = DateTime.now().toUtc().hour;
    if (hour < 5 || hour >= 18) return 'Bonsoir';
    if (hour < 12) return 'Bonjour';
    return 'Bon après-midi';
  }

  void _onPosterTap(int index, String roomId) {
    if (index != _current) {
      _carousel.animateToPage(index, duration: HMotion.scene, curve: HMotion.emphasized);
      return;
    }
    HapticFeedback.lightImpact();
    context.push('/home/room/$roomId');
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(roomsProvider);
    final stay = ref.watch(selectedStayProvider);
    final reduced = reduceMotion(context);

    Widget entrance(Widget child, int order) => reduced
        ? child
        : child
            .animate(delay: (250 + order * 140).ms)
            .fadeIn(duration: HMotion.scene, curve: HMotion.enter)
            .slideY(begin: -.2, end: 0, duration: HMotion.scene, curve: HMotion.enter);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: HGradients.projectorBeam)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: HSpace.md),
                entrance(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: HSpace.lg),
                    child: Row(
                      children: [
                        Expanded(child: Text('${_greeting.toUpperCase()} · LOMÉ', style: HText.credit, overflow: TextOverflow.ellipsis)),
                        Text('${rooms.length} SALLES', style: HText.credit.copyWith(color: HColors.ivoryFaint)),
                      ],
                    ),
                  ),
                  0,
                ),
                const SizedBox(height: HSpace.sm),
                entrance(
                  MarqueeSign(
                    child: Column(
                      children: [
                        Text('À L’AFFICHE', style: HText.marquee.copyWith(fontSize: 28, letterSpacing: 8)),
                        const SizedBox(height: HSpace.xxs),
                        Text('ce soir, une seule séance : la vôtre', style: HText.tagline.copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                  1,
                ),
                const SizedBox(height: HSpace.md),
                entrance(const StayChips(), 2),
                Expanded(
                  child: (rooms.isEmpty
                      ? const _EmptyBill()
                      : PageView.builder(
                          controller: _carousel,
                          itemCount: rooms.length,
                          onPageChanged: (i) {
                            setState(() => _current = i);
                            HapticFeedback.selectionClick();
                          },
                          itemBuilder: (context, i) => AnimatedBuilder(
                            animation: _carousel,
                            builder: (context, _) {
                              final page = _carousel.hasClients && _carousel.position.haveDimensions
                                  ? _carousel.page!
                                  : _current.toDouble();
                              return PosterCard(
                                room: rooms[i],
                                stay: stay,
                                delta: (page - i).clamp(-1.0, 1.0),
                                onTap: () => _onPosterTap(i, rooms[i].id),
                              );
                            },
                          ),
                        ))
                      .animate(delay: reduced ? 0.ms : 650.ms)
                      .fadeIn(duration: HMotion.curtain, curve: HMotion.enter)
                      .scaleXY(begin: reduced ? 1 : .88, end: 1, duration: HMotion.curtain, curve: HMotion.enter),
                ),
                if (rooms.isNotEmpty) _ReelCounter(current: _current, total: rooms.length),
                const SizedBox(height: HSpace.md),
              ],
            ),
          ),
          const Vignette(),
          const FilmGrain(intensity: .7),
        ],
      ),
    );
  }
}

/// Compteur « 03 — 08 » avec une barre de progression façon bobine.
class _ReelCounter extends StatelessWidget {
  const _ReelCounter({required this.current, required this.total});

  final int current;
  final int total;

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HSpace.xxl),
      child: Row(
        children: [
          Text(_two(current + 1), style: HText.credit),
          const SizedBox(width: HSpace.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(HRadius.pill),
              child: Stack(
                children: [
                  Container(height: 2, color: HColors.hairline),
                  AnimatedFractionallySizedBox(
                    duration: HMotion.base,
                    curve: HMotion.emphasized,
                    widthFactor: (current + 1) / total,
                    child: Container(height: 2, decoration: const BoxDecoration(gradient: HGradients.goldSheen)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: HSpace.sm),
          Text(_two(total), style: HText.credit.copyWith(color: HColors.ivoryFaint)),
        ],
      ),
    );
  }
}

class _EmptyBill extends StatelessWidget {
  const _EmptyBill();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.theaters_outlined, color: HColors.gold, size: HSpace.xxl),
            const SizedBox(height: HSpace.md),
            Text('Relâche ce soir', style: HText.title),
            const SizedBox(height: HSpace.xs),
            Text('Aucune salle n’est disponible pour le moment. Revenez un peu plus tard.', style: HText.body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
