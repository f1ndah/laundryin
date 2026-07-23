import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/db_service.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_list_tile.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_list_view.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/app_fab.dart';
import '../../widgets/app_snackbar.dart';
import '../nota_page.dart';

class TransaksiTab extends StatefulWidget {
  const TransaksiTab({super.key});

  @override
  State<TransaksiTab> createState() => TransaksiTabState();
}

class TransaksiTabState extends State<TransaksiTab> {
  String _search = '';
  String _filter = 'Semua';
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _layanan = [];
  List<Map<String, dynamic>> _tokoList = [];
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
    final toko = await DbService.getTokoList();
    if (mounted) {
      setState(() {
        _transactions = data;
        _layanan = layanan;
        _tokoList = toko;
        _loading = false;
      });
    }
  }

  Future<void> _batalTransaksi(int id) async {
    final trx = _transactions.firstWhere((t) => t['id'] == id);
    await DbService.batalTransaction(id);
    if (mounted) {
      AppSnackbar.success(
          context, 'Transaksi dibatalkan. Dana dikembalikan ke saldo.');
    }
    _loadData();
    await Supabase.instance.client.functions.invoke(
      'wa',
      body: {
        'type': 'UPDATE',
        'table': 'transactions',
        'record': {...trx, 'status': 'Batal'}
      },
    ).catchError((e) => debugPrint('WA Error: $e'));
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
          Text('Total: ${formatRupiah(harga)}',
              style: AppTextStyles.heading, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Image.asset(
            'assets/images/qrisbyr.png',
            width: 240,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.qr_code_2, size: 200, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text('a.n DANA 62-859****7733',
              style: AppTextStyles.caption, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'Scan QR di atas menggunakan aplikasi DANA',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
        actions: [
          if (onSudahBayar == null)
            AppButton(
                label: 'Tutup',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.pop(ctx))
          else
            AppButton(
              label: 'Sudah Bayar',
              variant: AppButtonVariant.primary,
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
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Tutup'),
              ),
            ],
          ),
        ),
      );

  void _formTransaksi() {
    if (_layanan.isEmpty) {
      AppSnackbar.error(context, 'Belum ada data layanan');
      return;
    }
    if (_tokoList.isEmpty) {
      AppSnackbar.error(context, 'Belum ada data toko/cabang');
      return;
    }
    final alamatCtrl = TextEditingController();
    final beratCtrl = TextEditingController();
    String jenis = _layanan.first['jenis'] as String;
    int tokoId = _tokoList.first['id'] as int;
    // ponytail: cashless + saldo refund
    String metode = 'QRIS';
    int saldo = 0;
    var saldoLoaded = false;
    final userId = AuthService.currentUser?.id;

    final voucherCtrl = TextEditingController();
    int potonganVoucher = 0;
    int? voucherId;
    String voucherMessage = '';

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
              DropdownButtonFormField<int>(
                initialValue: tokoId,
                items: _tokoList
                    .map((e) => DropdownMenuItem<int>(
                          value: e['id'] as int,
                          child: Text(e['nama'] as String),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => tokoId = val);
                },
                decoration: const InputDecoration(
                  labelText: 'Pilih Cabang Toko',
                  prefixIcon: Icon(Icons.storefront),
                ),
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: alamatCtrl,
                label: 'Alamat Jemput/Antar',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: jenis,
                items: _layanan
                    .map((e) => DropdownMenuItem<String>(
                          value: e['jenis'] as String,
                          child: Text(
                              '${e['jenis']} - ${formatRupiah(e['harga'])}/kg'),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: metode,
                items: [
                  const DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                  DropdownMenuItem(
                      value: 'Saldo',
                      child: Text('Saldo (${formatRupiah(saldo)})')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => metode = val);
                },
                decoration: const InputDecoration(
                  labelText: 'Metode Pembayaran',
                  prefixIcon: Icon(Icons.payment),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppInput(
                      controller: voucherCtrl,
                      label: 'Kode Voucher (Opsional)',
                      prefixIcon: Icons.local_activity_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Klaim',
                    onPressed: () async {
                      final k = voucherCtrl.text.trim();
                      if (k.isEmpty) return;
                      final v = await DbService.checkVoucher(k);
                      if (v != null) {
                        setDialogState(() {
                          potonganVoucher = (v['potongan'] as num).toInt();
                          voucherId = (v['id'] as num).toInt();
                          voucherMessage =
                              'Diskon ${formatRupiah(potonganVoucher)} diterapkan!';
                        });
                      } else {
                        setDialogState(() {
                          potonganVoucher = 0;
                          voucherId = null;
                          voucherMessage = 'Voucher tidak valid / kuota habis';
                        });
                      }
                    },
                  ),
                ],
              ),
              if (voucherMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    voucherMessage,
                    style: TextStyle(
                      color: voucherId != null
                          ? AppColors.success
                          : AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
            actions: [
              AppButton(
                  label: 'Batal',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Navigator.pop(ctx)),
              AppButton(
                label: 'Bayar',
                variant: AppButtonVariant.primary,
                onPressed: () async {
                  final beratVal =
                      double.tryParse(beratCtrl.text.replaceAll(',', '.')) ??
                          0.0;
                  if (beratVal <= 0 || alamatCtrl.text.trim().isEmpty) {
                    AppSnackbar.error(context, 'Lengkapi semua data');
                    return;
                  }
                  final layanan = _layanan.firstWhere(
                      (e) => e['jenis'] == jenis,
                      orElse: () => {'harga': 0});
                  int totalHarga =
                      (beratVal * (layanan['harga'] as int)).toInt() -
                          potonganVoucher;
                  if (totalHarga < 0) totalHarga = 0;
                  final alamat = alamatCtrl.text.trim();
                  final metodeBayar = metode;
                  final jenisCucian = jenis;
                  final selectedTokoId = tokoId;
                  final user = AuthService.currentUser;
                  if (user == null) return;

                  Future<void> simpan() async {
                    try {
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
                        'toko_id': selectedTokoId,
                        'tanggal': DateTime.now().toIso8601String(),
                      });
                      if (voucherId != null) {
                        await DbService.useVoucher(voucherId!);
                      }
                      if (!mounted) return;
                      _loadData();
                      _showTicket(
                          inserted['kode'] ?? inserted['id'], totalHarga);
                      // ponytail: fire-and-forget WA notif
                      await Supabase.instance.client.functions.invoke(
                        'wa',
                        body: {
                          'type': 'INSERT',
                          'table': 'transactions',
                          'record': inserted
                        },
                      ).catchError((e) => debugPrint('WA Error: $e'));
                    } catch (e) {
                      if (mounted) {
                        AppSnackbar.error(context, 'Gagal: $e');
                      }
                    }
                  }

                  if (metodeBayar == 'Saldo') {
                    final ok = await DbService.deductSaldo(user.id, totalHarga);
                    if (!ok) {
                      if (context.mounted) {
                        AppSnackbar.error(context,
                            'Saldo tidak cukup (${formatRupiah(saldo)})');
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
          const Text('Transaksi Berhasil!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text('ID Transaksi / Tiket Klaim',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('#$kode',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 16),
          Text('Total: ${formatRupiah(harga)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16)),
        ],
        actions: [
          AppButton(
              label: 'OK',
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.pop(ctx)),
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
        emptyTitle: _search.isNotEmpty || _filter != 'Semua'
            ? 'Tidak ada hasil'
            : 'Belum ada transaksi',
        emptySubtitle: _search.isNotEmpty || _filter != 'Semua'
            ? 'Coba ubah filter atau kata kunci'
            : 'Tekan tombol + untuk buat transaksi baru',
        onRefresh: _loadData,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Cari...',
                    hintStyle: AppTextStyles.caption,
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textLight),
                    filled: true,
                    fillColor: AppColors.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filter,
                  isExpanded: true,
                  icon:
                      const Icon(Icons.filter_list, color: AppColors.textLight),
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  items: _filters
                      .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _filter = v!),
                ),
              ),
            ],
          ),
        ),
        children: filtered.map((trx) {
          final tanggal = DateFormat('dd MMM yyyy, HH:mm')
              .format(DateTime.parse(trx['tanggal']));
          final toko = _tokoList.firstWhere((t) => t['id'] == trx['toko_id'],
              orElse: () => {'nama': '-', 'nomor_admin': ''});
          final tokoName = toko['nama'];
          final noWa = toko['nomor_admin']?.toString() ?? '';
          final subtitle =
              '${trx['berat']} Kg • ${formatRupiah(trx['harga'])} • $tokoName\n$tanggal';
          return AppTransactionCard(
            title: trx['jenis'] ?? '-',
            subtitle: subtitle,
            status: trx['status'],
            onTap: () => AppBottomSheet.show(
              context: context,
              title: '${trx['jenis']} • ${trx['berat']}Kg',
              subtitle: formatRupiah(trx['harga']),
              actions: [
                SheetAction(
                  icon: Icons.storefront,
                  label: tokoName ?? '-',
                  trailing: noWa.isNotEmpty
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.message,
                              color: Colors.green, size: 22),
                          onPressed: () => launchUrl(
                            Uri.parse('https://wa.me/$noWa'),
                            mode: LaunchMode.externalApplication,
                          ),
                        )
                      : null,
                ),
                SheetAction(
                  icon: Icons.receipt_long,
                  label: 'Lihat Nota',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            NotaPage(trx: trx, tokoName: tokoName ?? '-')),
                  ),
                ),
                SheetAction(icon: Icons.access_time, label: tanggal),
                if (trx['status'] != 'Selesai' && trx['status'] != 'Batal')
                  SheetAction(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Lihat ID / Tiket Klaim',
                    onTap: () => _showTicket(
                        trx['kode'] ?? trx['id'], trx['harga'] as int),
                  ),
                if (trx['bukti_url'] != null)
                  SheetAction(
                      icon: Icons.receipt_long,
                      label: 'Lihat Bukti Bayar',
                      onTap: () => _lihatBukti(trx['bukti_url'])),
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
      floatingActionButton: AppFab(
        onPressed: () => _formTransaksi(),
        icon: Icons.add,
        label: 'Transaksi',
      ),
    );
  }
}
