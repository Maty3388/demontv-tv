import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel> playlist;
  final int initialIndex;
  const PlayerScreen({super.key, required this.channel, this.playlist = const [], this.initialIndex = 0});
  @override State<PlayerScreen> createState() => _State();
}

class _State extends State<PlayerScreen> {
  BetterPlayerController? _ctrl;
  late int _idx;
  late List<Channel> _playlist;
  bool _showChannelInfo = false;
  final FocusNode _focusNode = FocusNode();
  bool _hasError = false;
  bool _isFavorite = false;
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _playlist = widget.playlist.isEmpty ? [widget.channel] : widget.playlist;
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    _idx = widget.initialIndex;
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
    _ctrl?.dispose();
    final rawUrl = ch.streamUrl;
    final parts = rawUrl.split('|');
    final url = parts[0].trim();
    final headers = <String, String>{'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'};
    if (parts.length > 1) {
      for (final kv in parts[1].split('&')) {
        final idx = kv.indexOf('=');
        if (idx > 0) headers[kv.substring(0, idx).trim()] = kv.substring(idx + 1).trim();
      }
    }
    headers.addAll(ch.headers);

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      headers: headers,
      liveStream: ch.isLive,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 5000,
        maxBufferMs: 30000,
        bufferForPlaybackMs: 2500,
        bufferForPlaybackAfterRebufferMs: 5000,
      ),
    );

    _ctrl = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fullScreenByDefault: true,
        allowedScreenSleep: false,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
          enableFullscreen: false,
          enableOverflowMenu: true,
          enablePip: false,
          enableSkips: false,
          enablePlaybackSpeed: false,
          enableSubtitles: false,
          enableAudioTracks: false,
          controlBarColor: Colors.black54,
          iconsColor: Colors.white,
          progressBarPlayedColor: AppTheme.accentCyan,
          progressBarHandleColor: AppTheme.accentCyan,
        ),
        eventListener: (e) {
          if (e.betterPlayerEventType == BetterPlayerEventType.exception) {
            if (mounted) setState(() => _hasError = true);
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) { setState(() => _hasError = false); _initPlayer(_playlist[_idx]); }
            });
          } else if (e.betterPlayerEventType == BetterPlayerEventType.initialized) {
            if (mounted) setState(() => _hasError = false);
          }
        },
      ),
      betterPlayerDataSource: dataSource,
    );
    setState(() {});
  }

  void _nextChannel() {
    final next = (_idx + 1) % _playlist.length;
    setState(() { _idx = next; _showChannelInfo = true; _isFavorite = _favorites.contains(_playlist[next].id); });
    _initPlayer(_playlist[next]);
    Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _showChannelInfo = false); });
  }

  void _prevChannel() {
    final prev = (_idx - 1 + _playlist.length) % _playlist.length;
    setState(() { _idx = prev; _showChannelInfo = true; _isFavorite = _favorites.contains(_playlist[prev].id); });
    _initPlayer(_playlist[prev]);
    Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _showChannelInfo = false); });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _focusNode.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight, DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: true,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
          behavior: HitTestBehavior.opaque,
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
                if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) { Navigator.pop(context); return KeyEventResult.handled; }
              }
              return KeyEventResult.ignored;
            },
            child: Listener(
              onPointerDown: (_) => _focusNode.requestFocus(),
              child: Stack(children: [
            if (_ctrl != null) BetterPlayer(controller: _ctrl!)
            else const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
            if (_hasError) Positioned.fill(child: Container(
              color: Colors.black87,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.signal_wifi_off, color: Colors.white54, size: 64),
                const SizedBox(height: 16),
                const Text('Canal no disponible', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Reconectando...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: AppTheme.accentCyan, strokeWidth: 2),
              ]))),
            if (_showChannelInfo) Positioned(left: 0, right: 0, bottom: 60,
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.accentCyan, width: 1.5)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.live_tv, color: AppTheme.accentCyan, size: 20),
                  const SizedBox(width: 10),
                  Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_playlist[_idx].name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('\${_idx + 1} de \${_playlist.length} canales', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _toggleFavorite,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_isFavorite ? Icons.star : Icons.star_border, color: _isFavorite ? const Color(0xFFFFD700) : Colors.white54, size: 16),
                      const SizedBox(width: 4),
                      Text(_isFavorite ? 'En favoritos' : 'Agregar a favoritos', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ])),
                  ]),
                ]),
              ))),
          ]),
              ),
          ),
        ),
    ));
}