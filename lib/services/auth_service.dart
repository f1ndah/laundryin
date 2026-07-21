import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  static User? get currentUser => _supabase.auth.currentUser;

  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  static Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final res = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return res;
  }

  static Future<String?> getRole() async {
    final profile = await getProfile();
    return profile?['role'] as String?;
  }

  static Future<void> login(String email, String password) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) throw Exception('Login gagal');
  }

  static Future<void> register({
    required String email,
    required String password,
    required String nama,
    required String role,
  }) async {
    final res = await _supabase.auth.signUp(email: email, password: password);
    if (res.user == null) throw Exception('Registrasi gagal');
    await _supabase.from('profiles').insert({
      'id': res.user!.id,
      'nama': nama,
      'email': email,
      'role': role,
    });
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
