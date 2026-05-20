import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class UpdateChecker {
  static const _currentVersion = '1.2.0';
  static const _apiUrl = 'http://149.104.92.205:25461/app/version';

  static Future<void> check(BuildContext context) async {
    try {
      final r = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 5));
      if (r.statusCode != 200) return;
      final data = jsonDecode(r.body);
      final rawVersion = (data['version'] ?? '1.0.0').replaceAll(RegExp(r'[^0-9.]'), '');
      final apkUrl = data['apkUrl'] ?? '';
      final changelog = data['changelog'] ?? '';
      final forceUpdate = data['forceUpdate'] == true;
      if (apkUrl.isEmpty) return;
      if (_compareVersions(rawVersion, _currentVersion) <= 0) return;
      if (context.mounted) _showDialog(context, rawVersion, changelog, apkUrl, forceUpdate);
    } catch (_) {}
  }

  static int _compareVersions(String a, String b) {
    final av = a.split('.').map(int.tryParse).toList();
    final bv = b.split('.').map(int.tryParse).toList();
    for (int i = 0; i < 3; i++) {
      final ai = (i < av.length ? av[i] : 0) ?? 0;
      final bi = (i < bv.length ? bv[i] : 0) ?? 0;
      if (ai != bi) return ai.compareTo(bi);
    }
    return 0;
  }

  static Future<void> _downloadAndInstall(String url, BuildContext ctx) async {
    try {
      // Pedir permiso de instalacion
      if (await Permission.requestInstallPackages.isDenied) {
        await Permission.requestInstallPackages.request();
      }
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final path = dir.path + '/demontv_update.apk';
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Descargando actualizacion...'), backgroundColor: Color(0xFF00CFDD), duration: Duration(seconds: 60)));
      await Dio().download(url, path);

    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: Colors.red));
    }
  }

  static void _showDialog(BuildContext ctx, String newVersion, String changelog, String apkUrl, bool forceUpdate) {
    showDialog(context: ctx, barrierDismissible: !forceUpdate, builder: (c) => WillPopScope(
      onWillPop: () async => !forceUpdate,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          const Text('NUEVA ACTUALIZACION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [const Text('Actual', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)), const Text(_currentVersion, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.arrow_forward, color: Colors.white)),
            Column(children: [const Text('Nueva', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)), Text(newVersion, style: const TextStyle(color: Color(0xFF00CFDD), fontSize: 22, fontWeight: FontWeight.bold))]),
          ]),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            if (!forceUpdate) TextButton(onPressed: () => Navigator.pop(c), child: const Text('MAS TARDE', style: TextStyle(color: Color(0xFF00CFDD), fontWeight: FontWeight.bold))),
            ElevatedButton(onPressed: () { Navigator.pop(c); _downloadAndInstall(apkUrl, ctx); },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00CFDD), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: const Text('ACTUALIZAR', style: TextStyle(fontWeight: FontWeight.bold))),
          ]),
        ]),
      ),
    ));
  }
}
