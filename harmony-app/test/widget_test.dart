import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmony_app/app.dart';
import 'package:harmony_app/core/format/fcfa.dart';

/// Téléphone de référence : 360 × 780 dp.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Réglage « réduire les animations » : toutes les boucles infinies s'arrêtent,
/// ce qui permet aussi de vérifier ce mode d'accessibilité.
void _reducedMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _launchToHome(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: HarmonyApp()));
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Passer'));
  await tester.pumpAndSettle();
}

void main() {
  group('fcfa', () {
    test('groupe les milliers avec une espace fine insécable', () {
      expect(fcfa(15000), '15 000 FCFA');
      expect(fcfa(500), '500 FCFA');
      expect(fcfa(1250000), '1 250 000 FCFA');
    });
  });

  group('Parcours (animations réduites)', () {
    testWidgets('ouverture puis première scène', (tester) async {
      _phone(tester);
      _reducedMotion(tester);
      await tester.pumpWidget(const ProviderScope(child: HarmonyApp()));
      expect(find.text('Séance privée · Lomé'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
      expect(find.text('SCÈNE 01'), findsOneWidget);
    });

    testWidgets('les scènes défilent jusqu’à l’entrée dans la salle', (tester) async {
      _phone(tester);
      _reducedMotion(tester);
      await tester.pumpWidget(const ProviderScope(child: HarmonyApp()));
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scène suivante'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scène suivante'));
      await tester.pumpAndSettle();
      expect(find.text('SCÈNE 03'), findsOneWidget);

      await tester.tap(find.text('Entrer dans la salle'));
      await tester.pumpAndSettle();
      expect(find.text('À L’AFFICHE'), findsOneWidget);
    });

    testWidgets('choisir une séance met à jour le prix de l’affiche', (tester) async {
      _phone(tester);
      _reducedMotion(tester);
      await _launchToHome(tester);

      expect(find.text('Suite Lagune'), findsOneWidget);
      expect(find.text(fcfa(55000)), findsOneWidget); // nuitée par défaut

      await tester.tap(find.bySemanticsLabel(RegExp('^3 heures')));
      await tester.pumpAndSettle();
      expect(find.text(fcfa(25000)), findsOneWidget);
    });

    testWidgets('toucher l’affiche ouvre la fiche chambre', (tester) async {
      _phone(tester);
      _reducedMotion(tester);
      await _launchToHome(tester);

      await tester.tap(find.bySemanticsLabel(RegExp('^Suite Lagune')));
      await tester.pumpAndSettle();
      expect(find.text('SYNOPSIS'), findsOneWidget);
      expect(find.text('Réserver'), findsOneWidget);

      await tester.tap(find.text('Réserver'));
      await tester.pump();
      expect(find.textContaining('la billetterie ouvre très bientôt'), findsOneWidget);
    });
  });

  testWidgets('animations complètes : un toucher passe l’ouverture', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const ProviderScope(child: HarmonyApp()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('TOUCHER POUR PASSER'), findsOneWidget);

    await tester.tapAt(const Offset(180, 390));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('SCÈNE 01'), findsOneWidget);
  });
}
