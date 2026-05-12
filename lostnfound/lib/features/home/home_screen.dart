import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/features/item/widgets/item_card.dart';
import 'package:lostnfound/features/report/data/items_provider.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  //───── Search dengan debounce 400ms ─────
  // Cegah query ke Supabase setiap ketukan — tunggu user berhenti mengetik.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(itemsFilterProvider.notifier)
          .update((f) => f.copyWith(query: value, page: 0));
    });
  }

  void _onCategoryChanged(String category) {
    ref
        .read(itemsFilterProvider.notifier)
        .update((f) => f.copyWith(category: category, page: 0));
  }

  // Pull-to-refresh
  Future<void> _onRefresh() async {
    return ref.refresh(itemsRealtimeProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final filter = ref.watch(itemsFilterProvider);
    final itemsAsync = ref.watch(itemsRealtimeProvider);
    final theme = Theme.of(context);
    final userName = (user?.userMetadata?['full_name'] as String? ?? 'Pengguna')
        .split(' ')
        .first;

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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            //───── Search Bar ─────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: 'Cari barang hilang / temuan...',
                  leading: const Icon(Icons.search, size: 20),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 14),
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  ),
                  onChanged: _onSearchChanged,
                  trailing: [
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      ),
                  ],
                ),
              ),
            ),

            //───── Greeting ─────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.titleMedium,
                    children: [
                      const TextSpan(text: 'Halo, '),
                      TextSpan(
                        text: '$userName! 👋',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            //───── Filter Chip Kategori ─────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  itemCount: AppConstants.itemCategories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    // Index 0 = "Semua"
                    final isAll = i == 0;
                    final value = isAll
                        ? ''
                        : AppConstants.itemCategories[i - 1]['value']!;
                    final label = isAll
                        ? ''
                        : AppConstants.itemCategories[i - 1]['label']!;
                    final selected = filter.category == value;
                    return FilterChip(
                      label: Text(label),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => _onCategoryChanged(value),
                    );
                  },
                ),
              ),
            ),

            //───── Section Label ─────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      filter.query.isNotEmpty
                          ? 'Hasil pencarian "${filter.query}"'
                          : filter.category.isNotEmpty
                          ? _categoryLabel(filter.category)
                          : 'Barang Temuan Terbaru',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Realtime indicator
                    itemsAsync.when(
                      data: (items) => Text(
                        '${items.length} barang',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            //───── Grid Item ─────
            itemsAsync.when(
              // Loading: shimmer grid
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: _gridDelegate,
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const _ShimmerCard(),
                    childCount: 6,
                  ),
                ),
              ),

              // Error state
              error: (e, _) =>
                  SliverToBoxAdapter(child: _ErrorState(onRetry: _onRefresh)),

              // Data
              data: (items) {
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      hasFilter:
                          filter.category.isNotEmpty || filter.query.isNotEmpty,
                      onReset: () {
                        _searchCtrl.clear();
                        ref
                            .read(itemsFilterProvider.notifier)
                            .update((_) => const ItemsFilter());
                      },
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: _gridDelegate,
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ItemCard(item: items[i]),
                      childCount: items.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
    );
  }
}

SliverGridDelegateWithFixedCrossAxisCount get _gridDelegate =>
    const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.75,
    );

String _categoryLabel(String cat) {
  return AppConstants.itemCategories.firstWhere(
        (c) => c['value'] == cat,
        orElse: () => {'label': cat},
      )['label'] ??
      cat;
}

//───── Shimmer loading card ─────
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Card(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade200,
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 80,
                      color: Colors.grey.shade200,
                    ),
                    const Spacer(),
                    Container(
                      height: 16,
                      width: 60,
                      color: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//───── Empty state ─────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onReset;
  const _EmptyState({required this.hasFilter, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.inventory_2_outlined,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'Tidak ada barang yang cocok'
                : 'Belum ada barang temuan',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Coba ubah kata kunci atau hapus filter.'
                : 'Jadilah yang pertama melaporkan barang temuan!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onReset,
              child: const Text('Hapus filter'),
            ),
          ],
        ],
      ),
    );
  }
}

//───── Error state ─────
class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.wifi_off_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat data',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Periksa koneksi internetmu dan coba lagi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
