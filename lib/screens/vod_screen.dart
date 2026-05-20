import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'content_player_screen.dart';

class VodScreen extends StatefulWidget {
  final String type;
  const VodScreen({super.key, required this.type});
  @override State<VodScreen> createState() => _State();
}

class _State extends State<VodScreen> {
  List<Content> _featured = [], _all = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();
  int _featuredIdx = 0;

  bool get isMovies => widget.type == 'movies';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await ApiService.loadToken();
      if (isMovies) {
        _featured = await ApiService.getMovies(featuredOnly: true);
        _all = await ApiService.getMovies(search: _search.isEmpty ? null : _search);
      } else {
        _featured = await ApiService.getSeries(featuredOnly: true);
        _all = await ApiService.getSeries(search: _search.isEmpty ? null : _search);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: SafeArea(child: _loading
      ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
      : CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _searchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _carousel()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(left: 16, bottom: 12), child: _GradientText('INGRESOS NUEVOS'))),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.65),
              delegate: SliverChildBuilderDelegate((ctx, i) => _ContentCard(content: _all[i % _all.length]), childCount: _all.isEmpty ? 0 : _all.length))),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ])),
  );

  Widget _header() => Padding(padding: const EdgeInsets.fromLTRB(16,12,16,0),
    child: Row(children: [
      const Icon(Icons.all_inclusive, color: Colors.white, size: 24),
      const SizedBox(width: 8),
      const Text('DemonTv Plus', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const Spacer(),
      Container(width: 40, height: 40,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.logoGradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.person_outline, color: Colors.white, size: 22)),
    ]));

  Widget _searchBar() => Padding(padding: const EdgeInsets.fromLTRB(16,14,16,0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('¡Bienvenido!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
      const Text('Listo para disfrutar', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)),
      const SizedBox(height: 14),
      TextField(controller: _searchCtrl, onChanged: (v) { _search = v; _load(); },
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: AppTheme.textHint), hintText: '¿Qué querés ver hoy?',
          suffixIcon: _search.isNotEmpty ? IconButton(onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); _load(); }, icon: const Icon(Icons.close, color: AppTheme.textHint)) : null)),
    ]));

  Widget _carousel() {
    if (_featured.isEmpty) return const SizedBox.shrink();
    return Stack(children: [
      Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.2, colors: [Color(0xFF1A1A2E), AppTheme.background])))),
      CarouselSlider.builder(
        itemCount: _featured.length,
        options: CarouselOptions(height: 260, enlargeCenterPage: true, enlargeFactor: 0.2, autoPlay: true, autoPlayInterval: const Duration(seconds: 4), viewportFraction: 0.55, onPageChanged: (i, _) => setState(() => _featuredIdx = i)),
        itemBuilder: (ctx, i, _) {
          final item = _featured[i];
          final isCenter = i == _featuredIdx;
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentPlayerScreen(content: item))),
            child: AnimatedContainer(duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(vertical: isCenter ? 8 : 20),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                boxShadow: isCenter ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))] : []),
              child: ClipRRect(borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(imageUrl: item.posterUrl, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.surface, child: const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan, strokeWidth: 2))),
                  errorWidget: (_, __, ___) => Container(color: AppTheme.surface, child: const Icon(Icons.movie, color: AppTheme.textHint, size: 40))))));
        }),
    ]);
  }
}

class _ContentCard extends StatelessWidget {
  final Content content;
  const _ContentCard({required this.content});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentPlayerScreen(content: content))),
    child: Stack(children: [
      ClipRRect(borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(imageUrl: content.posterUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: AppTheme.surface),
          errorWidget: (_, __, ___) => Container(color: AppTheme.surface, child: const Icon(Icons.movie_outlined, color: AppTheme.textHint, size: 30)))),
      if (content.type == ContentType.series)
        Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
          child: const Text('SERIES', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)))),
    ]),
  );
}

class _GradientText extends StatelessWidget {
  final String text;
  const _GradientText(this.text);
  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (b) => const LinearGradient(colors: [AppTheme.accentCyan, AppTheme.accentYellow], begin: Alignment.centerLeft, end: Alignment.centerRight).createShader(b),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.5)));
}
