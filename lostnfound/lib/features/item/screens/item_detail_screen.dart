import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lostnfound/core/theme/app_theme.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/features/claim/widgets/claim_bottom_sheet.dart';
import 'package:lostnfound/features/item/widgets/storage_image.dart';
import 'package:lostnfound/features/match/match_section.dart';
import 'package:lostnfound/features/report/data/item_detail_provider.dart';
import '../widgets/drop_point_card.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(itemDetailProvider(itemId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: detailAsync.when(
        loading: () => const _LoadingSkeleton(),
        error: (e, _) =>
            _ErrorView(onRetry: () => ref.refresh(itemDetailProvider(itemId))),
        data: (detail) {
          final item = detail.item;
          final isOwner = currentUser?.id == item.reporterId;

          return CustomScrollView(
            slivers: [
              //───── SliverAppBar dengan foto ─────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                leading: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  // Share button (placeholder — Minggu 4)
                  CircleAvatar(
                    backgroundColor: Colors.black38,
                    child: IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: item.photoUrls.isNotEmpty
                      ? PhotoCarouselViewer(
                          photoUrls: item.photoUrls,
                          height: 300,
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                ),
              ),

              //───── Konten detail ─────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status + tipe
                      Row(
                        children: [
                          _StatusChip(status: item.status),
                          const SizedBox(width: 8),
                          _TypeChip(type: item.type),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nama barang
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),

                      // Info grid: kategori, lokasi, tanggal
                      _InfoGrid(detail: detail),
                      const SizedBox(height: 20),

                      if (DropPointCard.shouldShow(
                        item.dropPoint,
                        item.status,
                      )) ...[
                        DropPointCard(
                          dropPoint: item.dropPoint!,
                          itemStatus: item.status,
                        ),
                      ],

                      // Divider
                      const Divider(),
                      const SizedBox(height: 12),

                      // Deskripsi
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        _SectionTitle('Deskripsi'),
                        const SizedBox(height: 6),
                        Text(
                          item.description!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.6,
                              ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Info pelapor
                      _SectionTitle('Dilaporkan oleh'),
                      const SizedBox(height: 8),
                      _ReporterTile(
                        name: detail.reporterName,
                        date: item.createdAt ?? item.itemDate,
                        isOwner: isOwner,
                      ),
                      const SizedBox(height: 20),

                      MatchSection(itemId: item.id!, itemType: item.type),
                      const SizedBox(height: 20),

                      // Pesan jika item milik sendiri
                      if (isOwner) ...[
                        const Divider(),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Ini adalah laporan milikmu. Kamu tidak bisa mengajukan klaim.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Pesan jika tidak login
                      if (currentUser == null &&
                          item.status == 'published') ...[
                        const Divider(),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/login'),
                          icon: const Icon(Icons.login),
                          label: const Text('Login untuk mengajukan klaim'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      //───── Tombol Klaim (bottom) ─────
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (detail) {
          final item = detail.item;
          final isOwner = currentUser?.id == item.reporterId;
          final canClaim =
              item.status == 'published' && !isOwner && currentUser != null;

          if (!canClaim) return null;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ElevatedButton.icon(
                onPressed: () =>
                    showClaimBottomSheet(context, item.id!, item.name),
                icon: const Icon(Icons.handshake_outlined),
                label: const Text(
                  'Ajukan Klaim',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF141A28),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        AppTheme.statusLabel(status),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final isFound = type == 'found';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFound ? Icons.search : Icons.search_off,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            isFound ? 'Barang Temuan' : 'Barang Hilang',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final ItemDetail detail;
  const _InfoGrid({required this.detail});

  @override
  Widget build(BuildContext context) {
    final item = detail.item;
    return Column(
      children: [
        _InfoRow(
          icon: Icons.category_outlined,
          label: 'Kategori',
          value: _categoryLabel(item.category),
        ),
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'Lokasi',
          value: item.location,
        ),
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: item.type == 'found' ? 'Tanggal Ditemukan' : 'Tanggal Hilang',
          value: DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(item.itemDate),
        ),
      ],
    );
  }

  String _categoryLabel(String cat) {
    const labels = {
      'electronics': 'Elektronik',
      'wallet': 'Dompet',
      'keys': 'Kunci',
      'clothing': 'Pakaian & Aksesoris',
      'bag': 'Tas',
      'documents': 'Dokumen',
      'glasses': 'Kacamata',
      'jewelry': 'Perhiasan',
      'other': 'Lainnya',
    };
    return labels[cat] ?? cat;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _ReporterTile extends StatelessWidget {
  final String name;
  final DateTime date;
  final bool isOwner;
  const _ReporterTile({
    required this.name,
    required this.date,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isOwner) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Kamu',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                'Dilaporkan ${DateFormat('d MMM yyyy', 'id_ID').format(date)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//───── Loading skeleton ─────
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

//───── Error view ─────
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Gagal memuat detail barang'),
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
