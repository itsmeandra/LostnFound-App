import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lostnfound/core/theme/app_theme.dart';
import 'package:lostnfound/features/report/data/item_model.dart';
import 'package:lostnfound/features/report/data/report_provider.dart';
import 'package:shimmer/shimmer.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(myReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Saya'),
        // Tab filter: Semua / Hilang / Temuan
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Hilang'),
            Tab(text: 'Temuan'),
          ],
        ),
      ),
      body: reportsAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) =>
            _ErrorState(onRetry: () => ref.refresh(myReportsProvider)),
        data: (reports) => TabBarView(
          controller: _tabCtrl,
          children: [
            _ReportList(items: reports, filter: null),
            _ReportList(items: reports, filter: 'lost'),
            _ReportList(items: reports, filter: 'found'),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 88,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

//───── Daftar laporan dengan filter ─────
class _ReportList extends StatelessWidget {
  final List<ItemModel> items;
  final String? filter; // null=semua, 'lost', 'found'

  const _ReportList({required this.items, this.filter});

  @override
  Widget build(BuildContext context) {
    final filtered = filter == null
        ? items
        : items.where((i) => i.type == filter).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filter == 'lost'
                  ? Icons.search_off
                  : filter == 'found'
                  ? Icons.search
                  : Icons.inventory_2_outlined,
              size: 52,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              filter == null
                  ? 'Belum ada laporan'
                  : filter == 'lost'
                  ? 'Belum ada laporan hilang'
                  : 'Belum ada laporan temuan',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap FAB di Beranda untuk membuat laporan baru.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {}, // TODO: trigger refresh via ref
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: filtered.length,
        itemBuilder: (context, i) => _ReportTile(item: filtered[i]),
      ),
    );
  }
}

//───── Tile untuk satu laporan ─────
class _ReportTile extends StatelessWidget {
  final ItemModel item;
  const _ReportTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(item.status);
    final statusLabel = AppTheme.statusLabel(item.status);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/item/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              //───── Ikon kategori ─────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _categoryEmoji(item.category),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              //───── Info ─────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama + tipe badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: item.type == 'lost'
                                ? Colors.orange.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.type == 'lost' ? 'Hilang' : 'Temuan',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: item.type == 'lost'
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Lokasi
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Status badge + tanggal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('d MMM yyyy').format(item.itemDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    // Pesan khusus jika ditolak
                    if (item.status == 'rejected' &&
                        item.rejectionReason != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 12,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.rejectionReason!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryEmoji(String category) {
    const map = {
      'electronics': '💻',
      'wallet': '👛',
      'keys': '🔑',
      'clothing': '👕',
      'bag': '🎒',
      'documents': '📄',
      'glasses': '👓',
      'jewelry': '💍',
      'other': '📦',
    };
    return map[category] ?? '📦';
  }
}

//───── Error state ─────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Gagal memuat laporan'),
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
