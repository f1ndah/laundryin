import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/db_service.dart';
import '../widgets/app_list_view.dart';
import '../widgets/app_list_tile.dart';

class PricelistPage extends StatefulWidget {
  const PricelistPage({super.key});

  @override
  State<PricelistPage> createState() => _PricelistPageState();
}

class _PricelistPageState extends State<PricelistPage> {
  List<Map<String, dynamic>> _layanan = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DbService.getLayanan();
    if (mounted) setState(() { _layanan = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricelist'),
        backgroundColor: AppColors.primary,
      ),
      body: AppListView(
        loading: _loading,
        isEmpty: _layanan.isEmpty,
        emptyIcon: Icons.local_laundry_service,
        emptyTitle: 'Belum ada layanan',
        onRefresh: _loadData,
        children: _layanan.map((e) => AppListTile(
          leadingIcon: Icons.local_laundry_service,
          title: e['jenis'],
          trailing: Text('${formatRupiah(e['harga'])}/kg', style: AppTextStyles.bodyBold),
        )).toList(),
      ),
    );
  }
}
