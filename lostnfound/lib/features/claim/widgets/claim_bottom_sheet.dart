import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lostnfound/core/theme/app_theme.dart';
import 'package:lostnfound/features/claim/data/claim_provider.dart';

// Helper: tampilkan bottom sheet dari luar
Future<void> showClaimBottomSheet(
  BuildContext context,
  String itemId,
  String itemName,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // penting: ikuti keyboard
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ClaimBottomSheet(itemId: itemId, itemName: itemName),
  );
}

class ClaimBottomSheet extends ConsumerStatefulWidget {
  final String itemId;
  final String itemName;
  const ClaimBottomSheet({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  @override
  ConsumerState<ClaimBottomSheet> createState() => _ClaimBottomSheetState();
}

class _ClaimBottomSheetState extends ConsumerState<ClaimBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _secretCtrl = TextEditingController();

  @override
  void dispose() {
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(claimFormProvider.notifier)
        .submitClaim(
          itemId: widget.itemId,
          secretDescription: _secretCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(claimFormProvider);
    final theme = Theme.of(context);

    // Listener: sukses → tutup sheet + snackbar
    ref.listen(claimFormProvider, (prev, next) {
      if (next.isSuccess) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Klaim berhasil diajukan! Admin akan meninjau.'),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(claimFormProvider.notifier).reset();
      } else if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    // Padding bawah menyesuaikan keyboard
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Judul
              Text(
                'Ajukan Klaim',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'untuk: ${widget.itemName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Isi jawaban dengan jujur. Admin akan memverifikasi '
                        'klaimmu sebelum barang diserahkan. '
                        'Jawaban hanya terlihat oleh admin.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSecondaryContainer,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ciri khusus / jawaban verifikasi
              Text(
                'Ciri Khusus Barang *',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jelaskan ciri yang hanya diketahui pemilik asli. '
                'Contoh: "Ada stiker nama di bagian dalam" atau '
                '"Nomor seri di bawah baterai adalah ABC123".',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _secretCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Tuliskan ciri khusus yang hanya kamu tahu...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 42),
                    child: Icon(Icons.vpn_key_outlined),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ciri khusus wajib diisi untuk verifikasi';
                  }
                  if (v.trim().length < 10) {
                    return 'Deskripsi terlalu pendek, minimal 10 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Upload bukti
              _ProofPhotoSection(),
              const SizedBox(height: 24),

              // Error message
              if (state.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Tombol submit
              ElevatedButton(
                onPressed: state.isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: state.isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Mengajukan klaim...'),
                        ],
                      )
                    : const Text('Kirim Klaim'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//───── Upload bukti foto ─────
class _ProofPhotoSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(claimFormProvider).proofPhotos;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Foto Bukti Kepemilikan',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(opsional, maks 3)',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Contoh: foto KTM, nota pembelian, atau foto lama bersama barang.',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...photos.asMap().entries.map(
              (e) => Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(e.value.path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => ref
                          .read(claimFormProvider.notifier)
                          .removeProofPhoto(e.key),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (photos.length < 3)
              GestureDetector(
                onTap: () => _showPicker(context, ref),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.4),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 22,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                ref.read(claimFormProvider.notifier).addProofPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                ref.read(claimFormProvider.notifier).addProofFromCamera();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
