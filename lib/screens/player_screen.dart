import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel> playlist; // canales de la misma categoria
  final int initialIndex;
  const PlayerScreen({super.key, required this.channel, this.playlist = const [], this.initialIndex = 0});
  @override State<PlayerScreen> createState() => _PlayerState();
}

class _PlayerState extends State<PlayerScreen> {
  VideoPlayerController? _ctrl;
  bool _showControls = true;
  bool _showChannelInfo = false;
  Timer? _hideTimer;
  Timer? _infoTimer;
  bool _initialized = false;
  late List<Channel> _playlist;
  late int _idx;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist.isEmpty ? [widget.channel] : widget.playlist;
    _idx = widget.initialIndex;
    _initPlayer(_playlist[_idx]);
  }

  Future<void> _initPlayer(Channel ch) async {
    _ctrl?.dispose();
    setState(() => _initialized = false);
    final parts = ch.streamUrl.split("|");
    final url = parts[0].trim();
    final headers = Map<String, String>.from(ch.headers);
    if (parts.length > 1) {
      for (final kv in parts[1].split("&")) {
        final i = kv.indexOf("=");
        if (i > 0) headers[kv.substring(0, i).trim()] = kv.substring(i + 1).trim();
      }
    }
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(url), httpHeaders: headers);
    await _ctrl!.initialize();
    await _ctrl!.play();
    if (mounted) setState(() => _initialized = true);
    _startHideTimer();
  }

  void _nextChannel() {
    if (_idx < _playlist.length - 1) {
      setState(() => _idx++);
      _initPlayer(_playlist[_idx]);
      _showChannelInfoBriefly();
    }
  }

  void _prevChannel() {
    if (_idx > 0) {
      setState(() => _idx--);
      _initPlayer(_playlist[_idx]);
      _showChannelInfoBriefly();
    }
  }

  void _showChannelInfoBriefly() {
    setState(() => _showChannelInfo = true);
    _infoTimer?.cancel();
    _infoTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showChannelInfo = false);
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _infoTimer?.cancel();
    _ctrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: true,
    child: Scaffold(
    backgroundColor: Colors.black,
    body: RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKey: (event) {
        if (event is! RawKeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _nextChannel();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _prevChannel();
        } else if (event.logicalKey == LogicalKeyboardKey.select ||
                   event.logicalKey == LogicalKeyboardKey.enter) {
          setState(() => _showControls = !_showControls);
          if (_showControls) _startHideTimer();
        }
      },
      child: GestureDetector(
        onTap: () { setState(() => _showControls = !_showControls); if (_showControls) _startHideTimer(); },
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity != null) {
            if (d.primaryVelocity! < -300) _nextChannel();
            else if (d.primaryVelocity! > 300) _prevChannel();
          }
        },
        child: Stack(children: [
          _initialized && _ctrl != null
            ? SizedBox.expand(child: FittedBox(fit: BoxFit.fill, child: SizedBox(width: 1920, height: 1080, child: VideoPlayer(_ctrl!))))
            : const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
          if (_showControls) _buildControls(),
          if (_showChannelInfo) Positioned(left: 0, right: 0, bottom: 60, child: _buildChannelInfo()),
        ]),
      ),
    ),
  ));

  Widget _buildControls() => Stack(children: [
    Positioned(top: 0, left: 0, right: 0, child: Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])),
      child: Row(children: [
        GestureDetector(onTap: () { if (Navigator.canPop(context)) Navigator.pop(context); },
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          Text(_playlist[_idx].category, style: const TextStyle(color: AppTheme.accentCyan, fontSize: 12)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.accentRed, borderRadius: BorderRadius.circular(6)),
          child: const Text("EN VIVO", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
      ])),
    ),
    // Hint de zapping
    Positioned(bottom: 20, right: 16, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
      child: Text(
        '${_idx + 1}/${_playlist.length}  < >  Cambiar canal',
        style: const TextStyle(color: Colors.white70, fontSize: 11)))),
  ]);

  Widget _buildChannelInfo() => Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.accentCyan, width: 1.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.live_tv, color: AppTheme.accentCyan, size: 20),
        const SizedBox(width: 10),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('${_idx + 1} de ${_playlist.length} canales', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ]),
      ]),
    ));
}
