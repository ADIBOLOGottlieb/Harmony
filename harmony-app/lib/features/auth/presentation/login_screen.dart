import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/harmony_logo.dart';
import '../application/session.dart';
import '../data/auth_api.dart';

/// Connexion en deux temps : numéro de téléphone, puis code reçu par SMS.
/// Ferme l'écran avec `true` en cas de succès.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController(text: '+228 ');
  final _code = TextEditingController();
  final _name = TextEditingController();
  String? _sentTo;
  String? _debugCode;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final phone = normalizePhone(_phone.text);
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      setState(() => _error = 'Saisissez un numéro valide, par exemple +228 90 12 34 56.');
      return;
    }
    await _run(() async {
      final debug = await ref.read(authApiProvider).requestOtp(phone);
      setState(() {
        _sentTo = phone;
        _debugCode = debug;
        _code.clear();
      });
    });
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _error = 'Le code contient 6 chiffres.');
      return;
    }
    await _run(() async {
      final result = await ref.read(authApiProvider).verify(_sentTo!, _code.text.trim(), name: _name.text);
      await ref.read(sessionProvider.notifier).signIn(result.token, result.user);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/profil');
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = ApiError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeStep = _sentTo != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HSpace.gutter),
          children: [
            const Center(child: HarmonyMark(size: 64)),
            const SizedBox(height: HSpace.lg),
            Text(
              codeStep ? 'Entrez le code reçu' : 'Votre numéro de téléphone',
              style: context.tt.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HSpace.xs),
            Text(
              codeStep
                  ? 'Nous avons envoyé un code à 6 chiffres au $_sentTo.'
                  : 'Recevez un code par SMS pour réserver et suivre vos séjours. Aucun mot de passe à retenir.',
              style: context.tt.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HSpace.xl),
            if (!codeStep)
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(labelText: 'Numéro de téléphone', prefixIcon: Icon(Icons.phone_outlined)),
                onSubmitted: (_) => _send(),
              )
            else ...[
              if (_debugCode != null)
                Container(
                  margin: const EdgeInsets.only(bottom: HSpace.md),
                  padding: const EdgeInsets.all(HSpace.md),
                  decoration: BoxDecoration(color: context.hc.accentSoft, borderRadius: BorderRadius.circular(HRadius.md)),
                  child: Text(
                    'Mode démonstration (aucun SMS envoyé) : votre code est $_debugCode.',
                    style: HText.labelSmall.copyWith(color: context.cs.onSurface),
                  ),
                ),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Code à 6 chiffres', prefixIcon: Icon(Icons.lock_outline_rounded), counterText: ''),
              ),
              const SizedBox(height: HSpace.sm),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                decoration: const InputDecoration(labelText: 'Votre prénom (facultatif)', prefixIcon: Icon(Icons.person_outline_rounded)),
                onSubmitted: (_) => _verify(),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: HSpace.md),
              Semantics(
                liveRegion: true,
                child: Text(_error!, style: HText.bodySmall.copyWith(color: context.cs.error)),
              ),
            ],
            const SizedBox(height: HSpace.lg),
            FilledButton(
              onPressed: _busy ? null : (codeStep ? _verify : _send),
              child: _busy
                  ? SizedBox.square(dimension: HSize.icon, child: CircularProgressIndicator(strokeWidth: 2, color: context.cs.onPrimary))
                  : Text(codeStep ? 'Se connecter' : 'Recevoir un code'),
            ),
            if (codeStep) ...[
              const SizedBox(height: HSpace.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: _busy ? null : () => setState(() => _sentTo = null), child: const Text('Changer de numéro')),
                  TextButton(onPressed: _busy ? null : _send, child: const Text('Renvoyer le code')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
