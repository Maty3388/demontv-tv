import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'player_screen.dart';
import 'content_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  List<Content> _movies = [];
  List<Content> _estrenos = [];
  List<Content> _series = [];
  List<Channel> _deportes = [];
  List<Channel> _featured = [];
  final PageController _pageCtrl = PageController(viewportFraction: 0.85);
  int _pageIdx = 0;
  Timer? _autoScrollTimer;
  bool _loading = true;
  static const _orange = Color(0xFFFF8C00);
  static const _orangeLight = Color(0xFFFFB347);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      await ApiService.loadToken();
      final movies   = await ApiService.getMovies(featuredOnly: true);
      final estrenos = await ApiService.getMovies(category: 'Estrenos 2026');
      final series   = await ApiService.getSeries(featuredOnly: true);
      final deportes = await ApiService.getChannels(category: 'Deportes');
      final featured = await ApiService.getChannels(featured: true);
      if (mounted) setState(() {
        _movies   = movies;
        _estrenos = estrenos;
        _series   = series;
        _deportes = deportes.take(15).toList();
        _featured = featured.take(10).toList();
        _startAutoScroll();
        _loading  = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _channelColor(String name) {
    final colors = [0xFFFF8C00, 0xFFE53935, 0xFF8E24AA, 0xFF1E88E5, 0xFF00897B, 0xFFD81B60, 0xFF6D4C41, 0xFF3949AB];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return Color(colors[idx]);
  }

  Color _channelColorLight(String name) {
    final colors = [0xFFFFB347, 0xFFEF9A9A, 0xFFCE93D8, 0xFF90CAF9, 0xFF80CBC4, 0xFFF48FB1, 0xFFBCAAA4, 0xFF9FA8DA];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return Color(colors[idx]);
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _featured.isEmpty) return;
      final next = (_pageIdx + 1) % _featured.length;
      _pageCtrl.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator(color: _orange));
    return RefreshIndicator(
      onRefresh: _load,
      color: _orange,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        if (_featured.isNotEmpty) SliverToBoxAdapter(child: _buildCarousel()),
        if (_movies.isNotEmpty)   ...[_buildTitle('Recomendados'),   SliverToBoxAdapter(child: _buildMovieRow(_movies))],
        if (_estrenos.isNotEmpty) ...[_buildTitle('Estrenos 2026'),  SliverToBoxAdapter(child: _buildMovieRow(_estrenos))],
        if (_series.isNotEmpty)   ...[_buildTitle('Series'),          SliverToBoxAdapter(child: _buildMovieRow(_series))],
        if (_deportes.isNotEmpty) ...[_buildTitle('Deportes'),        SliverToBoxAdapter(child: _buildChannelRow(_deportes))],
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Bienvenido', style: TextStyle(color: _orange, fontSize: 16, fontWeight: FontWeight.bold)),
      const Text('Que queres ver hoy?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    ]));

  Widget _buildCarousel() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(children: [
        const Text('Destacados', style: TextStyle(color: _orange, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: [_orange, Colors.transparent])))),
      ])),
    SizedBox(height: 180,
      child: PageView.builder(
        controller: _pageCtrl,
        onPageChanged: (i) {
          setState(() => _pageIdx = i);
          // Reiniciar timer al cambiar pagina manualmente
          _startAutoScroll();
        },
        itemCount: _featured.length,
        itemBuilder: (ctx, i) {
          final ch = _featured[i];
          final c1 = _channelColor(ch.name);
          final c2 = _channelColorLight(ch.name);
          return GestureDetector(
            onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch, playlist: _featured, initialIndex: i))),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
                boxShadow: [BoxShadow(color: c1.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Stack(children: [
                if (ch.logoUrl.isNotEmpty) Positioned.fill(
                  child: Padding(padding: const EdgeInsets.all(18),
                    child: CachedNetworkImage(imageUrl: ch.logoUrl, fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54, size: 48)))),
                Positioned(left: 0, right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.85), Colors.transparent])),
                    child: Text(ch.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis))),
                Positioned(top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                    child: const Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
              ])));
        })),
    const SizedBox(height: 8),
    // Dots indicadores
    Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_featured.length, (i) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: _pageIdx == i ? 16 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: _pageIdx == i ? _orange : Colors.white24,
          borderRadius: BorderRadius.circular(3))))),
    const SizedBox(height: 8),
  ]);

  Widget _buildMovieRow(List<Content> items) => SizedBox(height: 180,
    child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ContentPlayerScreen(content: items[i]))),
        child: Container(width: 110, margin: const EdgeInsets.only(right: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(imageUrl: items[i].posterUrl, height: 140, width: 110, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(height: 140, color: const Color(0xFF1A1A1A), child: const Icon(Icons.movie, color: Colors.white54)))),
            const SizedBox(height: 4),
            Text(items[i].title, style: const TextStyle(color: Colors.white, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])))));

  Widget _buildChannelRow(List<Channel> items) => SizedBox(height: 100,
    child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final c1 = _channelColor(items[i].name);
        final c2 = _channelColorLight(items[i].name);
        return GestureDetector(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => PlayerScreen(channel: items[i], playlist: items, initialIndex: i))),
          child: Container(width: 120, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: c1.withOpacity(0.3), blurRadius: 8)]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CachedNetworkImage(imageUrl: items[i].logoUrl, height: 50, width: 80, fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54, size: 30)),
              const SizedBox(height: 4),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(items[i].name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
            ])));
      }));

  Widget _buildTitle(String title) => SliverToBoxAdapter(
    child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(children: [
        Text(title, style: const TextStyle(color: _orange, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: [_orange, Colors.transparent])))),
      ])));
}
