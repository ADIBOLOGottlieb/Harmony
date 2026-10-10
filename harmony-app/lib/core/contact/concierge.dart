import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/i18n.dart';
import '../config/app_config.dart';

/// Appel ou WhatsApp vers le concierge. Message clair si le numéro n'est pas encore configuré.
Future<void> contactConcierge(BuildContext context, {required bool whatsapp}) async {
  const phone = AppConfig.conciergePhone;
  if (phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('Le numéro du concierge sera bientôt disponible.'))),
    );
    return;
  }
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  final uri = whatsapp ? Uri.https('wa.me', '/$digits') : Uri(scheme: 'tel', path: phone);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('Impossible d’ouvrir l’application.'))));
  }
}
