import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lostnfound/core/theme/app_theme.dart';
import 'package:lostnfound/features/claim/data/claim_model.dart';
import 'package:lostnfound/features/claim/data/claim_provider.dart';

// import '../../../../core/theme/app_theme.dart';
// import '../../data/claim_model.dart';
// import '../../data/claim_provider.dart';

// ── Helper: tampilkan bottom sheet ───────────────────────────
Future<void> showClaimBottomSheet(
  BuildContext context,
  String itemId,
  String itemName,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ClaimBottomSheet(itemId: itemId, itemName: itemName),
  );
}

// ── Widget utama ──────────────────────────────────────────────
class ClaimBottomSheet extends ConsumerWidget {
  final String itemId;
  final String itemName;
  const ClaimBottomSheet({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existingAsync = ref.watch(existingClaimProvider(itemId));

    return existingAsync.when(
      // Saat mengecek klaim existing: tampilkan loading minimal
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _ClaimForm(itemId: itemId, itemName: itemName),
      data: (existingClaim) {
        // Sudah pernah klaim → tampilkan status, bukan form
        if (existingClaim != null) {
          return _ExistingClaimView(claim: existingClaim, itemName: itemName);
        }
        // Belum pernah klaim → tampilkan form
        return _ClaimForm(itemId: itemId, itemName: itemName);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// View: klaim sudah pernah diajukan
// ─────────────────────────────────────────────────────────────
class _ExistingClaimView extends StatelessWidget {
  final ClaimModel claim;
  final String itemName;
  const _ExistingClaimView({required this.claim, required this.itemName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = claim.status.color;
    final label = claim.status.label;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            _HandleBar(),
            const SizedBox(height: 16),

            // Ikon status besar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                claim.isApproved
                    ? Icons.check_circle_outline
                    : claim.isRejected
                    ? Icons.cancel_outlined
                    : Icons.hourglass_empty_outlined,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'Klaim Sudah Diajukan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              itemName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Pesan sesuai status
            Text(
              claim.isApproved
                  ? 'Klaimmu telah disetujui oleh admin. '
                        'Admin akan menghubungimu untuk proses serah terima.'
                  : claim.isRejected
                  ? 'Klaimmu ditolak. '
                        '${claim.rejectionReason != null ? 'Alasan: ${claim.rejectionReason}' : ''}'
                  : 'Klaimmu sedang menunggu verifikasi admin. '
                        'Kamu akan mendapat notifikasi saat ada update.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Form: ajukan klaim baru
// ─────────────────────────────────────────────────────────────
class _ClaimForm extends ConsumerStatefulWidget {
  final String itemId;
  final String itemName;
  const _ClaimForm({required this.itemId, required this.itemName});

  @override
  ConsumerState<_ClaimForm> createState() => _ClaimFormState();
}

class _ClaimFormState extends ConsumerState<_ClaimForm> {
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
    final padding = MediaQuery.of(context).viewInsets.bottom;

    // Listener: sukses → tutup + snackbar informatif
    ref.listen(claimFormProvider, (prev, next) {
      if (next.isSuccess) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Klaim berhasil diajukan!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2),
                Text(
                  'Admin akan memverifikasi dalam 24 jam. '
                  'Pantau di tab "Laporanku" → Klaim.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(claimFormProvider.notifier).reset();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(child: _HandleBar()),
              const SizedBox(height: 16),

              // Judul
              Text(
                'Ajukan Klaim',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.itemName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Info panel: proses klaim
              _InfoPanel(),
              const SizedBox(height: 16),

              // ── Ciri khusus ──────────────────────────
              Text(
                'Ciri Khusus Barang *',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jelaskan detail yang hanya diketahui pemilik asli dan '
                'tidak mungkin ditebak orang lain.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _secretCtrl,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Contoh: "Di dalam dompet ada kartu nama '
                      'atas nama saya dan foto keluarga di slot '
                      'kanan, juga ada stiker biru di pojok bawah." '
                      '\n\nSemakin spesifik semakin baik.',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ciri khusus wajib diisi';
                  }
                  if (v.trim().length < 20) {
                    return 'Mohon deskripsikan lebih detail (min 20 karakter)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Foto bukti ────────────────────────────
              _ProofPhotoSection(),
              const SizedBox(height: 24),

              // Error
              if (state.error != null) _ErrorBanner(message: state.error!),

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

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Dengan mengajukan klaim, kamu menyatakan bahwa\n'
                  'informasi yang diberikan adalah benar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Upload foto bukti ─────────────────────────────────────────
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
          'Foto KTM, nota pembelian, struk garansi, atau foto lama '
          'bersama barang ini.',
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
              (e) => _ProofThumb(
                file: File(e.value.path),
                index: e.key,
                onRemove: () => ref
                    .read(claimFormProvider.notifier)
                    .removeProofPhoto(e.key),
              ),
            ),
            if (photos.length < 3) _AddProofButton(photosCount: photos.length),
          ],
        ),
      ],
    );
  }
}

class _ProofThumb extends StatelessWidget {
  final File file;
  final int index;
  final VoidCallback onRemove;
  const _ProofThumb({
    required this.file,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 11),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddProofButton extends ConsumerWidget {
  final int photosCount;
  const _AddProofButton({required this.photosCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _pick(context, ref),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
          ),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 22,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 3),
            Text(
              '${photosCount}/3',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pick(BuildContext context, WidgetRef ref) {
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
                ref.read(claimFormProvider.notifier).addProofFromGallery();
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

// ── Shared sub-widgets ────────────────────────────────────────
class _HandleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 15,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                'Bagaimana proses klaim bekerja',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...[
            '1. Isi ciri khusus dan upload bukti kepemilikan',
            '2. Admin memverifikasi klaim dalam 24 jam',
            '3. Jika disetujui, admin menghubungimu untuk serah terima',
            '4. Informasi klaimmu bersifat rahasia — tidak terlihat pengguna lain',
          ].map(
            (t) => Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSecondaryContainer,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
