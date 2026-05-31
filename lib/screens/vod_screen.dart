import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  List<Content> _all = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();
  int _catIdx = 0;
  int _itemIdx = 0;
  final Map<int, ScrollController> _rowCtrls = {};
  final _listCtrl = ScrollController();
  final _focusNode = FocusNode();

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
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (isMovies) _all = await ApiService.getMovies(search: _search.isEmpty ? null : _search);
      else _all = await ApiService.getSeries(search: _search.isEmpty ? null : _search);
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
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(canPop: false, onPopInvoked: (_) { widget.onBack?.call() ?? Navigator.maybePop(context); }, child: Scaffold(
    backgroundColor: AppTheme.background,
    body: Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (_, e) { _handleKey(e); return KeyEventResult.ignored; },
      child: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16,12,16,8),
          child: Row(children: [
            Text(isMovies ? 'Películas' : 'Series', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const Spacer(),
          ])),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
          : _all.isEmpty
            ? Center(child: Text(isMovies ? 'No hay películas' : 'No hay series', style: const TextStyle(color: AppTheme.textHint)))
            : ListView(
                controller: _listCtrl,
                padding: const EdgeInsets.only(bottom: 20),
                children: _grouped.entries.toList().asMap().entries.map((entry) {
                  final catI = entry.key;
                  final e = entry.value;
                  return _CategoryRow(
                    category: e.key,
                    items: e.value,
                    selectedIdx: catI == _catIdx ? _itemIdx : -1,
                    scrollCtrl: _rowCtrls.putIfAbsent(catI, () => ScrollController()),
                    onTap: (c) => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentPlayerScreen(content: c))),
                  );
                }).toList())),
      ]))));
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
    Padding(padding: const EdgeInsets.fromLTRB(16,16,16,8),
      child: Row(children: [
        Text(category, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFD700), Colors.transparent])))),
      ])),
    SizedBox(height: 150, child: ListView.builder(
      controller: scrollCtrl,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => onTap(items[i]),
        child: Container(
          width: 90, margin: const EdgeInsets.only(right: 8),
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
          ]))))),
  ]);
}
