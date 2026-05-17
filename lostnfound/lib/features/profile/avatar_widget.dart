import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String displayName; // untuk generate inisial fallback
  final double radius; // radius CircleAvatar
  final VoidCallback? onTap; // null = tidak bisa di-tap
  final bool showEditBadge; // tampilkan ikon pensil di sudut

  const AvatarWidget({
    super.key,
    this.avatarUrl,
    required this.displayName,
    this.radius = 28,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Inisial dari nama: "Budi Santoso" → "BS", "Rina" → "R"
    final initials = displayName.trim().isEmpty
        ? '?'
        : displayName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
              .join();

    Widget avatar;

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      // Ada foto — tampilkan dengan CachedNetworkImage
      avatar = CachedNetworkImage(
        imageUrl: avatarUrl!,
        imageBuilder: (_, imageProvider) =>
            CircleAvatar(radius: radius, backgroundImage: imageProvider),
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade100,
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
        errorWidget: (_, __, ___) =>
            _initialsAvatar(context, initials, radius, theme),
      );
    } else {
      // Tidak ada foto — tampilkan inisial
      avatar = _initialsAvatar(context, initials, radius, theme);
    }

    // Bungkus dengan Stack jika ada edit badge
    if (showEditBadge) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: radius * 0.65,
              height: radius * 0.65,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              child: Icon(Icons.edit, color: Colors.white, size: radius * 0.35),
            ),
          ),
        ],
      );
    }

    // Bungkus dengan GestureDetector jika bisa di-tap
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _initialsAvatar(
    BuildContext context,
    String initials,
    double radius,
    ThemeData theme,
  ) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.5,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
