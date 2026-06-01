import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'content_player_screen.dart';

class VodScreen extends StatefulWidget {
  final String type;
  final VoidCallback? onBack;
  const VodScreen({super.key, required this.type, this.onBack});
  @override State<VodScreen> createState() => _VodState();
}

class _VodState extends State<VodScreen> {
  List<Content> _featured = [];
  List<Content> _all = [];
  bool _loading = true;
  int _carouselIdx = 0;
  int _catIdx = 0;
  int _itemIdx = 0;
  final Map<int, ScrollController> _rowCtrls = {};
  final _listCtrl = ScrollController();
  final _focusNode = FocusNode();
  Timer? _carouselTimer;

  bool get isMovies => widget.type == 'movies';

  Map<String, List<Content>> get _grouped {
    final map = <String, List<Content>>{};
    for (final c in _all) map.putIfAbsent(c.category ?? 'Otros', () => []).add(c);
    return map;
  }

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_featured.isNotEmpty && mounted) setState(() => _carouselIdx = (_carouselIdx + 1) % _featured.length);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _listCtrl.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (isMovies) {
        _featured = await ApiService.getMovies(featuredOnly: true);
        _all = await ApiService.getMovies();
      } else {
        _featured = await ApiService.getSeries(featuredOnly: true);
        _all = await ApiService.getSeries();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent || _all.isEmpty) return;
    final cats = _grouped.keys.toList();
    final items = _grouped[cats[_catIdx]]!;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_itemIdx < items.length - 1) setState(() => _itemIdx++);
      _rowCtrls[_catIdx]?.animateTo(_itemIdx * 98.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_itemIdx > 0) setState(() => _itemIdx--);
      _rowCtrls[_catIdx]?.animateTo(_itemIdx * 98.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_catIdx < cats.length - 1) setState(() { _catIdx++; _itemIdx = 0; });
      _listCtrl.animateTo(_catIdx * 180.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_catIdx > 0) setState(() { _catIdx--; _itemIdx = 0; });
      _listCtrl.animateTo(_catIdx * 180.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
      final c = items[_itemIdx];
      Navigator.push(context, MaterialPageRoute(builder: (_) => ContentPlayerScreen(content: c)));
    } else if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) {
      widget.onBack?.call();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (_, e) { _handleKey(e); return KeyEventResult.ignored; },
      child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
        : ListView(controller: _listCtrl, padding: const EdgeInsets.only(bottom: 20), children: [
            // Header
            Padding(padding: const EdgeInsets.fromLTRB(16,16,16,4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isMovies ? 'Bienvenido' : 'Series', style: const TextStyle(color: AppTheme.accentCyan, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(isMovies ? 'Listo para disfrutar 🍿' : '¿Qué serie querés ver?', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ])),
            // Carousel
            if (_featured.isNotEmpty) ...[
              CarouselSlider(
                options: CarouselOptions(
                  height: 200, autoPlay: true, enlargeCenterPage: true,
                  viewportFraction: 0.85, autoPlayInterval: const Duration(seconds: 4),
                  onPageChanged: (i, _) => setState(() => _carouselIdx = i)),
                items: _featured.map((c) => GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentPlayerScreen(content: c))),
                  child: ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: Stack(fit: StackFit.expand, children: [
                      CachedNetworkImage(imageUrl: c.posterUrl, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: AppTheme.surface, child: const Icon(Icons.movie, color: AppTheme.textHint, size: 60))),
                      Positioned(bottom: 0, left: 0, right: 0, child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent])),
                        child: Text(c.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis))),
                    ])))).toList()),
              // Indicadores
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_featured.length, (i) => Container(
                width: i == _carouselIdx ? 16 : 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                decoration: BoxDecoration(color: i == _carouselIdx ? AppTheme.accentCyan : Colors.white24, borderRadius: BorderRadius.circular(3))))),
            ],
            // Categorías
            ..._grouped.entries.toList().asMap().entries.map((entry) {
              final catI = entry.key;
              final e = entry.value;
              return _CategoryRow(
                category: e.key, items: e.value,
                selectedIdx: catI == _catIdx ? _itemIdx : -1,
                scrollCtrl: _rowCtrls.putIfAbsent(catI, () => ScrollController()),
                onTap: (c) => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentPlayerScreen(content: c))),
              );
            }).toList(),
          ])));
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final List<Content> items;
  final Function(Content) onTap;
  final int selectedIdx;
  final ScrollController scrollCtrl;
  const _CategoryRow({required this.category, required this.items, required this.onTap, this.selectedIdx = -1, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16,16,16,8), child: Row(children: [
      Text(category, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
      const SizedBox(width: 8),
      Expanded(child: Container(height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFD700), Colors.transparent])))),
    ])),
    SizedBox(height: 150, child: ListView.builder(
      controller: scrollCtrl, scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => onTap(items[i]),
        child: Container(width: 90, margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: i == selectedIdx ? AppTheme.accentCyan.withOpacity(0.2) : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: i == selectedIdx ? AppTheme.accentCyan : Colors.transparent, width: 1.5)),
          child: Column(children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: items[i].posterUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: items[i].posterUrl, fit: BoxFit.cover, width: double.infinity,
                    errorWidget: (_, __, ___) => const Icon(Icons.movie, color: AppTheme.textHint))
                : const Center(child: Icon(Icons.movie, color: AppTheme.textHint)))),
            Padding(padding: const EdgeInsets.all(4),
              child: Text(items[i].title, style: const TextStyle(color: Colors.white, fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
          ])))),
  ]);
}
