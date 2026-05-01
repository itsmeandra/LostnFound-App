import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ref
          .read(authServiceProvider)
          .signUpWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
          );
      if (!mounted) return;

      // Jika Supabase Email Confirm aktif (default), user perlu konfirmasi dulu
      if (res.session == null) {
        _showConfirmationDialog();
      }
      // Jika Email Confirm dimatikan, langsung dapat session → router redirect ke /home
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapError(e.message));
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Cek email kamu'),
        content: Text(
          'Kami mengirim link konfirmasi ke ${_emailCtrl.text}. '
          'Klik link tersebut untuk mengaktifkan akun kamu.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text('Ke halaman login'),
          ),
        ],
      ),
    );
  }

  String _mapError(String msg) {
    if (msg.contains('already registered')) return 'Email sudah terdaftar.';
    if (msg.contains('Password should be'))
      return 'Password minimal 6 karakter.';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Buat Akun'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar sekarang',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gratis, tidak perlu kartu kredit.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null) ...[
                  _ErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],

                // ── Nama Lengkap ──
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Nama wajib diisi';
                    if (v.trim().length < 3) return 'Nama terlalu pendek';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Email ──
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ──
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure1,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure1
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Konfirmasi Password ──
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure2,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure2
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Konfirmasi password wajib diisi';
                    if (v != _passwordCtrl.text) return 'Password tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Tombol Daftar ──
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Buat Akun'),
                ),
                const SizedBox(height: 16),

                // ── Link ke Login ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? '),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Masuk'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
