import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ContentPlayerScreen extends StatefulWidget {
  final Content content;
  const ContentPlayerScreen({super.key, required this.content});
  @override State<ContentPlayerScreen> createState() => _State();
}

class _State extends State<ContentPlayerScreen> {
  VideoPlayerController? _ctrl;
  bool _initialized = false, _showControls = true;

  bool get hasStream => widget.content.streamUrl != null && widget.content.streamUrl!.isNotEmpty;

  @override
  void initState() { super.initState(); if (hasStream) _initPlayer(); }

  Future<void> _initPlayer() async {
    final url = widget.content.streamUrl!.split("|")[0].trim();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    await _ctrl!.initialize();
    await _ctrl!.play();
    setState(() => _initialized = true);
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: hasStream ? _buildPlayer() : _buildDetail());

  Widget _buildPlayer() => GestureDetector(
    onTap: () => setState(() => _showControls = !_showControls),
    child: Stack(children: [
      _initialized && _ctrl != null
        ? Center(child: AspectRatio(aspectRatio: _ctrl!.value.aspectRatio, child: VideoPlayer(_ctrl!)))
        : const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
      if (_showControls) Positioned(top: 40, left: 12, child: GestureDetector(onTap: () => Navigator.pop(context),
        child: Container(width: 38, height: 38, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: AppTheme.logoGradient)),
          child: const Icon(Icons.chevron_left, color: Colors.white, size: 26)))),
    ]));

  Widget _buildDetail() => SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(12,12,12,0), child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 38, height: 38,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: AppTheme.logoGradient)),
        child: const Icon(Icons.chevron_left, color: Colors.white, size: 26))),
      const SizedBox(width: 12),
      Expanded(child: Text(widget.content.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ])),
    Expanded(child: Padding(padding: const EdgeInsets.all(24), child: ClipRRect(borderRadius: BorderRadius.circular(20),
      child: CachedNetworkImage(imageUrl: widget.content.posterUrl, fit: BoxFit.contain,
        placeholder: (_, __) => Container(color: AppTheme.surface),
        errorWidget: (_, __, ___) => Container(color: AppTheme.surface, child: const Icon(Icons.movie, color: AppTheme.textHint, size: 80)))))),
  ]));
}
