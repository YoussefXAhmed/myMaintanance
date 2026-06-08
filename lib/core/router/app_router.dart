import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/advisor/advisor_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/documents/documents_screen.dart';
import '../../features/expenses/expenses_screen.dart';
import '../../features/fuel/fuel_screen.dart';
import '../../features/home/home_dashboard.dart';
import '../../features/maintenance/maintenance_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/vehicles/add_vehicle_screen.dart';
import '../../features/vehicles/vehicles_screen.dart';
import '../../models/vehicle.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

/// Route paths, kept in one place to avoid stringly-typed drift.
class AppRoutes {
  AppRoutes._();
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';

  static const home = '/home';
  static const maintenance = '/maintenance';
  static const fuel = '/fuel';
  static const expenses = '/expenses';
  static const more = '/more';

  static const vehicles = '/vehicles';
  static const addVehicle = '/vehicles/add';
  static const documents = '/documents';
  static const analytics = '/analytics';
  static const advisor = '/advisor';
  static const profile = '/profile';
  static const settings = '/settings';
}

/// Re-evaluates redirects whenever auth or onboarding state changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
    ref.listen(settingsProvider.select((s) => s.onboardingComplete), (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authControllerProvider).isAuthenticated;
      final onboarded = ref.read(settingsProvider).onboardingComplete;
      final loc = state.matchedLocation;

      final isSplash = loc == AppRoutes.splash;
      final isOnboarding = loc == AppRoutes.onboarding;
      final isAuthRoute = {
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.verifyEmail,
      }.contains(loc);

      if (isSplash) return null; // splash decides when it's ready

      if (!onboarded) return isOnboarding ? null : AppRoutes.onboarding;
      if (isOnboarding) return loggedIn ? AppRoutes.home : AppRoutes.login;

      if (!loggedIn) return isAuthRoute ? null : AppRoutes.login;
      if (isAuthRoute && loc != AppRoutes.verifyEmail) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.verifyEmail, builder: (_, __) => const VerifyEmailScreen()),

      // Bottom-nav shell.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeDashboard())]),
          StatefulShellBranch(
              routes: [GoRoute(path: AppRoutes.maintenance, builder: (_, __) => const MaintenanceScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.fuel, builder: (_, __) => const FuelScreen())]),
          StatefulShellBranch(
              routes: [GoRoute(path: AppRoutes.expenses, builder: (_, __) => const ExpensesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.more, builder: (_, __) => const MoreScreen())]),
        ],
      ),

      // Full-screen routes (pushed above the shell).
      GoRoute(path: AppRoutes.vehicles, builder: (_, __) => const VehiclesScreen()),
      GoRoute(
        path: AppRoutes.addVehicle,
        builder: (_, state) => AddVehicleScreen(vehicle: state.extra as Vehicle?),
      ),
      GoRoute(path: AppRoutes.documents, builder: (_, __) => const DocumentsScreen()),
      GoRoute(path: AppRoutes.analytics, builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: AppRoutes.advisor, builder: (_, __) => const AdvisorScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
    ],
  );
});
