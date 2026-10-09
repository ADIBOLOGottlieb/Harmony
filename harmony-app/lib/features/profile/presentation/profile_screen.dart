import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_logo.dart';
import '../application/theme_mode.dart';

/// Profil : compte (connexion à venir), préférences, assistance.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what arrive bientôt.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: HSpace.sm),
        children: [
          Padding(
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
                          child: Icon(Icons.person_outline_rounded, size: HSize.icon * 1.5, color: context.hc.accentText),
                        ),
                        const SizedBox(width: HSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bienvenue', style: context.tt.titleLarge),
                              Text('Connectez-vous pour réserver et suivre vos séjours.', style: context.tt.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: HSpace.md),
                    FilledButton(
                      onPressed: () => _soon(context, 'La connexion par numéro de téléphone'),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
            onTap: () => _soon(context, 'Le contact direct avec la conciergerie'),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
            leading: const Icon(Icons.description_outlined),
            title: const Text('Conditions et politique d’annulation'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _soon(context, 'La page des conditions'),
          ),
          const SizedBox(height: HSpace.xl),
          const Center(child: HarmonyLogo()),
          const SizedBox(height: HSpace.xs),
          Center(child: Text('Version 0.2 · aperçu', style: context.tt.bodyMedium)),
          const SizedBox(height: HSpace.xl),
        ],
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
