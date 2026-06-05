import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});
  @override State<LiveTvScreen> createState() => _State();
}

class _State extends State<LiveTvScreen> {
  List<Channel> _channels = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _showSearch = false;
  int _catIdx = 0;
  int _chIdx = 0;
  final List<FocusNode> _catFocusNodes = [];
  final List<List<FocusNode>> _chFocusNodes = [];
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadWithToken();
  }

  Future<void> _loadWithToken() async {
    await ApiService.loadToken();
    _load();
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    for (final f in _catFocusNodes) f.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _scrollCtrl.dispose();
    for (final row in _chFocusNodes) for (final f in row) f.dispose();
    super.dispose();
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final channels = await ApiService.getChannels(search: _search.isEmpty ? null : _search);
      const catOrder = [
        'EVENTOS', 'ARGENTINA', 'ARGENTINA INTERIOR', 'DEPORTES', 'NOTICIAS',
        'MÚSICA', 'RELIGIÓN', 'INFANTILES', 'CINE', 'CANALES 24/7', 'PLUTOTV',
        'PARAGUAY', 'BRASIL', 'CHILE', 'URUGUAY', 'MEXICO', 'COLOMBIA',
        'INTERNACIONAL', 'DESTACADOS', 'DOCUMENTALES', 'ADULTOS',
      ];
      channels.sort((a, b) {
        final ai = catOrder.indexWhere((c) => c.toLowerCase() == a.category.toLowerCase());
        final bi = catOrder.indexWhere((c) => c.toLowerCase() == b.category.toLowerCase());
        final av = ai == -1 ? 999 : ai;
        final bv = bi == -1 ? 999 : bi;
        if (av != bv) return av.compareTo(bv);
        return (a.number ?? 999).compareTo(b.number ?? 999);
      });
      setState(() {
        _channels = channels;
        _catFocusNodes.clear();
        _chFocusNodes.clear();
        for (int i = 0; i < _grouped.length; i++) {
          _catFocusNodes.add(FocusNode());
          _chFocusNodes.add(List.generate(_grouped.values.elementAt(i).length, (_) => FocusNode()));
        }
      });
    } catch (_) {}
    setState(() => _loading = false);
    if (_chFocusNodes.isNotEmpty && _chFocusNodes[0].isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) FocusScope.of(context).requestFocus(_chFocusNodes[0][0]);
        });
      });
    }
  }

  Map<String, List<Channel>> get _grouped {
    final map = <String, List<Channel>>{};
    for (final ch in _channels) map.putIfAbsent(ch.category, () => []).add(ch);
    return map;
  }


  Color _channelColor(String name) {
    final colors = [
      [0xFFFF8C00, 0xFFFFB347], // naranja
      [0xFFE53935, 0xFFEF9A9A], // rojo
      [0xFF8E24AA, 0xFFCE93D8], // violeta
      [0xFF1E88E5, 0xFF90CAF9], // azul
      [0xFF00897B, 0xFF80CBC4], // verde
      [0xFFD81B60, 0xFFF48FB1], // rosa
      [0xFF6D4C41, 0xFFBCAAA4], // marron
      [0xFF3949AB, 0xFF9FA8DA], // indigo
    ];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return Color(colors[idx][0]);
  }

  Color _channelColorLight(String name) {
    final colors = [
      [0xFFFF8C00, 0xFFFFB347],
      [0xFFE53935, 0xFFEF9A9A],
      [0xFF8E24AA, 0xFFCE93D8],
      [0xFF1E88E5, 0xFF90CAF9],
      [0xFF00897B, 0xFF80CBC4],
      [0xFFD81B60, 0xFFF48FB1],
      [0xFF6D4C41, 0xFFBCAAA4],
      [0xFF3949AB, 0xFF9FA8DA],
    ];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return Color(colors[idx][1]);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _chFocusNodes.isNotEmpty && _catIdx < _chFocusNodes.length) {
          final row = _chFocusNodes[_catIdx];
          if (_chIdx < row.length) FocusScope.of(context).requestFocus(row[_chIdx]);
        }
      });
    }
  }

  void _handleChannelKey(int catI, int chI, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final cats = _grouped.values.toList();
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final nextCh = chI + 1;
      if (nextCh < cats[catI].length) {
        FocusScope.of(context).requestFocus(_chFocusNodes[catI][nextCh]);
        setState(() { _catIdx = catI; _chIdx = nextCh; });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final prevCh = chI - 1;
      if (prevCh >= 0) {
        FocusScope.of(context).requestFocus(_chFocusNodes[catI][prevCh]);
        setState(() { _catIdx = catI; _chIdx = prevCh; });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final nextCat = catI + 1;
      if (nextCat < cats.length && _chFocusNodes[nextCat].isNotEmpty) {
        FocusScope.of(context).requestFocus(_chFocusNodes[nextCat][0]);
        setState(() { _catIdx = nextCat; _chIdx = 0; });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (catI == 0) {
        setState(() => _showSearch = true);
        FocusScope.of(context).requestFocus(_searchFocus);
      } else {
        final prevCat = catI - 1;
        if (_chFocusNodes[prevCat].isNotEmpty) {
          FocusScope.of(context).requestFocus(_chFocusNodes[prevCat][0]);
          setState(() { _catIdx = prevCat; _chIdx = 0; });
          _scrollCtrl.animateTo(prevCat * 160.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      }
    } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
      final channel = cats[catI][chI];
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel))).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _chFocusNodes.isNotEmpty && _catIdx < _chFocusNodes.length) {
            final row = _chFocusNodes[_catIdx];
            if (_chIdx < row.length) FocusScope.of(context).requestFocus(row[_chIdx]);
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: SafeArea(child: Column(children: [
      // Header con busqueda
      Padding(padding: const EdgeInsets.fromLTRB(16,12,16,8),
        child: Row(children: [
          const Text('TV en Vivo', style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const Spacer(),
          GestureDetector(
            onTap: () { setState(() => _showSearch = !_showSearch); if (_showSearch) FocusScope.of(context).requestFocus(_searchFocus); },
            child: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _showSearch ? const Color(0xFFFF8C00).withOpacity(0.2) : AppTheme.surface, borderRadius: BorderRadius.circular(10),
                border: _showSearch ? Border.all(color: const Color(0xFFFF8C00)) : null),
              child: Icon(Icons.search, color: _showSearch ? const Color(0xFFFF8C00) : AppTheme.textSecondary, size: 22))),
        ])),
      // Barra de busqueda
      if (_showSearch) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: _searchCtrl, focusNode: _searchFocus,
          onChanged: (v) { setState(() => _search = v); _load(); },
          onSubmitted: (_) { setState(() => _showSearch = false); if (_chFocusNodes.isNotEmpty && _chFocusNodes[0].isNotEmpty) FocusScope.of(context).requestFocus(_chFocusNodes[0][0]); },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
            hintText: 'Buscar canal...',
            filled: true, fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: _search.isNotEmpty ? IconButton(onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); _load(); }, icon: const Icon(Icons.close, color: AppTheme.textHint)) : null))),
      const SizedBox(height: 8),
      // Lista de canales
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: const Color(0xFFFF8C00)))
        : _channels.isEmpty
          ? const Center(child: Text('Sin canales', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView(padding: const EdgeInsets.only(bottom: 20),
              children: _grouped.entries.toList().asMap().entries.map((entry) {
                final catI = entry.key;
                final cat = entry.value.key;
                final channels = entry.value.value;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.fromLTRB(16,16,16,10),
                    child: Text(cat, style: const TextStyle(color: const Color(0xFFFF8C00), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
                  SizedBox(height: 130, child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: channels.length,
                    itemBuilder: (ctx, chI) {
                      final ch = channels[chI];
                      final isFocused = _catIdx == catI && _chIdx == chI;
                      if (catI >= _chFocusNodes.length || chI >= _chFocusNodes[catI].length) {
                        return const SizedBox();
                      }
                      return Focus(
                        focusNode: _chFocusNodes[catI][chI],
                        onFocusChange: (v) { if (v) setState(() { _catIdx = catI; _chIdx = chI; }); },
                        onKeyEvent: (node, event) { _handleChannelKey(catI, chI, event); return KeyEventResult.handled; },
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch))),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: isFocused ? 140 : 120,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                                colors: isFocused ? [_channelColor(ch.name), _channelColorLight(ch.name)] : [_channelColor(ch.name).withOpacity(0.7), _channelColorLight(ch.name).withOpacity(0.5)]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isFocused ? Colors.white : Colors.transparent, width: isFocused ? 2 : 0),
                              boxShadow: isFocused ? [BoxShadow(color: _channelColor(ch.name).withOpacity(0.5), blurRadius: 16)] : null),
                              SizedBox(width: 70, height: 70, child: ClipRRect(borderRadius: BorderRadius.circular(10),
                                child: ch.logoUrl.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: ch.logoUrl, fit: BoxFit.contain,
                                      placeholder: (_, __) => Container(color: AppTheme.surfaceAlt, child: const Icon(Icons.tv, color: AppTheme.textHint)),
                                      errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceAlt, child: const Icon(Icons.tv, color: AppTheme.textHint)))
                                  : Container(color: AppTheme.surfaceAlt, child: const Icon(Icons.tv, color: AppTheme.textHint, size: 30)))),
                              const SizedBox(height: 8),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(ch.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: isFocused ? Colors.white : AppTheme.textSecondary, fontSize: 11, fontWeight: isFocused ? FontWeight.bold : FontWeight.w500))),
                            ])),
                        ),
                      );
                    })),
                ]);
              }).toList())),
    ])),
  );
}
