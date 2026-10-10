import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contact/concierge.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_sheet.dart';
import '../../auth/application/session.dart';
import '../../../core/widgets/harmony_logo.dart';
import '../application/theme_mode.dart';

/// Profil : compte (connexion par téléphone), préférences, assistance.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: HSpace.sm),
        children: [
          _AccountCard(session: session),
          const _GroupTitle('Préférences'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apparence', style: context.tt.titleMedium),
                const SizedBox(height: HSpace.xs),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Système')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Clair')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Sombre')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: HSpace.xs),
          const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: HSpace.gutter),
            leading: Icon(Icons.translate_rounded),
            title: Text('Langue'),
            trailing: Text('Français'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: HSpace.gutter),
            leading: Icon(Icons.payments_outlined),
            title: Text('Devise'),
            trailing: Text('FCFA'),
          ),
          const _GroupTitle('Assistance'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('Contacter la conciergerie'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _contactSheet(context),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
            leading: const Icon(Icons.description_outlined),
            title: const Text('Conditions et politique d’annulation'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _conditionsSheet(context),
          ),
          const SizedBox(height: HSpace.xl),
          const Center(child: HarmonyLogo()),
          const SizedBox(height: HSpace.xs),
          Center(child: Text('Version 0.3 · aperçu', style: context.tt.bodyMedium)),
          const SizedBox(height: HSpace.xl),
        ],
      ),
    );
  }
}

Future<void> _contactSheet(BuildContext context) => showHarmonySheet<void>(
      context,
      title: 'Contacter la conciergerie',
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Notre concierge vous répond 7 j/7, de 7 h à 22 h.', style: sheet.tt.bodyLarge),
            const SizedBox(height: HSpace.md),
            FilledButton.icon(
              onPressed: () => contactConcierge(sheet, whatsapp: true),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('WhatsApp'),
            ),
            const SizedBox(height: HSpace.sm),
            OutlinedButton.icon(
              onPressed: () => contactConcierge(sheet, whatsapp: false),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Appeler'),
            ),
          ],
        ),
      ),
    );

Future<void> _conditionsSheet(BuildContext context) => showHarmonySheet<void>(
      context,
      title: 'Conditions de séjour',
      builder: (sheet) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.lg),
        children: [
          for (final (title, body) in _conditions) ...[
            Text(title, style: sheet.tt.titleMedium),
            const SizedBox(height: HSpace.xxs),
            Text(body, style: sheet.tt.bodyMedium),
            const SizedBox(height: HSpace.md),
          ],
        ],
      ),
    );

const _conditions = [
  ('Horaires', 'Arrivée à partir de 14 h, départ avant 11 h. Formule journée : de 10 h à 18 h.'),
  ('Paiement', 'Un acompte de 30 % confirme la réservation ; le solde est réglé avant l’arrivée. '
      'Les séjours courts sont payés en totalité. Mobile Money, carte ou virement.'),
  ('Annulation', 'Gratuite jusqu’à 5 jours avant l’arrivée : les sommes versées sont remboursées. '
      'Au-delà, l’acompte reste acquis.'),
  ('Caution', 'Réglée à l’arrivée auprès du concierge, restituée après l’état des lieux de sortie.'),
  ('Adresse', 'L’adresse exacte et l’itinéraire sont communiqués dès la confirmation de la réservation.'),
];

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.session});

  final Session? session;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vos réservations restent liées à votre numéro : reconnectez-vous à tout moment pour les retrouver.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: const Text('Rester connecté')),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: const Text('Se déconnecter')),
        ],
      ),
    );
    if (confirmed == true) await ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = session?.user;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(HSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: HSize.avatar / 2,
                    backgroundColor: context.hc.accentSoft,
                    child: user == null
                        ? Icon(Icons.person_outline_rounded, size: HSize.icon * 1.5, color: context.hc.accentText)
                        : Text(user.displayName.characters.first.toUpperCase(),
                            style: context.tt.headlineSmall?.copyWith(color: context.hc.accentText)),
                  ),
                  const SizedBox(width: HSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user == null ? 'Bienvenue' : user.displayName, style: context.tt.titleLarge),
                        Text(
                          user == null ? 'Connectez-vous pour réserver et suivre vos séjours.' : user.phone,
                          style: context.tt.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HSpace.md),
              if (user == null)
                FilledButton(onPressed: () => context.push('/connexion'), child: const Text('Se connecter'))
              else ...[
                FilledButton.tonal(onPressed: () => context.go('/reservations'), child: const Text('Mes réservations')),
                const SizedBox(height: HSpace.xs),
                TextButton(onPressed: () => _signOut(context, ref), child: const Text('Se déconnecter')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(HSpace.gutter, HSpace.lg, HSpace.gutter, HSpace.xs),
        child: Text(text.toUpperCase(), style: context.tt.labelSmall),
      );
}
