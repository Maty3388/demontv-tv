import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel> playlist;
  final int initialIndex;
  const PlayerScreen({super.key, required this.channel, this.playlist = const [], this.initialIndex = 0});
  @override State<PlayerScreen> createState() => _PlayerState();
}

class _PlayerState extends State<PlayerScreen> {
  late Player _player;
  late VideoController _videoCtrl;
  late int _idx;
  late List<Channel> _playlist;
  bool _showControls = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showZapOverlay = false;
  bool _isFavorite = false;
  Set<String> _favorites = {};
  Timer? _hideTimer;
  Timer? _zapOverlayTimer;
  int _zapToken = 0;
  int _retryCount = 0;
  final _focusNode = FocusNode();
  static const _orange = Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist.isEmpty ? [widget.channel] : widget.playlist;
    _idx = widget.initialIndex;
    _player = Player();
    _videoCtrl = VideoController(_player);
    _loadFavorites();
    _initPlayer(_playlist[_idx]);
    _player.stream.playing.listen((v) { if (mounted) setState(() => _isPlaying = v); });
    _player.stream.buffering.listen((v) { if (mounted) setState(() => _isLoading = v); });
    _player.stream.error.listen((e) { if (mounted && e.isNotEmpty) { setState(() { _hasError = true; _isLoading = false; }); _scheduleRetry(); } });
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _focusNode.requestFocus(); });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _scheduleRetry() {
    if (_retryCount >= 2) return;
    _retryCount++;
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _hasError) { setState(() { _hasError = false; _isLoading = true; }); _initPlayer(_playlist[_idx]); }
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await ApiService.getFavorites();
      if (mounted) setState(() { _favorites = favs.map((c) => c.id).toSet(); _isFavorite = _favorites.contains(_playlist[_idx].id); });
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final ch = _playlist[_idx];
    if (_isFavorite) {
      await ApiService.removeFavorite(ch.id);
      setState(() { _favorites.remove(ch.id); _isFavorite = false; });
    } else {
      await ApiService.addFavorite(ch.id);
      setState(() { _favorites.add(ch.id); _isFavorite = true; });
    }
  }

  void _initPlayer(Channel ch) {
    setState(() { _isLoading = true; _hasError = false; _isPlaying = false; });
    final url = ch.streamUrl.split('|')[0].trim();
    final headers = <String, String>{
      'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
    };
    headers.addAll(ch.headers);
    _player.open(Media(url, httpHeaders: headers));
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _focusNode.requestFocus(); });
  }

  void _showControlsTemporary() {
    setState(() => _showControls = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () { if (mounted) setState(() => _showControls = false); });
  }

  void _showZapInfo() {
    _zapOverlayTimer?.cancel();
    setState(() => _showZapOverlay = true);
    _zapOverlayTimer = Timer(const Duration(seconds: 3), () { if (mounted) setState(() => _showZapOverlay = false); });
  }

  void _changeChannel(int newIdx) {
    _hideTimer?.cancel();
    _retryCount = 0;
    setState(() { _idx = newIdx; _isFavorite = _favorites.contains(_playlist[newIdx].id); _showControls = false; _isLoading = true; _hasError = false; });
    _showZapInfo();
    final token = ++_zapToken;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && token == _zapToken) _initPlayer(_playlist[newIdx]);
    });
  }

  void _nextChannel() => _changeChannel((_idx + 1) % _playlist.length);
  void _prevChannel() => _changeChannel((_idx - 1 + _playlist.length) % _playlist.length);

  @override
  void dispose() {
    _hideTimer?.cancel();
    _zapOverlayTimer?.cancel();
    _focusNode.dispose();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: true,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () { _focusNode.requestFocus(); _showControlsTemporary(); },
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity != null) {
            if (d.primaryVelocity! < -300) _nextChannel();
            else if (d.primaryVelocity! > 300) _prevChannel();
          }
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.channelUp) { _nextChannel(); return KeyEventResult.handled; }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.channelDown) { _prevChannel(); return KeyEventResult.handled; }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) { _showControlsTemporary(); return KeyEventResult.handled; }
              if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) { Navigator.pop(context); return KeyEventResult.handled; }
            }
            return KeyEventResult.ignored;
          },
          child: Stack(children: [
            Video(controller: _videoCtrl, fill: Colors.black),
            if (_isLoading && !_hasError) Positioned.fill(child: Container(
              color: Colors.black,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_playlist[_idx].logoUrl.isNotEmpty) Container(
                  width: 80, height: 80, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                  child: Padding(padding: const EdgeInsets.all(12),
                    child: CachedNetworkImage(imageUrl: _playlist[_idx].logoUrl, fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54, size: 40)))),
                Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_playlist[_idx].category, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 24),
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _orange, strokeWidth: 2)),
                const SizedBox(height: 12),
                const Text('Cargando canal...', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ]))),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.5))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.signal_wifi_off, color: Colors.red, size: 14),
                    SizedBox(width: 6),
                    Text('Señal no disponible', style: TextStyle(color: Colors.red, fontSize: 13)),
                  ])),
                const SizedBox(height: 20),
                Text(_retryCount < 2 ? 'Reconectando...' : 'Canal no disponible', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                if (_retryCount < 2) ...[const SizedBox(height: 12), const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _orange, strokeWidth: 2))],
              ]))),
            if (_showZapOverlay && !_isLoading) Positioned(left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xEE000000), Color(0x00000000)])),
                child: Row(children: [
                  if (_playlist[_idx].logoUrl.isNotEmpty) Container(
                    width: 64, height: 64, margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: Border.all(color: _orange.withOpacity(0.5))),
                    child: Padding(padding: const EdgeInsets.all(8), child: CachedNetworkImage(imageUrl: _playlist[_idx].logoUrl, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54)))),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(4)), child: Text(_playlist[_idx].category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 8),
                      Text('${_idx + 1} / ${_playlist.length}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ]),
                  ])),
                ]))),
            if (_showControls) Positioned.fill(child: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xCC000000), Colors.transparent, Colors.transparent, Color(0xCC000000)], stops: [0.0, 0.3, 0.7, 1.0])),
              child: Column(children: [
                Padding(padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                  child: Row(children: [
                    GestureDetector(onTap: () => Navigator.pop(context),
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8), border: Border.all(color: _orange.withOpacity(0.5))), child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_playlist[_idx].category, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ])),
                    GestureDetector(onTap: _toggleFavorite,
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8), border: Border.all(color: _isFavorite ? _orange : Colors.white24)), child: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? _orange : Colors.white, size: 20))),
                  ])),
                const Spacer(),
                Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(children: [
                    Container(height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), gradient: const LinearGradient(colors: [_orange, Color(0xFFFFB347)]))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      GestureDetector(onTap: _prevChannel, child: const Icon(Icons.skip_previous, color: Colors.white, size: 32)),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () { if (_isPlaying) { _player.pause(); } else { _player.play(); } },
                        child: Container(width: 64, height: 64, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_orange, Color(0xFFFFB347)])), child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36))),
                      const SizedBox(width: 24),
                      GestureDetector(onTap: _nextChannel, child: const Icon(Icons.skip_next, color: Colors.white, size: 32)),
                    ]),
                    const SizedBox(height: 12),
                    Text('${_idx + 1} / ${_playlist.length}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ])),
              ]))),
          ]),
        ),
      ),
    ));
}
