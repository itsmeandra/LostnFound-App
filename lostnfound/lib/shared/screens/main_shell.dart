import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  // Mapping index tab ke route path
  static const List<String> _routes = [
    AppConstants.routeHome, // index 0 - Beranda
    '/track', // index 1 - Lacak (ditambahkan minggu 2)
    AppConstants.routeProfile, // index 2 - Profil
  ];

  @override
  Widget build(BuildContext context) {
    // Tentukan index aktif berdasarkan route saat ini
    final currentPath = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    for (int i = 0; i < _routes.length; i++) {
      if (currentPath.startsWith(_routes[i])) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child, // Konten halaman aktif dari GoRouter
      bottomNavigationBar: NavigationBar(
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
      // FAB "Lapor Hilang" hanya muncul di tab Beranda (index 0)
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppConstants.routeReport),
              icon: const Icon(Icons.add),
              label: const Text('Lapor Hilang'),
            )
          : null,
    );
  }
}
