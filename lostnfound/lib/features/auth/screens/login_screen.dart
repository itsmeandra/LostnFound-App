import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lostnfound/core/constants/app_constants.dart';
import 'package:lostnfound/features/auth/provider/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Submit Login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Google Sign In
  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      setState(() => _errorMessage = 'Login Google gagal. Coba lagi');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Translate Supabase errors into user-friendly Indonesian language messages.
  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email atau Password salah.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox kamu.';
    }
    if (message.contains('Too many requests')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa menit.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Header ──
                Text(
                  'Selamat Datang',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login untuk melaporkan atau mencari baarang.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),

                // ── Error Banner ──
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Email Field ──
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
                    if (!v.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password Field ──
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // ── Lupa Password ──
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Lupa password?'),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Tombol Login ──
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Masuk'),
                ),
                const SizedBox(height: 16),

                // ── Divider ──
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'atau',
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Google Sign In ──
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Lanjutkan dengan Google'),
                ),
                const SizedBox(height: 32),

                // ── Link ke Register ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun? '),
                    TextButton(
                      onPressed: () => context.push(AppConstants.routeRegister),
                      child: const Text('Daftar Sekarang'),
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
