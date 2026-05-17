import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

//───── Model profil ─────
class ProfileModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String role;

  const ProfileModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.avatarUrl,
    this.role = 'user',
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as String,
    fullName: json['full_name'] as String? ?? '',
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    role: json['role'] as String? ?? 'user',
  );

  Map<String, dynamic> toUpdateJson() => {
    'full_name': fullName,
    if (phone != null) 'phone': phone,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };

  ProfileModel copyWith({String? fullName, String? phone, String? avatarUrl}) =>
      ProfileModel(
        id: id,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        email: email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role,
      );
}

//───── State update profil ─────
class ProfileUpdateState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  const ProfileUpdateState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });
  ProfileUpdateState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) => ProfileUpdateState(
    isLoading: isLoading ?? this.isLoading,
    isSuccess: isSuccess ?? this.isSuccess,
    error: error,
  );
}

//───── Provider: fetch profil user ─────
final profileProvider = FutureProvider.autoDispose<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final resp = await supabase
      .from(AppConstants.tableProfiles)
      .select()
      .eq('id', user.id)
      .single();

  return ProfileModel.fromJson(resp as Map<String, dynamic>);
});

//───── Notifier: update profil ─────
class ProfileNotifier extends StateNotifier<ProfileUpdateState> {
  final Ref _ref;
  final _picker = ImagePicker();

  ProfileNotifier(this._ref) : super(const ProfileUpdateState());

  //───── Update nama & telepon ─────
  Future<void> updateProfile({required String fullName, String? phone}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('Tidak ada sesi aktif');

      await supabase
          .from(AppConstants.tableProfiles)
          .update({
            'full_name': fullName.trim(),
            'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
          })
          .eq('id', user.id);

      // Invalidate profileProvider agar UI refresh
      _ref.invalidate(profileProvider);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } on PostgrestException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memperbarui profil: ${e.message}',
      );
    }
  }

  //───── Upload & update avatar ─────
  Future<void> updateAvatar() async {
    // pilih foto dari galeri
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('Tidak ada sesi aktif');

      // Kompres avatar ke maks 200KB
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(dir.path, 'avatar_compressed.jpg');
      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        format: CompressFormat.jpeg,
        quality: 75,
        minWidth: 400,
        minHeight: 400,
      );

      final file = File(compressed?.path ?? picked.path);

      // Upload ke bucket avatars: path = {userId}/avatar.jpg
      final storagePath = '${user.id}/avatar.jpg';
      await supabase.storage
          .from(AppConstants.avatarsBucket)
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true, // timpa avatar lama
            ),
          );

      // Ambil public URL (bucket avatars adalah public)
      final publicUrl = supabase.storage
          .from(AppConstants.avatarsBucket)
          .getPublicUrl(storagePath);

      // Tambahkan cache-busting query param agar image widget reload
      final urlWithCache =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Simpan URL baru ke tabel profiles
      await supabase
          .from(AppConstants.tableProfiles)
          .update({'avatar_url': urlWithCache})
          .eq('id', user.id);

      // Bersihkan file temp
      try {
        await file.delete();
      } catch (_) {}

      _ref.invalidate(profileProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal mengubah foto profile, Coba lagi.',
      );
    }
  }

  //───── Hapus avatar ─────
  Future<void> removeAvatar() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('Tidak ada sesi aktif');

      // Hapus file dari Storage
      await supabase.storage.from(AppConstants.avatarsBucket).remove([
        '${user.id}/avatar.jpg',
      ]);

      // Reset avatar_url ke null di DB
      await supabase
          .from(AppConstants.tableProfiles)
          .update({'avatar_url': null})
          .eq('id', user.id);

      _ref.invalidate(profileProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal menghapus foto profil.',
      );
    }
  }

  void reset() => state = const ProfileUpdateState();
}

final profileNotifierProvider =
    StateNotifierProvider.autoDispose<ProfileNotifier, ProfileUpdateState>(
      (ref) => ProfileNotifier(ref),
    );
