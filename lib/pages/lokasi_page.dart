import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/db_service.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_list_tile.dart';

class LokasiPage extends StatefulWidget {
  const LokasiPage({super.key});

  @override
  State<LokasiPage> createState() => _LokasiPageState();
}

class _LokasiPageState extends State<LokasiPage> {
  Map<String, dynamic>? _toko;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DbService.getToko();
    if (mounted) setState(() { _toko = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Terdekat'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _toko == null
              ? const AppEmptyState(icon: Icons.location_off, title: 'Data toko belum tersedia')
              : ListView(
                  children: [
                    AppListTile(
                      leadingIcon: Icons.local_laundry_service,
                      title: _toko!['nama'] ?? '-',
                      subtitle: '${_toko!['alamat']}\nBuka: ${_toko!['jam_buka'] ?? '-'} - ${_toko!['jam_tutup'] ?? '-'}',
                      trailing: const Icon(Icons.directions),
                    ),
                  ],
                ),
    );
  }
}
