import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _State();
}

class _State extends State<HomeScreen> {
  List<dynamic> _channels = [];
  List<dynamic> _movies = [];
  List<dynamic> _series = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWithToken();
  }

  Future<void> _loadWithToken() async {
    await ApiService.loadToken();
    _load();
  }

  Future<void> _load() async {
    try {
      final channels = await ApiService.getChannels();
      final movies = await ApiService.getMovies(featuredOnly: true);
      final series = await ApiService.getSeries(featuredOnly: true);
      setState(() {
        _channels = channels.map((c) => {
          'name': c.name, 'logo': c.logoUrl, 'id': c.id,
          'stream_url': c.streamUrl, 'headers': c.headers, 'is_live': c.isLive
        }).toList();
        _movies = movies.map((m) => {
          'title': m.title, 'poster': m.posterUrl, 'id': m.id, 'stream_url': m.streamUrl
        }).toList();
        _series = series.map((s) => {
          'title': s.title, 'poster': s.posterUrl, 'id': s.id
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
      : RefreshIndicator(onRefresh: _load, color: AppTheme.accentCyan,
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            if (_channels.isNotEmpty) ...[
              _SectionTitle(title: '📺 TV en Vivo'),
              SliverToBoxAdapter(child: _buildChannels()),
            ],
            if (_movies.isNotEmpty) ...[
              _SectionTitle(title: '🎬 Películas Destacadas'),
              SliverToBoxAdapter(child: _buildMovies()),
            ],
            if (_series.isNotEmpty) ...[
              _SectionTitle(title: '📱 Series Destacadas'),
              SliverToBoxAdapter(child: _buildSeries()),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ])),
  );

  Widget _buildHero() => Container(
    height: 220,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [const Color(0xFF1A0A2E), AppTheme.background])),
    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.logoGradient), borderRadius: BorderRadius.circular(10)),
          child: const Center(child: Text('D+', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))),
        const SizedBox(width: 10),
        const Text('DemonTv Plus', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
      const Spacer(),
      ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF7B2FFF), Color(0xFFFF6B9D)],
        ).createShader(bounds),
        child: Text('Bienvenido', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
      const Text('¿Qué querés ver hoy?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildChannels() => SizedBox(height: 90,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _channels.length,
      itemBuilder: (ctx, i) {
        final ch = _channels[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(ctx, '/player', arguments: ch),
          child: Container(
            width: 120, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (ch['logo']?.isNotEmpty == true)
                ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(imageUrl: ch['logo'], width: 50, height: 40, fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(Icons.tv, color: AppTheme.textHint, size: 30)))
              else const Icon(Icons.tv, color: AppTheme.textHint, size: 30),
              const SizedBox(height: 6),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(ch['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
            ])));
      }));

  Widget _buildMovies() => SizedBox(height: 180,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _movies.length,
      itemBuilder: (ctx, i) {
        final m = _movies[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(ctx, '/content', arguments: m),
          child: Container(
            width: 110, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: m['poster']?.isNotEmpty == true
                  ? CachedNetworkImage(imageUrl: m['poster'], fit: BoxFit.cover, width: double.infinity,
                      errorWidget: (_, __, ___) => const Icon(Icons.movie, color: AppTheme.textHint, size: 40))
                  : const Center(child: Icon(Icons.movie, color: AppTheme.textHint, size: 40)))),
              Padding(padding: const EdgeInsets.all(6),
                child: Text(m['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ])));
      }));

  Widget _buildSeries() => SizedBox(height: 180,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _series.length,
      itemBuilder: (ctx, i) {
        final s = _series[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(ctx, '/content', arguments: s),
          child: Container(
            width: 110, margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: s['poster']?.isNotEmpty == true
                  ? CachedNetworkImage(imageUrl: s['poster'], fit: BoxFit.cover, width: double.infinity,
                      errorWidget: (_, __, ___) => const Icon(Icons.tv, color: AppTheme.textHint, size: 40))
                  : const Center(child: Icon(Icons.tv, color: AppTheme.textHint, size: 40)))),
              Padding(padding: const EdgeInsets.all(6),
                child: Text(s['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ])));
      }));
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF7B2FFF), Color(0xFFFF6B9D)],
        ).createShader(bounds),
        child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
}
