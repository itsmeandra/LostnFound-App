import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/features/report/data/photo_upload_service.dart';
import 'package:lostnfound/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//───── State form klaim ─────
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

//───── Notifier ─────
class ClaimFormNotifier extends StateNotifier<ClaimFormState> {
  final Ref _ref;
  final _photoService = PhotoUploadService();

  ClaimFormNotifier(this._ref) : super(const ClaimFormState());

  Future<void> addProofPhoto() async {
    if (state.proofPhotos.length >= 3) return; // maks 3 bukti
    final picked = await _photoService.pickFromGallery(maxImages: 1);
    if (picked.isNotEmpty) {
      state = state.copyWith(proofPhotos: [...state.proofPhotos, picked.first]);
    }
  }

  Future<void> addProofFromCamera() async {
    if (state.proofPhotos.length >= 3) return;
    final picked = await _photoService.pickFromCamera();
    if (picked != null) {
      state = state.copyWith(proofPhotos: [...state.proofPhotos, picked]);
    }
  }

  void removeProofPhoto(int index) {
    final updated = [...state.proofPhotos]..removeAt(index);
    state = state.copyWith(proofPhotos: updated);
  }

  // Submit klaim — upload bukti + insert ke DB
  Future<void> submitClaim({
    required String itemId,
    required String secretDescription,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('Harus login terlebih dahulu');

      // Upload foto bukti kepemilikan
      final proofUrls = state.proofPhotos.isNotEmpty
          ? await _photoService.uploadAll(state.proofPhotos, user.id)
          : <String>[];

      // Insert klaim ke DB
      // RLS memastikan claimant_id = auth.uid()
      await supabase.from(AppConstants.tableClaims).insert({
        'item_id': itemId,
        'claimant_id': user.id,
        'proof_photos': proofUrls,
        'secret_description': secretDescription.trim(),
        'status': 'pending',
      });

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        proofPhotos: [],
      );
    } on PostgrestException catch (e) {
      // Kode 23505: unique constraint violation (sudah pernah klaim item ini)
      final msg = e.code == '23505'
          ? 'Kamu sudah pernah mengajukan klaim untuk barang ini.'
          : 'Gagal mengajukan klaim. Coba lagi.';
      state = state.copyWith(isLoading: false, error: msg);
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
