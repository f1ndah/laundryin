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
  List<Map<String, dynamic>> _tokoList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DbService.getTokoList();
    if (mounted) setState(() { _tokoList = data; _loading = false; });
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
          : _tokoList.isEmpty
              ? const AppEmptyState(icon: Icons.location_off, title: 'Data toko belum tersedia')
              : ListView(
                  children: _tokoList.map((toko) => AppListTile(
                    leadingIcon: Icons.local_laundry_service,
                    title: toko['nama'] ?? '-',
                    subtitle: '${toko['alamat']}\nBuka: ${toko['jam_buka'] ?? '-'} — ${toko['jam_tutup'] ?? '-'}',
                    trailing: const Icon(Icons.directions),
                  )).toList(),
                ),
    );
  }
}
