import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/room/presentation/room_detail_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../motion/cinematic_transitions.dart';

/// Mise en scène des enchaînements :
/// ouverture → (iris) → scènes d'intro → (entracte, rideaux) → affiche → (Hero) → fiche.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CinematicTransitions.crossFade(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CinematicTransitions.iris(
          key: state.pageKey,
          origin: Alignment.center,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CinematicTransitions.intermission(key: state.pageKey, child: const HomeScreen()),
        routes: [
          GoRoute(
            path: 'room/:id',
            pageBuilder: (context, state) => CinematicTransitions.crossFade(
              key: state.pageKey,
              child: RoomDetailScreen(roomId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
    ],
  );
});
