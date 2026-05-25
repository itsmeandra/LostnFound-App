import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lostnfound/core/theme/app_theme.dart';
import 'package:lostnfound/features/match/match_provider.dart';
import 'package:shimmer/shimmer.dart';

class MatchSection extends ConsumerWidget {
  final String itemId;
  final String itemType; // 'lost' atau 'found'

  const MatchSection({super.key, required this.itemId, required this.itemType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hanya tampil untuk laporan hilang
    if (itemType != 'lost') return const SizedBox.shrink();

    final matchesAsync = ref.watch(matchesForItemProvider(itemId));

    return matchesAsync.when(
      loading: () => _MatchSectionShimmer(),
      error: (_, __) => const SizedBox.shrink(), // silent fail
      // Cek error
      // error: (err, stack) {
      //   debugPrint('Match Error: $err'); // Cek log di terminal VS Code
      //   return Padding(
      //     padding: const EdgeInsets.all(20),
      //     child: Text('Error Match: $err', style: const TextStyle(color: Colors.red)),
      //   );
      // },
      data: (matches) {
        if (matches.isEmpty) return const SizedBox.shrink();
        return _MatchContent(matches: matches);
      },
    );
  }
}

//───── Konten matches ─────
class _MatchContent extends StatelessWidget {
  final List<MatchModel> matches;
  const _MatchContent({required this.matches});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.statusPending.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: AppTheme.statusPending,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kemungkinan Barang Cocok',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${matches.length} barang temuan yang mungkin milikmu',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scroll list
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _MatchCard(match: matches[i]),
          ),
        ),
        const SizedBox(height: 20),

        // Info disclaimer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pencocokan dilakukan otomatis berdasarkan nama, '
                    'kategori, dan lokasi. Tidak 100% akurat.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

//───── Card satu hasil match ─────
class _MatchCard extends StatelessWidget {
  final MatchModel match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foundItem = match.foundItem;
    if (foundItem == null) return const SizedBox.shrink();

    final hasPhoto = foundItem.photoUrls.isNotEmpty;
    final score = match.scorePercent;

    // Warna skor: hijau ≥80, kuning 60–79, abu <60
    final scoreColor = score >= 80
        ? Colors.green.shade600
        : score >= 60
        ? Colors.orange.shade600
        : Colors.grey;

    return GestureDetector(
      onTap: () => context.push('/item/${foundItem.id}'),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: foundItem.photoUrls.first,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(height: 100, color: Colors.grey.shade100),
                      errorWidget: (_, __, ___) =>
                          _noPhotoBox(foundItem.category),
                    )
                  : _noPhotoBox(foundItem.category),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foundItem.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    foundItem.location,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Skor kecocokan
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 12,
                        color: scoreColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Cocok $score%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noPhotoBox(String category) {
    const icons = {
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
    return Container(
      height: 100,
      color: Colors.grey.shade50,
      child: Center(
        child: Text(
          icons[category] ?? '📦',
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}

//───── Shimmer loading ─────
class _MatchSectionShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 16,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 160,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
