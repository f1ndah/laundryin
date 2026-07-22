import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';

class NotaPage extends StatefulWidget {
  final Map<String, dynamic> trx;
  final String tokoName;

  const NotaPage({super.key, required this.trx, required this.tokoName});

  @override
  State<NotaPage> createState() => _NotaPageState();
}

class _NotaPageState extends State<NotaPage> {
  final _key = GlobalKey();

  Future<void> _share() async {
    try {
      final boundary =
          _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = Directory.systemTemp;
      final file = File('${dir.path}/nota_${widget.trx['kode'] ?? widget.trx['id']}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)],
          text: 'Nota LaundryIN #${widget.trx['kode'] ?? widget.trx['id']}');
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Gagal membagikan nota');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tgl = DateFormat('dd MMMM yyyy, HH:mm')
        .format(DateTime.parse(widget.trx['tanggal']));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nota Transaksi'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Bagikan',
            onPressed: _share,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            RepaintBoundary(
              key: _key,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Image.asset('assets/images/logo.png',
                        height: 64,
                        errorBuilder: (_, __, ___) => Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_laundry_service,
                              size: 48, color: AppColors.primary),
                        )),
                    const SizedBox(height: 8),
                    const Text('LaundryIN',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('Nota Transaksi',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const Divider(height: 32),
                    _row('Kode', '#${widget.trx['kode'] ?? widget.trx['id']}'),
                    _row('Tanggal', tgl),
                    _row('Pelanggan', widget.trx['nama_pelanggan'] ?? '-'),
                    const Divider(height: 24),
                    _row('Layanan', widget.trx['jenis'] ?? '-'),
                    _row('Berat', '${widget.trx['berat']} Kg'),
                    _row('Cabang', widget.tokoName),
                    _row('Alamat', widget.trx['alamat'] ?? '-'),
                    const Divider(height: 24),
                    _row('Metode Bayar', widget.trx['metode'] ?? 'QRIS'),
                    _row('Total', formatRupiah(widget.trx['harga']),
                        bold: true),
                    const Divider(height: 24),
                    _row('Status', widget.trx['status'] ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Tutup',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
