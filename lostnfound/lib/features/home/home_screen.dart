import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {}, // Diimplementasikan Minggu 3
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              // GoRouter otomatis redirect ke /login
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Search Bar ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SearchBar(
                hintText: 'Cari barang...',
                leading: const Icon(Icons.search),
                padding: const MaterialStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
                onTap: () {}, // Diimplementasikan Minggu 2
              ),
            ),
          ),

          // ── Greeting ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Halo, ${user?.userMetadata?['full_name'] ?? 'Pengguna'} 👋',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),

          // ── Placeholder Grid ─────────────────
          // Diganti dengan data nyata di Minggu 2 Hari 10
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _PlaceholderCard(),
                childCount: 6, // Placeholder sementara
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Kartu placeholder dengan shimmer effect
// Akan diganti dengan ItemCard yang sesungguhnya di Minggu 2
class _PlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 80, color: Colors.grey.shade200),
                const SizedBox(height: 6),
                Container(height: 10, width: 60, color: Colors.grey.shade200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
