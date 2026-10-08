import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/fcfa.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/poster_art.dart';
import '../../home/data/rooms_repository.dart';
import '../../home/domain/room.dart';

/// Fiche chambre : l'affiche arrive en Hero depuis le carrousel, des bandes
/// cinémascope s'écartent, puis le contenu se déroule comme un générique.
class RoomDetailScreen extends ConsumerStatefulWidget {
  const RoomDetailScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _bars = AnimationController(vsync: this, duration: HMotion.curtain, value: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _bars.value = 0;
    } else if (_bars.value == 1 && !_bars.isAnimating) {
      Future.delayed(HMotion.base, () {
        if (mounted) _bars.animateTo(0, curve: HMotion.curtainCurve);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _bars.dispose();
    super.dispose();
  }

  void _book(Room room, StayType stay) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${stay.screening} · ${room.name} — la billetterie ouvre très bientôt.')));
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomByIdProvider(widget.roomId));
    if (room == null) return const _MissingRoom();
    final stay = ref.watch(selectedStayProvider);
    final size = MediaQuery.sizeOf(context);
    final reduced = reduceMotion(context);
    final posterHeight = size.height * .56;

    List<Widget> credits(List<Widget> children) => reduced
        ? children
        : children
            .animate(interval: 70.ms, delay: 350.ms)
            .fadeIn(duration: HMotion.scene, curve: HMotion.enter)
            .slideY(begin: .25, end: 0, duration: HMotion.scene, curve: HMotion.enter);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: posterHeight,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(HRadius.sheet)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: room.heroTag,
                          child: AnimatedBuilder(
                            animation: _scroll,
                            builder: (context, _) {
                              final offset = _scroll.hasClients ? _scroll.offset : 0.0;
                              return PosterArt(
                                mood: room.mood,
                                seed: room.posterSeed,
                                parallax: (offset / posterHeight).clamp(-1.0, 1.0),
                              );
                            },
                          ),
                        ),
                        const DecoratedBox(decoration: BoxDecoration(gradient: HGradients.posterScrim)),
                        Positioned(
                          left: HSpace.lg,
                          right: HSpace.lg,
                          bottom: HSpace.lg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: credits([
                              Text(room.category.toUpperCase(), style: HText.credit),
                              const SizedBox(height: HSpace.xs),
                              Text(room.name, style: HText.displayLarge),
                              const SizedBox(height: HSpace.xs),
                              Text(room.tagline, style: HText.tagline),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(HSpace.lg, HSpace.xl, HSpace.lg, 0),
                sliver: SliverList.list(
                  children: credits([
                    const _SectionTitle('Synopsis'),
                    Text(room.synopsis, style: HText.body),
                    const SizedBox(height: HSpace.xl),
                    const _SectionTitle('Au programme'),
                    _AmenityCredits(amenities: room.amenities),
                    const SizedBox(height: HSpace.xl),
                    const _SectionTitle('Les séances'),
                    for (final s in StayType.values)
                      _ScreeningRow(
                        stay: s,
                        price: room.priceFor(s),
                        selected: s == stay,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(selectedStayProvider.notifier).select(s);
                        },
                      ),
                    const SizedBox(height: HSize.buttonHeight * 3),
                  ]),
                ),
              ),
            ],
          ),
          // Bandes cinémascope qui s'écartent à l'ouverture.
          AnimatedBuilder(
            animation: _bars,
            builder: (context, _) {
              final h = _bars.value * size.height * .22;
              if (h <= 0) return const SizedBox.shrink();
              return IgnorePointer(
                child: Column(
                  children: [
                    Container(height: h, color: HColors.shadow),
                    const Spacer(),
                    Container(height: h, color: HColors.shadow),
                  ],
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(HSpace.md),
              child: GlassIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Retour à l’affiche',
                onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BookingBar(room: room, stay: stay, onBook: () => _book(room, stay))
                .animate(delay: reduced ? 0.ms : 700.ms)
                .slideY(begin: reduced ? 0 : 1.2, end: 0, duration: HMotion.scene, curve: HMotion.enter),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HSpace.sm),
      child: Row(
        children: [
          Text(text.toUpperCase(), style: HText.credit),
          const SizedBox(width: HSpace.sm),
          const Expanded(child: Divider(color: HColors.hairline, height: 1)),
        ],
      ),
    );
  }
}

/// Équipements présentés comme un générique centré, séparés de losanges dorés.
class _AmenityCredits extends StatelessWidget {
  const _AmenityCredits({required this.amenities});

  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (i, a) in amenities.indexed) ...[
          if (i > 0) Text('◆', style: HText.credit.copyWith(fontSize: 8, color: HColors.goldDeep)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: HSpace.xxs),
            child: Text(a, style: HText.title.copyWith(fontSize: 18), textAlign: TextAlign.center),
          ),
        ],
      ],
    );
  }
}

class _ScreeningRow extends StatelessWidget {
  const _ScreeningRow({required this.stay, required this.price, required this.selected, required this.onTap});

  final StayType stay;
  final int price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${stay.label}, ${stay.screening}, ${fcfa(price)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: HMotion.base,
          curve: HMotion.emphasized,
          margin: const EdgeInsets.only(bottom: HSpace.xs),
          padding: const EdgeInsets.symmetric(horizontal: HSpace.md, vertical: HSpace.sm),
          constraints: const BoxConstraints(minHeight: HSize.buttonHeight + HSpace.xs),
          decoration: BoxDecoration(
            color: selected ? HColors.velvetDeep : HColors.nightRaised,
            borderRadius: BorderRadius.circular(HRadius.md),
            border: Border.all(color: selected ? HColors.gold : HColors.hairline),
            boxShadow: selected ? HShadows.goldGlow : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stay.label, style: HText.label),
                    Text(stay.screening, style: HText.tagline.copyWith(fontSize: 14)),
                  ],
                ),
              ),
              Text(fcfa(price), style: HText.price.copyWith(fontSize: 17, color: selected ? HColors.goldLight : HColors.ivoryMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre flottante en verre : séance choisie, prix et bouton de réservation.
class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.room, required this.stay, required this.onBook});

  final Room room;
  final StayType stay;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(HSpace.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HRadius.card),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(HSpace.lg, HSpace.sm, HSpace.sm, HSpace.sm),
            decoration: BoxDecoration(
              color: HColors.glass,
              borderRadius: BorderRadius.circular(HRadius.card),
              border: Border.all(color: HColors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stay.screening.toUpperCase(), style: HText.creditSmall),
                      AnimatedSwitcher(
                        duration: HMotion.base,
                        child: Text(fcfa(room.priceFor(stay)), key: ValueKey(stay), style: HText.price),
                      ),
                    ],
                  ),
                ),
                GoldPillButton(label: 'Réserver', icon: Icons.local_activity_rounded, expand: false, onPressed: onBook),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingRoom extends StatelessWidget {
  const _MissingRoom();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(HSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cette salle n’est plus à l’affiche', style: HText.title, textAlign: TextAlign.center),
              const SizedBox(height: HSpace.lg),
              GoldPillButton(label: 'Retour à l’affiche', expand: false, onPressed: () => context.go('/home')),
            ],
          ),
        ),
      ),
    );
  }
}
