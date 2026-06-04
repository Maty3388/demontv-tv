import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class UpdateChecker {
  static const _currentVersion = '2.4.5';
  static String get currentVersion => _currentVersion;
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
      if (mounted) setState(() { _downloading = false; _error = e.toString().contains('cancel') ? null : 'Error: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}'; });
    }
  }

  void _cancel() {
    _cancelToken?.cancel();
    setState(() { _downloading = false; _progress = 0; });
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: FocusNode()..requestFocus(),
    autofocus: true,
    onKey: (event) {
      if (event is RawKeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
          if (!_downloading) _download();
        }
        if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) {
          if (!widget.forceUpdate && !_downloading) Navigator.pop(context);
        }
      }
    },
    child: WillPopScope(
    onWillPop: () async => !widget.forceUpdate && !_downloading,
    child: Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.4), width: 1.5),
          boxShadow: [BoxShadow(color: const Color(0xFFFF8C00).withOpacity(0.25), blurRadius: 40, spreadRadius: 2)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Icono
          Container(width: 68, height: 68,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFFB347)]),
              boxShadow: [BoxShadow(color: const Color(0xFFFF8C00).withOpacity(0.5), blurRadius: 20)]),
            child: Icon(_downloading ? Icons.downloading : Icons.system_update,
              color: Colors.white, size: 34)),
          const SizedBox(height: 16),
          Text(_downloading ? 'DESCARGANDO...' : 'NUEVA VERSIÓN',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
          const SizedBox(height: 20),
          // Versiones
          if (!_downloading) Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Column(children: [
                const Text('Actual', style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 4),
                Text(UpdateChecker._currentVersion,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFFF8C00).withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward, color: Color(0xFFFF8C00), size: 18))),
              Column(children: [
                const Text('Nueva', style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 4),
                Text(widget.newVersion,
                  style: const TextStyle(color: Color(0xFFFF8C00), fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ])),
          // Changelog
          if (widget.changelog.isNotEmpty && !_downloading) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
              child: Text(widget.changelog,
                style: const TextStyle(color: Colors.white60, fontSize: 12), textAlign: TextAlign.center)),
          ],
          // Progreso descarga
          if (_downloading) ...[
            const SizedBox(height: 20),
            Text('${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Color(0xFFFF8C00), fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8C00)),
                minHeight: 8)),
            const SizedBox(height: 8),
            Text(_total > 0 ? '${_formatBytes(_received)} / ${_formatBytes(_total)}' : 'Calculando...',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
          const SizedBox(height: 24),
          if (!_downloading) Row(children: [
            if (!widget.forceUpdate) Expanded(child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white24)),
                backgroundColor: Colors.white10),
              child: const Text('Más tarde', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
            if (!widget.forceUpdate) const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              autofocus: true,
              onPressed: _download,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                shadowColor: const Color(0xFFFF8C00)),
              child: const Text('ACTUALIZAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))),
          ]) else ElevatedButton(
            onPressed: _cancel,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.white10,
              foregroundColor: Colors.white60,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600))),
        ]),
      ))));
}
