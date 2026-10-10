import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../catalog/application/favorites.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/presentation/property_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesProvider);
    final items = ref.watch(apartmentsProvider).where((a) => ids.contains(a.id)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(t('Favoris'))),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: t('Aucun favori'),
              message: t('Touchez le cœur d’un bien pour le retrouver ici et comparer vos coups de cœur.'),
              actionLabel: t('Explorer les biens'),
              onAction: () => context.go('/explorer'),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.sm, HSpace.gutter, HSpace.xl),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: HSpace.lg),
              itemBuilder: (context, i) => PropertyCard(
                apartment: items[i],
                onTap: () => context.push('/bien/${items[i].id}'),
              ),
            ),
    );
  }
}
