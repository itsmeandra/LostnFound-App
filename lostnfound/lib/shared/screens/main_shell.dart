import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lostnfound/core/constants/app_constants.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const List<String> _routes = [
    '/home',
    '/laporan',
    '/track',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    for (int i = 0; i < _routes.length; i++) {
      if (currentPath.startsWith(_routes[i])) {
        currentIndex = i;
        break;
      }
    }

    const primaryDeepBlue = Color(0xFF131B2E);
    const textSecondary = Color(0xFF76777D);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (currentIndex != 0) {
          context.go(AppConstants.routeHome);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF8FA),
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: Colors.transparent,
              elevation: 0,
              height: 72,
              overlayColor: WidgetStateProperty.all(Colors.transparent),

              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryDeepBlue,
                  );
                }
                return GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                );
              }),

              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: primaryDeepBlue, size: 26);
                }
                return const IconThemeData(color: textSecondary, size: 24);
              }),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                if (index != currentIndex) {
                  context.go(_routes[index]);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.add_circle_outline),
                  selectedIcon: Icon(Icons.add_circle),
                  label: 'Laporan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.track_changes_outlined),
                  selectedIcon: Icon(Icons.track_changes),
                  label: 'Lacak',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),

        // ── Floating Action Button (Hanya muncul di tab Beranda) ──
        floatingActionButton: currentIndex == 0
            ? FloatingActionButton(
                onPressed: () => context.push(AppConstants.routeReport),
                backgroundColor: primaryDeepBlue,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add, size: 28),
              )
            : null,
      ),
    );
  }
}
