import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/db_service.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_list_tile.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/app_card.dart';
import '../lokasi_page.dart';
import '../pricelist_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  List<Map<String, dynamic>> _recent = [];
  String _userName = 'Pelanggan';
  int _saldo = 0;
  bool _loading = true;

  final PageController _bannerController = PageController(viewportFraction: 0.9);
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    
    final data = await DbService.getUserTransactions(user.id);
    final profile = await AuthService.getProfile();
    final saldo = await DbService.getSaldo(user.id);

    if (mounted) {
      setState(() {
        _recent = data.take(3).toList();
        _userName = profile?['nama'] ?? 'Pelanggan';
        _saldo = saldo;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadRecent,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 48),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selamat datang,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur notifikasi dalam pengembangan 🛠️'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Wallet Card & Quick Actions overlapping header
            Transform.translate(
              offset: const Offset(0, -32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Wallet Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Saldo Kamu', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(formatRupiah(_saldo), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Banner Carousel
                    SizedBox(
                      height: 110,
                      child: PageView.builder(
                        padEnds: false,
                        controller: _bannerController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentBannerIndex = index;
                          });
                        },
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          final banners = [
                            {
                              'title': 'Diskon 20% Cuci Bed Cover!',
                              'subtitle': 'Promo akhir bulan khusus untuk Anda.',
                              'color': AppColors.accent,
                              'icon': Icons.local_offer,
                            },
                            {
                              'title': 'Laundry Ekspres 24 Jam',
                              'subtitle': 'Pakaian bersih dan wangi dalam sehari.',
                              'color': AppColors.secondary,
                              'icon': Icons.speed,
                            },
                            {
                              'title': 'Gratis Antar Jemput',
                              'subtitle': 'Untuk jarak maksimal 5 km dari toko.',
                              'color': AppColors.success,
                              'icon': Icons.delivery_dining,
                            }
                          ];
                          final b = banners[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: b['color'] as Color,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        b['title'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        b['subtitle'] as String,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  b['icon'] as IconData,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 48,
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Banner Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: _currentBannerIndex == index ? 16 : 6,
                          decoration: BoxDecoration(
                            color: _currentBannerIndex == index ? AppColors.primary : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LokasiPage())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.location_on, color: AppColors.primary, size: 28),
                                  const SizedBox(height: 8),
                                  const Text('Lokasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PricelistPage())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.price_change, color: AppColors.primary, size: 28),
                                  const SizedBox(height: 8),
                                  const Text('Pricelist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Recent Transactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Transform.translate(
                offset: const Offset(0, -16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transaksi Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                    const SizedBox(height: 16),
                    if (_loading)
                      Column(
                        children: List.generate(3, (index) => AppShimmer(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            height: 76,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )),
                      )
                    else if (_recent.isEmpty)
                      const AppEmptyState(
                        icon: Icons.receipt_long,
                        title: 'Belum ada transaksi',
                        subtitle: 'Yuk buat pesanan pertamamu!',
                      )
                    else
                      ..._recent.map((trx) {
                        final tanggal = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(trx['tanggal']));
                        return AppTransactionCard(
                          title: trx['jenis'] ?? '-',
                          subtitle: '${trx['berat']} Kg • $tanggal',
                          status: trx['status'] ?? '-',
                        );
                      }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
