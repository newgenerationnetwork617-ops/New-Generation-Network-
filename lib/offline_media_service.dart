import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineMediaService {
  static const _key = 'ngn_offline_media';

  Future<Map<String,String>> saved() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key) ?? const <String>[];
    final result = <String,String>{};
    for (final value in values) {
      final cut = value.indexOf('|');
      if (cut > 0) result[value.substring(0,cut)] = value.substring(cut + 1);
    }
    return result;
  }

  Future<String> download({required String id, required String url, required String title}) async {
    final uri = Uri.parse(url);
    final dir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${dir.path}/ngn_downloads');
    await mediaDir.create(recursive: true);
    var extension = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last.split('.').last;
    if (extension.length > 5 || extension == uri.pathSegments.last) extension = 'media';
    final safe = title.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${mediaDir.path}/${id}_$safe.$extension');

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Download failed (${response.statusCode})');
      }
      final sink = file.openWrite();
      await response.pipe(sink);
    } finally {
      client.close();
    }

    final prefs = await SharedPreferences.getInstance();
    final current = await saved();
    current[id] = file.path;
    await prefs.setStringList(_key, current.entries.map((e) => '${e.key}|${e.value}').toList());
    return file.path;
  }

  Future<void> open(String path) => OpenFilex.open(path).then((_) {});

  Future<void> remove(String id) async {
    final current = await saved();
    final path = current.remove(id);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, current.entries.map((e) => '${e.key}|${e.value}').toList());
  }
}
