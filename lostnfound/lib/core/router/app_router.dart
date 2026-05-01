import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/features/auth/screens/login_screen.dart';
import 'package:lostnfound/features/auth/screens/register_screen.dart';
import 'package:lostnfound/features/home/home_screen.dart';
import 'package:lostnfound/shared/screens/main_shell.dart';
import 'package:lostnfound/shared/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    refreshListenable: authNotifier,
    debugLogDiagnostics: true,

    // ── Redirect Guard ──
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      // final isSplash = state.matchedLocation == AppConstants.routeSplash;
      final isAuthPage =
          state.matchedLocation == AppConstants.routeLogin ||
          state.matchedLocation == AppConstants.routeRegister;

      // Belum login, mau ke halaman protected → paksa ke /login
      if (!isLoggedIn && !isAuthPage) return '/login';

      // Sudah login, masih di halaman login/register → ke /home
      if (isLoggedIn && isAuthPage) return '/home';

      // if (isSplash) return null;

      if (!isLoggedIn && !isAuthPage) return AppConstants.routeLogin;

      if (isLoggedIn && isAuthPage) return AppConstants.routeHome;

      return null;
    },

    routes: [
      // ── Splash ──
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Auth Routes ──
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── App Shell ──
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppConstants.routeHome,
            builder: (_, __) => const HomeScreen(),
          ),
        ],
      ),
    ],
  );
});

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
