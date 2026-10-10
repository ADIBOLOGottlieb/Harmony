import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/fcfa.dart';
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
    if (!ok && mounted) _snack('Impossible d’ouvrir la page.');
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
      title: 'Payer le solde · ${fcfa(booking.balanceDue)}',
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

  Future<void> _cancel(Booking booking) async {
    final deadline = booking.cancellationDeadline;
    final free = deadline != null && DateTime.now().toUtc().isBefore(deadline.toUtc());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation ?'),
        content: Text(free
            ? 'L’annulation est gratuite jusqu’au ${fullDate(deadline)} : les sommes versées vous seront remboursées.'
            : 'Le délai d’annulation gratuite est dépassé : l’acompte versé reste acquis.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Garder')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Annuler la réservation')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _act(() => ref.read(bookingApiProvider).cancel(booking.reference), success: 'Réservation annulée.');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookingDetailProvider(widget.reference));
    return Scaffold(
      appBar: AppBar(title: Text('Réservation ${widget.reference}')),
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
                OutlinedButton(onPressed: _refresh, child: const Text('Réessayer')),
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
              const SizedBox(height: HSpace.md),
              _Line(label: 'Séjour', value: b.stayTypeLabel),
              _Line(label: 'Arrivée', value: '${fullDate(b.startAt)} · ${timeOfDay(b.startAt)}'),
              _Line(label: 'Départ', value: '${fullDate(b.endAt)} · ${timeOfDay(b.endAt)}'),
              _Line(label: 'Voyageurs', value: '${b.guests}'),
              const Padding(padding: EdgeInsets.symmetric(vertical: HSpace.md), child: Divider()),
              Text('Reçu', style: context.tt.titleLarge),
              const SizedBox(height: HSpace.xs),
              for (final l in b.lines) _Line(label: l.label, value: fcfa(l.amount)),
              _Line(label: 'Total', value: fcfa(b.total), strong: true),
              _Line(label: 'Déjà réglé', value: fcfa(b.paid)),
              _Line(label: 'Reste à payer', value: fcfa(b.balanceDue), strong: b.balanceDue > 0),
              _Line(label: 'Caution (à l’arrivée)', value: fcfa(b.securityDeposit)),
              if (b.payments.isNotEmpty) ...[
                const SizedBox(height: HSpace.md),
                Text('Paiements', style: context.tt.titleMedium),
                for (final p in b.payments)
                  _Line(label: '${p.kindLabel} · ${p.methodLabel}', value: '${fcfa(p.amount)} · ${p.statusLabel}'),
              ],
              const SizedBox(height: HSpace.lg),
              if (b.isConfirmed && b.balanceDue > 0 && b.pendingPayment == null)
                FilledButton(
                  onPressed: _busy ? null : () => _payBalance(b),
                  child: Text('Payer le solde · ${fcfa(b.balanceDue)}'),
                ),
              if (b.isCancellable) ...[
                const SizedBox(height: HSpace.sm),
                OutlinedButton(
                  onPressed: _busy ? null : () => _cancel(b),
                  child: const Text('Annuler la réservation'),
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
            Text('Paiement en attente', style: context.tt.titleMedium),
            const SizedBox(height: HSpace.xxs),
            if (payment?.instructions != null)
              SelectableText(payment!.instructions!, style: context.tt.bodyMedium)
            else
              Text(
                'Vos dates sont réservées pendant 30 minutes. Finalisez le paiement pour confirmer votre séjour.',
                style: context.tt.bodyMedium,
              ),
            if (payment?.checkoutUrl != null) ...[
              const SizedBox(height: HSpace.sm),
              FilledButton(onPressed: () => onOpen(payment.checkoutUrl!), child: Text('Payer ${fcfa(payment!.amount)}')),
              TextButton(onPressed: onCheck, child: const Text('J’ai payé : vérifier')),
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
                Text('Votre séjour est confirmé', style: context.tt.titleMedium),
              ],
            ),
            if (booking.address != null) ...[
              const SizedBox(height: HSpace.sm),
              Text('Adresse', style: context.tt.labelSmall),
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
                label: const Text('Itinéraire'),
              ),
            ],
          ],
        ),
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
