import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import '../models/models.dart';

class DashPlayerScreen extends StatefulWidget {
  final Channel channel;
  final String streamUrl;
  const DashPlayerScreen({super.key, required this.channel, required this.streamUrl});
  @override State<DashPlayerScreen> createState() => _DashPlayerScreenState();
}

class _DashPlayerScreenState extends State<DashPlayerScreen> {
  BetterPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    final src = BetterPlayerDataSource(BetterPlayerDataSourceType.network, widget.streamUrl, videoFormat: BetterPlayerVideoFormat.dash);
    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(autoPlay: true, fullScreenByDefault: true, deviceOrientationsOnFullScreen: [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]),
      betterPlayerDataSource: src,
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: BetterPlayer(controller: _controller!),
  );
}
