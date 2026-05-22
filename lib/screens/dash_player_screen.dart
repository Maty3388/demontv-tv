import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/models.dart';

class DashPlayerScreen extends StatefulWidget {
  final Channel channel;
  final String streamUrl;
  const DashPlayerScreen({super.key, required this.channel, required this.streamUrl});
  @override State<DashPlayerScreen> createState() => _DashPlayerScreenState();
}

class _DashPlayerScreenState extends State<DashPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.streamUrl));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Video(controller: _controller),
  );
}
