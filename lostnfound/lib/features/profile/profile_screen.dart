import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/features/profile/avatar_widget.dart';
import 'package:lostnfound/features/profile/edit_profile_sheet.dart';
import 'package:lostnfound/features/profile/profile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final updateState = ref.watch(profileNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        // Tidak ada back button — ini tab root
        automaticallyImplyLeading: false,
      ),
      body: profileAsync.when(
        loading: () => const _ProfileSkeleton(),
        error: (e, _) =>
            _ErrorView(onRetry: () => ref.refresh(profileProvider)),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil tidak ditemukan.'));
          }

          return ListView(
            children: [
              //───── Header: Avatar + Nama + Email ─────
              _ProfileHeader(
                profile: profile,
                isUploading: updateState.isLoading,
                onAvatarTap: () => _showAvatarOptions(context, ref, profile),
                onEditTap: () => showEditProfileSheet(context, profile),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),

              //───── Section: Akun ─────
              _SectionHeader('Akun'),
              _SettingsTile(
                icon: Icons.edit_outlined,
                title: 'Edit Profil',
                subtitle: 'Ubah nama dan nomor telepon',
                onTap: () => showEditProfileSheet(context, profile),
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Ubah Password',
                subtitle: 'Kirim email reset password',
                onTap: () => _handleResetPassword(context, ref, profile.email),
              ),

              const Divider(height: 1),

              //───── Section: Aktivitas ─────
              _SectionHeader('Aktivitas'),
              _SettingsTile(
                icon: Icons.list_alt_outlined,
                title: 'Laporan Saya',
                subtitle: 'Lihat semua laporan yang pernah dibuat',
                onTap: () => context.go('/track'),
                showChevron: true,
              ),
              _SettingsTile(
                icon: Icons.handshake_outlined,
                title: 'Klaim Saya',
                subtitle: 'Status pengajuan klaim',
                onTap: () {
                  context.push(AppConstants.routeMyClaims);
                },
                showChevron: true,
              ),

              const Divider(height: 1),

              //───── Section: Aplikasi ─────
              _SectionHeader('Aplikasi'),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Tentang Aplikasi',
                subtitle: 'Versi 1.0.0 • Lost & Found App',
                onTap: () => _showAboutDialog(context),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Kebijakan Privasi',
                onTap: () async {
                  // Ganti dengan URL kebijakan privasi yang sesungguhnya
                  final uri = Uri.parse('https://example.com/privacy');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),

              const Divider(height: 1),
              const SizedBox(height: 8),

              //───── Tombol Logout ─────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context, ref),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  //───── Opsi ganti/hapus avatar ─────
  void _showAvatarOptions(
    BuildContext context,
    WidgetRef ref,
    ProfileModel profile,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Ganti Foto Profil'),
              onTap: () {
                Navigator.pop(context);
                ref.read(profileNotifierProvider.notifier).updateAvatar();
              },
            ),
            if (profile.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Hapus Foto Profil',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(profileNotifierProvider.notifier).removeAvatar();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  //───── Reset password via email ─────
  Future<void> _handleResetPassword(
    BuildContext context,
    WidgetRef ref,
    String? email,
  ) async {
    if (email == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email tidak tersedia.')));
      return;
    }

    try {
      await ref.read(authServiceProvider).resetPassword(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email reset password dikirim ke $email. Cek inbox kamu.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim email reset. Coba lagi.'),
          ),
        );
      }
    }
  }

  //───── Logout dengan konfirmasi ─────
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Keluar dari aplikasi?'),
        content: const Text(
          'Kamu akan keluar dari akunmu. Untuk mengakses laporan, '
          'kamu perlu login kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authServiceProvider).signOut();
      // GoRouter redirect otomatis ke /login setelah signOut
    }
  }

  //───── About dialog ─────
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Lost n Found',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Team Lost n Found',
      children: [
        const SizedBox(height: 12),
        const Text(
          'Platform pelaporan dan pencarian barang hilang/temuan '
          'di lingkungan kampus dan sekitarnya.',
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  final bool isUploading;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditTap;

  const _ProfileHeader({
    required this.profile,
    required this.isUploading,
    required this.onAvatarTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              AvatarWidget(
                avatarUrl: profile.avatarUrl,
                displayName: profile.fullName,
                radius: 48,
                onTap: isUploading ? null : onAvatarTap,
                showEditBadge: !isUploading,
              ),
              if (isUploading)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Nama
          Text(
            profile.fullName.isEmpty ? 'Nama belum diatur' : profile.fullName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          // Email
          if (profile.email != null) ...[
            const SizedBox(height: 4),
            Text(
              profile.email!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          // Role badge (admin saja)
          if (profile.role == 'admin') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Administrator',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Tombol edit
          OutlinedButton.icon(
            onPressed: onEditTap,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Profil'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(160, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: showChevron
          ? Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant)
          : null,
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

//───── Loading skeleton ─────
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Header skeleton
        Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 12),
                Container(width: 140, height: 16, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Container(width: 200, height: 12, color: Colors.grey.shade200),
              ],
            ),
          ),
        ),
        // Tile skeletons
        ...List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(width: 24, height: 24, color: Colors.grey.shade200),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 13,
                        color: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 180,
                        height: 11,
                        color: Colors.grey.shade200,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

//───── Error view ─────
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Gagal memuat profil'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
