import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'dart:async';

class ContentPlayerScreen extends StatefulWidget {
  final Content content;
  const ContentPlayerScreen({super.key, required this.content});
  @override State<ContentPlayerScreen> createState() => _State();
}

class _State extends State<ContentPlayerScreen> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _showControls = true;
  bool _isPlaying = false;
  Timer? _hideTimer;
  static const _orange = Color(0xFFFF8C00);
  static const _orangeLight = Color(0xFFFFB347);

  bool get hasStream => widget.content.streamUrl != null && widget.content.streamUrl!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (hasStream) _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.content.streamUrl!.split("|")[0].trim();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    await _ctrl!.initialize();
    await _ctrl!.play();
    setState(() { _initialized = true; _isPlaying = true; });
    _showControlsTemporary();
    _ctrl!.addListener(() {
      if (mounted) setState(() => _isPlaying = _ctrl!.value.isPlaying);
    });
  }

  void _showControlsTemporary() {
    setState(() => _showControls = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _togglePlay() {
    if (_ctrl == null) return;
    if (_isPlaying) { _ctrl!.pause(); } else { _ctrl!.play(); }
    setState(() => _isPlaying = !_isPlaying);
    _showControlsTemporary();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _hideTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: hasStream ? _buildPlayer() : _buildDetail());

  Widget _buildPlayer() => RawKeyboardListener(
    focusNode: FocusNode()..requestFocus(),
    autofocus: true,
    onKey: (event) {
      if (event is RawKeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
          _showControls ? _togglePlay() : _showControlsTemporary();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _showControlsTemporary();
        } else if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) {
          Navigator.pop(context);
        }
      }
    },
    child: GestureDetector(
      onTap: () => _showControls ? _togglePlay() : _showControlsTemporary(),
      child: Stack(children: [
        _initialized && _ctrl != null
          ? Center(child: AspectRatio(aspectRatio: _ctrl!.value.aspectRatio, child: VideoPlayer(_ctrl!)))
          : const Center(child: CircularProgressIndicator(color: _orange)),
        if (_showControls) ...[
          // Gradiente
          Positioned.fill(child: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xCC000000), Colors.transparent, Colors.transparent, Color(0xCC000000)],
              stops: [0.0, 0.3, 0.7, 1.0])))),
          // Header
          Positioned(top: 40, left: 16, right: 16, child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _orange.withOpacity(0.5))),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.content.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (widget.content.year != null) Text(widget.content.year!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ])),
          // Controles
          Positioned(left: 16, right: 16, bottom: 40, child: Column(children: [
            // Barra de progreso
            if (_initialized && _ctrl != null) ValueListenableBuilder(
              valueListenable: _ctrl!,
              builder: (_, val, __) {
                final pos = val.position.inMilliseconds.toDouble();
                final dur = val.duration.inMilliseconds.toDouble();
                return Column(children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _orange, thumbColor: _orangeLight,
                      inactiveTrackColor: Colors.white24, trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                    child: Slider(
                      value: dur > 0 ? pos / dur : 0,
                      onChanged: (v) { _ctrl!.seekTo(Duration(milliseconds: (v * dur).toInt())); },
                    )),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_formatDur(val.position), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    Text(_formatDur(val.duration), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ]),
                ]);
              }),
            const SizedBox(height: 12),
            // Botones
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(
                onTap: () { _ctrl?.seekTo(Duration(seconds: (_ctrl!.value.position.inSeconds - 10).clamp(0, 999999))); },
                child: const Icon(Icons.replay_10, color: Colors.white70, size: 32)),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(width: 60, height: 60,
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [_orange, _orangeLight])),
                  child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 34))),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () { _ctrl?.seekTo(Duration(seconds: (_ctrl!.value.position.inSeconds + 10))); },
                child: const Icon(Icons.forward_10, color: Colors.white70, size: 32)),
            ]),
          ])),
        ],
      ])));

  String _formatDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2,'0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2,'0');
    return h > 0 ? '\$h:\$m:\$s' : '\$m:\$s';
  }

  Widget _buildDetail() => SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(12,12,12,0), child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context),
        child: Container(width: 38, height: 38,
          decoration: const BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_orange, _orangeLight])),
          child: const Icon(Icons.chevron_left, color: Colors.white, size: 26))),
      const SizedBox(width: 12),
      Expanded(child: Text(widget.content.title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
    ])),
    Expanded(child: Padding(padding: const EdgeInsets.all(24),
      child: ClipRRect(borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(imageUrl: widget.content.posterUrl, fit: BoxFit.contain,
          placeholder: (_, __) => Container(color: AppTheme.surface),
          errorWidget: (_, __, ___) => Container(color: AppTheme.surface,
            child: const Icon(Icons.movie, color: AppTheme.textHint, size: 80)))))),
  ]));
}
