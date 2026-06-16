import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class DropPointCard extends StatelessWidget {
  final String dropPoint;
  final String itemStatus;

  const DropPointCard({
    super.key,
    required this.dropPoint,
    required this.itemStatus,
  });

  // Hanya tampilkan untuk status yang relevan
  static bool shouldShow(String? dropPoint, String status) {
    if (dropPoint == null || dropPoint.isEmpty) return false;
    return ['published', 'claimed', 'completed'].contains(status);
  }

  @override
  Widget build(BuildContext context) {
    // Warna berbeda per status
    final (bgColor, borderColor, iconColor, label) = switch (itemStatus) {
      'published' => (
        const Color(0xFFE3F2FD),
        const Color(0xFF90CAF9),
        const Color(0xFF1565C0),
        'Lokasi Penyimpanan Barang',
      ),
      'claimed' => (
        const Color(0xFFE8F5E9),
        const Color(0xFFA5D6A7),
        const Color(0xFF2E7D32),
        'Lokasi Pengambilan Barang',
      ),
      _ => (
        const Color(0xFFF5F5F5),
        const Color(0xFFBDBDBD),
        Colors.grey,
        'Lokasi Barang',
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lokasi
            Text(
              dropPoint,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: iconColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),

            // Action buttons
            Row(
              children: [
                // Salin
                _ActionChip(
                  icon: Icons.copy_outlined,
                  label: 'Salin',
                  color: iconColor,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: dropPoint));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lokasi disalin'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                // Buka Maps
                _ActionChip(
                  icon: Icons.map_outlined,
                  label: 'Buka Maps',
                  color: iconColor,
                  onTap: () async {
                    final query = Uri.encodeComponent(dropPoint);
                    final uri = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$query',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
