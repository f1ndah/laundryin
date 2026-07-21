import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionStatus {
  final String local;
  final String? remote;
  final String? releaseUrl;
  final bool isLatest;
  final bool checked;

  const VersionStatus({
    required this.local,
    this.remote,
    this.releaseUrl,
    required this.isLatest,
    required this.checked,
  });
}

class AppVersionService {
  // ponytail: repo hardcode, ganti kalau fork pindah
  static const repo = 'f1ndah/laundryin';
  static const releasesUrl = 'https://github.com/$repo/releases';

  static Future<String> localVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static Future<VersionStatus> check() async {
    final local = await localVersion();
    try {
      final latest = await _latestRelease();
      if (latest == null) {
        return VersionStatus(local: local, isLatest: true, checked: false);
      }
      final normRemote = _norm(latest.tag);
      final normLocal = _norm(local);
      final isLatest = _cmp(normLocal, normRemote) >= 0;
      return VersionStatus(
        local: local,
        remote: normRemote,
        releaseUrl: latest.url,
        isLatest: isLatest,
        checked: true,
      );
    } catch (_) {
      return VersionStatus(local: local, isLatest: true, checked: false);
    }
  }

  static Future<({String tag, String url})?> _latestRelease() async {
    final releaseUri = Uri.parse('https://api.github.com/repos/$repo/releases/latest');
    final releaseRes = await http.get(releaseUri, headers: {'Accept': 'application/vnd.github+json'});
    if (releaseRes.statusCode == 200) {
      final body = jsonDecode(releaseRes.body) as Map<String, dynamic>;
      final tag = body['tag_name'] as String?;
      if (tag != null && tag.isNotEmpty) {
        final url = (body['html_url'] as String?) ?? '$releasesUrl/tag/$tag';
        return (tag: tag, url: url);
      }
    }

    final tagsUri = Uri.parse('https://api.github.com/repos/$repo/tags?per_page=1');
    final tagsRes = await http.get(tagsUri, headers: {'Accept': 'application/vnd.github+json'});
    if (tagsRes.statusCode != 200) return null;
    final list = jsonDecode(tagsRes.body) as List<dynamic>;
    if (list.isEmpty) return null;
    final tag = (list.first as Map<String, dynamic>)['name'] as String?;
    if (tag == null || tag.isEmpty) return null;
    return (tag: tag, url: '$releasesUrl/tag/$tag');
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
