import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/fcfa.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/harmony_image.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/application/session.dart';
import '../data/gallery_api.dart';
import '../domain/artwork.dart';

/// Acquisitions du client : œuvres réservées, réglées ou annulées.
class ArtworkOrdersScreen extends ConsumerWidget {
  const ArtworkOrdersScreen({super.key});

  Future<void> _cancel(BuildContext context, WidgetRef ref, ArtworkOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(t('Annuler cette demande ?')),
        content: Text(t('L’œuvre sera remise en vente.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(t('Garder'))),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(t('Annuler la demande'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(galleryApiProvider).cancel(order.reference);
      ref.invalidate(myArtworkOrdersProvider);
      ref.invalidate(artworksProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiError.from(e).message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t('Mes acquisitions'))),
      body: session == null
          ? EmptyState(
              icon: Icons.lock_outline_rounded,
              title: t('Connectez-vous pour voir vos acquisitions'),
              message: t('Vos demandes d’œuvres sont liées à votre numéro de téléphone.'),
              actionLabel: t('Se connecter'),
              onAction: () => context.push('/connexion'),
            )
          : ref.watch(myArtworkOrdersProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: t('Impossible de charger vos acquisitions'),
                  message: ApiError.from(e).message,
                  actionLabel: t('Réessayer'),
                  onAction: () => ref.invalidate(myArtworkOrdersProvider),
                ),
                data: (orders) => orders.isEmpty
                    ? EmptyState(
                        icon: Icons.palette_outlined,
                        title: t('Aucune acquisition pour l’instant'),
                        message: t('Les œuvres que vous réservez apparaîtront ici.'),
                        actionLabel: t('Découvrir la galerie'),
                        onAction: () => context.pushReplacement('/galerie'),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(myArtworkOrdersProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(HSpace.gutter),
                          itemCount: orders.length,
                          separatorBuilder: (_, _) => const SizedBox(height: HSpace.md),
                          itemBuilder: (context, i) => _OrderCard(
                            order: orders[i],
                            onCancel: () => _cancel(context, ref, orders[i]),
                          ),
                        ),
                      ),
              ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onCancel});

  final ArtworkOrder order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final tone = switch (order.status) {
      'paid' => BadgeTone.positive,
      'pending' => BadgeTone.caution,
      _ => BadgeTone.neutral,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(HRadius.sm),
                  child: SizedBox(
                    width: 64,
                    height: 80,
                    child: (order.cover ?? '').isEmpty ? const Skeleton() : HarmonyImage(order.cover!),
                  ),
                ),
                const SizedBox(width: HSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.artworkTitle, style: context.tt.titleMedium),
                      if (order.artistName != null) Text(order.artistName!, style: context.tt.bodyMedium),
                      const SizedBox(height: HSpace.xxs),
                      StatusBadge(label: order.statusLabel, tone: tone),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: HSpace.sm),
            Text('${order.reference} · ${order.deliveryMethod.label} · ${fcfa(order.total)}', style: context.tt.bodyMedium),
            if (order.isPending) ...[
              if (order.expiresAt != null)
                Text(
                  t('Réservée pour vous jusqu’au {date} à {time}.', {
                    'date': fullDate(order.expiresAt!),
                    'time': timeOfDay(order.expiresAt!),
                  }),
                  style: context.tt.bodyMedium,
                ),
              if (order.paymentInstructions != null) ...[
                const SizedBox(height: HSpace.xs),
                Text(order.paymentInstructions!, style: context.tt.bodyMedium),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: onCancel, child: Text(t('Annuler la demande'))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
