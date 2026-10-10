import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/fcfa.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_sheet.dart';
import '../../../core/widgets/location_map.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/booking_api.dart';
import '../domain/booking_models.dart';

BadgeTone bookingTone(String status) => switch (status) {
      'confirmed' => BadgeTone.positive,
      'pending' => BadgeTone.caution,
      _ => BadgeTone.neutral,
    };

/// Suivi d'une réservation : statut, paiement, adresse (une fois confirmée), solde, annulation.
/// Le statut est revérifié automatiquement tant qu'un paiement en ligne est attendu.
class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.reference});

  final String reference;

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> with WidgetsBindingObserver {
  Timer? _poll;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(const Duration(seconds: 6), (_) {
      final booking = ref.read(bookingDetailProvider(widget.reference)).value;
      if (booking != null && booking.isPending && booking.pendingPayment?.checkoutUrl != null) _refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(); // retour de la page de paiement
  }

  void _refresh() {
    ref.invalidate(bookingDetailProvider(widget.reference));
    ref.invalidate(myBookingsProvider);
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack(t('Impossible d’ouvrir la page.'));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _act(Future<Booking> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      final booking = await action();
      _refresh();
      final checkout = booking.pendingPayment?.checkoutUrl;
      if (checkout != null) await _open(checkout);
      if (success != null && mounted) _snack(success);
    } catch (e) {
      if (mounted) _snack(ApiError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payBalance(Booking booking) async {
    final method = await showHarmonySheet<PaymentMethod>(
      context,
      title: t('Payer le solde · {amount}', {'amount': fcfa(booking.balanceDue)}),
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: HSpace.lg),
        children: [
          for (final m in PaymentMethod.values)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
              leading: Icon(m.icon),
              title: Text(m.label),
              subtitle: Text(m.hint),
              onTap: () => Navigator.of(context).pop(m),
            ),
        ],
      ),
    );
    if (method == null) return;
    await _act(() => ref.read(bookingApiProvider).payBalance(booking.reference, method));
  }

  Future<void> _review(Booking booking) async {
    final result = await showHarmonySheet<(int, String)>(
      context,
      title: t('Votre avis sur {title}', {'title': booking.apartmentTitle}),
      builder: (context) => const _ReviewForm(),
    );
    if (result == null) return;
    await _act(
      () => ref.read(bookingApiProvider).review(booking.reference, result.$1, result.$2),
      success: t('Merci ! Votre avis sera publié après relecture par la conciergerie.'),
    );
  }

  Future<void> _cancel(Booking booking) async {
    final deadline = booking.cancellationDeadline;
    final free = deadline != null && DateTime.now().toUtc().isBefore(deadline.toUtc());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Annuler la réservation ?')),
        content: Text(free
            ? t('L’annulation est gratuite jusqu’au {date} : les sommes versées vous seront remboursées.', {'date': fullDate(deadline)})
            : t('Le délai d’annulation gratuite est dépassé : l’acompte versé reste acquis.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t('Garder'))),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t('Annuler la réservation'))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _act(() => ref.read(bookingApiProvider).cancel(booking.reference), success: t('Réservation annulée.'));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookingDetailProvider(widget.reference));
    return Scaffold(
      appBar: AppBar(title: Text(t('Réservation {reference}', {'reference': widget.reference}))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(HSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ApiError.from(e).message, textAlign: TextAlign.center, style: context.tt.bodyLarge),
                const SizedBox(height: HSpace.md),
                OutlinedButton(onPressed: _refresh, child: Text(t('Réessayer'))),
              ],
            ),
          ),
        ),
        data: (b) => RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.xl),
            children: [
              Row(
                children: [
                  StatusBadge(label: b.statusLabel, tone: bookingTone(b.status)),
                  const Spacer(),
                  SelectableText(b.reference, style: HText.titleSans.copyWith(color: context.cs.onSurface, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: HSpace.sm),
              Text(b.apartmentTitle, style: context.tt.headlineMedium),
              if (b.apartmentZone != null) Text('${b.apartmentZone} · Lomé', style: context.tt.bodyMedium),
              const SizedBox(height: HSpace.md),
              if (b.isPending) _PendingCard(booking: b, onOpen: _open, onCheck: _refresh),
              if (b.isConfirmed) _ConfirmedCard(booking: b, onOpen: _open),
              if (b.canReview || b.reviewRating != null) _ReviewCard(booking: b, onReview: () => _review(b)),
              const SizedBox(height: HSpace.md),
              _Line(label: t('Séjour'), value: b.stayTypeLabel),
              _Line(label: t('Arrivée'), value: '${fullDate(b.startAt)} · ${timeOfDay(b.startAt)}'),
              _Line(label: t('Départ'), value: '${fullDate(b.endAt)} · ${timeOfDay(b.endAt)}'),
              _Line(label: t('Voyageurs'), value: '${b.guests}'),
              const Padding(padding: EdgeInsets.symmetric(vertical: HSpace.md), child: Divider()),
              Text(t('Reçu'), style: context.tt.titleLarge),
              const SizedBox(height: HSpace.xs),
              for (final l in b.lines) _Line(label: l.label, value: fcfa(l.amount)),
              _Line(label: t('Total'), value: fcfa(b.total), strong: true),
              _Line(label: t('Déjà réglé'), value: fcfa(b.paid)),
              _Line(label: t('Reste à payer'), value: fcfa(b.balanceDue), strong: b.balanceDue > 0),
              _Line(label: t('Caution (à l’arrivée)'), value: fcfa(b.securityDeposit)),
              if (b.payments.isNotEmpty) ...[
                const SizedBox(height: HSpace.md),
                Text(t('Paiements'), style: context.tt.titleMedium),
                for (final p in b.payments)
                  _Line(label: '${p.kindLabel} · ${p.methodLabel}', value: '${fcfa(p.amount)} · ${p.statusLabel}'),
              ],
              const SizedBox(height: HSpace.lg),
              if (b.isConfirmed && b.balanceDue > 0 && b.pendingPayment == null)
                FilledButton(
                  onPressed: _busy ? null : () => _payBalance(b),
                  child: Text(t('Payer le solde · {amount}', {'amount': fcfa(b.balanceDue)})),
                ),
              if (b.isCancellable) ...[
                const SizedBox(height: HSpace.sm),
                OutlinedButton(
                  onPressed: _busy ? null : () => _cancel(b),
                  child: Text(t('Annuler la réservation')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.booking, required this.onOpen, required this.onCheck});

  final Booking booking;
  final Future<void> Function(String url) onOpen;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final payment = booking.pendingPayment;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t('Paiement en attente'), style: context.tt.titleMedium),
            const SizedBox(height: HSpace.xxs),
            if (payment?.instructions != null)
              SelectableText(payment!.instructions!, style: context.tt.bodyMedium)
            else
              Text(
                t('Vos dates sont réservées pendant 30 minutes. Finalisez le paiement pour confirmer votre séjour.'),
                style: context.tt.bodyMedium,
              ),
            if (payment?.checkoutUrl != null) ...[
              const SizedBox(height: HSpace.sm),
              FilledButton(onPressed: () => onOpen(payment.checkoutUrl!), child: Text(t('Payer {amount}', {'amount': fcfa(payment!.amount)}))),
              TextButton(onPressed: onCheck, child: Text(t('J’ai payé : vérifier'))),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfirmedCard extends StatelessWidget {
  const _ConfirmedCard({required this.booking, required this.onOpen});

  final Booking booking;
  final Future<void> Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    final hasPosition = booking.latitude != null && booking.longitude != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.verified_outlined, color: context.hc.success),
                const SizedBox(width: HSpace.xs),
                Text(t('Votre séjour est confirmé'), style: context.tt.titleMedium),
              ],
            ),
            if (booking.address != null) ...[
              const SizedBox(height: HSpace.sm),
              Text(t('Adresse'), style: context.tt.labelSmall),
              SelectableText(booking.address!, style: context.tt.bodyLarge),
            ],
            if (hasPosition) ...[
              const SizedBox(height: HSpace.sm),
              LocationMap(latitude: booking.latitude!, longitude: booking.longitude!, exact: true),
              const SizedBox(height: HSpace.sm),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onOpen(Uri.https('www.google.com', '/maps/dir/', {
                    'api': '1',
                    'destination': '${booking.latitude},${booking.longitude}',
                  }).toString());
                },
                icon: const Icon(Icons.directions_outlined),
                label: Text(t('Itinéraire')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.booking, required this.onReview});

  final Booking booking;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final rating = booking.reviewRating;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(rating == null ? t('Comment s’est passé votre séjour ?') : t('Merci pour votre avis'), style: context.tt.titleMedium),
            const SizedBox(height: HSpace.xxs),
            if (rating == null) ...[
              Text(t('Votre retour aide la conciergerie à soigner chaque séjour.'), style: context.tt.bodyMedium),
              const SizedBox(height: HSpace.sm),
              FilledButton.tonal(onPressed: onReview, child: Text(t('Donner mon avis'))),
            ] else ...[
              _Stars(rating: rating),
              if (booking.reviewComment != null) ...[
                const SizedBox(height: HSpace.xs),
                Text(booking.reviewComment!, style: context.tt.bodyMedium),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) => Semantics(
        label: t('{rating} sur 5', {'rating': rating}),
        excludeSemantics: true,
        child: Row(
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(i <= rating ? Icons.star_rounded : Icons.star_outline_rounded, color: context.hc.accent, size: HSize.icon),
          ],
        ),
      );
}

/// Note de 1 à 5 et commentaire facultatif ; renvoie (note, commentaire).
class _ReviewForm extends StatefulWidget {
  const _ReviewForm();

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  int _rating = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: i == 1 ? t('1 étoile') : t('{n} étoiles', {'n': i}),
                  isSelected: i <= _rating,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = i);
                  },
                  icon: Icon(Icons.star_outline_rounded, color: context.hc.textMuted),
                  selectedIcon: Icon(Icons.star_rounded, color: context.hc.accent),
                ),
            ],
          ),
          const SizedBox(height: HSpace.sm),
          TextField(
            controller: _comment,
            maxLength: 1000,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(labelText: t('Commentaire (facultatif)')),
          ),
          const SizedBox(height: HSpace.sm),
          FilledButton(
            onPressed: _rating == 0 ? null : () => Navigator.of(context).pop((_rating, _comment.text)),
            child: Text(t('Envoyer mon avis')),
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
