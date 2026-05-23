import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel> playlist;
  final int initialIndex;
  const PlayerScreen({super.key, required this.channel, this.playlist = const [], this.initialIndex = 0});
  @override State<PlayerScreen> createState() => _PlayerState();
}

class _PlayerState extends State<PlayerScreen> {
  BetterPlayerController? _ctrl;
  bool _showInfo = false;
  Timer? _infoTimer;
  late List<Channel> _playlist;
  late int _idx;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist.isEmpty ? [widget.channel] : widget.playlist;
    _idx = widget.initialIndex;
    _initPlayer(_playlist[_idx]);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _infoTimer?.cancel();
    super.dispose();
  }

  String _detectFormat(String url) {
    final u = url.toLowerCase();
    if (u.contains('.mpd') || u.contains('dash')) return 'dash';
    if (u.contains('.m3u8') || u.contains('hls')) return 'hls';
    if (u.contains('.ts')) return 'ts';
    return 'other';
  }

  Future<void> _initPlayer(Channel ch) async {
    _ctrl?.dispose();
    final url = ch.streamUrl.split('|')[0].trim();
    final headers = Map<String, String>.from(ch.headers);
    headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36';

    final format = _detectFormat(url);
    BetterPlayerDataSourceType sourceType = BetterPlayerDataSourceType.network;

    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      sourceType,
      url,
      headers: headers,
      videoFormat: format == 'dash' ? BetterPlayerVideoFormat.dash
        : format == 'hls' ? BetterPlayerVideoFormat.hls
        : format == 'ts' ? BetterPlayerVideoFormat.ss
        : BetterPlayerVideoFormat.other,
      notificationConfiguration: BetterPlayerNotificationConfiguration(
        showNotification: false,
      ),
    );

    final ctrl = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fullScreenByDefault: false,
        aspectRatio: 16/9,
        fit: BoxFit.contain,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
        ),
        errorBuilder: (ctx, msg) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(msg ?? 'Error al reproducir', style: const TextStyle(color: Colors.white)),
          ])),
      ),
      betterPlayerDataSource: dataSource,
    );

    if (mounted) setState(() => _ctrl = ctrl);
  }

  void _nextChannel() {
    if (_playlist.isEmpty) return;
    final next = (_idx + 1) % _playlist.length;
    setState(() => _idx = next);
    _initPlayer(_playlist[next]);
  }

  void _prevChannel() {
    if (_playlist.isEmpty) return;
    final prev = (_idx - 1 + _playlist.length) % _playlist.length;
    setState(() => _idx = prev);
    _initPlayer(_playlist[prev]);
  }

  void _showChannelInfo() {
    setState(() => _showInfo = true);
    _infoTimer?.cancel();
    _infoTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showInfo = false);
    });
  }

  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) { _nextChannel(); _showChannelInfo(); }
    else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) { _prevChannel(); _showChannelInfo(); }
    else if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.arrowDown) { _showChannelInfo(); }
    else if (event.logicalKey == LogicalKeyboardKey.goBack) { Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: FocusNode()..requestFocus(),
    onKey: _handleKey,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Player
        if (_ctrl != null)
          SizedBox.expand(child: BetterPlayer(controller: _ctrl!))
        else
          const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
        // Info canal
        if (_showInfo)
          Positioned(bottom: 24, left: 24, right: 24,
            child: AnimatedOpacity(opacity: _showInfo ? 1.0 : 0.0, duration: const Duration(milliseconds: 300),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  if (_playlist[_idx].logoUrl.isNotEmpty)
                    ClipRRect(borderRadius: BorderRadius.circular(6),
                      child: Image.network(_playlist[_idx].logoUrl, width: 40, height: 40, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox(width: 40))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(_playlist[_idx].category, style: const TextStyle(color: AppTheme.accentCyan, fontSize: 12)),
                  ])),
                  Text('\${_idx + 1}/\${_playlist.length}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ])))),
      ])));
}
