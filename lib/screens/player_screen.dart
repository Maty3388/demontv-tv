import '../services/stream_proxy.dart';
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
  bool _showControls = false;
  bool _showChannelInfo = false;
  Timer? _hideTimer;
  Timer? _infoTimer;
  bool _initialized = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  late List<Channel> _playlist;
  late int _idx;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _playlist = widget.playlist.isEmpty ? [widget.channel] : widget.playlist;
    _idx = widget.initialIndex;
    _initPlayer(_playlist[_idx]);
  }

  Future<void> _initPlayer(Channel ch) async {
    _ctrl?.dispose();
    setState(() => _initialized = false);
    _reconnectTimer?.cancel();
    _ctrl?.dispose();
    setState(() => _initialized = false);
    final parts = ch.streamUrl.split("|");
    String url = parts[0].trim();
    final headers = Map<String, String>.from(ch.headers);
    headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36';
    try {
      // Usar proxy solo si hay Referer u otros headers especiales
      final hasSpecialHeaders = ch.headers.containsKey('Referer') || ch.headers.containsKey('Origin');
      final playUrl = hasSpecialHeaders ? StreamProxy.proxyUrl(url, headers) : url;
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(playUrl), httpHeaders: hasSpecialHeaders ? {} : {'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'}, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false));
      await ctrl.initialize();
      ctrl.addListener(() {
        if (!mounted) return;
        final val = ctrl.value;
        if (val.hasError && _reconnectAttempts < 5) {
          _reconnectTimer?.cancel();
          _reconnectTimer = Timer(const Duration(seconds: 3), () {
            _reconnectAttempts++;
            _initPlayer(ch);
          });
        } else if (!val.hasError) {
          _reconnectAttempts = 0;
        }
      });
      if (!mounted) return;
      _ctrl = ctrl;
      _ctrl!.play();
      setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _initialized = false);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _hideTimer?.cancel();
    _infoTimer?.cancel();
    _reconnectTimer?.cancel();
    _ctrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    super.dispose();
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
        behavior: HitTestBehavior.opaque,
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
