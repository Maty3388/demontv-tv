import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'content_player_screen.dart';

class VodScreen extends StatefulWidget {
  final String type;
  const VodScreen({super.key, required this.type});
  @override State<VodScreen> createState() => _VodState();
}

class _VodState extends State<VodScreen> {
  List<Content> _all = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();
  int _selectedIdx = 0;
  final int _cols = 5;
  final List<GlobalKey> _keys = [];

  bool get isMovies => widget.type == 'movies';

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await ApiService.loadToken();
      if (isMovies) {
        _all = await ApiService.getMovies(search: _search.isEmpty ? null : _search);
      } else {
        _all = await ApiService.getSeries(search: _search.isEmpty ? null : _search);
      }
      _keys.clear();
      _keys.addAll(List.generate(_all.length, (_) => GlobalKey()));
      _selectedIdx = 0;
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent || _all.isEmpty) return;
    final len = _all.length;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() => _selectedIdx = (_selectedIdx + 1) % len);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() => _selectedIdx = (_selectedIdx - 1 + len) % len);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _selectedIdx = (_selectedIdx + _cols) < len ? _selectedIdx + _cols : _selectedIdx);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _selectedIdx = (_selectedIdx - _cols) >= 0 ? _selectedIdx - _cols : _selectedIdx);
    } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ContentPlayerScreen(content: _all[_selectedIdx])));
    }
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: FocusNode()..requestFocus(),
    onKey: _handleKey,
    child: Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16,12,16,0),
          child: Row(children: [
            Text(isMovies ? 'Películas' : 'Series', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
          ])),
        Padding(padding: const EdgeInsets.fromLTRB(16,12,16,8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) { _search = v; _load(); },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppTheme.textHint, size: 20),
              hintText: isMovies ? 'Buscar película...' : 'Buscar serie...',
              hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
              filled: true, fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.close, color: AppTheme.textHint, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); _load(); }) : null))),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
          : _all.isEmpty
            ? Center(child: Text(isMovies ? 'No hay películas' : 'No hay series', style: const TextStyle(color: AppTheme.textHint)))
            : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 0.65),
                itemCount: _all.length,
                itemBuilder: (ctx, i) => _ContentCard(
                  content: _all[i],
                  selected: i == _selectedIdx,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentPlayerScreen(content: _all[i])))))),
      ]))));
}

class _ContentCard extends StatelessWidget {
  final Content content;
  final bool selected;
  final VoidCallback onTap;
  const _ContentCard({required this.content, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? AppTheme.accentCyan : Colors.transparent, width: 2),
        boxShadow: selected ? [BoxShadow(color: AppTheme.accentCyan.withOpacity(0.4), blurRadius: 10)] : []),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          child: content.posterUrl.isNotEmpty
            ? Image.network(content.posterUrl, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie_outlined, color: AppTheme.textHint, size: 30)))
            : const Center(child: Icon(Icons.movie_outlined, color: AppTheme.textHint, size: 30)))),
        Padding(padding: const EdgeInsets.fromLTRB(6,4,6,6),
          child: Text(content.title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ])));
}
