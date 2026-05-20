import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static const _currentVersion = '1.0.0';
  static const _apiUrl = 'http://149.104.92.205:25461/app/version';

  static Future<void> check(BuildContext context) async {
    try {
      final r = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 5));
      if (r.statusCode != 200) return;
      final data = jsonDecode(r.body);
      final rawVersion = data['version'] ?? '1.0.0';
      final newVersion = rawVersion.replaceAll(RegExp(r'[^0-9.]'), '').replaceAll(RegExp(r'^\.+|\.+$'), '');
      final apkUrl = data['apkUrl'] ?? '';
      final changelog = data['changelog'] ?? '';
      final forceUpdate = data['forceUpdate'] == true;

      if (apkUrl.isEmpty) return;
      if (_compareVersions(newVersion, _currentVersion) <= 0) return;

      if (context.mounted) {
        _showDialog(context, newVersion, changelog, apkUrl, forceUpdate);
      }
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

  static void _showDialog(BuildContext context, String newVersion, String changelog, String apkUrl, bool forceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => !forceUpdate,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            const Text('NUEVA ACTUALIZACION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
            const SizedBox(height: 4),
            const Text('Nueva version de la app!', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Column(children: [
                const Text('Version Actual', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                Text(_currentVersion, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.arrow_forward, color: Colors.white, size: 20)),
              Column(children: [
                const Text('Nueva Version', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                Text(newVersion, style: const TextStyle(color: Color(0xFF00CFDD), fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ]),
            if (changelog.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF2A2A2E), borderRadius: BorderRadius.circular(10)),
                child: Text(changelog, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12), textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('MAS TARDE', style: TextStyle(color: Color(0xFF00CFDD), fontWeight: FontWeight.bold))),
              ElevatedButton(
                onPressed: () => _openUrl(apkUrl, ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                child: const Text('ACTUALIZAR', style: TextStyle(fontWeight: FontWeight.bold))),
            ]),
            if (!forceUpdate) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: () {}, child: const Text('CAMBIOS', style: TextStyle(color: Color(0xFF00CFDD), fontSize: 12))),
            ],
          ]),
        ),
      ),
    );
  }

  static Future<void> _openUrl(String url, BuildContext ctx) async {
    try {
      Navigator.pop(ctx);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Abriendo descarga...'), backgroundColor: Color(0xFF00CFDD)));
      }
    } catch (_) {}
  }
}
