import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmony_app/app.dart';
import 'package:harmony_app/core/format/dates.dart';
import 'package:harmony_app/core/format/fcfa.dart';
import 'package:harmony_app/core/network/api_client.dart';
import 'package:harmony_app/core/router/app_router.dart';
import 'package:harmony_app/core/storage/storage.dart';
import 'package:harmony_app/core/widgets/location_map.dart';
import 'package:harmony_app/features/auth/application/session.dart';
import 'package:harmony_app/features/booking/application/booking_draft.dart';
import 'package:harmony_app/features/catalog/application/favorites.dart';
import 'package:harmony_app/features/catalog/application/search_criteria.dart';
import 'package:harmony_app/features/catalog/domain/apartment.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

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

/// Lance l'app avec une API factice (hors connexion par défaut : catalogue de démonstration),
/// des préférences en mémoire et, au besoin, une session déjà ouverte.
Future<ProviderContainer> _launch(
  WidgetTester tester, {
  FakeApi? api,
  TokenStore? tokens,
  bool signedIn = false,
}) async {
  _phone(tester);
  _reducedMotion(tester);
  final store = tokens ?? MemoryTokenStore();
  if (signedIn) await store.write('jeton-test');
  SharedPreferences.setMockInitialValues({
    if (signedIn) 'session.user.v1': jsonEncode(userJson()),
  });
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    preferencesProvider.overrideWithValue(preferences),
    apiClientProvider.overrideWithValue((api ?? FakeApi()).dio()),
    tokenStoreProvider.overrideWithValue(store),
    mapTilesEnabledProvider.overrideWithValue(false),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HarmonyApp()));
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
  return container;
}

/// Onglet de la barre du bas (le même libellé sert aussi de titre d'écran).
Finder _tab(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Jour libre du calendrier de réservation.
Future<void> _tapDay(WidgetTester tester, DateTime day) async {
  final label = '${fullDate(DateTime.utc(day.year, day.month, day.day))}, libre';
  final cell = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);
  await tester.scrollUntilVisible(cell, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(cell);
  await tester.pumpAndSettle();
}

/// Fiche Villa Lagune → « Réserver » → deux nuits → récapitulatif.
Future<void> _openRecap(WidgetTester tester, ProviderContainer container, DateTime checkIn, DateTime checkOut) async {
  container.read(appRouterProvider).push('/bien/villa-lagune');
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Réserver'));
  await tester.pumpAndSettle();
  expect(find.text('Vos dates'), findsOneWidget);

  await _tapDay(tester, checkIn);
  await _tapDay(tester, checkOut);
  final draft = container.read(bookingDraftProvider)!;
  expect((draft.checkIn, draft.checkOut, draft.isComplete), (checkIn, checkOut, true));

  await tester.tap(find.text('Voir le récapitulatif'));
  await tester.pumpAndSettle();
  expect(find.text('Récapitulatif'), findsOneWidget);
}

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
      // API injoignable : le catalogue embarqué est affiché et signalé.
      expect(find.text('Hors connexion'), findsOneWidget);
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

    testWidgets('les filtres d’équipements restreignent les résultats', (tester) async {
      final container = await _launch(tester);
      await tester.tap(_tab('Explorer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Filtres'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Piscine'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Appliquer'));
      await tester.pumpAndSettle();

      expect(find.text('Filtres · 1'), findsOneWidget);
      expect(container.read(searchCriteriaProvider).amenities, {Amenity.pool});
      final results = container.read(searchResultsProvider);
      expect(results, isNotEmpty);
      expect(results.every((a) => a.amenities.contains(Amenity.pool)), isTrue);
    });

    testWidgets('la fiche bien affiche équipements, tarifs et carte du quartier', (tester) async {
      final semantics = tester.ensureSemantics();
      await _launch(tester);

      await tester.tap(find.bySemanticsLabel(RegExp('^Villa Lagune, Villa')));
      await tester.pumpAndSettle();

      expect(find.text('Villa Lagune'), findsWidgets);
      await tester.scrollUntilVisible(find.text('Piscine'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Équipements'), findsOneWidget);
      expect(find.text('Piscine'), findsOneWidget);
      expect(find.text(fcfa(150000)), findsWidgets);
      await tester.scrollUntilVisible(find.byType(LocationMap), 300, scrollable: find.byType(Scrollable).first);
      expect(find.byType(LocationMap), findsOneWidget);
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

  group('Compte et réservation', () {
    final today = todayInLome();
    final checkIn = DateTime(today.year, today.month, today.day + 2);
    final checkOut = DateTime(today.year, today.month, today.day + 4);

    testWidgets('sans session, l’onglet Réservations invite à se connecter', (tester) async {
      await _launch(tester);
      await tester.tap(_tab('Réservations'));
      await tester.pumpAndSettle();
      expect(find.text('Connectez-vous pour voir vos séjours'), findsOneWidget);
    });

    testWidgets('connexion par téléphone et code depuis le profil', (tester) async {
      final api = FakeApi({
        'POST /auth/otp': (_) => {'message': 'Code envoyé.', 'debug_code': '123456'},
        'POST /auth/verify': (_) => {'token': 'jeton-recu', 'user': userJson()},
      });
      final tokens = MemoryTokenStore();
      final container = await _launch(tester, api: api, tokens: tokens);

      await tester.tap(_tab('Profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Numéro de téléphone'), '90 00 00 00');
      await tester.tap(find.widgetWithText(FilledButton, 'Recevoir un code'));
      await tester.pumpAndSettle();
      expect(api.last('POST /auth/otp')!.data, {'phone': '+22890000000'});
      expect(find.textContaining('votre code est 123456'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Code à 6 chiffres'), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
      await tester.pumpAndSettle();

      expect(await tokens.read(), 'jeton-recu');
      expect(container.read(sessionProvider)?.user.name, 'Afi');
      expect(find.text('Afi'), findsOneWidget);
      expect(find.text('Se déconnecter'), findsOneWidget);
    });

    testWidgets('réserver deux nuits et payer par virement', (tester) async {
      final booking = bookingJson(
        checkIn: checkIn,
        checkOut: checkOut,
        instructions: 'Virement sur le compte HARMONY HOME, référence HH-TEST01.',
      );
      final api = FakeApi({
        'GET /apartments/villa-lagune/availability': (r) => {'data': availabilityJson(r)},
        'POST /bookings/quote': (_) => {'data': quoteJson(checkIn, checkOut)},
        'POST /bookings': (_) => FakeReply(201, {'data': booking}),
        'GET /bookings/HH-TEST01': (_) => {'data': booking},
      });
      final container = await _launch(tester, api: api, signedIn: true);

      await _openRecap(tester, container, checkIn, checkOut);
      expect(find.text('Acompte à payer maintenant'), findsOneWidget);
      expect(find.text(fcfa(94500)), findsOneWidget);
      expect(find.text(fcfa(315000)), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Virement bancaire'), 200, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('Virement bancaire'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Virement bancaire'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Réserver et payer par virement'));
      await tester.pumpAndSettle();

      final sent = api.last('POST /bookings')!.data as Map;
      expect(sent['apartment'], 'villa-lagune');
      expect(sent['stay_type'], 'night');
      expect(sent['check_in'], isoDay(checkIn));
      expect(sent['check_out'], isoDay(checkOut));
      expect(sent['payment_method'], 'bank_transfer');

      expect(find.text('Réservation HH-TEST01'), findsOneWidget);
      expect(find.text('Paiement en attente'), findsOneWidget);
      expect(find.textContaining('référence HH-TEST01'), findsOneWidget);
      // L'adresse exacte n'est jamais affichée avant confirmation.
      expect(find.text('Adresse'), findsNothing);
    });

    testWidgets('des dates prises entre-temps affichent un message clair', (tester) async {
      final api = FakeApi({
        'GET /apartments/villa-lagune/availability': (r) => {'data': availabilityJson(r)},
        'POST /bookings/quote': (_) => {'data': quoteJson(checkIn, checkOut)},
        'POST /bookings': (_) => const FakeReply(409, {
              'message': 'Ces dates viennent d’être réservées. Choisissez d’autres dates.',
              'code': 'dates_unavailable',
            }),
      });
      final container = await _launch(tester, api: api, signedIn: true);

      await _openRecap(tester, container, checkIn, checkOut);
      await tester.tap(find.textContaining('Payer '));
      await tester.pumpAndSettle();

      expect(find.text('Ces dates viennent d’être réservées. Choisissez d’autres dates.'), findsOneWidget);
      expect(find.text('Récapitulatif'), findsOneWidget);
    });
  });
}
