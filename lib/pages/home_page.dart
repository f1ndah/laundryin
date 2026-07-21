import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../widgets/app_about.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_input.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_list_view.dart';
import 'lokasi_page.dart';
import 'pricelist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          _TransaksiTab(),
          _ProfilTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transaksi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<Map<String, dynamic>> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final data = await DbService.getUserTransactions(user.id);
    if (mounted) {
      setState(() {
        _recent = data.take(3).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 35,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.local_laundry_service, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text('LaundryIN'),
          ],
        ),
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecent,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                AppMenuCard(
                  icon: Icons.location_on,
                  label: 'Lokasi Laundry',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LokasiPage()),
                  ),
                ),
                AppMenuCard(
                  icon: Icons.price_change,
                  label: 'Pricelist',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PricelistPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Transaksi Terbaru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_recent.isEmpty)
              const AppEmptyState(
                icon: Icons.receipt_long,
                title: 'Belum ada transaksi',
                subtitle: 'Buat transaksi pertamamu di tab Transaksi',
              )
            else
              ..._recent.map((trx) {
                final tanggal = DateFormat('dd MMM yyyy')
                    .format(DateTime.parse(trx['tanggal']));
                final statusColor = {
                  'Selesai': Colors.green,
                  'Proses': Colors.blue,
                  'Menunggu': Colors.orange,
                  'Batal': Colors.grey,
                }[trx['status']] ?? Colors.grey;
                return AppListTile(
                  leadingIcon: trx['jenis'] == 'Selimut' ? Icons.bed : Icons.checkroom,
                  title: trx['jenis'] ?? '-',
                  subtitle: '${trx['berat']} Kg • $tanggal',
                  trailing: Chip(
                    label: Text(trx['status'], style: const TextStyle(fontSize: 12)),
                    backgroundColor: statusColor.withValues(alpha: 0.2),
                    labelStyle: TextStyle(color: statusColor),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _TransaksiTab extends StatefulWidget {
  const _TransaksiTab();

  @override
  State<_TransaksiTab> createState() => _TransaksiTabState();
}

class _TransaksiTabState extends State<_TransaksiTab> {
  String _search = '';
  String _filter = 'Semua';
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _layanan = [];
  bool _loading = true;

  final _filters = ['Semua', 'Menunggu', 'Proses', 'Selesai', 'Batal'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final data = await DbService.getUserTransactions(user.id);
    final layanan = await DbService.getLayanan();
    if (mounted) {
      setState(() {
        _transactions = data;
        _layanan = layanan;
        _loading = false;
      });
    }
  }

  Future<void> _batalTransaksi(int id) async {
    await DbService.batalTransaction(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi dibatalkan. Dana dikembalikan ke saldo.'), backgroundColor: Colors.green),
      );
    }
    _loadData();
  }

  List<Map<String, dynamic>> get _filtered {
    var result = _transactions;
    if (_filter != 'Semua') {
      result = result.where((e) => e['status'] == _filter).toList();
    }
    if (_search.isNotEmpty) {
      result = result
          .where((e) => e['jenis']
              .toString()
              .toLowerCase()
              .contains(_search.toLowerCase()))
          .toList();
    }
    return result;
  }

  void _lihatQRIS(int harga, {Future<void> Function()? onSudahBayar}) {
    AppDialog.show(
      context: context,
      builder: (ctx) => AppDialog.themed(
        context: ctx,
        title: 'Bayar dengan DANA QRIS',
        content: [
          Text('Total: ${formatRupiah(harga)}', style: AppTextStyles.heading, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Image.asset(
            'assets/images/qrisbyr.png',
            width: 240,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.qr_code_2, size: 200, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text('a.n DANA 62-859****7733', style: AppTextStyles.caption, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'Scan QR di atas menggunakan aplikasi DANA',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
        actions: [
          if (onSudahBayar == null)
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))
          else
            AppButton(
              label: 'Sudah Bayar',
              onPressed: () async {
                Navigator.pop(ctx);
                await onSudahBayar();
              },
            ),
        ],
      ),
    );
  }

  void _lihatBukti(String url) => showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    ),
  );

  void _formTransaksi() {
    if (_layanan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada data layanan')),
      );
      return;
    }
    final alamatCtrl = TextEditingController();
    final beratCtrl = TextEditingController();
    String jenis = _layanan.first['jenis'] as String;
    // ponytail: cashless + saldo refund
    String metode = 'QRIS';
    int saldo = 0;
    var saldoLoaded = false;
    final userId = AuthService.currentUser?.id;

    AppDialog.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (userId != null && !saldoLoaded) {
            saldoLoaded = true;
            DbService.getSaldo(userId).then((s) {
              if (ctx.mounted) setDialogState(() => saldo = s);
            });
          }
          return AppDialog.themed(
          context: ctx,
          title: 'Tambah Transaksi',
          content: [
            AppInput(
              controller: alamatCtrl,
              label: 'Alamat Jemput/Antar',
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: jenis,
              items: _layanan
                  .map((e) => DropdownMenuItem<String>(
                        value: e['jenis'] as String,
                        child: Text('${e['jenis']} - ${formatRupiah(e['harga'])}/kg'),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setDialogState(() => jenis = val);
              },
              decoration: const InputDecoration(labelText: 'Jenis Cucian'),
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: beratCtrl,
              label: 'Berat (Kg)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: metode,
              items: [
                const DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                DropdownMenuItem(value: 'Saldo', child: Text('Saldo (${formatRupiah(saldo)})')),
              ],
              onChanged: (val) {
                if (val != null) setDialogState(() => metode = val);
              },
              decoration: const InputDecoration(
                labelText: 'Metode Pembayaran',
                prefixIcon: Icon(Icons.payment),
              ),
            ),
          ],
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            AppButton(
              label: 'Bayar',
              onPressed: () async {
                final beratVal = double.tryParse(beratCtrl.text.replaceAll(',', '.')) ?? 0.0;
                if (beratVal <= 0 || alamatCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lengkapi semua data')),
                  );
                  return;
                }
                final layanan = _layanan.firstWhere((e) => e['jenis'] == jenis, orElse: () => {'harga': 0});
                final totalHarga = (beratVal * (layanan['harga'] as int)).toInt();
                final alamat = alamatCtrl.text.trim();
                final metodeBayar = metode;
                final jenisCucian = jenis;
                final user = AuthService.currentUser;
                if (user == null) return;

                Future<void> simpan() async {
                  final profile = await AuthService.getProfile();
                  final inserted = await DbService.insertTransaction({
                    'user_id': user.id,
                    'nama_pelanggan': profile?['nama'] ?? '-',
                    'alamat': alamat,
                    'berat': beratVal,
                    'jenis': jenisCucian,
                    'harga': totalHarga,
                    'metode': metodeBayar,
                    'status': 'Menunggu',
                    'tanggal': DateTime.now().toIso8601String(),
                  });
                  if (!mounted) return;
                  _loadData();
                  _showTicket(inserted['kode'] ?? inserted['id'], totalHarga);
                }

                if (metodeBayar == 'Saldo') {
                  final ok = await DbService.deductSaldo(user.id, totalHarga);
                  if (!ok) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Saldo tidak cukup (${formatRupiah(saldo)})'), backgroundColor: Colors.red),
                      );
                    }
                    return;
                  }
                  Navigator.pop(ctx);
                  await simpan();
                  return;
                }

                Navigator.pop(ctx);
                _lihatQRIS(totalHarga, onSudahBayar: simpan);
              },
            ),
          ],
        );
        },
      ),
    );
  }

  void _showTicket(dynamic kode, int harga) {
    AppDialog.show(
      context: context,
      builder: (ctx) => AppDialog.themed(
        context: ctx,
        title: null,
        content: [
          const Icon(Icons.check_circle, color: Colors.green, size: 56),
          const SizedBox(height: 12),
          const Text('Transaksi Berhasil!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text('ID Transaksi / Tiket Klaim', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('#$kode', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
          const SizedBox(height: 16),
          Text('Total: ${formatRupiah(harga)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        ],
        actions: [
          AppButton(label: 'OK', onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Saya'),
        backgroundColor: AppColors.primary,
      ),
      body: AppListView(
        loading: _loading,
        isEmpty: filtered.isEmpty,
        emptyIcon: Icons.receipt_long,
        emptyTitle: _search.isNotEmpty || _filter != 'Semua' ? 'Tidak ada hasil' : 'Belum ada transaksi',
        emptySubtitle: _search.isNotEmpty || _filter != 'Semua' ? 'Coba ubah filter atau kata kunci' : 'Tekan tombol + untuk buat transaksi baru',
        onRefresh: _loadData,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                  items: _filters.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _filter = v!),
                ),
              ),
            ],
          ),
        ),
        children: filtered.map((trx) {
          final tanggal = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(trx['tanggal']));
          return AppTransactionCard(
            title: trx['jenis'] ?? '-',
            subtitle: '${trx['berat']} Kg • ${formatRupiah(trx['harga'])} • $tanggal',
            status: trx['status'],
            onTap: () => AppBottomSheet.show(
              context: context,
              title: trx['jenis'] ?? '-',
              subtitle: formatRupiah(trx['harga']),
              actions: [
                SheetAction(icon: Icons.local_laundry_service, label: '${trx['berat']}Kg'),
                SheetAction(icon: Icons.location_on_outlined, label: trx['alamat'] ?? '-'),
                SheetAction(icon: Icons.payment, label: trx['metode'] ?? 'QRIS'),
                SheetAction(icon: Icons.access_time, label: tanggal),
                SheetAction(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Lihat ID / Tiket Klaim',
                  onTap: () => _showTicket(trx['kode'] ?? trx['id'], trx['harga'] as int),
                ),
                if (trx['bukti_url'] != null)
                  SheetAction(icon: Icons.receipt_long, label: 'Lihat Bukti Bayar', onTap: () => _lihatBukti(trx['bukti_url'])),
                if (trx['status'] == 'Menunggu')
                  SheetAction(
                    icon: Icons.cancel,
                    label: 'Batalkan Transaksi',
                    color: AppColors.danger,
                    onTap: () => _batalTransaksi(trx['id']),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formTransaksi(),
        icon: const Icon(Icons.add),
        label: const Text('Transaksi Baru'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ProfilTab extends StatefulWidget {
  const _ProfilTab();

  @override
  State<_ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<_ProfilTab> {
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

  Widget _statCard(String value, String label, Color bg, Color fg) {
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Text(value, style: AppTextStyles.heading.copyWith(color: fg)),
          Text(label, style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.8))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '-';
    final total = _transactions.length;
    final menunggu = _transactions.where((e) => e['status'] == 'Menunggu').length;
    final proses = _transactions.where((e) => e['status'] == 'Proses').length;
    final selesai = _transactions.where((e) => e['status'] == 'Selesai').length;

    return Scaffold(
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
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 60),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _profile?['nama'] ?? '-',
                          style: AppTextStyles.heading,
                        ),
                      ),
                      Center(
                        child: Text(email, style: AppTextStyles.caption),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.teal.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.teal.shade700, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Saldo', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
                                    Text(
                                      formatRupiah((_profile?['saldo'] as num?)?.toInt() ?? 0),
                                      style: AppTextStyles.heading.copyWith(color: Colors.teal.shade800),
                                    ),
                                    Text(
                                      'Dari refund batal. Tidak bisa ditarik tunai.',
                                      style: AppTextStyles.caption.copyWith(color: Colors.teal.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Statistik',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _statCard('$total', 'Total', Colors.blue.shade50, Colors.blue.shade700)),
                          const SizedBox(width: 8),
                          Expanded(child: _statCard('$menunggu', 'Menunggu', Colors.orange.shade50, Colors.orange.shade700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _statCard('$proses', 'Proses', Colors.indigo.shade50, Colors.indigo.shade700)),
                          const SizedBox(width: 8),
                          Expanded(child: _statCard('$selesai', 'Selesai', Colors.green.shade50, Colors.green.shade700)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AppListTile(
                        leadingIcon: Icons.logout,
                        title: 'Logout',
                        onTap: () => AuthService.logout(),
                      ),
                    ],
                  ),
                ),
    );
  }
}
