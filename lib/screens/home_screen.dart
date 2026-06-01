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
  List<Channel> _tvCanales = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await ApiService.loadToken();
      final movies = await ApiService.getMovies(featuredOnly: true);
      final estrenos = await ApiService.getMovies(category: 'Estrenos 2026');
      final series = await ApiService.getSeries(featuredOnly: true);
      final deportes = await ApiService.getChannels(category: 'DEPORTES');
      final tvCanales = await ApiService.getChannels(category: 'ARGENTINA');
      if (mounted) setState(() {
        _movies = movies;
        _estrenos = estrenos;
        _series = series;
        _deportes = deportes.take(15).toList();
        _tvCanales = tvCanales.take(15).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan));
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accentCyan,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        if (_tvCanales.isNotEmpty) ...[_buildTitle('📺 TV en Vivo'), SliverToBoxAdapter(child: _buildChannelRow(_tvCanales))],
        if (_movies.isNotEmpty) ...[_buildTitle('⭐ Recomendados'), SliverToBoxAdapter(child: _buildMovieRow(_movies))],
        if (_estrenos.isNotEmpty) ...[_buildTitle('🎬 Estrenos 2026'), SliverToBoxAdapter(child: _buildMovieRow(_estrenos))],
        if (_series.isNotEmpty) ...[_buildTitle('📺 Series'), SliverToBoxAdapter(child: _buildMovieRow(_series))],
        if (_deportes.isNotEmpty) ...[_buildTitle('⚽ Deportes'), SliverToBoxAdapter(child: _buildChannelRow(_deportes))],
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ]),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Bienvenido', style: TextStyle(color: Color(0xFF7B2FFF), fontSize: 16, fontWeight: FontWeight.bold)),
      const Text('¿Qué querés ver hoy?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    ]),
  );

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

  Widget _buildChannelRow(List<Channel> items) => SizedBox(height: 90,
    child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => PlayerScreen(channel: items[i], playlist: items, initialIndex: i))),
        child: Container(width: 120, margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF2E2E2E))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CachedNetworkImage(imageUrl: items[i].logoUrl, height: 45, width: 80, fit: BoxFit.contain,
              errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54, size: 30)),
            const SizedBox(height: 4),
            Text(items[i].name, style: const TextStyle(color: Colors.white, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ])))));

  Widget _buildTitle(String title) => SliverToBoxAdapter(
    child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(children: [
        Text(title, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFD700), Colors.transparent])))),
      ])));
}
