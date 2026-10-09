import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmony_app/app.dart';
import 'package:harmony_app/core/format/dates.dart';
import 'package:harmony_app/core/format/fcfa.dart';
import 'package:harmony_app/core/router/app_router.dart';
import 'package:harmony_app/features/catalog/application/favorites.dart';

/// Téléphone de référence : 390 × 844 dp.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Réglage « réduire les animations » : coupe les boucles (squelettes animés)
/// et vérifie au passage ce mode d'accessibilité.
void _reducedMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<ProviderContainer> _launch(WidgetTester tester) async {
  _phone(tester);
  _reducedMotion(tester);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HarmonyApp()));
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
  return container;
}

/// Onglet de la barre du bas (le même libellé sert aussi de titre d'écran).
Finder _tab(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  group('Formatage', () {
    test('FCFA : espace fine insécable entre les milliers', () {
      expect(fcfa(15000), '15 000 FCFA');
      expect(fcfa(500), '500 FCFA');
      expect(fcfa(1250000), '1 250 000 FCFA');
    });

    test('dates : plage lisible et nombre de nuits', () {
      final sameMonth = DateTimeRange(start: DateTime(2026, 10, 12), end: DateTime(2026, 10, 15));
      final twoMonths = DateTimeRange(start: DateTime(2026, 10, 30), end: DateTime(2026, 11, 2));
      expect(dateRangeLabel(sameMonth), '12 – 15 oct.');
      expect(dateRangeLabel(twoMonths), '30 oct. – 2 nov.');
      expect(nightsIn(sameMonth), 3);
      expect(plural(1, 'nuit'), '1 nuit');
      expect(plural(3, 'nuit'), '3 nuits');
    });
  });

  group('Parcours client', () {
    testWidgets('l’ouverture mène à l’accueil et ses sections', (tester) async {
      await _launch(tester);
      expect(find.text('Votre adresse\nd’exception à Lomé'), findsOneWidget);
      expect(find.text('Appartements à la une'), findsOneWidget);
      expect(find.text('Rechercher'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Nouveautés'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Par zone'), findsOneWidget);
    });

    testWidgets('rechercher par zone filtre l’écran Explorer', (tester) async {
      final semantics = tester.ensureSemantics();
      await _launch(tester);

      await tester.tap(find.bySemanticsLabel(RegExp('^Destination')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Baguida')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rechercher'));
      await tester.pumpAndSettle();

      expect(find.text('1 bien à Lomé'), findsOneWidget);
      expect(find.text('Villa Lagune'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('la fiche bien affiche équipements, tarifs et réservation', (tester) async {
      final semantics = tester.ensureSemantics();
      await _launch(tester);

      await tester.tap(find.bySemanticsLabel(RegExp('^Villa Lagune, Villa')));
      await tester.pumpAndSettle();

      expect(find.text('Villa Lagune'), findsWidgets);
      await tester.scrollUntilVisible(find.text('Piscine'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Équipements'), findsOneWidget);
      expect(find.text('Piscine'), findsOneWidget);
      expect(find.text(fcfa(150000)), findsWidgets);

      await tester.tap(find.widgetWithText(FilledButton, 'Réserver'));
      await tester.pump();
      expect(find.textContaining('La réservation en ligne arrive'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('un bien en maintenance ne peut pas être réservé', (tester) async {
      final container = await _launch(tester);
      container.read(appRouterProvider).push('/bien/appartement-indigo');
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'En maintenance'));
      expect(button.onPressed, isNull);
    });

    testWidgets('un favori apparaît dans l’onglet Favoris', (tester) async {
      final semantics = tester.ensureSemantics();
      final container = await _launch(tester);

      await tester.tap(_tab('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Aucun favori'), findsOneWidget);

      await tester.tap(_tab('Accueil'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Ajouter Villa Lagune aux favoris'));
      await tester.pumpAndSettle();
      // Le cœur ajoute aux favoris sans ouvrir la fiche du bien.
      expect(container.read(favoritesProvider), contains('villa-lagune'));
      expect(container.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path, '/accueil');

      await tester.tap(_tab('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Aucun favori'), findsNothing);
      expect(find.text('Villa Lagune'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('le mode sombre se choisit dans le profil', (tester) async {
      await _launch(tester);
      await tester.tap(_tab('Profil'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sombre'));
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.text('Apparence'))).brightness, Brightness.dark);
    });
  });
}
