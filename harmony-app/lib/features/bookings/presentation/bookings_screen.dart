import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/harmony_image.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/application/session.dart';
import '../../booking/data/booking_api.dart';
import '../../booking/domain/booking_models.dart';
import '../../booking/presentation/booking_detail_screen.dart';
import '../../catalog/data/catalog_api.dart';

/// Réservations du client : à venir et passées, avec leur statut.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t('Réservations'))),
      body: session == null
          ? EmptyState(
              icon: Icons.lock_outline_rounded,
              title: t('Connectez-vous pour voir vos séjours'),
              message: t('Vos réservations, leurs reçus et le contact de votre concierge sont liés à votre numéro de téléphone.'),
              actionLabel: t('Se connecter'),
              onAction: () => context.push('/connexion'),
            )
          : ref.watch(myBookingsProvider).when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(HSpace.gutter),
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: HSpace.md),
                      child: Skeleton(height: 88, radius: HRadius.md),
                    ),
                  ),
                ),
                error: (e, _) {
                  final error = ApiError.from(e);
                  if (error.status == 401) {
                    Future.microtask(() => ref.read(sessionProvider.notifier).expire());
                  }
                  return EmptyState(
                    icon: error.offline ? Icons.cloud_off_outlined : Icons.error_outline_rounded,
                    title: error.offline ? t('Hors connexion') : t('Impossible de charger vos réservations'),
                    message: error.message,
                    actionLabel: t('Réessayer'),
                    onAction: () => ref.invalidate(myBookingsProvider),
                  );
                },
                data: (bookings) => bookings.isEmpty
                    ? EmptyState(
                        icon: Icons.event_available_outlined,
                        title: t('Aucune réservation pour l’instant'),
                        message: t('Vos séjours apparaîtront ici, avec leur reçu et le contact de votre concierge.'),
                        actionLabel: t('Explorer les biens'),
                        onAction: () => context.go('/explorer'),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(myBookingsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(HSpace.gutter),
                          itemCount: bookings.length,
                          separatorBuilder: (_, _) => const SizedBox(height: HSpace.md),
                          itemBuilder: (context, i) => _BookingTile(booking: bookings[i]),
                        ),
                      ),
              ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final cover = photoSource(booking.apartmentCover);
    return Semantics(
      button: true,
      label: t('{title}, {status}, du {from} au {to}', {
        'title': booking.apartmentTitle,
        'status': booking.statusLabel,
        'from': fullDate(booking.startAt),
        'to': fullDate(booking.endAt),
      }),
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/reservation/${booking.reference}'),
          child: Padding(
            padding: const EdgeInsets.all(HSpace.sm),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(HRadius.sm),
                  child: SizedBox(width: 72, height: 72, child: cover.isEmpty ? const Skeleton() : HarmonyImage(cover)),
                ),
                const SizedBox(width: HSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.apartmentTitle, style: context.tt.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${shortDate(lome(booking.startAt))} → ${shortDate(lome(booking.endAt))} · ${booking.reference}',
                          style: context.tt.bodyMedium),
                      const SizedBox(height: HSpace.xxs),
                      StatusBadge(label: booking.statusLabel, tone: bookingTone(booking.status)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.hc.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
