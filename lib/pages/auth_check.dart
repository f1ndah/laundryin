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
  Future<Map<String, dynamic>?>? _profileFuture;
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _profileFuture == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        final user = session?.user ?? AuthService.currentUser;

        if (user == null) {
          _profileFuture = null;
          _lastUserId = null;
          return const LoginPage();
        }

        // Only fetch profile if user has changed
        if (_profileFuture == null || _lastUserId != user.id) {
          _lastUserId = user.id;
          _profileFuture = AuthService.getProfile();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              // Only logout if we're sure the fetch finished and returned null
              if (profileSnapshot.connectionState == ConnectionState.done) {
                AuthService.logout();
                return const Scaffold(
                  body: Center(
                    child: Text('Session tidak valid, silahkan login ulang'),
                  ),
                );
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
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
