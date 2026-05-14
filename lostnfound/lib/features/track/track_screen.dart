import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lostnfound/core/theme/app_theme.dart';
import 'package:lostnfound/features/report/data/report_provider.dart';

class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Lacak')),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Gagal memuat data')),
        data: (reports) {
          // Hitung summary per status
          final pending = reports.where((r) => r.status == 'pending').length;
          final published = reports
              .where((r) => r.status == 'published')
              .length;
          final claimed = reports.where((r) => r.status == 'claimed').length;
          final completed = reports
              .where((r) => r.status == 'completed')
              .length;
          final rejected = reports.where((r) => r.status == 'rejected').length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              //───── Summary cards ─────
              Text(
                'Ringkasan Laporan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: [
                  _SummaryCard(
                    count: pending,
                    label: 'Menunggu',
                    color: AppTheme.statusPending,
                  ),
                  _SummaryCard(
                    count: published,
                    label: 'Publik',
                    color: AppTheme.statusPublished,
                  ),
                  _SummaryCard(
                    count: completed,
                    label: 'Selesai',
                    color: AppTheme.statusCompleted,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              //───── Lihat semua laporan ─────
              OutlinedButton.icon(
                onPressed: () => context.push('/my-reports'),
                icon: const Icon(Icons.list_alt_outlined),
                label: Text('Lihat Semua ${reports.length} Laporan'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 24),

              //───── Laporan terbaru (3 item) ─────
              if (reports.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Laporan Terbaru',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/my-reports'),
                      child: const Text('Lihat semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...reports
                    .take(3)
                    .map(
                      (r) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.statusColor(
                              r.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              r.type == 'lost' ? '🔴' : '🟢',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        title: Text(
                          r.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          r.location,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.statusColor(
                              r.status,
                            ).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            AppTheme.statusLabel(r.status),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.statusColor(r.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: () => context.push('/item/${r.id}'),
                      ),
                    ),
              ],

              //───── Empty state ─────
              if (reports.isEmpty) ...[
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 52,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum ada laporan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Lapor Hilang" di Beranda untuk memulai.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

//───── Summary card ─────
class _SummaryCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
