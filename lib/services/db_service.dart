import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  static final _supabase = Supabase.instance.client;

  // ponytail: 5 char random claim code, PK tetap bigint
  static String genKodeTrx() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    return List.generate(5, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // ========== TRANSACTIONS ==========

  static Future<List<Map<String, dynamic>>> getTransactions({String? userId}) async {
    if (userId != null) {
      return await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    }
    return await _supabase
        .from('transactions')
        .select()
        .order('created_at', ascending: false);
  }

  static Future<List<Map<String, dynamic>>> getUserTransactions(String userId) async {
    return await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  static Future<Map<String, dynamic>> insertTransaction(Map<String, dynamic> data) async {
    data = {...data, 'kode': data['kode'] ?? genKodeTrx()};
    final rows = await _supabase.from('transactions').insert(data).select();
    return rows.first;
  }

  static Future<void> updateTransaction(int id, Map<String, dynamic> data) async {
    await _supabase.from('transactions').update(data).eq('id', id);
  }

  static Future<void> deleteTransaction(int id) async {
    await _supabase.from('transactions').delete().eq('id', id);
  }

  static Future<void> toggleStatus(int id, String currentStatus) async {
    if (currentStatus == 'Batal' || currentStatus == 'Selesai') return;
    const cycle = <String, String>{'Menunggu': 'Proses', 'Proses': 'Selesai'};
    final newStatus = cycle[currentStatus];
    if (newStatus == null) return;
    await _supabase.from('transactions').update({'status': newStatus}).eq('id', id);
  }

  static Future<void> batalTransaction(int id) async {
    final trx = await _supabase.from('transactions').select().eq('id', id).maybeSingle();
    if (trx == null || trx['status'] == 'Batal') return;
    await _supabase.from('transactions').update({'status': 'Batal'}).eq('id', id);
    // ponytail: refund ke saldo (tidak bisa tarik tunai)
    await _addSaldo(trx['user_id'] as String, (trx['harga'] as num).toInt());
  }

  // ========== SALDO ==========

  static Future<int> getSaldo(String userId) async {
    final p = await _supabase.from('profiles').select('saldo').eq('id', userId).maybeSingle();
    return (p?['saldo'] as num?)?.toInt() ?? 0;
  }

  static Future<void> _addSaldo(String userId, int amount) async {
    if (amount <= 0) return;
    final saldo = await getSaldo(userId);
    await _supabase.from('profiles').update({'saldo': saldo + amount}).eq('id', userId);
  }

  /// false = saldo kurang
  static Future<bool> deductSaldo(String userId, int amount) async {
    if (amount <= 0) return true;
    final saldo = await getSaldo(userId);
    if (saldo < amount) return false;
    await _supabase.from('profiles').update({'saldo': saldo - amount}).eq('id', userId);
    return true;
  }

  // ========== LAYANAN ==========

  static Future<List<Map<String, dynamic>>> getLayanan() async {
    return await _supabase.from('layanan').select().order('id');
  }

  static Future<void> updateLayanan(int id, {String? jenis, int? harga}) async {
    final data = <String, dynamic>{};
    if (jenis != null) data['jenis'] = jenis;
    if (harga != null) data['harga'] = harga;
    if (data.isEmpty) return;
    await _supabase.from('layanan').update(data).eq('id', id);
  }

  static Future<void> insertLayanan(String jenis, int harga) async {
    await _supabase.from('layanan').insert({'jenis': jenis, 'harga': harga});
  }

  static Future<void> deleteLayanan(int id) async {
    await _supabase.from('layanan').delete().eq('id', id);
  }

  // ========== TOKO ==========

  static Future<List<Map<String, dynamic>>> getTokoList() async {
    return await _supabase.from('toko').select().order('id');
  }

  static Future<Map<String, dynamic>> insertToko(Map<String, dynamic> data) async {
    final rows = await _supabase.from('toko').insert(data).select();
    return rows.first;
  }

  static Future<void> updateToko(int id, Map<String, dynamic> data) async {
    await _supabase.from('toko').update(data).eq('id', id);
  }

  static Future<void> deleteToko(int id) async {
    await _supabase.from('toko').delete().eq('id', id);
  }

  // ========== PELANGGAN ==========

  static Future<List<Map<String, dynamic>>> getPelanggan() async {
    return await _supabase
        .from('profiles')
        .select()
        .eq('role', 'pelanggan')
        .order('created_at', ascending: false);
  }

  // ========== BANNERS ==========

  static Future<List<Map<String, dynamic>>> getBanners() async {
    return await _supabase.from('banners').select().order('created_at', ascending: true);
  }

  static Future<Map<String, dynamic>> insertBanner(Map<String, dynamic> data) async {
    final rows = await _supabase.from('banners').insert(data).select();
    return rows.first;
  }

  static Future<void> updateBanner(int id, Map<String, dynamic> data) async {
    await _supabase.from('banners').update(data).eq('id', id);
  }

  static Future<void> deleteBanner(int id) async {
    await _supabase.from('banners').delete().eq('id', id);
  }

  static Future<String> uploadBannerImage(String fileName, dynamic fileBytes) async {
    await _supabase.storage.from('banners').uploadBinary(
      fileName,
      fileBytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );
    return _supabase.storage.from('banners').getPublicUrl(fileName);
  }

  // --- VOUCHERS ---
  static Future<List<Map<String, dynamic>>> getVouchers() async {
    final res = await _supabase.from('vouchers').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> insertVoucher(Map<String, dynamic> data) async {
    await _supabase.from('vouchers').insert(data);
  }

  static Future<void> updateVoucher(int id, Map<String, dynamic> data) async {
    await _supabase.from('vouchers').update(data).eq('id', id);
  }

  static Future<void> deleteVoucher(int id) async {
    await _supabase.from('vouchers').delete().eq('id', id);
  }

  static Future<Map<String, dynamic>?> checkVoucher(String kode) async {
    final res = await _supabase
        .from('vouchers')
        .select()
        .eq('kode', kode.toUpperCase())
        .eq('is_active', true)
        .gt('kuota', 0)
        .maybeSingle();
    return res;
  }

  static Future<void> useVoucher(int voucherId) async {
    // Kurangi kuota voucher (ini idealnya pakai RPC di server, tapi untuk prototype ini aman)
    final voucher = await _supabase.from('vouchers').select('kuota').eq('id', voucherId).single();
    final currentKuota = voucher['kuota'] as int;
    if (currentKuota > 0) {
      await _supabase.from('vouchers').update({'kuota': currentKuota - 1}).eq('id', voucherId);
    }
  }
}
