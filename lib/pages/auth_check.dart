import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'admin_page.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        if (session == null) {
          return const LoginPage();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: AuthService.getProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              AuthService.logout();
              return const Scaffold(
                body: Center(
                  child: Text('Session tidak valid, silahkan login ulang'),
                ),
              );
            }

            final role = profile['role'] ?? 'pelanggan';
            return role == 'admin' ? const AdminPage() : const HomePage();
          },
        );
      },
    );
  }
}
