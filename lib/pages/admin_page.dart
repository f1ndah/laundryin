import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:uuid/uuid.dart';
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
import '../widgets/app_fab.dart';

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
          _PelangganTab(),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Transaksi'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pelanggan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
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
    if (mounted)
      setState(() {
        _transactions = data;
        _loading = false;
      });
  }

  void _ubahStatus(int id, String currentStatus) async {
    if (currentStatus == 'Batal' || currentStatus == 'Selesai') return;
    await DbService.toggleStatus(id, currentStatus);
    _loadData();
  }

  IconData _statusIcon(String status) =>
      const {
        'Menunggu': Icons.play_arrow,
        'Proses': Icons.check_circle,
      }[status] ??
      Icons.help;

  String _statusNextLabel(String status) =>
      {
        'Menunggu': 'Tandai Proses',
        'Proses': 'Tandai Selesai',
      }[status] ??
      '';

  Color _statusColor(String status) =>
      {
        'Menunggu': AppColors.accent,
        'Proses': AppColors.success,
      }[status] ??
      AppColors.textLight;

  @override
  Widget build(BuildContext context) {
    final totalPendapatan = _transactions
        .where((e) => e['status'] == 'Selesai')
        .fold<int>(0, (sum, item) => sum + (item['harga'] as int));
    final menunggu =
        _transactions.where((e) => e['status'] == 'Menunggu').length;
    final proses = _transactions.where((e) => e['status'] == 'Proses').length;
    final selesai = _transactions.where((e) => e['status'] == 'Selesai').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        backgroundColor: AppColors.primary,
        actions: [
          AppAbout.action(context),
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
                    gradient: const LinearGradient(
                        colors: [AppColors.success, Color(0xFF45B7A0)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Pendapatan',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                            Text('Transaksi Selesai',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          ]),
                      Text(formatRupiah(totalPendapatan),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: Container(
                          decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(12),
                          child: Column(children: [
                            Text('$menunggu',
                                style: AppTextStyles.heading
                                    .copyWith(color: Colors.orange.shade700)),
                            const SizedBox(height: 4),
                            const Text('Menunggu',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                          ]))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Container(
                          decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(12),
                          child: Column(children: [
                            Text('$proses',
                                style: AppTextStyles.heading
                                    .copyWith(color: Colors.blue.shade700)),
                            const SizedBox(height: 4),
                            const Text('Proses',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                          ]))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Container(
                          decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(12),
                          child: Column(children: [
                            Text('$selesai',
                                style: AppTextStyles.heading
                                    .copyWith(color: Colors.green.shade700)),
                            const SizedBox(height: 4),
                            const Text('Selesai',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                          ]))),
                ]),
                const SizedBox(height: 16),
                if (_transactions.isEmpty)
                  const AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Belum ada transaksi')
                else
                  ..._transactions.map((trx) {
                    final tanggal = DateFormat('dd MMM yyyy, HH:mm')
                        .format(DateTime.parse(trx['tanggal']));
                    return AppTransactionCard(
                      title: trx['nama_pelanggan'] ?? '-',
                      subtitle:
                          '${trx['jenis']} ${trx['berat']}Kg • ${trx['metode'] ?? 'QRIS'} • ${formatRupiah(trx['harga'])}\n$tanggal',
                      status: trx['status'],
                      color: AppColors.surface,
                      onTap: () => AppBottomSheet.show(
                        context: context,
                        title: trx['nama_pelanggan'] ?? '-',
                        subtitle: formatRupiah(trx['harga']),
                        actions: [
                          SheetAction(
                            icon: Icons.info_outline,
                            label:
                                '${trx['jenis']} • ${trx['berat']}Kg • ${trx['metode'] ?? 'QRIS'}',
                          ),
                          SheetAction(
                            icon: Icons.location_on_outlined,
                            label: trx['alamat'] ?? '-',
                          ),
                          SheetAction(
                            icon: Icons.access_time,
                            label: tanggal,
                          ),
                          if (trx['status'] == 'Batal' ||
                              trx['status'] == 'Selesai')
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
                              onTap: () =>
                                  _ubahStatus(trx['id'], trx['status']),
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

class _PelangganTab extends StatefulWidget {
  const _PelangganTab();

  @override
  State<_PelangganTab> createState() => _PelangganTabState();
}

class _PelangganTabState extends State<_PelangganTab> {
  List<Map<String, dynamic>> _pelanggan = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DbService.getPelanggan();
    if (mounted)
      setState(() {
        _pelanggan = data;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan'),
        backgroundColor: AppColors.primary,
        actions: [
          AppAbout.action(context),
        ],
      ),
      body: AppListView(
        loading: _loading,
        isEmpty: _pelanggan.isEmpty,
        emptyIcon: Icons.people_outline,
        emptyTitle: 'Belum ada pelanggan',
        onRefresh: _loadData,
        children: _pelanggan
            .map((p) => GestureDetector(
                onTap: () => AppBottomSheet.show(
                      context: context,
                      title: p['nama'] ?? '-',
                      subtitle: p['email'] ?? '-',
                      actions: [
                        SheetAction(
                            icon: Icons.calendar_today,
                            label:
                                'Terdaftar: ${DateFormat('dd MMM yyyy').format(DateTime.parse(p['created_at']))}'),
                      ],
                    ),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    CircleAvatar(child: Text((p['nama'] ?? 'A')[0])),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(p['nama'] ?? '-', style: AppTextStyles.bodyBold),
                          Text(p['email'] ?? '-', style: AppTextStyles.caption),
                        ])),
                    Text(
                        DateFormat('dd MMM yyyy')
                            .format(DateTime.parse(p['created_at'])),
                        style: AppTextStyles.caption),
                  ]),
                )))
            .toList(),
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await AuthService.getProfile();
    if (mounted)
      setState(() {
        _profile = profile;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '-';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Admin'),
        backgroundColor: AppColors.primary,
        actions: [
          AppAbout.action(context),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.admin_panel_settings, size: 60),
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
                  const SizedBox(height: 8),
                  Center(
                    child: Chip(
                      label: const Text('Admin'),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppListTile(
                    leadingIcon: Icons.local_laundry_service,
                    title: 'Layanan & Harga',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const _LayananPage())),
                  ),
                  AppListTile(
                    leadingIcon: Icons.store,
                    title: 'Toko',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const _TokoPage())),
                  ),
                  AppListTile(
                    leadingIcon: Icons.campaign,
                    title: 'Banners & Promosi',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const _BannerPage())),
                  ),
                  AppListTile(
                    leadingIcon: Icons.discount_outlined,
                    title: 'Voucher & Diskon',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const _VoucherPage())),
                  ),
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

class _LayananPage extends StatefulWidget {
  const _LayananPage();

  @override
  State<_LayananPage> createState() => _LayananPageState();
}

class _LayananPageState extends State<_LayananPage> {
  List<Map<String, dynamic>> _layanan = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DbService.getLayanan();
    if (mounted)
      setState(() {
        _layanan = data;
        _loading = false;
      });
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
          AppInput(
              controller: hargaCtrl,
              label: 'Harga /kg',
              keyboardType: TextInputType.number),
        ],
        actions: [
          AppButton(
              label: 'Batal',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(ctx)),
          AppButton(
            label: 'Simpan',
            variant: AppButtonVariant.primary,
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
    final jenisCtrl =
        TextEditingController(text: item['jenis']?.toString() ?? '');
    final hargaCtrl =
        TextEditingController(text: item['harga']?.toString() ?? '');
    AppDialog.show(
      context: context,
      builder: (ctx) => AppDialog.themed(
        context: ctx,
        title: 'Ubah Layanan',
        content: [
          AppInput(controller: jenisCtrl, label: 'Jenis Cucian'),
          const SizedBox(height: 12),
          AppInput(
              controller: hargaCtrl,
              label: 'Harga /kg',
              keyboardType: TextInputType.number),
        ],
        actions: [
          AppButton(
              label: 'Batal',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(ctx)),
          AppButton(
            label: 'Simpan',
            variant: AppButtonVariant.primary,
            onPressed: () async {
              final jenis = jenisCtrl.text.trim();
              final harga = int.tryParse(hargaCtrl.text);
              if (jenis.isNotEmpty && harga != null && harga > 0) {
                await DbService.updateLayanan((item['id'] as num).toInt(),
                    jenis: jenis, harga: harga);
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
      ),
      floatingActionButton: AppFab(
        label: 'Layanan',
        icon: Icons.add,
        onPressed: _tambahLayanan,
      ),
      body: AppListView(
        loading: _loading,
        isEmpty: _layanan.isEmpty,
        emptyIcon: Icons.local_laundry_service,
        emptyTitle: 'Belum ada layanan',
        emptySubtitle: 'Tekan tombol + untuk tambah layanan',
        onRefresh: _loadData,
        children: _layanan
            .map((item) => AppListTile(
                  leadingIcon: Icons.local_laundry_service,
                  title: item['jenis'],
                  trailing: Text('${formatRupiah(item['harga'])}/kg',
                      style: AppTextStyles.bodyBold),
                  onTap: () => AppBottomSheet.show(
                    context: context,
                    title: item['jenis'],
                    subtitle: '${formatRupiah(item['harga'])}/kg',
                    actions: [
                      SheetAction(
                          icon: Icons.edit,
                          label: 'Ubah',
                          color: AppColors.primary,
                          onTap: () => _ubahLayanan(item)),
                      SheetAction(
                          icon: Icons.delete,
                          label: 'Hapus',
                          color: AppColors.danger,
                          onTap: () => _hapusLayanan(item)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _TokoPage extends StatefulWidget {
  const _TokoPage();

  @override
  State<_TokoPage> createState() => _TokoPageState();
}

class _TokoPageState extends State<_TokoPage> {
  List<Map<String, dynamic>> _tokoList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DbService.getTokoList();
    if (mounted)
      setState(() {
        _tokoList = data;
        _loading = false;
      });
  }

  void _tambahToko() => _formToko();

  void _ubahToko(Map<String, dynamic> item) => _formToko(item: item);

  void _formToko({Map<String, dynamic>? item}) {
    final isNew = item == null;
    final namaCtrl = TextEditingController(text: item?['nama'] ?? '');
    final alamatCtrl = TextEditingController(text: item?['alamat'] ?? '');
    final jamBukaCtrl =
        TextEditingController(text: item?['jam_buka'] ?? '08:00');
    final jamTutupCtrl =
        TextEditingController(text: item?['jam_tutup'] ?? '20:00');
    final noWACtrl = TextEditingController(text: item?['nomor_admin'] ?? '');

    AppDialog.show(
      context: context,
      builder: (ctx) => AppDialog.themed(
        context: ctx,
        title: isNew ? 'Tambah Cabang Toko' : 'Edit Cabang Toko',
        content: [
          AppInput(controller: namaCtrl, label: 'Nama Cabang'),
          const SizedBox(height: 12),
          AppInput(controller: alamatCtrl, label: 'Alamat', maxLines: 2),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: AppInput(controller: jamBukaCtrl, label: 'Jam Buka')),
            const SizedBox(width: 12),
            Expanded(
                child: AppInput(controller: jamTutupCtrl, label: 'Jam Tutup')),
          ]),
          const SizedBox(height: 12),
          AppInput(
              controller: noWACtrl,
              label: 'No WA Admin (628xxx / 08xxx)',
              keyboardType: TextInputType.phone),
        ],
        actions: [
          AppButton(
              label: 'Batal',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(ctx)),
          AppButton(
            label: 'Simpan',
            variant: AppButtonVariant.primary,
            onPressed: () async {
              var waNumber = noWACtrl.text.trim();
              if (waNumber.startsWith('0')) {
                waNumber = '62${waNumber.substring(1)}';
              } else if (waNumber.startsWith('+62')) {
                waNumber = waNumber.substring(1);
              }

              final data = {
                'nama': namaCtrl.text.trim(),
                'alamat': alamatCtrl.text.trim(),
                'jam_buka': jamBukaCtrl.text.trim(),
                'jam_tutup': jamTutupCtrl.text.trim(),
                'nomor_admin': waNumber,
              };
              if (isNew) {
                await DbService.insertToko(data);
              } else {
                await DbService.updateToko((item['id'] as num).toInt(), data);
              }
              Navigator.pop(ctx);
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _hapusToko(Map<String, dynamic> item) async {
    final ok = await AppDialog.confirm(
      context: context,
      title: 'Hapus Cabang Toko',
      message: 'Hapus "${item['nama']}"?',
      confirmLabel: 'Hapus',
      confirmColor: AppColors.danger,
    );
    if (ok == true) {
      await DbService.deleteToko((item['id'] as num).toInt());
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cabang Toko'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: AppFab(
        label: 'Toko',
        icon: Icons.add,
        onPressed: _tambahToko,
      ),
      body: AppListView(
        loading: _loading,
        isEmpty: _tokoList.isEmpty,
        emptyIcon: Icons.store,
        emptyTitle: 'Belum ada cabang toko',
        emptySubtitle: 'Tekan tombol + untuk tambah cabang',
        onRefresh: _loadData,
        children: _tokoList
            .map((item) => AppListTile(
                  leadingIcon: Icons.store,
                  title: item['nama'],
                  subtitle: item['alamat'] +
                      (item['nomor_admin'] != null &&
                              item['nomor_admin'].toString().isNotEmpty
                          ? '\nWA: ${item['nomor_admin']}'
                          : ''),
                  trailing: Text('${item['jam_buka']} — ${item['jam_tutup']}',
                      style: AppTextStyles.caption),
                  onTap: () => AppBottomSheet.show(
                    context: context,
                    title: item['nama'],
                    subtitle: item['alamat'],
                    actions: [
                      SheetAction(
                          icon: Icons.edit,
                          label: 'Ubah',
                          color: AppColors.primary,
                          onTap: () => _ubahToko(item)),
                      SheetAction(
                          icon: Icons.delete,
                          label: 'Hapus',
                          color: AppColors.danger,
                          onTap: () => _hapusToko(item)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _BannerPage extends StatefulWidget {
  const _BannerPage();

  @override
  State<_BannerPage> createState() => _BannerPageState();
}

class _BannerPageState extends State<_BannerPage> {
  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DbService.getBanners();
    if (mounted)
      setState(() {
        _banners = data;
        _loading = false;
      });
  }

  Future<void> _uploadBanner() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Kompresi tahap 1 saat pilih gambar
    );

    if (image == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 1),
      compressQuality: 70, // Kompresi tahap 2 setelah dipotong
      compressFormat: ImageCompressFormat.jpg,
      maxWidth: 1200,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Banner',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Banner',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null) {
      if (mounted) {
        setState(() => _loading = true);
        try {
          final fileName = '${const Uuid().v4()}.jpg';
          final file = File(croppedFile.path);
          final imageUrl = await DbService.uploadBannerImage(
              fileName, file.readAsBytesSync());

          await DbService.insertBanner({
            'title': 'Banner', // Not used in UI but required by DB
            'subtitle': '',
            'color': 'primary',
            'icon_name': 'image',
            'image_url': imageUrl,
            'is_active': true,
          });
        } catch (e) {
          debugPrint('Upload error: $e');
        } finally {
          _loadData();
        }
      }
    }
  }

  Future<void> _hapusBanner(Map<String, dynamic> item) async {
    final ok = await AppDialog.confirm(
      context: context,
      title: 'Hapus Banner',
      message: 'Hapus banner ini?',
      confirmLabel: 'Hapus',
      confirmColor: AppColors.danger,
    );
    if (ok == true) {
      await DbService.deleteBanner((item['id'] as num).toInt());
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banners & Promosi'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: AppFab(
        label: 'Banner',
        icon: Icons.add_photo_alternate,
        onPressed: _uploadBanner,
      ),
      body: AppListView(
        loading: _loading,
        isEmpty: _banners.isEmpty,
        emptyIcon: Icons.campaign,
        emptyTitle: 'Belum ada banner',
        emptySubtitle: 'Tekan tombol + untuk upload gambar banner',
        onRefresh: _loadData,
        children: _banners.map((item) {
          final imageUrl = item['image_url'] as String?;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 2 / 1,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(color: AppColors.primary),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _hapusBanner(item),
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VoucherPage extends StatefulWidget {
  const _VoucherPage();

  @override
  State<_VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<_VoucherPage> {
  List<Map<String, dynamic>> _vouchers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DbService.getVouchers();
    if (mounted)
      setState(() {
        _vouchers = data;
        _loading = false;
      });
  }

  void _formVoucher({Map<String, dynamic>? item}) {
    final isNew = item == null;
    final kodeCtrl = TextEditingController(text: item?['kode'] ?? '');
    final potonganCtrl =
        TextEditingController(text: item?['potongan']?.toString() ?? '');
    final kuotaCtrl =
        TextEditingController(text: item?['kuota']?.toString() ?? '');
    bool isActive = item?['is_active'] ?? true;

    AppDialog.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AppDialog.themed(
          context: ctx,
          title: isNew ? 'Tambah Voucher' : 'Ubah Voucher',
          content: [
            AppInput(
                controller: kodeCtrl, label: 'Kode Voucher (Misal: HEMAT10K)'),
            const SizedBox(height: 12),
            AppInput(
                controller: potonganCtrl,
                label: 'Potongan Harga (Rp)',
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            AppInput(
                controller: kuotaCtrl,
                label: 'Kuota Penggunaan',
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Status Aktif'),
                const Spacer(),
                Switch(
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ],
          actions: [
            AppButton(
                label: 'Batal',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.pop(ctx)),
            AppButton(
              label: 'Simpan',
              variant: AppButtonVariant.primary,
              onPressed: () async {
                final kode = kodeCtrl.text.trim().toUpperCase();
                final potongan = int.tryParse(potonganCtrl.text) ?? 0;
                final kuota = int.tryParse(kuotaCtrl.text) ?? 0;

                if (kode.isEmpty || potongan <= 0 || kuota < 0) {
                  return; // validasi gagal
                }

                final data = {
                  'kode': kode,
                  'potongan': potongan,
                  'kuota': kuota,
                  'is_active': isActive,
                };

                if (isNew) {
                  await DbService.insertVoucher(data);
                } else {
                  await DbService.updateVoucher(
                      (item['id'] as num).toInt(), data);
                }
                if (mounted) Navigator.pop(ctx);
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hapusVoucher(Map<String, dynamic> item) async {
    final ok = await AppDialog.confirm(
      context: context,
      title: 'Hapus Voucher',
      message: 'Hapus voucher "${item['kode']}"?',
      confirmLabel: 'Hapus',
      confirmColor: AppColors.danger,
    );
    if (ok == true) {
      await DbService.deleteVoucher((item['id'] as num).toInt());
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher & Diskon'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: AppFab(
        label: 'Voucher',
        icon: Icons.add,
        onPressed: () => _formVoucher(),
      ),
      body: AppListView(
        loading: _loading,
        isEmpty: _vouchers.isEmpty,
        emptyIcon: Icons.discount_outlined,
        emptyTitle: 'Belum ada voucher',
        emptySubtitle: 'Tekan tombol + untuk membuat voucher promo',
        onRefresh: _loadData,
        children: _vouchers
            .map((item) => AppListTile(
                  leadingIcon: Icons.local_activity_outlined,
                  title: item['kode'],
                  subtitle:
                      'Kuota: ${item['kuota']} • ${item['is_active'] ? "Aktif" : "Non-aktif"}',
                  trailing: Text('-${formatRupiah(item['potongan'])}',
                      style: AppTextStyles.bodyBold
                          .copyWith(color: AppColors.success)),
                  onTap: () => AppBottomSheet.show(
                    context: context,
                    title: item['kode'],
                    subtitle: 'Potongan: ${formatRupiah(item['potongan'])}',
                    actions: [
                      SheetAction(
                          icon: Icons.edit,
                          label: 'Ubah',
                          color: AppColors.primary,
                          onTap: () => _formVoucher(item: item)),
                      SheetAction(
                          icon: Icons.delete,
                          label: 'Hapus',
                          color: AppColors.danger,
                          onTap: () => _hapusVoucher(item)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
