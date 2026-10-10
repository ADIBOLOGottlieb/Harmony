import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/fcfa.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/harmony_image.dart';
import '../../../core/widgets/harmony_sheet.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/application/session.dart';
import '../data/gallery_api.dart';
import '../domain/artwork.dart';
import 'artwork_card.dart';

/// Fiche d'une œuvre : visuel plein cadre, cartel, artiste, demande d'acquisition.
class ArtworkDetailScreen extends ConsumerWidget {
  const ArtworkDetailScreen({super.key, required this.slug});

  final String slug;

  Future<void> _acquire(BuildContext context, WidgetRef ref, Artwork artwork) async {
    if (ref.read(sessionProvider) == null) {
      final signedIn = await context.push<bool>('/connexion');
      if (signedIn != true || !context.mounted) return;
    }
    final order = await showHarmonySheet<ArtworkOrder>(
      context,
      title: t('Acquérir « {title} »', {'title': artwork.title}),
      builder: (_) => _OrderForm(artwork: artwork),
    );
    if (order == null || !context.mounted) return;
    HapticFeedback.mediumImpact();
    ref.invalidate(artworksProvider);
    ref.invalidate(artworkProvider(slug));
    ref.invalidate(myArtworkOrdersProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t('Œuvre réservée pour vous. La galerie vous contacte pour le règlement.')),
    ));
    context.push('/acquisitions');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(artworkProvider(slug));
    return async.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.palette_outlined,
          title: t('Œuvre introuvable'),
          message: ApiError.from(e).message,
          actionLabel: t('Réessayer'),
          onAction: () => ref.invalidate(artworkProvider(slug)),
        ),
      ),
      data: (artwork) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: MediaQuery.sizeOf(context).width / ArtworkCard.aspect,
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(tag: artwork.heroTag, child: HarmonyImage(artwork.cover)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.lg, HSpace.gutter, HSpace.xl),
              sliver: SliverList.list(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(label: artwork.status.label, tone: artworkTone(artwork.status)),
                  ),
                  const SizedBox(height: HSpace.sm),
                  Text(artwork.title, style: context.tt.headlineMedium),
                  if (artwork.artist != null) Text(artwork.artist!.name, style: context.tt.titleMedium),
                  const SizedBox(height: HSpace.md),
                  _Line(label: t('Technique'), value: artwork.medium),
                  _Line(label: t('Dimensions'), value: artwork.dimensions),
                  if (artwork.year != null) _Line(label: t('Année'), value: '${artwork.year}'),
                  _Line(label: t('Prix'), value: fcfaWithEquivalent(artwork.price), strong: true),
                  const SizedBox(height: HSpace.md),
                  Text(artwork.description, style: context.tt.bodyLarge),
                  if (artwork.artist?.bio != null) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: HSpace.md), child: Divider()),
                    Text(t('L’artiste'), style: context.tt.titleLarge),
                    const SizedBox(height: HSpace.xs),
                    Text(artwork.artist!.bio!, style: context.tt.bodyMedium),
                  ],
                  const SizedBox(height: HSpace.md),
                  Text(
                    t('Pièce unique, livrée avec un certificat d’authenticité. Réservée pour vous 48 h le temps du règlement.'),
                    style: context.tt.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: context.cs.surfaceContainerLowest,
            border: Border(top: BorderSide(color: context.hc.hairline)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.sm, HSpace.gutter, HSpace.sm),
              child: FilledButton(
                onPressed: artwork.isAvailable ? () => _acquire(context, ref, artwork) : null,
                child: Text(artwork.isAvailable ? t('Acquérir cette œuvre') : artwork.status.label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mode de remise, adresse et message ; renvoie la demande créée.
class _OrderForm extends ConsumerStatefulWidget {
  const _OrderForm({required this.artwork});

  final Artwork artwork;

  @override
  ConsumerState<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends ConsumerState<_OrderForm> {
  DeliveryMethod _delivery = DeliveryMethod.pickup;
  final _address = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_delivery == DeliveryMethod.delivery && _address.text.trim().isEmpty) {
      setState(() => _error = t('Indiquez l’adresse de livraison.'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await ref.read(galleryApiProvider).order(
            widget.artwork.slug,
            _delivery,
            address: _address.text,
            note: _note.text,
          );
      if (mounted) Navigator.of(context).pop(order);
    } catch (e) {
      final error = ApiError.from(e);
      if (error.status == 401) await ref.read(sessionProvider.notifier).expire();
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fee = _delivery == DeliveryMethod.delivery ? widget.artwork.deliveryFee : 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<DeliveryMethod>(
            showSelectedIcon: false,
            segments: [for (final d in DeliveryMethod.values) ButtonSegment(value: d, label: Text(d.label))],
            selected: {_delivery},
            onSelectionChanged: (s) => setState(() => _delivery = s.first),
          ),
          if (_delivery == DeliveryMethod.delivery) ...[
            const SizedBox(height: HSpace.sm),
            TextField(
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: t('Adresse de livraison à Lomé')),
            ),
          ],
          const SizedBox(height: HSpace.sm),
          TextField(
            controller: _note,
            maxLines: 3,
            minLines: 2,
            maxLength: 1000,
            decoration: InputDecoration(labelText: t('Message pour la galerie (facultatif)')),
          ),
          _Line(label: t('Œuvre'), value: fcfa(widget.artwork.price)),
          if (fee > 0) _Line(label: t('Livraison'), value: fcfa(fee)),
          _Line(label: t('Total'), value: fcfaWithEquivalent(widget.artwork.price + fee), strong: true),
          const SizedBox(height: HSpace.xs),
          Text(
            t('Aucun paiement maintenant : l’œuvre vous est réservée 48 h et la galerie vous contacte pour le règlement.'),
            style: context.tt.bodyMedium,
          ),
          if (_error != null) ...[
            const SizedBox(height: HSpace.sm),
            Semantics(liveRegion: true, child: Text(_error!, style: HText.bodySmall.copyWith(color: context.cs.error))),
          ],
          const SizedBox(height: HSpace.md),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? SizedBox.square(
                    dimension: HSize.icon,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.cs.onPrimary),
                  )
                : Text(t('Réserver l’œuvre')),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong ? HText.titleSans.copyWith(color: context.cs.onSurface) : context.tt.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: context.tt.bodyMedium)),
          const SizedBox(width: HSpace.sm),
          Flexible(child: Text(value, style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
