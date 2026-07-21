import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _loginKey = GlobalKey<FormState>();
  final _regKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nama.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? Colors.green : Colors.red),
    );
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.login(_email.text.trim(), _password.text);
    } on AuthException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('Login gagal: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _register() async {
    if (!_regKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(
        email: _email.text.trim(),
        password: _password.text,
        nama: _nama.text.trim(),
        role: 'pelanggan',
      );
      if (mounted) {
        _snack('Daftar berhasil! Silahkan login', ok: true);
        _tab.animateTo(0);
      }
    } on AuthException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('Registrasi gagal: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 70,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_laundry_service,
                      size: 70,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('LaundryIN', style: AppTextStyles.heading),
                  Text('Cuci baju tanpa ribet', style: AppTextStyles.caption),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tab,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primary,
                    tabs: const [Tab(text: 'Login'), Tab(text: 'Daftar')],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 280,
                    child: TabBarView(
                      controller: _tab,
                      children: [_loginForm(), _registerForm()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    return Form(
      key: _loginKey,
      child: Column(
        children: [
          AppInput(
            controller: _email,
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            validator: (v) => v!.isEmpty ? 'Wajib' : null,
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _password,
            label: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) => v!.length < 6 ? 'Min 6' : null,
          ),
          const SizedBox(height: 24),
          AppButton(label: 'LOGIN', onPressed: _login, isLoading: _loading),
        ],
      ),
    );
  }

  Widget _registerForm() {
    return Form(
      key: _regKey,
      child: Column(
        children: [
          AppInput(
            controller: _nama,
            label: 'Nama Lengkap',
            prefixIcon: Icons.person_outline,
            validator: (v) => v!.trim().isEmpty ? 'Wajib' : null,
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _email,
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            validator: (v) => v!.isEmpty ? 'Wajib' : null,
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _password,
            label: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) => v!.length < 6 ? 'Min 6' : null,
          ),
          const SizedBox(height: 24),
          AppButton(label: 'DAFTAR', onPressed: _register, isLoading: _loading),
        ],
      ),
    );
  }
}
