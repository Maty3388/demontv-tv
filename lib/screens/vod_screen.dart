import 'package:flutter/material.dart';
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
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: SafeArea(child: Column(children: [
      // Header
      Padding(padding: const EdgeInsets.fromLTRB(16,12,16,0),
        child: Row(children: [
          Text(isMovies ? 'Películas' : 'Series', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
        ])),
      // Buscador
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
      // Grid
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
        : _all.isEmpty
          ? Center(child: Text(isMovies ? 'No hay películas' : 'No hay series', style: const TextStyle(color: AppTheme.textHint)))
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.7),
              itemCount: _all.length,
              itemBuilder: (ctx, i) => _ContentCard(content: _all[i]))),
    ])));
}

class _ContentCard extends StatelessWidget {
  final Content content;
  const _ContentCard({required this.content});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentPlayerScreen(content: content))),
    child: Container(
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          child: content.posterUrl.isNotEmpty
            ? Image.network(content.posterUrl, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie_outlined, color: AppTheme.textHint, size: 30)))
            : const Center(child: Icon(Icons.movie_outlined, color: AppTheme.textHint, size: 30)))),
        Padding(padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
          child: Text(content.title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ])));
}
