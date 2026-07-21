import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final _supabase = Supabase.instance.client;
  static const String bucket = 'laundryin';

  static Future<String?> uploadBukti(String filePath, String userId) async {
    final file = File(filePath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.png';
    await _supabase.storage.from(bucket).upload(fileName, file);
    return _supabase.storage.from(bucket).getPublicUrl(fileName);
  }

  static String getPublicUrl(String path) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }
}
