import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_button.dart';
import '../services/db_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_input.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _isLogin = true;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool ok = false}) {
    if (!ok && msg.contains('sedang dikembangkan')) {
      AppSnackbar.info(context, msg);
    } else {
      AppSnackbar.show(context, message: msg, isError: !ok);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    try {
      if (_isLogin) {
        await AuthService.login(_email.text.trim(), _password.text);
      } else {
        await AuthService.register(
          email: _email.text.trim(),
          password: _password.text,
          nama: _nama.text.trim(),
          role: 'pelanggan',
        );
        if (mounted) {
          _snack('Pendaftaran berhasil! Silakan masuk.', ok: true);
          setState(() {
            _isLogin = true;
            _password.clear();
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('${_isLogin ? 'Login' : 'Registrasi'} gagal: $e');
    }
    
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Header
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_laundry_service,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isLogin ? 'Selamat Datang!' : 'Buat Akun Baru',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Masuk untuk melanjutkan ke LaundryIN' : 'Daftar sekarang untuk mulai memesan',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Fields
                  if (!_isLogin) ...[
                    AppInput(
                      controller: _nama,
                      label: 'Nama Lengkap',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v!.trim().isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),
                  ],
                  AppInput(
                    controller: _email,
                    label: 'Email',
                    prefixIcon: Icons.email_outlined,
                    validator: (v) => v!.isEmpty ? 'Email wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  AppInput(
                    controller: _password,
                    label: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => v!.length < 6 ? 'Password minimal 6 karakter' : null,
                  ),
                  const SizedBox(height: 8),
                  
                  // Lupa Password (mock)
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(
                        label: 'Lupa Password?',
                        variant: AppButtonVariant.ghost,
                        onPressed: () {
                          _snack('Fitur lupa password sedang dikembangkan.');
                        },
                      ),
                    )
                  else
                    const SizedBox(height: 24),
                  
                  if (_isLogin) const SizedBox(height: 16),

                  // Submit Button
                  AppButton(
                    label: _isLogin ? 'MASUK' : 'DAFTAR SEKARANG',
                    variant: AppButtonVariant.primary,
                    onPressed: _submit,
                    isLoading: _loading,
                    icon: Icons.arrow_forward,
                    iconRight: true,
                    expandContent: true,
                  ),
                  const SizedBox(height: 32),

                  // Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? 'Belum punya akun?' : 'Sudah punya akun?',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      AppButton(
                        label: _isLogin ? 'Daftar di sini' : 'Masuk di sini',
                        variant: AppButtonVariant.ghost,
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _formKey.currentState?.reset();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
