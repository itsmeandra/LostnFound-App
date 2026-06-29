import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lostnfound/features/claim/data/claim_model.dart';
import 'package:lostnfound/features/claim/data/claim_provider.dart';

class MyClaimsScreen extends ConsumerWidget {
  const MyClaimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(myClaimsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FB),
      appBar: AppBar(
        title: const Text(
          'Klaim Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: claimsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Terjadi kesalahan: $err')),
        data: (claims) {
          if (claims.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada klaim yang diajukan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(myClaimsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: claims.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _ClaimCard(claim: claims[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ClaimCard extends ConsumerWidget {
  final ClaimModel claim;
  const _ClaimCard({required this.claim});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = claim.item;
    if (item == null) return const SizedBox.shrink();

    final actionState = ref.watch(claimActionProvider);

    // Mengambil warna dan label langsung dari Enum! Sangat praktis.
    final statusColor = claim.status.color;
    final statusLabel = claim.status.label;

    String actionMessage;
    IconData actionIcon;

    // Menentukan pesan instruksi berdasarkan enum
    switch (claim.status) {
      case ClaimStatus.approved:
        actionMessage =
            'Silakan ambil barang di Ruang Admin (Gedung Utama). Bawa KTM asli sebagai bukti.';
        actionIcon = Icons.check_circle_outline;
        break;
      case ClaimStatus.rejected:
        actionMessage =
            claim.rejectionReason ??
            'Bukti yang dilampirkan tidak sesuai atau barang sudah diambil orang lain.';
        actionIcon = Icons.cancel_outlined;
        break;
      case ClaimStatus.completed:
        actionMessage = 'Barang telah berhasil diserahkan kepadamu.';
        actionIcon = Icons.handshake_outlined;
        break;
      case ClaimStatus.pending:
        actionMessage =
            'Admin sedang meninjau bukti klaimmu. Mohon tunggu proses 1x24 jam.';
        actionIcon = Icons.access_time;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: statusColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(actionIcon, size: 18, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('d MMM yyyy').format(claim.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Info Barang
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.photoUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.photoUrls.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 16),

                // Detail
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Action / Instruksi Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionMessage,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),

                // Tombol aksi KHUSUS JIKA STATUS APPROVED
                if (claim.isApproved) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: actionState.isLoading
                          ? null
                          : () async {
                              // Jalankan fungsi dan tunggu hasilnya (true/false)
                              final isSuccess = await ref
                                  .read(claimActionProvider.notifier)
                                  .confirmItemReceived(claim.id, claim.itemId);

                              if (!context.mounted) return;

                              if (isSuccess) {
                                // Jika Berhasil: Hijau
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Selesai! Barang telah dikonfirmasi.',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                // Jika Gagal: Merah dan tampilkan errornya
                                final errorMsg = ref
                                    .read(claimActionProvider)
                                    .error;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal memproses: $errorMsg'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: actionState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Konfirmasi Barang Diterima'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
