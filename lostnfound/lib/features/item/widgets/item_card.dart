import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lostnfound/core/theme/app_theme.dart';
import 'package:lostnfound/features/report/data/item_model.dart';
import 'package:shimmer/shimmer.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = AppTheme.statusColor(item.status);
    final hasPhoto = item.photoUrls.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/item/${item.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //───── Foto ─────
            Expanded(
              flex: 3,
              child: hasPhoto
                  ? _PhotoArea(url: item.photoUrls.first)
                  : _NoPhotoPlaceholder(category: item.category),
            ),

            //───── Info ─────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama barang
                    Text(
                      item.name,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Lokasi
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 11,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item.location,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Status badge + tanggal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppTheme.statusLabel(item.status),
                            style: TextStyle(
                              fontSize: 9,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Tanggal ditemukan
                        Text(
                          _formatDate(item.itemDate),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return '$diff hari lalu';
    return DateFormat('d MMM', 'id_ID').format(date);
  }
}

//───── Foto dengan CachedNetworkImage ─────
class _PhotoArea extends StatelessWidget {
  final String url;
  const _PhotoArea({required this.url});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      fit: BoxFit.cover,
      // Shimmer saat loading
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(color: Colors.grey.shade200),
      ),
      // Placeholder jika gagal load
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              size: 28, color: Colors.grey),
        ),
      ),
    );
  }
}

//───── Placeholder jika tidak ada foto ─────
class _NoPhotoPlaceholder extends StatelessWidget {
  final String category;
  const _NoPhotoPlaceholder({required this.category});

  static const _categoryIcons = <String, String>{
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
      child: Center(
        child: Text(
          _categoryIcons[category] ?? '📦',
          style: const TextStyle(fontSize: 36),
        ),
      ),
    );
  }
}