import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/core/services/fcm_service.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/features/auth/screens/login_screen.dart';
import 'package:lostnfound/features/auth/screens/register_screen.dart';
import 'package:lostnfound/features/claim/widgets/my_claims_screen.dart';
import 'package:lostnfound/features/home/home_screen.dart';
import 'package:lostnfound/features/item/screens/item_detail_screen.dart';
import 'package:lostnfound/features/notification/notification_screen.dart';
import 'package:lostnfound/features/profile/profile_screen.dart';
import 'package:lostnfound/features/report/screens/my_reports_screen.dart';
import 'package:lostnfound/features/report/screens/report_form_screen.dart';
import 'package:lostnfound/features/track/track_screen.dart';
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

      // if (isSplash) return null;

      // Belum login, mau ke halaman protected → paksa ke /login
      if (!isLoggedIn && !isAuthPage) return AppConstants.routeLogin;

      // Sudah login, masih di halaman login/register → ke /home
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
      GoRoute(
        path: AppConstants.routeReport, // '/report'
        builder: (_, __) => const ReportFormScreen(),
      ),
      GoRoute(
        path: '/item/:id',
        builder: (context, state) {
          // Ambil parameter ID dari URL
          final itemId = state.pathParameters['id']!;
          return ItemDetailScreen(itemId: itemId);
        },
      ),
      GoRoute(path: '/my-reports', builder: (_, __) => const MyReportsScreen()),
      GoRoute(
        path: AppConstants.routeMyClaims,
        builder: (_, __) => const MyClaimsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationScreen(),
      ),

      // ── App Shell ──
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/laporan',
            builder: (_, __) => const ReportFormScreen(),
          ),
          GoRoute(path: '/track', builder: (_, __) => const TrackScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});

class _AuthNotifier extends ChangeNotifier {
  final Ref _ref;
  GoRouter? _router;

  _AuthNotifier(Ref ref) : _ref = ref {
    ref.listen(authStateProvider, (prev, next) {
      final event = next.value?.event;

      // Saat user login (email, Google, atau session restore)
      if (event == AuthChangeEvent.signedIn) {
        _initFCM();
      }
      notifyListeners();
    });
  }

  // Init FCM dengan callback navigasi
  Future<void> _initFCM() async {
    try {
      await FCMService().initialize(
        onTap: (route, itemID) {
          // Navigasi dari notifikasi → pakai router
          _router?.go(route);
        },
      );
    } catch (e) {
      debugPrint('Router: FCM ini gagal: $e');
    }
  }
}
