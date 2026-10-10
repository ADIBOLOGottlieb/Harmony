import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/contact/concierge.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_logo.dart';
import '../../../core/widgets/harmony_sheet.dart';
import '../../auth/application/session.dart';
import '../../auth/data/auth_api.dart';
import '../application/preferences.dart';
import '../application/theme_mode.dart';

/// Sélection d'une photo sur l'appareil (remplaçable dans les tests). Renvoie le chemin du fichier.
final avatarPickerProvider = Provider<Future<String?> Function(ImageSource source)>(
  (ref) => (source) async =>
      (await ImagePicker().pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85))?.path,
);

/// Profil : compte et photo, préférences (apparence, langue, devise), galerie, assistance.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);
    final currency = ref.watch(currencyProvider);
    final session = ref.watch(sessionProvider);

    Widget choice<T>(String title, Set<T> selected, List<ButtonSegment<T>> segments, ValueChanged<T> onChanged) => Padding(
          padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.tt.titleMedium),
              const SizedBox(height: HSpace.xs),
              SegmentedButton<T>(
                showSelectedIcon: false,
                segments: segments,
                selected: selected,
                onSelectionChanged: (s) {
                  HapticFeedback.selectionClick();
                  onChanged(s.first);
                },
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(t('Profil'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: HSpace.sm),
        children: [
          _AccountCard(session: session),
          _GroupTitle(t('Préférences')),
          choice<ThemeMode>(
            t('Apparence'),
            {mode},
            [
              ButtonSegment(value: ThemeMode.system, label: Text(t('Système'))),
              ButtonSegment(value: ThemeMode.light, label: Text(t('Clair'))),
              ButtonSegment(value: ThemeMode.dark, label: Text(t('Sombre'))),
            ],
            (m) => ref.read(themeModeProvider.notifier).set(m),
          ),
          choice<AppLanguage>(
            t('Langue'),
            {language},
            [for (final l in AppLanguage.values) ButtonSegment(value: l, label: Text(l.label))],
            (l) => ref.read(languageProvider.notifier).set(l),
          ),
          choice<DisplayCurrency>(
            t('Devise d’affichage'),
            {currency},
            [for (final c in DisplayCurrency.values) ButtonSegment(value: c, label: Text(c.code))],
            (c) => ref.read(currencyProvider.notifier).set(c),
          ),
          if (currency != DisplayCurrency.xof)
            Padding(
              padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.sm),
              child: Text(
                t('Prix convertis à titre indicatif : les paiements restent en FCFA.'),
                style: context.tt.bodyMedium,
              ),
            ),
          _GroupTitle(t('Galerie d’art')),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
            leading: const Icon(Icons.palette_outlined),
            title: Text(t('La galerie')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/galerie'),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
            leading: const Icon(Icons.shopping_bag_outlined),
            title: Text(t('Mes acquisitions')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/acquisitions'),
          ),
          _GroupTitle(t('Assistance')),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
            leading: const Icon(Icons.support_agent_outlined),
            title: Text(t('Contacter la conciergerie')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _contactSheet(context),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
            leading: const Icon(Icons.description_outlined),
            title: Text(t('Conditions et politique d’annulation')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _conditionsSheet(context),
          ),
          const SizedBox(height: HSpace.xl),
          const Center(child: HarmonyLogo()),
          const SizedBox(height: HSpace.xs),
          Center(child: Text(t('Version 0.4 · aperçu'), style: context.tt.bodyMedium)),
          const SizedBox(height: HSpace.xl),
        ],
      ),
    );
  }
}

Future<void> _contactSheet(BuildContext context) => showHarmonySheet<void>(
      context,
      title: t('Contacter la conciergerie'),
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t('Notre concierge vous répond 7 j/7, de 7 h à 22 h.'), style: sheet.tt.bodyLarge),
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
              label: Text(t('Appeler')),
            ),
          ],
        ),
      ),
    );

Future<void> _conditionsSheet(BuildContext context) => showHarmonySheet<void>(
      context,
      title: t('Conditions de séjour'),
      builder: (sheet) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(HSpace.gutter, 0, HSpace.gutter, HSpace.lg),
        children: [
          for (final (title, body) in _conditions) ...[
            Text(t(title), style: sheet.tt.titleMedium),
            const SizedBox(height: HSpace.xxs),
            Text(t(body), style: sheet.tt.bodyMedium),
            const SizedBox(height: HSpace.md),
          ],
        ],
      ),
    );

const _conditions = [
  ('Horaires', 'Arrivée à partir de 14 h, départ avant 11 h. Formule journée : de 10 h à 18 h.'),
  ('Paiement', 'Un acompte de 30 % confirme la réservation ; le solde est réglé avant l’arrivée. Les séjours courts sont payés en totalité. Mobile Money, carte ou virement.'),
  ('Annulation', 'Gratuite jusqu’à 5 jours avant l’arrivée : les sommes versées sont remboursées. Au-delà, l’acompte reste acquis.'),
  ('Caution', 'Réglée à l’arrivée auprès du concierge, restituée après l’état des lieux de sortie.'),
  ('Adresse', 'L’adresse exacte et l’itinéraire sont communiqués dès la confirmation de la réservation.'),
];

class _AccountCard extends ConsumerStatefulWidget {
  const _AccountCard({required this.session});

  final Session? session;

  @override
  ConsumerState<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<_AccountCard> {
  bool _uploading = false;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changePhoto(AppUser user) async {
    final action = await showHarmonySheet<String>(
      context,
      title: t('Photo de profil'),
      builder: (sheet) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: HSpace.lg),
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(t('Choisir dans la galerie')),
            onTap: () => Navigator.of(sheet).pop('gallery'),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(t('Prendre une photo')),
            onTap: () => Navigator.of(sheet).pop('camera'),
          ),
          if (user.avatar != null)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: HSpace.gutter),
              leading: Icon(Icons.delete_outline_rounded, color: context.cs.error),
              title: Text(t('Retirer la photo')),
              onTap: () => Navigator.of(sheet).pop('remove'),
            ),
        ],
      ),
    );
    if (action == null || !mounted) return;

    final api = ref.read(authApiProvider);
    try {
      Future<AppUser> request;
      if (action == 'remove') {
        request = api.removeAvatar();
      } else {
        final path = await ref.read(avatarPickerProvider)(action == 'camera' ? ImageSource.camera : ImageSource.gallery);
        if (path == null) return;
        request = api.uploadAvatar(path);
      }
      setState(() => _uploading = true);
      final updated = await request;
      await ref.read(sessionProvider.notifier).updateUser(updated);
      HapticFeedback.mediumImpact();
      if (mounted) _snack(action == 'remove' ? t('Photo retirée.') : t('Photo de profil mise à jour.'));
    } catch (e) {
      final error = ApiError.from(e);
      if (error.status == 401) await ref.read(sessionProvider.notifier).expire();
      if (mounted) _snack(error.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(t('Se déconnecter ?')),
        content: Text(t('Vos réservations restent liées à votre numéro : reconnectez-vous à tout moment pour les retrouver.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(t('Rester connecté'))),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(t('Se déconnecter'))),
        ],
      ),
    );
    if (confirmed == true) await ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session?.user;
    final avatarUrl = user?.avatar;
    final avatar = CircleAvatar(
      radius: HSize.avatar / 2,
      backgroundColor: context.hc.accentSoft,
      foregroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
      onForegroundImageError: avatarUrl == null ? null : (_, _) {},
      child: user == null
          ? Icon(Icons.person_outline_rounded, size: HSize.icon * 1.5, color: context.hc.accentText)
          : Text(user.displayName.characters.first.toUpperCase(),
              style: context.tt.headlineSmall?.copyWith(color: context.hc.accentText)),
    );

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
                  if (user == null)
                    avatar
                  else
                    Semantics(
                      button: true,
                      label: t('Changer la photo de profil'),
                      excludeSemantics: true,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _uploading ? null : () => _changePhoto(user),
                        child: Stack(
                          children: [
                            avatar,
                            if (_uploading)
                              const Positioned.fill(child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: HSize.iconSm * 0.75,
                                backgroundColor: context.cs.primary,
                                child: Icon(Icons.photo_camera_outlined, size: HSize.iconSm * 0.8, color: context.cs.onPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: HSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user == null ? t('Bienvenue') : user.displayName, style: context.tt.titleLarge),
                        Text(
                          user == null ? t('Connectez-vous pour réserver et suivre vos séjours.') : user.phone,
                          style: context.tt.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HSpace.md),
              if (user == null)
                FilledButton(onPressed: () => context.push('/connexion'), child: Text(t('Se connecter')))
              else ...[
                FilledButton.tonal(onPressed: () => context.go('/reservations'), child: Text(t('Mes réservations'))),
                const SizedBox(height: HSpace.xs),
                TextButton(onPressed: _signOut, child: Text(t('Se déconnecter'))),
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
