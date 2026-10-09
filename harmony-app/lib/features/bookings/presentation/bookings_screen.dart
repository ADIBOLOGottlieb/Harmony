import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';

/// Réservations du client. Vide tant que le flux de réservation n'est pas branché.
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réservations')),
      body: EmptyState(
        icon: Icons.event_available_outlined,
        title: 'Aucune réservation pour l’instant',
        message: 'Vos séjours confirmés apparaîtront ici, avec leur reçu et le contact de votre concierge.',
        actionLabel: 'Explorer les biens',
        onAction: () => context.go('/explorer'),
      ),
    );
  }
}
