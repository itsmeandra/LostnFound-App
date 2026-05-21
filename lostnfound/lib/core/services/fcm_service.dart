// lib/core/services/fcm_service.dart
//
// Service utama untuk Firebase Cloud Messaging (FCM).
//
// Tanggung jawab:
//   1. Inisialisasi Firebase + FCM
//   2. Minta izin notifikasi (iOS wajib, Android 13+)
//   3. Dapatkan device token → simpan ke tabel profiles
//   4. Handle notifikasi foreground (app terbuka)
//   5. Handle notifikasi background (app di background/closed)
//   6. Handle tap notifikasi → navigasi ke halaman terkait
//   7. Refresh token saat berubah (token FCM bisa expired)
//
// Alur token:
//   Login berhasil → getToken() → simpan ke profiles.fcm_token
//   Token diperbarui → onTokenRefresh → update DB
//   Logout → hapus token dari DB (opsional, cegah notif stale)

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/firebase_options.dart';

import '../../main.dart';

// ── Background message handler ────────────────────────────────
// Harus top-level function (bukan method class) karena
// dipanggil di isolate terpisah saat app tidak aktif.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase sudah terinisialisasi di background isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM Background: ${message.notification?.title}');
  // Untuk background, flutter_local_notifications menampilkan notif
  // secara otomatis jika notification payload ada.
  // Tidak perlu aksi tambahan di sini untuk kasus sederhana.
}

class FCMService {
  static final FCMService _instance = FCMService._();
  factory FCMService() => _instance;
  FCMService._();

  final _messaging = FirebaseMessaging.instance;

  // Plugin untuk notifikasi lokal (foreground display di Android)
  final _localNotif = FlutterLocalNotificationsPlugin();

  // Channel Android untuk notifikasi app
  static const _androidChannel = AndroidNotificationChannel(
    'lostnfound_default', // ID channel — harus sama di AndroidManifest
    'Lost & Found Notifications', // nama yang tampil di pengaturan HP
    description: 'Notifikasi status laporan dan klaim barang',
    importance: Importance.high,
  );

  // Callback navigasi — di-set dari main.dart atau router
  // Dipanggil saat user tap notifikasi
  Function(String route, String? itemId)? onNotificationTap;

  // ── Inisialisasi Firebase ──────────────────────────────────
  static Future<void> initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // ── Setup lengkap FCM ─────────────────────────────────────
  // Dipanggil sekali setelah login berhasil.
  Future<void> initialize({
    required Function(String route, String? itemId) onTap,
  }) async {
    onNotificationTap = onTap;

    // 1. Daftarkan background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Setup flutter_local_notifications (untuk foreground di Android)
    await _setupLocalNotifications();

    // 3. Minta izin
    await _requestPermission();

    // 4. Dapatkan & simpan token
    await _saveToken();

    // 5. Listen perubahan token
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // 6. Handle notifikasi saat app di foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Handle tap notifikasi saat app di background (tapi terbuka)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 8. Cek jika app dibuka dari notifikasi (app sebelumnya closed)
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);

    debugPrint('FCM: inisialisasi selesai');
  }

  // ── Minta izin notifikasi ─────────────────────────────────
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false, // true = izin sementara (iOS)
      sound: true,
    );

    debugPrint('FCM Permission: ${settings.authorizationStatus}');
    // authorizationStatus:
    //   authorized   = user memberi izin
    //   denied       = user menolak
    //   notDetermined = belum diminta (iOS)
    //   provisional  = izin sementara (iOS)
  }

  // ── Dapatkan dan simpan token ke profiles ─────────────────
  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _updateTokenInDB(token);
        debugPrint('FCM Token: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('FCM: gagal mendapatkan token: $e');
    }
  }

  // ── Update token ke Supabase ──────────────────────────────
  Future<void> _updateTokenInDB(String token) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from(AppConstants.tableProfiles)
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) {
      debugPrint('FCM: gagal menyimpan token ke DB: $e');
    }
  }

  // ── Token berubah → update DB ─────────────────────────────
  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('FCM: token diperbarui');
    await _updateTokenInDB(newToken);
  }

  // ── Hapus token saat logout ───────────────────────────────
  // Mencegah notifikasi dikirim ke device yang sudah logout
  Future<void> clearToken() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from(AppConstants.tableProfiles)
          .update({'fcm_token': null})
          .eq('id', user.id);
      await _messaging.deleteToken();
      debugPrint('FCM: token dihapus');
    } catch (e) {
      debugPrint('FCM: gagal menghapus token: $e');
    }
  }

  // ── Setup flutter_local_notifications ────────────────────
  Future<void> _setupLocalNotifications() async {
    // Buat Android channel (notifikasi tidak muncul tanpa ini di Android 8+)
    final androidPlugin = AndroidFlutterLocalNotificationsPlugin();
    await androidPlugin.createNotificationChannel(_androidChannel);

    // Inisialisasi plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // Sudah diminta via requestPermission()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotif.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      // Callback saat user tap notifikasi lokal
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _handlePayload(details.payload!);
        }
      },
    );
  }

  // ── Handle notifikasi foreground ──────────────────────────
  // Di iOS, notifikasi otomatis tampil saat foreground.
  // Di Android, perlu tampilkan manual via flutter_local_notifications.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('FCM Foreground: ${notification.title} — ${notification.body}');

    // Tampilkan sebagai notifikasi lokal di Android
    await _localNotif.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Payload untuk navigasi saat tap
      payload: jsonEncode(message.data),
    );
  }

  // ── Handle tap notifikasi (background → app terbuka) ─────
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM Tap: data=${message.data}');
    _handlePayload(jsonEncode(message.data));
  }

  // ── Parse payload dan navigasi ────────────────────────────
  // Payload format: { "type": "item_published", "item_id": "uuid" }
  void _handlePayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final itemId = data['item_id'] as String?;

      final route = switch (type) {
        'item_published' => '/item/$itemId',
        'claim_approved' => '/track', // ke halaman laporan saya
        'claim_rejected' => '/track',
        'match_found' => '/item/$itemId',
        _ => '/home',
      };

      onNotificationTap?.call(route, itemId);
    } catch (e) {
      debugPrint('FCM: gagal parse payload: $e');
    }
  }

  // ── Cek status izin notifikasi ────────────────────────────
  Future<bool> get isPermissionGranted async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
