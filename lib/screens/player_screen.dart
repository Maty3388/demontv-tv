import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  const PlayerScreen({super.key, required this.channel});
  @override State<PlayerScreen> createState() => _State();
}

class _State extends State<PlayerScreen> {
  VideoPlayerController? _ctrl;
  bool _showControls = true;
  Timer? _hideTimer;
  bool _initialized = false;

  @override
  void initState() { super.initState(); _initPlayer(); }

  Future<void> _initPlayer() async {
    final parts = widget.channel.streamUrl.split("|");
    final url = parts[0].trim();
    final headers = Map<String, String>.from(widget.channel.headers);
    if (parts.length > 1) {
      for (final kv in parts[1].split("&")) {
        final i = kv.indexOf("=");
        if (i > 0) headers[kv.substring(0, i).trim()] = kv.substring(i + 1).trim();
      }
    }
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(url), httpHeaders: headers);
    await _ctrl!.initialize();
    await _ctrl!.play();
    setState(() => _initialized = true);
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () { if (mounted) setState(() => _showControls = false); });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _ctrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.goBack) { if (Navigator.canPop(context)) Navigator.pop(context); }
          if (event.logicalKey == LogicalKeyboardKey.select) {
            setState(() => _showControls = !_showControls);
            if (_showControls) _startHideTimer();
          }
        }
      },
      child: GestureDetector(
        onTap: () { setState(() => _showControls = !_showControls); if (_showControls) _startHideTimer(); },
        child: Stack(children: [
          _initialized && _ctrl != null
            ? Center(child: AspectRatio(aspectRatio: _ctrl!.value.aspectRatio, child: VideoPlayer(_ctrl!)))
            : const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
          if (_showControls) _buildControls(),
        ]),
      ),
    ),
  );

  Widget _buildControls() => Stack(children: [
    Positioned(top: 0, left: 0, right: 0, child: Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])),
      child: Row(children: [
        GestureDetector(onTap: () => Navigator.pop(context),
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24))),
        const SizedBox(width: 12),
        Expanded(child: Text(widget.channel.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.accentRed, borderRadius: BorderRadius.circular(6)),
          child: const Text("EN VIVO", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
      ])),
    ),
  ]);
}
