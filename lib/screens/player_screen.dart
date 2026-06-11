import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel> playlist;
  final int initialIndex;
  const PlayerScreen({super.key, required this.channel, this.playlist = const [], this.initialIndex = 0});
  @override State<PlayerScreen> createState() => _State();
}

class _State extends State<PlayerScreen> {
  late Player _player;
  late VideoController _ctrl;
  late int _idx;
  late List<Channel> _playlist;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = false;
  final FocusNode _focusNode = FocusNode();
  static const _orange = Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _playlist = widget.playlist.isEmpty ? [widget.channel] : widget.playlist;
    _idx = widget.initialIndex;
    _player = Player();
    _ctrl = VideoController(_player);
    _player.stream.playing.listen((playing) {
      if (playing && mounted) setState(() { _isLoading = false; _hasError = false; });
    });
    _player.stream.error.listen((error) {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    });
    _loadChannel(_idx);
    Future.delayed(const Duration(milliseconds: 200), () => _focusNode.requestFocus());
  }

  void _loadChannel(int idx) {
    setState(() { _isLoading = true; _hasError = false; _showControls = false; });
    final ch = _playlist[idx];
    final url = ch.streamUrl.split('|')[0].trim();
    _player.open(Media(url, httpHeaders: {
      'User-Agent': 'Mozilla/5.0',
      ...ch.headers,
    }));
    // Timeout de seguridad
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isLoading) setState(() { _hasError = true; _isLoading = false; });
    });
  }

  void _nextChannel() {
    _idx = (_idx + 1) % _playlist.length;
    _loadChannel(_idx);
  }

  void _prevChannel() {
    _idx = (_idx - 1 + _playlist.length) % _playlist.length;
    _loadChannel(_idx);
  }

  @override
  void dispose() {
    _player.dispose();
    _focusNode.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: true,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (_, event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.channelUp) { _nextChannel(); return KeyEventResult.handled; }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.channelDown) { _prevChannel(); return KeyEventResult.handled; }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
              setState(() => _showControls = !_showControls); return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) { Navigator.pop(context); return KeyEventResult.handled; }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          onHorizontalDragEnd: (d) {
            if (d.primaryVelocity != null) {
              if (d.primaryVelocity! < -300) _nextChannel();
              else if (d.primaryVelocity! > 300) _prevChannel();
            }
          },
          child: Stack(children: [
            // Video
            Container(color: Colors.black),
            if (!_isLoading && !_hasError) Video(controller: _ctrl),

            // Overlay zapping
            if (_isLoading && !_hasError) Positioned.fill(child: Container(
              color: Colors.black,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_playlist[_idx].logoUrl.isNotEmpty) Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(10),
                  child: CachedNetworkImage(imageUrl: _playlist[_idx].logoUrl, fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54, size: 40))),
                const SizedBox(height: 16),
                Text('${_idx + 1}', style: const TextStyle(color: _orange, fontSize: 72, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 8),
                Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_playlist[_idx].category, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                const SizedBox(height: 28),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
                  Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 8, height: 8,
                    decoration: BoxDecoration(color: i < 3 ? _orange : const Color(0xFF333333), shape: BoxShape.circle)))),
              ]))),

            // Error
            if (_hasError) Positioned.fill(child: Container(
              color: Colors.black,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_playlist[_idx].logoUrl.isNotEmpty) Container(
                  width: 80, height: 80, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                  child: Padding(padding: const EdgeInsets.all(12),
                    child: CachedNetworkImage(imageUrl: _playlist[_idx].logoUrl, fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54, size: 40)))),
                Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Canal no disponible', style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton(onPressed: () => _loadChannel(_idx), child: const Text('Reintentar', style: TextStyle(color: _orange))),
                  const SizedBox(width: 16),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Volver', style: TextStyle(color: Colors.white54))),
                ]),
              ]))),

            // Info zapping
            if (_showControls && !_isLoading) Positioned(bottom: 20, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  if (_playlist[_idx].logoUrl.isNotEmpty) Container(
                    width: 48, height: 48, margin: const EdgeInsets.only(right: 12),
                    child: CachedNetworkImage(imageUrl: _playlist[_idx].logoUrl, fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54))),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_playlist[_idx].category, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ])),
                  Text('${_idx + 1} / ${_playlist.length}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ]))),
          ]),
        ),
      ),
    ),
  );
}
