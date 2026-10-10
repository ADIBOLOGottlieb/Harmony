import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/apartment/presentation/apartment_detail_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/booking/presentation/booking_detail_screen.dart';
import '../../features/booking/presentation/booking_flow_screen.dart';
import '../../features/booking/presentation/booking_recap_screen.dart';
import '../../features/bookings/presentation/bookings_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../motion/page_transitions.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Ouverture → coque à cinq onglets. Fiche bien, réservation et connexion
/// s'ouvrent par-dessus la coque (navigateur racine).
final appRouterProvider = Provider<GoRouter>((ref) {
  GoRoute overShell(String path, Widget Function(GoRouterState state) build) => GoRoute(
        path: path,
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => softPage(key: state.pageKey, child: build(state)),
      );

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) => softPage(key: state.pageKey, child: MainShell(shell: shell)),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/accueil', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/explorer', builder: (_, _) => const ExploreScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/reservations', builder: (_, _) => const BookingsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/favoris', builder: (_, _) => const FavoritesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profil', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      overShell('/bien/:id', (s) => ApartmentDetailScreen(apartmentId: s.pathParameters['id']!)),
      overShell('/bien/:id/reserver', (s) => BookingFlowScreen(apartmentId: s.pathParameters['id']!)),
      overShell('/bien/:id/recapitulatif', (s) => BookingRecapScreen(apartmentId: s.pathParameters['id']!)),
      overShell('/reservation/:ref', (s) => BookingDetailScreen(reference: s.pathParameters['ref']!)),
      overShell('/connexion', (_) => const LoginScreen()),
    ],
  );
});
