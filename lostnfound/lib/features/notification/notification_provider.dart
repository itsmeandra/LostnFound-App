import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/features/notification/notification_model.dart';
import '../../../../main.dart';

//───── 1. Stream Notifikasi Realtime ─────
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

//───── 2. Penghitung Unread (Badge) ─────
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final notifsAsync = ref.watch(notificationsStreamProvider);
  return notifsAsync.maybeWhen(
    data: (notifs) => notifs.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

//───── 3. Controller Aksi Database ─────
class NotificationController {
  // Tandai 1 notifikasi dibaca
  Future<void> markAsRead(String id) async {
    await supabase
        .from(AppConstants.tableNotifications)
        .update({'is_read': true})
        .eq('id', id);
  }

  // Tandai banyak notifikasi dibaca sekaligus
  Future<void> markAllAsRead(List<String> unreadIds) async {
    if (unreadIds.isEmpty) return;
    await supabase
        .from(AppConstants.tableNotifications)
        .update({'is_read': true})
        .inFilter('id', unreadIds);
  }
}

// Provider untuk mengakses fungsi controller di UI
final notificationControllerProvider = Provider<NotificationController>(
  (ref) => NotificationController(),
);
