import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  return AuthService();
});

class AuthService {
  final _auth = supabase.auth;

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

  // ── Login dengan email & password ──
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Login dengan Google ──
  Future<bool> signInWithGoogle() async {
    return await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.lostnfound://login-callback',
    );
  }

  // ── Logout ──
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Reset Password ──
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.lostnfound://reset-callback',
    );
  }

  // ── Cek apakah sudah login ──
  bool get isAuthenticated => _auth.currentUser != null;

  // ── Ambil user saat ini ──
  User? get currentUser => _auth.currentUser;
}