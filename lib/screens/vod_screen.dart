import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  List<Content> _all = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();
  int _catIdx = 0;
  int _itemIdx = 0;
  final _scrollCtrl = ScrollController();

  bool get isMovies => widget.type == 'movies';
  bool get isAdult => widget.type == 'adult';

  Map<String, List<Content>> get _grouped {
    final map = <String, List<Content>>{};
    for (final c in _all) map.putIfAbsent(c.category ?? 'Sin categoría', () => []).add(c);
    return map;
  }

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (isMovies) _all = await ApiService.getMovies(search: _search.isEmpty ? null : _search);
      else _all = await ApiService.getSeries(search: _search.isEmpty ? null : _search);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16,12,16,8),
        child: Row(children: [
          Text(isMovies ? 'Películas' : 'Series', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _search = _search.isEmpty ? ' ' : ''),
            child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.search, color: AppTheme.textSecondary, size: 22))),
        ])),
      if (_search.isNotEmpty || _searchCtrl.text.isNotEmpty)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(controller: _searchCtrl, autofocus: true, onChanged: (v) { _search = v; _load(); },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
              hintText: isMovies ? 'Buscar película...' : 'Buscar serie...',
              filled: true, fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              hintStyle: const TextStyle(color: AppTheme.textHint),
              suffixIcon: IconButton(onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); _load(); }, icon: const Icon(Icons.close, color: AppTheme.textHint))))),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
        : _all.isEmpty
          ? Center(child: Text(isMovies ? 'No hay películas' : 'No hay series', style: const TextStyle(color: AppTheme.textHint)))
          : ListView(controller: _scrollCtrl, padding: const EdgeInsets.only(bottom: 20),
              children: _grouped.entries.map((e) => _CategoryRow(
                category: e.key,
                items: e.value,
                onTap: (c) => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentPlayerScreen(content: c))),
              )).toList())),
    ])));
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final List<Content> items;
  final Function(Content) onTap;
  const _CategoryRow({required this.category, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16,16,16,8),
      child: Row(children: [
        Text(category, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFD700), Colors.transparent])))),
      ])),
    SizedBox(height: 150, child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => onTap(items[i]),
        child: Container(
          width: 90, margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: items[i].posterUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: items[i].posterUrl, fit: BoxFit.cover, width: double.infinity,
                    errorWidget: (_, __, ___) => const Icon(Icons.movie, color: AppTheme.textHint))
                : const Center(child: Icon(Icons.movie, color: AppTheme.textHint)))),
            Padding(padding: const EdgeInsets.all(4),
              child: Text(items[i].title, style: const TextStyle(color: Colors.white, fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
          ]))))),
  ]);
}
