import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/fcfa.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_tokens.dart';
import '../../auth/application/session.dart';
import '../../catalog/data/catalog_repository.dart';
import '../application/booking_draft.dart';
import '../data/booking_api.dart';
import '../domain/booking_models.dart';

/// Étape 2 : récapitulatif chiffré, choix du moyen de paiement, paiement.
class BookingRecapScreen extends ConsumerStatefulWidget {
  const BookingRecapScreen({super.key, required this.apartmentId});

  final String apartmentId;

  @override
  ConsumerState<BookingRecapScreen> createState() => _BookingRecapScreenState();
}

class _BookingRecapScreenState extends ConsumerState<BookingRecapScreen> {
  bool _submitting = false;
  String? _error;

  Future<void> _pay(BookingDraft draft) async {
    if (ref.read(sessionProvider) == null) {
      final signedIn = await context.push<bool>('/connexion');
      if (signedIn != true || !mounted) return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final booking = await ref.read(bookingApiProvider).create(draft.toRequest(withPayment: true));
      HapticFeedback.mediumImpact();
      ref.invalidate(myBookingsProvider);
      ref.invalidate(availabilityProvider(draft.apartmentId));
      final checkout = booking.pendingPayment?.checkoutUrl;
      if (checkout != null) {
        await launchUrl(Uri.parse(checkout), mode: LaunchMode.externalApplication);
      }
      if (mounted) context.go('/reservation/${booking.reference}');
    } catch (e) {
      final error = ApiError.from(e);
      if (error.status == 401) await ref.read(sessionProvider.notifier).expire();
      if (error.code == 'dates_unavailable') ref.invalidate(availabilityProvider(draft.apartmentId));
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    final apartment = ref.watch(apartmentByIdProvider(widget.apartmentId));
    if (draft == null || apartment == null || !draft.isComplete) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(t('Choisissez d’abord vos dates.'))));
    }
    final quote = ref.watch(quoteProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('Récapitulatif'))),
      body: quote.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(HSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ApiError.from(e).message, textAlign: TextAlign.center, style: context.tt.bodyLarge),
                const SizedBox(height: HSpace.md),
                OutlinedButton(onPressed: () => ref.invalidate(quoteProvider), child: Text(t('Réessayer'))),
              ],
            ),
          ),
        ),
        data: (q) => ListView(
          padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.xl),
          children: [
            Text(apartment.title, style: context.tt.headlineMedium),
            const SizedBox(height: HSpace.md),
            _Row(icon: Icons.login_rounded, label: t('Arrivée'), value: '${fullDate(q.startAt)} · ${timeOfDay(q.startAt)}'),
            _Row(icon: Icons.logout_rounded, label: t('Départ'), value: '${fullDate(q.endAt)} · ${timeOfDay(q.endAt)}'),
            _Row(icon: Icons.people_outline_rounded, label: t('Voyageurs'), value: '${draft.guests}'),
            const Padding(padding: EdgeInsets.symmetric(vertical: HSpace.md), child: Divider()),
            for (final line in q.lines) _Amount(label: line.label, amount: line.amount),
            const SizedBox(height: HSpace.xs),
            _Amount(label: t('Total du séjour'), amount: q.total, strong: true),
            if (Money.current != DisplayCurrency.xof)
              Text(
                t('Soit {amount} environ. Le paiement se fait en FCFA.', {'amount': converted(q.total, Money.current)}),
                style: context.tt.bodyMedium,
              ),
            const SizedBox(height: HSpace.md),
            Container(
              padding: const EdgeInsets.all(HSpace.md),
              decoration: BoxDecoration(color: context.hc.accentSoft, borderRadius: BorderRadius.circular(HRadius.md)),
              child: Column(
                children: [
                  _Amount(label: q.balance > 0 ? t('Acompte à payer maintenant') : t('À payer maintenant'), amount: q.advance, strong: true),
                  if (q.balance > 0) _Amount(label: t('Solde avant l’arrivée'), amount: q.balance),
                ],
              ),
            ),
            const SizedBox(height: HSpace.sm),
            Text(
              t('Caution de {amount} réglée à l’arrivée auprès du concierge et restituée après l’état des lieux.', {'amount': fcfa(q.securityDeposit)}),
              style: context.tt.bodyMedium,
            ),
            const SizedBox(height: HSpace.lg),
            Text(t('Moyen de paiement'), style: context.tt.titleLarge),
            const SizedBox(height: HSpace.xs),
            for (final m in PaymentMethod.values)
              _MethodTile(
                method: m,
                selected: draft.paymentMethod == m,
                onTap: () => ref.read(bookingDraftProvider.notifier).update((d) => d.copyWith(paymentMethod: m)),
              ),
            const SizedBox(height: HSpace.md),
            Text(
              t('Annulation gratuite jusqu’à 5 jours avant l’arrivée : l’acompte vous est alors remboursé. Au-delà, l’acompte reste acquis.'),
              style: context.tt.bodyMedium,
            ),
          ],
        ),
      ),
      bottomNavigationBar: quote.hasValue
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: context.cs.surfaceContainerLowest,
                border: Border(top: BorderSide(color: context.hc.hairline)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.sm, HSpace.gutter, HSpace.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Juste au-dessus du bouton : l'erreur reste visible quel que soit le défilement.
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: HSpace.xs),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(_error!, style: HText.bodySmall.copyWith(color: context.cs.error)),
                          ),
                        ),
                      FilledButton(
                        onPressed: _submitting ? null : () => _pay(draft),
                        child: _submitting
                            ? SizedBox.square(
                                dimension: HSize.icon,
                                child: CircularProgressIndicator(strokeWidth: 2, color: context.cs.onPrimary),
                              )
                            : Text(draft.paymentMethod == PaymentMethod.bankTransfer
                                ? t('Réserver et payer par virement')
                                : t('Payer {amount}', {'amount': fcfa(quote.requireValue.advance)})),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: HSpace.xs),
        child: Row(
          children: [
            Icon(icon, size: HSize.icon, color: context.hc.accentText),
            const SizedBox(width: HSpace.sm),
            Text(label, style: context.tt.bodyMedium),
            const Spacer(),
            Flexible(child: Text(value, style: context.tt.titleMedium, textAlign: TextAlign.end)),
          ],
        ),
      );
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.amount, this.strong = false});

  final String label;
  final int amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong ? HText.titleSans.copyWith(color: context.cs.onSurface) : context.tt.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(fcfa(amount), style: style),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method, required this.selected, required this.onTap});

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HSpace.xs),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: context.cs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HRadius.md),
            side: BorderSide(color: selected ? context.cs.primary : context.hc.hairline, width: selected ? 1.5 : 1),
          ),
          child: ListTile(
            onTap: onTap,
            leading: Icon(method.icon, color: context.hc.accentText),
            title: Text(method.label),
            subtitle: Text(method.hint),
            trailing: Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? context.cs.primary : context.hc.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
