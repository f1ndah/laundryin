import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionStatus {
  final String local;
  final String? remote;
  final bool isLatest;
  final bool checked;

  const VersionStatus({
    required this.local,
    this.remote,
    required this.isLatest,
    required this.checked,
  });
}

class AppVersionService {
  // ponytail: repo hardcode, ganti kalau fork pindah
  static const repo = 'f1ndah/laundryin';

  static Future<String> localVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static Future<VersionStatus> check() async {
    final local = await localVersion();
    try {
      final remote = await _latestTag();
      if (remote == null) {
        return VersionStatus(local: local, isLatest: true, checked: false);
      }
      final normRemote = _norm(remote);
      final normLocal = _norm(local);
      final latest = _cmp(normLocal, normRemote) >= 0;
      return VersionStatus(
        local: local,
        remote: normRemote,
        isLatest: latest,
        checked: true,
      );
    } catch (_) {
      return VersionStatus(local: local, isLatest: true, checked: false);
    }
  }

  static Future<String?> _latestTag() async {
    final releaseUri = Uri.parse('https://api.github.com/repos/$repo/releases/latest');
    final releaseRes = await http.get(releaseUri, headers: {'Accept': 'application/vnd.github+json'});
    if (releaseRes.statusCode == 200) {
      final body = jsonDecode(releaseRes.body) as Map<String, dynamic>;
      final tag = body['tag_name'] as String?;
      if (tag != null && tag.isNotEmpty) return tag;
    }

    final tagsUri = Uri.parse('https://api.github.com/repos/$repo/tags?per_page=1');
    final tagsRes = await http.get(tagsUri, headers: {'Accept': 'application/vnd.github+json'});
    if (tagsRes.statusCode != 200) return null;
    final list = jsonDecode(tagsRes.body) as List<dynamic>;
    if (list.isEmpty) return null;
    return (list.first as Map<String, dynamic>)['name'] as String?;
  }

  static String _norm(String v) =>
      v.trim().replaceFirst(RegExp(r'^[vV]'), '').split('+').first;

  static int _cmp(String a, String b) {
    List<int> parts(String s) =>
        s.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pa = parts(a);
    final pb = parts(b);
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}
