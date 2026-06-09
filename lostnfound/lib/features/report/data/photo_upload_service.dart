import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/main.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoUploadService {
  final _picker = ImagePicker();

  //───── Pilih dari galeri (multi) ─────
  // Mengembalikan list path file lokal setelah dikompresi.
  Future<List<XFile>> pickFromGallery({int maxImages = 5}) async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 85, // Pre-quality dari picker (kompresi tambahan di bawah)
    );
    // Batasi sesuai sisa slot
    return picked.take(maxImages).toList();
  }

  //───── Ambil dari kamera (satu foto) ─────
  Future<XFile?> pickFromCamera() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
  }

  //───── Kompres satu file ─────
  // Target: ukuran < maxSizeKb, kualitas JPEG minQuality–maxQuality
  Future<File?> compressImage(XFile xfile) async {
    final file = File(xfile.path);
    final size = await file.length();
    final maxBytes = AppConstants.maxPhotoSizeKb * 1024; // 800KB

    // Jika sudah kecil, tidak perlu kompresi
    if (size <= maxBytes) return file;

    final dir = await getTemporaryDirectory();
    final targetPath = p.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      format: CompressFormat.jpeg,
      quality: AppConstants.maxPhotoQuality, // 80
      minWidth: 1080,
      minHeight: 1080,
    );

    return result != null ? File(result.path) : file;
  }

  //───── Upload satu foto ke Supabase Storage ─────
  // Path di bucket: {userId}/{epochMs}_{index}.jpg
  // Mengembalikan URL publik (jika bucket public) atau signed URL.
  Future<String?> uploadPhoto(File file, String userId, int index) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
    final storagePath = '$userId/$fileName';

    try {
      await supabase.storage
          .from(AppConstants.itemPhotosBucket)
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      // Bucket 'item-photos' adalah private — gunakan createSignedUrl
      // untuk URL yang valid 1 jam. Untuk production pertimbangkan
      // menyimpan path & generate signed URL on-demand.
      //
      // Alternatif jika bucket public:
      // return supabase.storage.from(AppConstants.itemPhotosBucket).getPublicUrl(storagePath);
      final expiresIn = 60 * 60 * 24 * 30; // 1 bulan

      final signedUrl = await supabase.storage
          .from(AppConstants.itemPhotosBucket)
          // .createSignedUrl(storagePath, 60 * 60); // 1 jam
          .createSignedUrl(storagePath, expiresIn);

      return signedUrl;
    } catch (e) {
      debugPrint('Upload photo error: $e');
      return null;
    }
  }

  //───── Upload semua foto sekaligus ─────
  // Kompresi + upload semua foto yang dipilih user.
  // Mengembalikan list URL (hanya yang berhasil).
  Future<List<String>> uploadAll(List<XFile> files, String userId) async {
    final urls = <String>[];

    for (int i = 0; i < files.length; i++) {
      // 1. Kompres
      final compressed = await compressImage(files[i]);
      if (compressed == null) continue;

      // 2. Upload
      final url = await uploadPhoto(compressed, userId, i);
      if (url != null) urls.add(url);

      // 3. Hapus file temp setelah upload
      try {
        if (compressed.path != files[i].path) {
          await compressed.delete();
        }
      } catch (_) {}
    }

    return urls;
  }

  //───── Hapus foto dari Storage ─────
  // Dipakai saat user uncheck foto dari form.
  Future<void> deletePhoto(String url, String userId) async {
    try {
      // Extract path dari signed URL: ambil bagian setelah bucket name
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf(AppConstants.itemPhotosBucket);
      if (bucketIdx == -1) return;
      final storagePath = segments.sublist(bucketIdx + 1).join('/');
      await supabase.storage.from(AppConstants.itemPhotosBucket).remove([
        storagePath,
      ]);
    } catch (e) {
      debugPrint('Delete photo error: $e');
    }
  }
}
