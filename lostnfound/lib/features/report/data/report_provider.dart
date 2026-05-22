import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/main.dart';
import 'item_model.dart';
import 'photo_upload_service.dart';

//───── State form laporan ─────
// Immutable state untuk ReportFormNotifier.
class ReportFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final List<XFile> selectedPhotos; // File lokal yang dipilih user

  const ReportFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.selectedPhotos = const [],
  });

  ReportFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    List<XFile>? selectedPhotos,
  }) {
    return ReportFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // null = hapus error
      isSuccess: isSuccess ?? this.isSuccess,
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
    );
  }
}

//───── Notifier form laporan ─────
class ReportFormNotifier extends StateNotifier<ReportFormState> {
  final Ref _ref;
  final _photoService = PhotoUploadService();

  ReportFormNotifier(this._ref) : super(const ReportFormState());

  //───── Tambah foto dari galeri ─────
  Future<void> addPhotosFromGallery() async {
    final current = state.selectedPhotos;
    final remaining = AppConstants.maxPhotosPerItem - current.length;
    if (remaining <= 0) return;

    final picked = await _photoService.pickFromGallery(maxImages: remaining);
    state = state.copyWith(selectedPhotos: [...current, ...picked]);
  }

  //───── Tambah foto dari kamera ─────
  Future<void> addPhotoFromCamera() async {
    final current = state.selectedPhotos;
    if (current.length >= AppConstants.maxPhotosPerItem) return;

    final picked = await _photoService.pickFromCamera();
    if (picked != null) {
      state = state.copyWith(selectedPhotos: [...current, picked]);
    }
  }

  //───── Hapus foto dari daftar ─────
  void removePhoto(int index) {
    final updated = [...state.selectedPhotos];
    updated.removeAt(index);
    state = state.copyWith(selectedPhotos: updated);
  }

  //───── Submit laporan ─────
  // Alur lengkap: validasi → upload foto → insert DB
  Future<void> submitReport({
    required String type, // 'lost' | 'found'
    required String name,
    required String category,
    required String location,
    required double? latitude,
    required double? longitude,
    String? description,
    String? distinctiveFeatures,
    required DateTime itemDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('Harus login terlebih dahulu');

      // 1. Upload semua foto yang dipilih
      final photoUrls = state.selectedPhotos.isNotEmpty
          ? await _photoService.uploadAll(state.selectedPhotos, user.id)
          : <String>[];

      // 2. Buat model item
      final item = ItemModel(
        reporterId: user.id,
        type: type,
        name: name.trim(),
        category: category,
        location: location.trim(),
        latitude: latitude,
        longitude: longitude,
        description: description?.trim().isNotEmpty == true
            ? description!.trim()
            : null,
        distinctiveFeatures: distinctiveFeatures?.trim().isNotEmpty == true
            ? distinctiveFeatures!.trim()
            : null,
        photoUrls: photoUrls,
        status: 'pending', // selalu pending — admin yang approve
        itemDate: itemDate,
      );

      // 3. Insert ke Supabase — RLS memastikan reporter_id = auth.uid()
      await supabase.from(AppConstants.tableItems).insert(item.toJson());

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        selectedPhotos: [], // reset foto setelah submit
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e.toString()),
      );
    }
  }

  //───── Reset state (kembali ke form kosong) ─────
  void reset() {
    state = const ReportFormState();
  }

  String _parseError(String raw) {
    if (raw.contains('storage')) return 'Gagal upload foto. Coba lagi.';
    if (raw.contains('network')) return 'Tidak ada koneksi internet.';
    if (raw.contains('row-level')) return 'Sesi habis. Silakan login ulang.';
    return 'Terjadi kesalahan. Coba lagi.';
  }
}

// Provider untuk form state
final reportFormProvider =
    StateNotifierProvider.autoDispose<ReportFormNotifier, ReportFormState>(
      (ref) => ReportFormNotifier(ref),
    );

//───── My Reports ─────
// Semua laporan milik user yang sedang login (semua status).
// Menggunakan FutureProvider.autoDispose agar tidak cache saat keluar screen.
final myReportsProvider = FutureProvider.autoDispose<List<ItemModel>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final response = await supabase
      .from(AppConstants.tableItems)
      .select()
      .eq('reporter_id', user.id)
      .order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((json) => ItemModel.fromJson(json as Map<String, dynamic>))
      .toList();
});
