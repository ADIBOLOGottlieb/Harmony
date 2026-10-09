import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/apartment/presentation/apartment_detail_screen.dart';
import '../../features/bookings/presentation/bookings_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../motion/page_transitions.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Ouverture → coque à cinq onglets. La fiche bien s'ouvre par-dessus la coque.
final appRouterProvider = Provider<GoRouter>((ref) {
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
      GoRoute(
        path: '/bien/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => softPage(
          key: state.pageKey,
          child: ApartmentDetailScreen(apartmentId: state.pathParameters['id']!),
        ),
      ),
    ],
  );
});
