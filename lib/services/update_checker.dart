import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class UpdateChecker {
  static const _currentVersion = '1.2.2';
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

  static void _showDialog(BuildContext ctx, String newVersion, String changelog, String apkUrl, bool forceUpdate) {
    showDialog(
      context: ctx,
      barrierDismissible: !forceUpdate,
      builder: (c) => _UpdateDialog(newVersion: newVersion, changelog: changelog, apkUrl: apkUrl, forceUpdate: forceUpdate),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String newVersion, changelog, apkUrl;
  final bool forceUpdate;
  const _UpdateDialog({required this.newVersion, required this.changelog, required this.apkUrl, required this.forceUpdate});
  @override State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  int _received = 0;
  int _total = 0;
  String? _error;
  CancelToken? _cancelToken;

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _download() async {
    setState(() { _downloading = true; _progress = 0; _error = null; });
    try {
      if (await Permission.requestInstallPackages.isDenied) {
        await Permission.requestInstallPackages.request();
      }
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final path = dir.path + '/demontv_update.apk';
      _cancelToken = CancelToken();
      await Dio().download(
        widget.apkUrl, path,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (mounted) setState(() {
            _received = received;
            _total = total;
            _progress = total > 0 ? received / total : 0;
          });
        },
      );
      if (!mounted) return;
      final fileUri = 'content://com.demontv.demon_tv_plus.fileprovider/external_files/demontv_update.apk';
      final intent = AndroidIntent(
        action: 'action_view',
        data: fileUri,
        type: 'application/vnd.android.package-archive',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_GRANT_READ_URI_PERMISSION],
      );
      await intent.launch();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _downloading = false; _error = e.toString().contains('cancel') ? null : 'Error al descargar'; });
    }
  }

  void _cancel() {
    _cancelToken?.cancel();
    setState(() { _downloading = false; _progress = 0; });
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
    onWillPop: () async => !widget.forceUpdate && !_downloading,
    child: AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Text(
          _downloading ? 'DESCARGANDO...' : 'NUEVA ACTUALIZACION',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(children: [
            const Text('Actual', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
            const Text(UpdateChecker._currentVersion, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Icon(Icons.arrow_forward, color: Colors.white)),
          Column(children: [
            const Text('Nueva', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
            Text(widget.newVersion, style: const TextStyle(color: Color(0xFF00CFDD), fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
        ]),
        if (widget.changelog.isNotEmpty && !_downloading) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF2A2A2E), borderRadius: BorderRadius.circular(10)),
            child: Text(widget.changelog, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11), textAlign: TextAlign.center)),
        ],
        if (_downloading) ...[
          const SizedBox(height: 20),
          Text('${(_progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Color(0xFF00CFDD), fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFF2A2A2E),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00CFDD)),
              minHeight: 10)),
          const SizedBox(height: 6),
          Text(
            _total > 0 ? '${_formatBytes(_received)} / ${_formatBytes(_total)}' : 'Calculando...',
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        if (!_downloading) Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          if (!widget.forceUpdate) TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('MAS TARDE', style: TextStyle(color: Color(0xFF00CFDD), fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: _download,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CFDD), foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: const Text('ACTUALIZAR', style: TextStyle(fontWeight: FontWeight.bold))),
        ]) else TextButton(
          onPressed: _cancel,
          child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF9E9E9E)))),
      ]),
    ),
  );
}
