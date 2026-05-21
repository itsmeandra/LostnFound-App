import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/features/report/data/photo_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../main.dart';
import '../../../../core/constants/app_constants.dart';
import 'claim_model.dart';

// 1. Provider: semua klaim milik user yang sedang login
//    Join ke items(id, name, category, location, photo_urls, status, type)
final myClaimsProvider = FutureProvider.autoDispose<List<ClaimModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final resp = await supabase
      .from(AppConstants.tableClaims)
      .select('''
        *,
        items:item_id (
          id, name, category, location,
          photo_urls, status, type
        )
      ''')
      .eq('claimant_id', user.id)
      .order('created_at', ascending: false);

  return (resp as List<dynamic>)
      .map((j) => ClaimModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

// 2. Provider: cek apakah user sudah pernah klaim item tertentu
//    Dipakai di ItemDetailScreen untuk tampilkan status klaim
final existingClaimProvider = FutureProvider.autoDispose
    .family<ClaimModel?, String>((ref, itemId) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) return null;

      try {
        final resp = await supabase
            .from(AppConstants.tableClaims)
            .select()
            .eq('item_id', itemId)
            .eq('claimant_id', user.id)
            .maybeSingle(); // null jika tidak ada, tidak throw error

        if (resp == null) return null;
        return ClaimModel.fromJson(resp as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    });

// 3. State form klaim
class ClaimFormState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final List<XFile> proofPhotos;

  const ClaimFormState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.proofPhotos = const [],
  });

  ClaimFormState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    List<XFile>? proofPhotos,
  }) => ClaimFormState(
    isLoading: isLoading ?? this.isLoading,
    isSuccess: isSuccess ?? this.isSuccess,
    error: error,
    proofPhotos: proofPhotos ?? this.proofPhotos,
  );
}

// 4. Notifier: form klaim
class ClaimFormNotifier extends StateNotifier<ClaimFormState> {
  final Ref _ref;
  final _photoSvc = PhotoUploadService();

  ClaimFormNotifier(this._ref) : super(const ClaimFormState());

  //───── Tambah/hapus foto bukti ─────
  Future<void> addProofFromGallery() async {
    if (state.proofPhotos.length >= 3) return;
    final picked = await _photoSvc.pickFromGallery(maxImages: 1);
    if (picked.isNotEmpty) {
      state = state.copyWith(proofPhotos: [...state.proofPhotos, picked.first]);
    }
  }

  Future<void> addProofFromCamera() async {
    if (state.proofPhotos.length >= 3) return;
    final picked = await _photoSvc.pickFromCamera();
    if (picked != null) {
      state = state.copyWith(proofPhotos: [...state.proofPhotos, picked]);
    }
  }

  void removeProofPhoto(int index) {
    final updated = [...state.proofPhotos]..removeAt(index);
    state = state.copyWith(proofPhotos: updated);
  }

  //───── Submit klaim ─────
  // Alur: upload foto bukti → insert ke claims → invalidate providers
  Future<void> submitClaim({
    required String itemId,
    required String secretDescription,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('Silakan login terlebih dahulu');

      // 1. Upload foto bukti ke Storage
      final proofUrls = state.proofPhotos.isNotEmpty
          ? await _photoSvc.uploadAll(state.proofPhotos, user.id)
          : <String>[];

      // 2. Insert ke tabel claims
      // RLS memastikan claimant_id = auth.uid()
      await supabase.from(AppConstants.tableClaims).insert({
        'item_id': itemId,
        'claimant_id': user.id,
        'proof_photos': proofUrls,
        'secret_description': secretDescription.trim(),
        'status': 'pending',
      });

      // 3. Refresh daftar klaim user + cek existing klaim
      _ref.invalidate(myClaimsProvider);
      _ref.invalidate(existingClaimProvider(itemId));

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        proofPhotos: [],
      );
    } on PostgrestException catch (e) {
      // 23505 = unique constraint: (item_id, claimant_id)
      state = state.copyWith(
        isLoading: false,
        error: e.code == '23505'
            ? 'Kamu sudah pernah mengajukan klaim untuk barang ini.'
            : 'Gagal mengajukan klaim. Coba lagi.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().contains('network')
            ? 'Tidak ada koneksi internet.'
            : 'Terjadi kesalahan. Coba lagi.',
      );
    }
  }

  void reset() => state = const ClaimFormState();
}

// Provider autoDispose — reset saat keluar dari bottom sheet
final claimFormProvider =
    StateNotifierProvider.autoDispose<ClaimFormNotifier, ClaimFormState>(
      (ref) => ClaimFormNotifier(ref),
    );
