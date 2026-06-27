import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:lostnfound/features/profile/avatar_widget.dart';
import 'package:lostnfound/features/profile/edit_profile_sheet.dart';
import 'package:lostnfound/features/profile/profile_provider.dart';

const _surfaceColor = Colors.white;
const _primaryDeepBlue = Color(0xFF131B2E);
const _borderLight = Color(0xFFE2E8F0);
const _textSecondary = Color(0xFF45464D);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final updateState = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Profil Saya',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _primaryDeepBlue,
          ),
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
            children: [
              _ProfileHeader(
                profile: profile,
                isUploading: updateState.isLoading,
                onAvatarTap: () => _showAvatarOptions(context, ref, profile),
              ),
              const SizedBox(height: 40),

              const _SectionHeader('Akun'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profil',
                    subtitle: 'Ubah nama dan nomor telepon',
                    onTap: () => showEditProfileSheet(context, profile),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _SectionHeader('Aktivitas'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Laporan Saya',
                    subtitle: 'Lihat semua laporan yang pernah dibuat',
                    onTap: () => context.go('/my-reports'),
                  ),
                  _SettingsTile(
                    icon: Icons.handshake_outlined,
                    title: 'Klaim Saya',
                    subtitle: 'Status pengajuan klaim',
                    onTap: () => context.push(AppConstants.routeMyClaims),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _SectionHeader('Aplikasi'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.help_outline,
                    title: 'Tentang Aplikasi',
                    subtitle: 'Versi 1.0.0 • Lost n Found App',
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              OutlinedButton.icon(
                onPressed: () => _handleLogout(context, ref),
                icon: const Icon(
                  Icons.logout,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                label: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFDC2626),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFFEF2F2,
                  ),
                  side: BorderSide(
                    color: Colors.red.shade200,
                  ), // Garis tepi merah
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _showAvatarOptions(
    BuildContext context,
    WidgetRef ref,
    ProfileModel profile,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_outlined,
                    size: 32,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Keluar dari aplikasi?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Kamu akan keluar dari akunmu. Untuk mengakses laporan, kamu perlu login kembali.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFDC2626,
                          ), // Merah solid
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Keluar',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authServiceProvider).signOut();
    }
  }

  void _showAboutDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  'Lost n Found',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  'Versi 1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Platform pelaporan dan pencarian barang hilang/temuan '
                  'di lingkungan kampus dan sekitarnya.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  '© 2026 Team Lost n Found. All rights reserved.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  final bool isUploading;
  final VoidCallback onAvatarTap;

  const _ProfileHeader({
    required this.profile,
    required this.isUploading,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AvatarWidget(
                  avatarUrl: profile.avatarUrl,
                  displayName: profile.fullName,
                  radius: 56, // Diperbesar sesuai desain
                  onTap: isUploading ? null : onAvatarTap,
                  showEditBadge: false,
                ),
              ),
              if (isUploading)
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Name
          Text(
            profile.fullName.isEmpty ? 'Nama belum diatur' : profile.fullName,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _primaryDeepBlue,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          if (profile.email != null)
            Text(
              profile.email!,
              style: GoogleFonts.inter(fontSize: 14, color: _textSecondary),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _primaryDeepBlue,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(
                  height: 1,
                  color: _borderLight,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(icon, size: 24, color: _primaryDeepBlue),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _primaryDeepBlue,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: _textSecondary),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFFC6C6CD),
        size: 20,
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

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
