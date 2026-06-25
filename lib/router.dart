import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/user_profile_provider.dart';
import 'screens/shell_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/goals/goals_screen.dart';
import 'screens/purchases/purchases_screen.dart';
import 'screens/projection/projection_screen.dart';
import 'screens/ledger/ledger_screen.dart';
import 'screens/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final profile = ref.watch(userProfileProvider);
  return buildAppRouter(profile?.onboardingComplete ?? false);
});

GoRouter buildAppRouter(bool onboardingComplete) {
  return GoRouter(
    initialLocation:
        onboardingComplete ? '/dashboard' : '/onboarding',
    redirect: (context, state) {
      // Handled by initialLocation logic
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goals',
                builder: (context, state) => const GoalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/purchases',
                builder: (context, state) => const PurchasesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projection',
                builder: (context, state) => const ProjectionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ledger',
                builder: (context, state) => const LedgerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
