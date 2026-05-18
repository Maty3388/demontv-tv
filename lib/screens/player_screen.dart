import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  const PlayerScreen({super.key, required this.channel});
  @override State<PlayerScreen> createState() => _State();
}

class _State extends State<PlayerScreen> {
  BetterPlayerController? _ctrl;
  bool _controlsVisible = true, _buffering = true;
  Timer? _hideTimer;
  Duration _pos = Duration.zero;
  Duration _dur = const Duration(hours: 2);

  @override
  void initState() { super.initState(); _initPlayer(widget.channel); _startHideTimer(); }

  void _initPlayer(Channel channel) {
    final parts = channel.streamUrl.split('|');
    final url = parts[0].trim();
    final headers = Map<String, String>.from(channel.headers);
    if (parts.length > 1) {
      for (final kv in parts[1].split('&')) {
        final idx = kv.indexOf('=');
        if (idx > 0) headers[kv.substring(0, idx).trim()] = kv.substring(idx + 1).trim();
      }
    }
    BetterPlayerVideoFormat? fmt;
    if (url.contains('.m3u8')) fmt = BetterPlayerVideoFormat.hls;
    if (url.contains('.mpd'))  fmt = BetterPlayerVideoFormat.dash;
    final ds = BetterPlayerDataSource(BetterPlayerDataSourceType.network, url,
      videoFormat: fmt, headers: headers.isNotEmpty ? headers : null, liveStream: channel.isLive,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(minBufferMs: 1000, maxBufferMs: 8000, bufferForPlaybackMs: 500, bufferForPlaybackAfterRebufferMs: 1000));
    setState(() { _ctrl?.dispose(); _ctrl = BetterPlayerController(const BetterPlayerConfiguration(autoPlay: true, fit: BoxFit.contain, controlsConfiguration: BetterPlayerControlsConfiguration(showControls: false), allowedScreenSleep: false)); _buffering = true; });
    _ctrl!.setupDataSource(ds).then((_) {
      _ctrl!.addEventsListener((e) {
        if (!mounted) return;
        if (e.betterPlayerEventType == BetterPlayerEventType.bufferingEnd) setState(() => _buffering = false);
        if (e.betterPlayerEventType == BetterPlayerEventType.bufferingStart) setState(() => _buffering = true);
        if (e.betterPlayerEventType == BetterPlayerEventType.progress) {
          final vp = _ctrl?.videoPlayerController?.value;
          if (vp != null) setState(() { _pos = vp.position; _dur = vp.duration ?? const Duration(hours: 2); });
        }
      });
    });
  }

  void _startHideTimer() { _hideTimer?.cancel(); _hideTimer = Timer(const Duration(seconds: 4), () { if (mounted) setState(() => _controlsVisible = false); }); }
  void _skip(int secs) { _ctrl?.seekTo(_pos + Duration(seconds: secs)); _startHideTimer(); }
  void _togglePlay() { if (_ctrl?.isPlaying() == true) _ctrl?.pause(); else _ctrl?.play(); setState(() {}); _startHideTimer(); }

  @override
  void dispose() { _hideTimer?.cancel(); _ctrl?.dispose(); SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]); SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); super.dispose(); }

  String _fmt(Duration d) => '${d.inMinutes.toString().padLeft(2,'0')}:${d.inSeconds.remainder(60).toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black,
    body: SafeArea(child: Stack(children: [
      Positioned.fill(child: _ctrl != null ? BetterPlayer(controller: _ctrl!) : const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))),
      if (_buffering) const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
      Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque,
        onTap: () { setState(() => _controlsVisible = !_controlsVisible); if (_controlsVisible) _startHideTimer(); },
        onDoubleTapDown: (d) { final w = MediaQuery.of(context).size.width; _skip(d.localPosition.dx < w/2 ? -10 : 10); },
        child: const ColoredBox(color: Colors.transparent))),
      AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: _controlsVisible ? 1.0 : 0.0,
        child: IgnorePointer(ignoring: !_controlsVisible, child: _buildControls())),
    ])));

  Widget _buildControls() {
    final prog = _dur.inMilliseconds > 0 ? (_pos.inMilliseconds / _dur.inMilliseconds).clamp(0.0, 1.0) : 0.0;
    return Stack(children: [
      Positioned(top:0,left:0,right:0,child:Container(height:80,decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.black.withOpacity(0.8),Colors.transparent])))),
      Positioned(bottom:0,left:0,right:0,child:Container(height:120,decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.bottomCenter,end:Alignment.topCenter,colors:[Colors.black.withOpacity(0.9),Colors.transparent])))),
      Positioned(top:12,left:12,right:12,child:Row(children:[
        GestureDetector(onTap:()=>Navigator.pop(context),child:Container(width:38,height:38,decoration:const BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:AppTheme.logoGradient)),child:const Icon(Icons.chevron_left,color:Colors.white,size:26))),
        const Spacer(),
        Text(widget.channel.name.toUpperCase(),style:const TextStyle(color:Colors.white,fontSize:14,fontWeight:FontWeight.bold,letterSpacing:1)),
      ])),
      Center(child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        GestureDetector(onTap:()=>_skip(-10),child:const Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.replay,color:Colors.white,size:32),Text('10',style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.bold))])),
        const SizedBox(width:40),
        GestureDetector(onTap:_togglePlay,child:Container(width:64,height:64,decoration:const BoxDecoration(shape:BoxShape.circle,color:Colors.white),child:Icon(_ctrl?.isPlaying()==true?Icons.pause:Icons.play_arrow,color:Colors.black,size:36))),
        const SizedBox(width:40),
        GestureDetector(onTap:()=>_skip(10),child:const Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.forward_10,color:Colors.white,size:32),Text('10',style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.bold))])),
      ])),
      Positioned(bottom:16,left:16,right:16,child:Column(mainAxisSize:MainAxisSize.min,children:[
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          Text(_fmt(_pos),style:const TextStyle(color:Colors.white,fontSize:12)),
          Text(widget.channel.isLive?'EN VIVO':_fmt(_dur),style:TextStyle(color:widget.channel.isLive?AppTheme.accentRed:Colors.white,fontSize:12,fontWeight:FontWeight.bold)),
        ]),
        SliderTheme(data:SliderTheme.of(context).copyWith(activeTrackColor:AppTheme.accentCyan,inactiveTrackColor:Colors.white24,thumbColor:Colors.white,thumbShape:const RoundSliderThumbShape(enabledThumbRadius:7),overlayShape:SliderComponentShape.noOverlay,trackHeight:3),
          child:Slider(value:prog,onChanged:(v)=>_ctrl?.seekTo(Duration(milliseconds:(v*_dur.inMilliseconds).toInt())))),
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          GestureDetector(onTap:(){SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft,DeviceOrientation.landscapeRight]);SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);},child:const Row(children:[Icon(Icons.zoom_out_map,color:Colors.white,size:20),SizedBox(width:4),Text('Zoom',style:TextStyle(color:Colors.white,fontSize:12))])),
          GestureDetector(onTap:()=>showDialog(context:context,builder:(_)=>AlertDialog(backgroundColor:AppTheme.surface,title:const Text('Calidad',style:TextStyle(color:Colors.white)),content:Column(mainAxisSize:MainAxisSize.min,children:['Auto','1080p','720p','480p','360p'].map((q)=>ListTile(title:Text(q,style:const TextStyle(color:AppTheme.textSecondary)),leading:const Icon(Icons.hd,color:AppTheme.accentCyan),onTap:()=>Navigator.pop(context))).toList()))),child:const Row(children:[Icon(Icons.settings_outlined,color:Colors.white,size:20),SizedBox(width:4),Text('Ajustes',style:TextStyle(color:Colors.white,fontSize:12))])),
        ]),
      ])),
    ]);
  }
}
