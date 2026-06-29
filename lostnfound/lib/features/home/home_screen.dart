import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/features/home/widgets/notification_badge.dart';
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

  final Color _bgColor = const Color(0xFFFCFCFC);
  final Color _navyColor = const Color(0xFF141A28);
  final Color _lightGrey = const Color(0xFFF3F4F6);

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.menu, color: Colors.black87),
        //   onPressed: () {},
        // ),
        title: const Text(
          'Lost n Found',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [const NotificationBadge()],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            //───── Greeting ─────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 10, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $userName',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Periksa laporan yang sedang aktif atau cari item.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            //───── Search Bar ─────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari barang milik anda...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    filled: true,
                    fillColor: _lightGrey,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _navyColor),
                    ),
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
                    final isAll = i == 0;
                    final value = isAll
                        ? ''
                        : AppConstants.itemCategories[i - 1]['value']!;

                    final labelText = isAll
                        ? 'Semua'
                        : AppConstants.itemCategories[i - 1]['label']!;

                    final selected = filter.category == value;

                    return InputChip(
                      label: Text(labelText),
                      selected: selected,
                      showCheckmark: false,

                      side: BorderSide(
                        color: selected
                            ? theme.colorScheme.primary
                            : Colors.grey.shade300,
                      ),

                      onSelected: (_) {
                        if (selected && !isAll) {
                          _onCategoryChanged('');
                        } else {
                          _onCategoryChanged(value);
                        }
                      },

                      onDeleted: (selected && !isAll)
                          ? () => _onCategoryChanged('')
                          : null,

                      deleteIcon: const Icon(Icons.close, size: 16),
                      deleteIconColor: theme.colorScheme.onPrimaryContainer,
                    );
                  },
                ),
              ),
            ),

            //───── Section Label ─────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      filter.query.isNotEmpty
                          ? 'Hasil pencarian "${filter.query}"'
                          : filter.category.isNotEmpty
                          ? _categoryLabel(filter.category)
                          : 'Baru Ditemukan',
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

            //───── List Item (Pengganti Grid Item) ─────
            itemsAsync.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: _ShimmerCard(),
                    ),
                    childCount: 3,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ItemCard(item: items[i]),
                      ),
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
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Container(height: 180, width: double.infinity, color: Colors.white),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 20, width: 200, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(height: 14, width: 150, color: Colors.white),
                  const SizedBox(height: 16),
                  Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
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
