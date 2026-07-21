import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../widgets/app_about.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_list_view.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_input.dart';
import 'home_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _TransaksiTab(),
          _LayananTab(),
          _TokoTab(),
          _PelangganTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transaksi'),
          BottomNavigationBarItem(icon: Icon(Icons.local_laundry_service), label: 'Layanan'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Toko'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pelanggan'),
        ],
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
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DbService.getTransactions();
    if (mounted) setState(() { _transactions = data; _loading = false; });
  }

  void _ubahStatus(int id, String currentStatus) async {
    if (currentStatus == 'Batal' || currentStatus == 'Selesai') return;
    await DbService.toggleStatus(id, currentStatus);
    _loadData();
  }

  IconData _statusIcon(String status) => const {
    'Menunggu': Icons.play_arrow,
    'Proses': Icons.check_circle,
  }[status] ?? Icons.help;

  String _statusNextLabel(String status) => {
    'Menunggu': 'Tandai Proses',
    'Proses': 'Tandai Selesai',
  }[status] ?? '';

  Color _statusColor(String status) => {
    'Menunggu': AppColors.accent,
    'Proses': AppColors.success,
  }[status] ?? AppColors.textLight;

  @override
  Widget build(BuildContext context) {
    final totalPendapatan = _transactions
        .where((e) => e['status'] == 'Selesai')
        .fold<int>(0, (sum, item) => sum + (item['harga'] as int));
    final menunggu = _transactions.where((e) => e['status'] == 'Menunggu').length;
    final proses = _transactions.where((e) => e['status'] == 'Proses').length;
    final selesai = _transactions.where((e) => e['status'] == 'Selesai').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        backgroundColor: AppColors.primary,
        actions: [
          AppAbout.action(context),
          IconButton(icon: const Icon(Icons.visibility), tooltip: 'Lihat sebagai Pelanggan', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => AuthService.logout()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(padding: const EdgeInsets.all(12), children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF45B7A0)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Total Pendapatan', style: TextStyle(color: Colors.white, fontSize: 14)),
                        Text('Transaksi Selesai', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ]),
                      Text(formatRupiah(totalPendapatan), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Card(color: Colors.orange.shade50, child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
                    Text('$menunggu', style: AppTextStyles.heading.copyWith(color: Colors.orange.shade700)),
                    const Text('Menunggu', style: TextStyle(fontSize: 10)),
                  ])))),
                  const SizedBox(width: 8),
                  Expanded(child: Card(color: Colors.blue.shade50, child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
                    Text('$proses', style: AppTextStyles.heading.copyWith(color: Colors.blue.shade700)),
                    const Text('Proses', style: TextStyle(fontSize: 10)),
                  ])))),
                  const SizedBox(width: 8),
                  Expanded(child: Card(color: Colors.green.shade50, child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
                    Text('$selesai', style: AppTextStyles.heading.copyWith(color: Colors.green.shade700)),
                    const Text('Selesai', style: TextStyle(fontSize: 10)),
                  ])))),
                ]),
                const SizedBox(height: 16),
                if (_transactions.isEmpty)
                  const AppEmptyState(icon: Icons.inventory_2_outlined, title: 'Belum ada transaksi')
                else
                  ..._transactions.map((trx) {
                    final tanggal = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(trx['tanggal']));
                    return AppTransactionCard(
                      title: trx['nama_pelanggan'] ?? '-',
                      subtitle: '${trx['jenis']} ${trx['berat']}Kg • ${trx['metode'] ?? 'QRIS'} • ${formatRupiah(trx['harga'])}\n$tanggal',
                      status: trx['status'],
                      color: AppColors.surface,
                      onTap: () => AppBottomSheet.show(
                        context: context,
                        title: trx['nama_pelanggan'] ?? '-',
                        subtitle: formatRupiah(trx['harga']),
                        actions: [
                          SheetAction(
                            icon: Icons.info_outline,
                            label: '${trx['jenis']} • ${trx['berat']}Kg • ${trx['metode'] ?? 'QRIS'}',
                          ),
                          SheetAction(
                            icon: Icons.location_on_outlined,
                            label: trx['alamat'] ?? '-',
                          ),
                          SheetAction(
                            icon: Icons.access_time,
                            label: tanggal,
                          ),
                          if (trx['status'] == 'Batal' || trx['status'] == 'Selesai')
                            SheetAction(
                              icon: Icons.block,
                              label: trx['status'] == 'Batal'
                                  ? 'Dibatalkan — status terkunci'
                                  : 'Selesai — status terkunci',
                              color: Colors.grey,
                            )
                          else
                            SheetAction(
                              icon: _statusIcon(trx['status']),
                              label: _statusNextLabel(trx['status']),
                              color: _statusColor(trx['status']),
                              onTap: () => _ubahStatus(trx['id'], trx['status']),
                            ),
                        ],
                      ),
                    );
                  }),
              ]),
            ),
    );
  }
}

class _LayananTab extends StatefulWidget {
  const _LayananTab();

  @override
  State<_LayananTab> createState() => _LayananTabState();
}

class _LayananTabState extends State<_LayananTab> {
  List<Map<String, dynamic>> _layanan = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final data = await DbService.getLayanan();
    if (mounted) setState(() { _layanan = data; _loading = false; });
  }

  void _tambahLayanan() {
    final jenisCtrl = TextEditingController();
    final hargaCtrl = TextEditingController();
    AppDialog.show(
      context: context,
      builder: (ctx) => AppDialog.themed(
        context: ctx,
        title: 'Tambah Layanan',
        content: [
          AppInput(controller: jenisCtrl, label: 'Jenis Cucian'),
          const SizedBox(height: 12),
          AppInput(controller: hargaCtrl, label: 'Harga /kg', keyboardType: TextInputType.number),
        ],
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          AppButton(
            label: 'Simpan',
            onPressed: () async {
              final jenis = jenisCtrl.text.trim();
              final harga = int.tryParse(hargaCtrl.text);
              if (jenis.isNotEmpty && harga != null && harga > 0) {
                await DbService.insertLayanan(jenis, harga);
                Navigator.pop(ctx);
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  void _ubahLayanan(Map<String, dynamic> item) {
    final jenisCtrl = TextEditingController(text: item['jenis']?.toString() ?? '');
    final hargaCtrl = TextEditingController(text: item['harga']?.toString() ?? '');
    AppDialog.show(
      context: context,
      builder: (ctx) => AppDialog.themed(
        context: ctx,
        title: 'Ubah Layanan',
        content: [
          AppInput(controller: jenisCtrl, label: 'Jenis Cucian'),
          const SizedBox(height: 12),
          AppInput(controller: hargaCtrl, label: 'Harga /kg', keyboardType: TextInputType.number),
        ],
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          AppButton(
            label: 'Simpan',
            onPressed: () async {
              final jenis = jenisCtrl.text.trim();
              final harga = int.tryParse(hargaCtrl.text);
              if (jenis.isNotEmpty && harga != null && harga > 0) {
                await DbService.updateLayanan((item['id'] as num).toInt(), jenis: jenis, harga: harga);
                Navigator.pop(ctx);
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _hapusLayanan(Map<String, dynamic> item) async {
    final ok = await AppDialog.confirm(
      context: context,
      title: 'Hapus Layanan',
      message: 'Hapus "${item['jenis']}"?',
      confirmLabel: 'Hapus',
      confirmColor: AppColors.danger,
    );
    if (ok == true) {
      await DbService.deleteLayanan((item['id'] as num).toInt());
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layanan & Harga'),
        backgroundColor: AppColors.primary,
        actions: [
          AppAbout.action(context),
          IconButton(icon: const Icon(Icons.visibility), tooltip: 'Lihat sebagai Pelanggan', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => AuthService.logout()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'layanan_fab',
        backgroundColor: AppColors.primary,
        elevation: 2,
        onPressed: _tambahLayanan,
        child: const Icon(Icons.add),
      ),
      body: AppListView(
        loading: _loading,
        isEmpty: _layanan.isEmpty,
        emptyIcon: Icons.local_laundry_service,
        emptyTitle: 'Belum ada layanan',
        emptySubtitle: 'Tekan tombol + untuk tambah layanan',
        onRefresh: _loadData,
        children: _layanan.map((item) => AppListTile(
          leadingIcon: Icons.local_laundry_service,
          title: item['jenis'],
          trailing: Text('${formatRupiah(item['harga'])}/kg', style: AppTextStyles.bodyBold),
          onTap: () => AppBottomSheet.show(
            context: context,
            title: item['jenis'],
            subtitle: '${formatRupiah(item['harga'])}/kg',
            actions: [
              SheetAction(icon: Icons.edit, label: 'Ubah', color: AppColors.primary, onTap: () => _ubahLayanan(item)),
              SheetAction(icon: Icons.delete, label: 'Hapus', color: AppColors.danger, onTap: () => _hapusLayanan(item)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _TokoTab extends StatefulWidget {
  const _TokoTab();

  @override
  State<_TokoTab> createState() => _TokoTabState();
}

class _TokoTabState extends State<_TokoTab> {
  Map<String, dynamic>? _toko;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final data = await DbService.getToko();
    if (mounted) setState(() { _toko = data; _loading = false; });
  }

  void _editToko() {
    final isNew = _toko == null;
    final namaCtrl = TextEditingController(text: _toko?['nama'] ?? '');
    final alamatCtrl = TextEditingController(text: _toko?['alamat'] ?? '');
    final jamBukaCtrl = TextEditingController(text: _toko?['jam_buka'] ?? '08:00');
    final jamTutupCtrl = TextEditingController(text: _toko?['jam_tutup'] ?? '20:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isNew ? 'Tambah Toko' : 'Edit Toko'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppInput(controller: namaCtrl, label: 'Nama Toko'),
            const SizedBox(height: 12),
            AppInput(controller: alamatCtrl, label: 'Alamat', maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: AppInput(controller: jamBukaCtrl, label: 'Jam Buka')),
              const SizedBox(width: 12),
              Expanded(child: AppInput(controller: jamTutupCtrl, label: 'Jam Tutup')),
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            await DbService.updateToko({
              'nama': namaCtrl.text.trim(),
              'alamat': alamatCtrl.text.trim(),
              'jam_buka': jamBukaCtrl.text.trim(),
              'jam_tutup': jamTutupCtrl.text.trim(),
            });
            Navigator.pop(ctx);
            _loadData();
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko'),
        backgroundColor: AppColors.primary,
        actions: [
          AppAbout.action(context),
          IconButton(icon: const Icon(Icons.visibility), tooltip: 'Lihat sebagai Pelanggan', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => AuthService.logout()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _toko == null
              ? RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(children: const [
                    AppEmptyState(icon: Icons.store, title: 'Belum ada data toko'),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        const Icon(Icons.store, size: 64, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(_toko!['nama'] ?? '-', style: AppTextStyles.heading),
                        const SizedBox(height: 8),
                        Text(_toko!['alamat'] ?? '-', style: AppTextStyles.body, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('${_toko!['jam_buka'] ?? '-'} - ${_toko!['jam_tutup'] ?? '-'}', style: AppTextStyles.caption),
                        const SizedBox(height: 16),
                        AppButton(label: 'Edit', icon: Icons.edit, onPressed: _editToko),
                      ]),
                    ),
                  ]),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'toko_fab',
        backgroundColor: AppColors.primary,
        elevation: 2,
        onPressed: _editToko,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PelangganTab extends StatefulWidget {
  const _PelangganTab();

  @override
  State<_PelangganTab> createState() => _PelangganTabState();
}

class _PelangganTabState extends State<_PelangganTab> {
  List<Map<String, dynamic>> _pelanggan = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final data = await DbService.getPelanggan();
    if (mounted) setState(() { _pelanggan = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan'),
        backgroundColor: AppColors.primary,
        actions: [
          AppAbout.action(context),
          IconButton(icon: const Icon(Icons.visibility), tooltip: 'Lihat sebagai Pelanggan', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => AuthService.logout()),
        ],
      ),
      body: AppListView(
        loading: _loading,
        isEmpty: _pelanggan.isEmpty,
        emptyIcon: Icons.people_outline,
        emptyTitle: 'Belum ada pelanggan',
        onRefresh: _loadData,
        children: _pelanggan.map((p) => InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => AppBottomSheet.show(
            context: context,
            title: p['nama'] ?? '-',
            subtitle: p['email'] ?? '-',
            actions: [
              SheetAction(icon: Icons.calendar_today, label: 'Terdaftar: ${DateFormat('dd MMM yyyy').format(DateTime.parse(p['created_at']))}'),
            ],
          ),
          child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            CircleAvatar(child: Text((p['nama'] ?? 'A')[0])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['nama'] ?? '-', style: AppTextStyles.bodyBold),
              Text(p['email'] ?? '-', style: AppTextStyles.caption),
            ])),
            Text(DateFormat('dd MMM yyyy').format(DateTime.parse(p['created_at'])), style: AppTextStyles.caption),
          ]),
        ))).toList(),
      ),
    );
  }
}
