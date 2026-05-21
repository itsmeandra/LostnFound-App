import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import '../../../../main.dart';

//───── Model notifikasi ─────
class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        data: (json['data'] as Map<String, dynamic>?) ?? {},
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  // Route yang dituju saat notifikasi di-tap
  String? get targetRoute {
    final itemId = data['item_id'] as String?;
    return switch (type) {
      'item_published' => itemId != null ? '/item/$itemId' : null,
      'claim_approved' => '/track',
      'claim_rejected' => '/track',
      'match_found' => itemId != null ? '/item/$itemId' : null,
      _ => null,
    };
  }

  // Ikon per tipe notifikasi
  IconData get icon => switch (type) {
    'item_published' => Icons.check_circle_outline,
    'claim_approved' => Icons.handshake_outlined,
    'claim_rejected' => Icons.cancel_outlined,
    'match_found' => Icons.search_outlined,
    _ => Icons.notifications_outlined,
  };

  Color get iconColor => switch (type) {
    'item_published' => const Color(0xFF388E3C),
    'claim_approved' => const Color(0xFF1565C0),
    'claim_rejected' => const Color(0xFFD32F2F),
    'match_found' => const Color(0xFFF57C00),
    _ => Colors.grey,
  };
}

//───── Providers ─────

// Stream notifikasi user — realtime
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) return Stream.value([]);

      return supabase
          .from(AppConstants.tableNotifications)
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50)
          .map(
            (data) => data
                .map(
                  (j) => NotificationModel.fromJson(j as Map<String, dynamic>),
                )
                .toList(),
          );
    });

// Count unread — untuk badge di AppBar
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final notifsAsync = ref.watch(notificationsStreamProvider);
  return notifsAsync.maybeWhen(
    data: (notifs) => notifs.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

//───── Screen ─────
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          // Mark all as read
          notifsAsync.maybeWhen(
            data: (notifs) {
              final hasUnread = notifs.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _markAllAsRead(notifs),
                child: const Text('Tandai semua'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Gagal memuat notifikasi'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(notificationsStreamProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (notifs) {
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifikasi tentang laporan dan klaim\nakan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) => _NotificationTile(
              notif: notifs[i],
              onTap: () => _handleTap(context, notifs[i]),
            ),
          );
        },
      ),
    );
  }

  // Tandai semua notifikasi sebagai sudah dibaca
  Future<void> _markAllAsRead(List<NotificationModel> notifs) async {
    final unreadIds = notifs.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;

    await supabase
        .from(AppConstants.tableNotifications)
        .update({'is_read': true})
        .inFilter('id', unreadIds);
  }

  // Tap notifikasi → mark read + navigasi
  Future<void> _handleTap(BuildContext context, NotificationModel notif) async {
    // Mark as read
    if (!notif.isRead) {
      await supabase
          .from(AppConstants.tableNotifications)
          .update({'is_read': true})
          .eq('id', notif.id);
    }

    // Navigasi jika ada route target
    if (context.mounted && notif.targetRoute != null) {
      context.push(notif.targetRoute!);
    }
  }
}

//───── Tile notifikasi ─────
class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;

  const _NotificationTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.isRead
            ? null
            : theme.colorScheme.primaryContainer.withOpacity(0.08),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon tipe notifikasi
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notif.iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(notif.icon, color: notif.iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Konten
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: notif.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notif.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chevron jika punya target navigasi
            if (notif.targetRoute != null)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('d MMM', 'id_ID').format(dt);
  }
}
