import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel> playlist;
  final int initialIndex;
  const PlayerScreen({super.key, required this.channel, this.playlist = const [], this.initialIndex = 0});
  @override State<PlayerScreen> createState() => _State();
}

class _State extends State<PlayerScreen> {
  BetterPlayerController? _ctrl;
  int _zapToken = 0;
  bool _showZapOverlay = false;
  Timer? _zapOverlayTimer;
  late int _idx;
  late List<Channel> _playlist;
  bool _showControls = false;
  Timer? _hideTimer;
  final FocusNode _focusNode = FocusNode();
  bool _hasError = false;
  bool _isLoading = true;
  bool _isPlaying = true;
  bool _isFavorite = false;
  Set<String> _favorites = {};
  static const _orange = Color(0xFFFF8C00);
  static const _orangeLight = Color(0xFFFFB347);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _playlist = widget.playlist.isEmpty ? [widget.channel] : widget.playlist;
    _idx = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _initPlayer(_playlist[_idx]);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await ApiService.getFavorites();
      if (mounted) setState(() { _favorites = favs.map((c) => c.id).toSet(); _isFavorite = _favorites.contains(_playlist[_idx].id); });
    } catch (_) {}
  }

  void _toggleFavorite() async {
    final ch = _playlist[_idx];
    if (_favorites.contains(ch.id)) {
      await ApiService.removeFavorite(ch.id);
      setState(() { _favorites.remove(ch.id); _isFavorite = false; });
    } else {
      await ApiService.addFavorite(ch.id);
      setState(() { _favorites.add(ch.id); _isFavorite = true; });
    }
  }

  void _initPlayer(Channel ch) {
    if (mounted) setState(() { _isLoading = true; _showControls = false; _isPlaying = false; });
    final url = ch.streamUrl.split('|')[0].trim();
    final headers = <String, String>{
      'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
      'Accept': '*/*',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
    };
    headers.addAll(ch.headers);

    // Detectar formato por URL
    final urlLower = url.toLowerCase();
    BetterPlayerDataSource dataSource;
    if (urlLower.contains('.mpd')) {
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, url,
        headers: headers, liveStream: ch.isLive,
        videoFormat: BetterPlayerVideoFormat.dash,
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 2000, maxBufferMs: 10000,
          bufferForPlaybackMs: 1000, bufferForPlaybackAfterRebufferMs: 2000),
      );
    } else if (urlLower.contains('.m3u8') || urlLower.contains('hls')) {
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, url,
        headers: headers, liveStream: ch.isLive,
        videoFormat: BetterPlayerVideoFormat.hls,
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 3000, maxBufferMs: 15000,
          bufferForPlaybackMs: 1500, bufferForPlaybackAfterRebufferMs: 3000),
      );
    } else {
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, url,
        headers: headers, liveStream: ch.isLive,
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 2000, maxBufferMs: 10000,
          bufferForPlaybackMs: 1000, bufferForPlaybackAfterRebufferMs: 2000),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _focusNode.requestFocus(); });
    _ctrl = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true, looping: false,
        fullScreenByDefault: true, allowedScreenSleep: false,
        controlsConfiguration: const BetterPlayerControlsConfiguration(showControls: false),
        autoDetectFullscreenAspectRatio: true,
        eventListener: (e) {
          if (e.betterPlayerEventType == BetterPlayerEventType.play) {
            if (mounted) setState(() => _isPlaying = true);
          } else if (e.betterPlayerEventType == BetterPlayerEventType.pause) {
            if (mounted) setState(() => _isPlaying = false);
          } else if (e.betterPlayerEventType == BetterPlayerEventType.exception) {
            if (mounted) setState(() => _hasError = true);
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) { setState(() => _hasError = false); _initPlayer(_playlist[_idx]); }
            });
          } else if (e.betterPlayerEventType == BetterPlayerEventType.initialized) {
            if (mounted) { Future.delayed(const Duration(milliseconds: 200), () { if (mounted) setState(() { _hasError = false; _isLoading = false; _isPlaying = true; }); }); _showControlsTemporary(); }
          }
        },
      ),
      betterPlayerDataSource: dataSource,
    );
    setState(() {});
  }

  void _showControlsTemporary() {
    setState(() => _showControls = true);
    _hideTimer?.cancel();
    _zapOverlayTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () { if (mounted) setState(() => _showControls = false); });
  }

  void _showZapInfo() {
    _zapOverlayTimer?.cancel();
    setState(() => _showZapOverlay = true);
    _zapOverlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showZapOverlay = false);
    });
  }

  void _nextChannel() {
    final next = (_idx + 1) % _playlist.length;
    setState(() { _idx = next; _isFavorite = _favorites.contains(_playlist[next].id); _showControls = false; });
    _hideTimer?.cancel();
    _ctrl?.dispose();
    _ctrl = null;
    _showZapInfo();
    final token = ++_zapToken;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && token == _zapToken) _initPlayer(_playlist[next]);
    });
  }

  void _prevChannel() {
    final prev = (_idx - 1 + _playlist.length) % _playlist.length;
    setState(() { _idx = prev; _isFavorite = _favorites.contains(_playlist[prev].id); _showControls = false; });
    _hideTimer?.cancel();
    _ctrl?.dispose();
    _ctrl = null;
    _showZapInfo();
    final token = ++_zapToken;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && token == _zapToken) _initPlayer(_playlist[prev]);
    });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _hideTimer?.cancel();
    _focusNode.dispose();
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
          onKey: (node, event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.channelUp) { _nextChannel(); return KeyEventResult.handled; }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.channelDown) { _prevChannel(); return KeyEventResult.handled; }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) { _showControlsTemporary(); return KeyEventResult.handled; }
              if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) { Navigator.pop(context); return KeyEventResult.handled; }
            }
            return KeyEventResult.ignored;
          },
          child: Stack(children: [
            // Fondo negro siempre presente
            Container(color: Colors.black),
            // Player con fade para evitar pantalla blanca
            if (_ctrl != null) AnimatedOpacity(
              opacity: _isLoading ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: BetterPlayer(controller: _ctrl!)),
            if (_isLoading && !_hasError) Positioned.fill(child: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0D0D0D), Color(0xFF1A0800), Color(0xFF0D0D0D)])),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_playlist[_idx].logoUrl.isNotEmpty) SizedBox(width: 80, height: 80,
                  child: CachedNetworkImage(imageUrl: _playlist[_idx].logoUrl, fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54, size: 48))),
                const SizedBox(height: 16),
                Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_playlist[_idx].category, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: _orange, strokeWidth: 2),
                const SizedBox(height: 12),
                const Text('Cargando canal...', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ]))),
            if (_hasError) Positioned.fill(child: Container(
              color: Colors.black,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                // Logo del canal
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
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.5))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.signal_wifi_off, color: Colors.red, size: 14),
                    SizedBox(width: 6),
                    Text('Señal no disponible', style: TextStyle(color: Colors.red, fontSize: 13)),
                  ])),
                const SizedBox(height: 20),
                const Text('Reconectando automáticamente...', style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 12),
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _orange, strokeWidth: 2)),
              ]))),
            // Overlay de zapping estilo Netflix
            if (_showZapOverlay && !_isLoading) AnimatedOpacity(
              opacity: _showZapOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Color(0xEE000000), Color(0x00000000)])),
                  child: Row(children: [
                    if (_playlist[_idx].logoUrl.isNotEmpty) Container(
                      width: 64, height: 64,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _orange.withOpacity(0.5))),
                      child: Padding(padding: const EdgeInsets.all(8),
                        child: CachedNetworkImage(imageUrl: _playlist[_idx].logoUrl, fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54)))),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_playlist[_idx].name,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(4)),
                          child: Text(_playlist[_idx].category,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: const Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 8),
                        Text('${_idx + 1} / ${_playlist.length}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ]),
                    ])),
                  ])))),
            if (_showControls) Positioned.fill(child: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xCC000000), Colors.transparent, Colors.transparent, Color(0xCC000000)],
                stops: [0.0, 0.3, 0.7, 1.0])),
              child: Column(children: [
                Padding(padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _orange.withOpacity(0.5))),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_playlist[_idx].category, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ])),
                    GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _isFavorite ? _orange : Colors.white24)),
                        child: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? _orange : Colors.white, size: 20))),
                  ])),
                const Spacer(),
                Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(children: [
                    Container(height: 4, decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(colors: [_orange, _orangeLight]))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      GestureDetector(onTap: _prevChannel, child: const Icon(Icons.skip_previous, color: Colors.white, size: 32)),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () { if (_isPlaying) { _ctrl?.pause(); setState(() => _isPlaying = false); } else { _ctrl?.play(); setState(() => _isPlaying = true); } },
                        child: Container(width: 64, height: 64,
                          decoration: const BoxDecoration(shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [_orange, _orangeLight])),
                          child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36))),
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
