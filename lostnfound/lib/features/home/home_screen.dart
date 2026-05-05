import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
import 'package:lostnfound/core/theme/app_theme.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = '';

  static const _categories = [
    {'value': '', 'label': 'Semua'},
    {'value': 'electronics', 'label': 'Elektronik'},
    {'value': 'wallet', 'label': 'Dompet'},
    {'value': 'keys', 'label': 'Kunci'},
    {'value': 'bag', 'label': 'Tas'},
    {'value': 'documents', 'label': 'Dokumen'},
    {'value': 'other', 'label': 'Lainnya'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] as String? ?? 'Pengguna';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost n Found'),
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
          //───── Search Bar ─────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SearchBar(
                hintText: 'Cari barang hilang atau temuan...',
                leading: const Icon(Icons.search, size: 20),
                padding: const MaterialStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14),
                ),
                elevation: const MaterialStatePropertyAll(0),
                backgroundColor: MaterialStatePropertyAll(
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                ),
                onTap: () {}, // Diimplementasikan Minggu 2
              ),
            ),
          ),

          //───── Greeting ─────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleMedium,
                  children: [
                    const TextSpan(text: 'Halo, '),
                    TextSpan(
                      text: userName.split(' ').first,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const TextSpan(text: '!'),
                  ],
                ),
              ),
            ),
          ),

          //───── Filter Chip Kategori ─────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat['value'];
                  return FilterChip(
                    label: Text(cat['label']!),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedCategory = cat['value']!;
                    }),
                    showCheckmark: false,
                  );
                },
              ),
            ),
          ),

          //───── Section Label ─────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Barang Temuan Terbaru',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),

          //───── Grid Item ─────
          // TODO Minggu 2: ganti SliverGrid ini dengan
          // data dari Supabase via Riverpod StreamProvider
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _PlaceholderItemCard(index: index),
                childCount: 6,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),

          // ───── Placeholder Grid ─────
          // Diganti dengan data nyata di Minggu 2 Hari 10
          // SliverPadding(
          //   padding: const EdgeInsets.all(16),
          //   sliver: SliverGrid(
          //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          //       crossAxisCount: 2,
          //       crossAxisSpacing: 12,
          //       mainAxisSpacing: 12,
          //       childAspectRatio: 0.85,
          //     ),
          //     delegate: SliverChildBuilderDelegate(
          //       (context, index) => _PlaceholderCard(),
          //       childCount: 6, // Placeholder sementara
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

// Kartu placeholder dengan shimmer effect
// Akan diganti dengan ItemCard yang sesungguhnya di Minggu 2
class _PlaceholderItemCard extends StatelessWidget {
  final int index;
  const _PlaceholderItemCard({required this.index});

  // Data dummy untuk preview
  static const _dummies = [
    {
      'name': 'Dompet Hitam',
      'cat': 'Dompet',
      'loc': 'Kantin A',
      'status': 'published',
      'icon': '👛',
    },
    {
      'name': 'Kunci Motor',
      'cat': 'Kunci',
      'loc': 'Parkiran B',
      'status': 'published',
      'icon': '🔑',
    },
    {
      'name': 'MacBook Air',
      'cat': 'Elektronik',
      'loc': 'Perpus',
      'status': 'claimed',
      'icon': '💻',
    },
    {
      'name': 'KTM / KTP',
      'cat': 'Dokumen',
      'loc': 'Koridor C',
      'status': 'published',
      'icon': '📄',
    },
    {
      'name': 'Earphone TWS',
      'cat': 'Elektronik',
      'loc': 'Lab 3',
      'status': 'published',
      'icon': '🎧',
    },
    {
      'name': 'Tas Ransel',
      'cat': 'Tas',
      'loc': 'Aula Utama',
      'status': 'completed',
      'icon': '🎒',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final d = _dummies[index % _dummies.length];
    final statusColor = AppTheme.statusColor(d['status']!);
    final statusLabel = AppTheme.statusLabel(d['status']!);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto area (placeholder)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(d['icon']!,
                style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
          ),
          // Info area
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['name']!,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(d['loc']!,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                Container(padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12),borderRadius: BorderRadius.circular(4)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w500),),
                ),
              ],
            ),
          ),
        ],
      ),
      )
    );
  }
}
