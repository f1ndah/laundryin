import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/db_service.dart';
import '../../widgets/app_about.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_list_tile.dart';
import '../auth_check.dart';

class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key});

  @override
  State<ProfilTab> createState() => ProfilTabState();
}

class ProfilTabState extends State<ProfilTab> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await AuthService.getProfile();
    final user = AuthService.currentUser;
    List<Map<String, dynamic>> trx = [];
    if (user != null) {
      trx = await DbService.getUserTransactions(user.id);
    }
    if (mounted) {
      setState(() {
        _profile = profile;
        _transactions = trx;
        _loading = false;
      });
    }
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '-';
    final total = _transactions.length;
    final menunggu = _transactions.where((e) => e['status'] == 'Menunggu').length;
    final proses = _transactions.where((e) => e['status'] == 'Proses').length;
    final selesai = _transactions.where((e) => e['status'] == 'Selesai').length;
    final saldo = (_profile?['saldo'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppColors.primary,
        actions: [AppAbout.action(context)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Data profil tidak ditemukan',
                  subtitle: 'Silahkan login ulang',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      // Profile Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                            ),
                            child: const CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, size: 40, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _profile?['nama'] ?? '-',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
                                ),
                                const SizedBox(height: 4),
                                Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Wallet Info (Minimalist)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Saldo Refund', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatRupiah(saldo),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Statistics (Flat grid)
                      const Text('Statistik Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statItem('$total', 'Total', Icons.receipt_long, Colors.blue),
                            _statItem('$menunggu', 'Antre', Icons.access_time, Colors.orange),
                            _statItem('$proses', 'Proses', Icons.local_laundry_service, Colors.indigo),
                            _statItem('$selesai', 'Selesai', Icons.check_circle, Colors.green),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.logout, color: Colors.red, size: 20),
                              ),
                              title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
                              onTap: () => AuthService.logout(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}
