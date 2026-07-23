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
import '../../widgets/app_snackbar.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  List<Map<String, dynamic>> _recent = [];
  List<Map<String, dynamic>> _banners = [];
  String _userName = 'Pelanggan';
  int _saldo = 0;
  bool _loading = true;

  final PageController _bannerController =
      PageController(viewportFraction: 0.9);
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
    final banners = await DbService.getBanners();

    if (mounted) {
      setState(() {
        _recent = data.take(3).toList();
        _userName = profile?['nama'] ?? 'Pelanggan';
        _saldo = saldo;
        _banners = banners;
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
              padding: const EdgeInsets.only(
                  top: 64, left: 24, right: 24, bottom: 48),
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
                      const Text('Selamat datang,',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(_userName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white),
                    onPressed: () {
                      AppSnackbar.info(
                          context, 'Fitur notifikasi dalam pengembangan 🛠️');
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
                        // Removed shadow
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Saldo Kamu',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(formatRupiah(_saldo),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_banners.isNotEmpty) const SizedBox(height: 24),

                    // Banner Carousel
                    if (_banners.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 2 / 1,
                        child: PageView.builder(
                          padEnds: false,
                          controller: _bannerController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentBannerIndex = index;
                            });
                          },
                          itemCount: _banners.length,
                          itemBuilder: (context, index) {
                            final b = _banners[index];
                            final imageUrl = b['image_url'] as String?;

                            return GestureDetector(
                              onTap: () {
                                if (imageUrl != null && imageUrl.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.all(16),
                                      child: Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          InteractiveViewer(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Image.network(imageUrl,
                                                  fit: BoxFit.contain),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.white, size: 30),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Center(
                                                child: Icon(Icons.broken_image,
                                                    color: Colors.white,
                                                    size: 32));
                                          },
                                        )
                                      : const Center(
                                          child: Icon(Icons.image,
                                              color: Colors.white, size: 32)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (_banners.isNotEmpty) const SizedBox(height: 12),

                    // Banner Indicator
                    if (_banners.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_banners.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: _currentBannerIndex == index ? 16 : 6,
                            decoration: BoxDecoration(
                              color: _currentBannerIndex == index
                                  ? AppColors.primary
                                  : Colors.grey.withValues(alpha: 0.3),
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
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LokasiPage())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: AppColors.primary, size: 28),
                                  const SizedBox(height: 8),
                                  const Text('Lokasi',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PricelistPage())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.price_change,
                                      color: AppColors.primary, size: 28),
                                  const SizedBox(height: 8),
                                  const Text('Pricelist',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
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
                    const Text('Transaksi Terbaru',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text)),
                    const SizedBox(height: 16),
                    if (_loading)
                      Column(
                        children: List.generate(
                            3,
                            (index) => AppShimmer(
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
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
                        final tanggal = DateFormat('dd MMM yyyy, HH:mm')
                            .format(DateTime.parse(trx['tanggal']));
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
