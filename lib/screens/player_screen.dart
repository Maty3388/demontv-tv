import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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
  late final Player _player;
  late final VideoController _controller;
  bool _showInfo = false;
  Timer? _infoTimer;
  late List<Channel> _playlist;
  late int _idx;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist.isEmpty ? [widget.channel] : widget.playlist;
    _idx = widget.initialIndex;
    _player = Player();
    _controller = VideoController(_player);
    _playChannel(_playlist[_idx]);
  }

  @override
  void dispose() {
    _infoTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playChannel(Channel ch) async {
    final url = ch.streamUrl.split('|')[0].trim();
    final headers = Map<String, String>.from(ch.headers);
    headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36';
    await _player.open(Media(url, httpHeaders: headers));
  }

  void _nextChannel() {
    if (_playlist.isEmpty) return;
    final next = (_idx + 1) % _playlist.length;
    setState(() => _idx = next);
    _playChannel(_playlist[next]);
    _showChannelInfo();
  }

  void _prevChannel() {
    if (_playlist.isEmpty) return;
    final prev = (_idx - 1 + _playlist.length) % _playlist.length;
    setState(() => _idx = prev);
    _playChannel(_playlist[prev]);
    _showChannelInfo();
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
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) _nextChannel();
    else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _prevChannel();
    else if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.arrowDown) _showChannelInfo();
    else if (event.logicalKey == LogicalKeyboardKey.goBack) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: FocusNode()..requestFocus(),
    onKey: _handleKey,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        SizedBox.expand(child: Video(controller: _controller)),
        if (_showInfo)
          Positioned(bottom: 24, left: 24, right: 24,
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
              ]))),
      ])));
}
