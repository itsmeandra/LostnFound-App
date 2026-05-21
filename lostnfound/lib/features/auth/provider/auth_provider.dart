import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lostnfound/core/services/fcm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main.dart'; // akses `supabase` global

// ── Auth State Stream ──
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

// ── Current User ──
final currentUserProvider = Provider<User?>((ref) {
  return supabase.auth.currentUser;
});

// ── Auth Service ──
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

class AuthService {
  final Ref _ref;
  final _auth = supabase.auth;

  AuthService(this._ref);

  // ── Daftar dengan email & password ──
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName}, // user_metadata
    );
  }

  // ── Login dengan email & password → init FCM  ──
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
    required Function(String, String?) onNotificationTap,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    // Inisialisasi FCM setelah sesi terbentuk
    if (response.session != null) {
      await _initFCM(onNotificationTap);
    }
    return response;
  }

  // ── Login dengan Google → init FCM  ──
  Future<bool> signInWithGoogle({
    required Function(String, String?) onNotificationsTap,
  }) async {
    final success = await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.lostnfound://login-callback',
    );
    return success;
  }

  // ── Logout → init FCM  ──
  Future<void> signOut() async {
    try {
      await FCMService().clearToken();
    } catch (e) {
      debugPrint('Auth: gagal clear FCM token: $e');
    }
    await _auth.signOut();
  }

  // ── Reset Password ──
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.lostnfound://reset-callback',
    );
  }

  // ── Helper: init FCM ──────────────────────────────────────
  Future<void> _initFCM(Function(String, String?) onNotificationTap) async {
    try {
      await FCMService().initialize(onTap: onNotificationTap);
    } catch (e) {
      // FCM gagal tidak boleh menghentikan alur login
      debugPrint('Auth: FCM init gagal: $e');
    }
  }

  // ── Cek apakah sudah login ──
  bool get isAuthenticated => _auth.currentUser != null;

  // ── Ambil user saat ini ──
  User? get currentUser => _auth.currentUser;
}