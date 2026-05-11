import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/report/data/report_provider.dart';

class PhotoPickerWidget extends ConsumerWidget {
  const PhotoPickerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(reportFormProvider).selectedPhotos;
    final canAdd = photos.length < AppConstants.maxPhotosPerItem;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //───── Label & Counter ─────
        Row(
          children: [
            Text(
              'Foto Barang',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${photos.length}/${AppConstants.maxPhotosPerItem}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Min 1 foto, maks ${AppConstants.maxPhotosPerItem} foto. '
          'Foto akan dikompres otomatis.',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        //───── Grid foto ─────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Foto yang sudah dipilih
            ...photos.asMap().entries.map(
              (entry) => _PhotoThumb(
                file: File(entry.value.path),
                index: entry.key,
                onRemove: () => ref
                    .read(reportFormProvider.notifier)
                    .removePhoto(entry.key),
              ),
            ),
            // Tombol tambah (hanya jika masih ada slot)
            if (canAdd) _AddPhotoButton(photos: photos),
          ],
        ),
      ],
    );
  }
}

//───── Thumbnail foto terpilih ─────
class _PhotoThumb extends StatelessWidget {
  final File file;
  final int index;
  final VoidCallback onRemove;

  const _PhotoThumb({
    required this.file,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gambar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
          ),
          // Badge index (foto ke-berapa)
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
          // Tombol hapus
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//───── Tombol tambah foto ─────
class _AddPhotoButton extends ConsumerWidget {
  final List<XFile> photos;
  const _AddPhotoButton({required this.photos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showSourcePicker(context, ref),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 28,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              'Tambah',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom sheet untuk pilih sumber foto
  void _showSourcePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              subtitle: Text(
                'Bisa pilih ${AppConstants.maxPhotosPerItem - photos.length} foto sekaligus',
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(reportFormProvider.notifier).addPhotosFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(reportFormProvider.notifier).addPhotoFromCamera();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
