import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'player_screen.dart';
import '../services/update_checker.dart';
import 'vod_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainState();
}

class _MainState extends State<MainScreen> {
  // Sidebar: 0=MiPerfil 1=TVenVivo 2=Peliculas 3=Series 4=Adultos 5=Historial 6=Actualizar 7=CerrarSesion
  int _sideIdx = 1;
  bool _inContent = false;
  bool _profileExpanded = false;
  bool _sidebarCollapsed = false;
  String _userEmail = "";
  String _userExpiry = "";
  static const String _adultPin = "1234";

  @override
  void initState() { super.initState(); _loadProfile(); WidgetsBinding.instance.addPostFrameCallback((_) { UpdateChecker.check(context); }); }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail  = prefs.getString("userEmail") ?? "";
      _userExpiry = prefs.getString("userExpiry") ?? "";
    });
  }

  void _onKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    if (!_inContent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_sideIdx > 0) setState(() => _sideIdx--);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_sideIdx < 7) setState(() => _sideIdx++);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                 event.logicalKey == LogicalKeyboardKey.select ||
                 event.logicalKey == LogicalKeyboardKey.enter) {
        _selectItem();
      }
    } else {
      if (event.logicalKey == LogicalKeyboardKey.goBack) {
        setState(() => _inContent = false);
      }
    }
  }

  void _selectItem() {
    switch (_sideIdx) {
      case 0: setState(() => _profileExpanded = !_profileExpanded); break;
      case 4: _showAdultPin(); break;
      case 5: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Historial borrado"), backgroundColor: AppTheme.accentCyan)); break;
      case 6: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lista actualizada"), backgroundColor: AppTheme.accentCyan)); break;
      case 7: ApiService.clearToken(); Navigator.pushReplacementNamed(context, "/login"); break;
      default: setState(() => _inContent = true);
    }
  }

  void _showAdultPin() {
    final pin = TextEditingController();
    String? error;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Contenido Adultos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock, color: AppTheme.accentCyan, size: 48),
          const SizedBox(height: 16),
          TextField(controller: pin, obscureText: true, keyboardType: TextInputType.number,
            maxLength: 4, textAlign: TextAlign.center, autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(counterText: "", filled: true, fillColor: const Color(0xFF2A2A2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              errorText: error)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () {
            if (pin.text == _adultPin) { Navigator.pop(ctx); setState(() { _sideIdx = 4; _inContent = true; }); }
            else set(() => error = "PIN incorrecto");
          }, child: const Text("ENTRAR", style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold))),
        ],
      ),
    ));
  }

  Widget _buildContent() {
    switch (_sideIdx) {
      case 1: return _TVLiveScreen(onBack: () => setState(() => _inContent = false), collapsed: _sidebarCollapsed);
      case 2: return const VodScreen(type: "movies");
      case 3: return const VodScreen(type: "series");
      case 4: return _TVLiveScreen(onBack: () => setState(() => _inContent = false), collapsed: _sidebarCollapsed);
      default: return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: FocusNode()..requestFocus(),
    autofocus: true,
    onKey: _onKey,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Row(children: [
        _buildSidebar(),
        Expanded(child: _inContent ? _buildContent() : _buildWelcome()),
      ]),
    ),
  );

  Widget _buildWelcome() => Container(
    color: AppTheme.background,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A2E), Color(0xFF0A0A1A)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Bienvenido a", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 2),
          const Text("DemonTv Plus", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Selecciona una opcion del menu con las flechas", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
      Expanded(child: _WelcomeChannels(onPlay: (ch, playlist, idx) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch, playlist: playlist, initialIndex: idx)));
      })),
    ]),
  );

  Widget _buildSidebar() {
    final items = [
      _SItem(0, Icons.person_outline, "Mi Perfil", isProfile: true),
      _SItem(1, Icons.live_tv_outlined, "TV en Vivo"),
      _SItem(2, Icons.movie_outlined, "Peliculas"),
      _SItem(3, Icons.video_library_outlined, "Series"),
      _SItem(4, Icons.eighteen_up_rating_outlined, "Adultos", isAdult: true),
      _SItem(5, Icons.history_outlined, "Historial", isRed: true),
      _SItem(6, Icons.refresh_outlined, "Actualizar", isRed: true),
      _SItem(7, Icons.logout, "Cerrar Sesion", isRed: true),
    ];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _sidebarCollapsed ? 60 : 200,
      color: const Color(0xFF0D0D0D),
      child: Column(children: [
        const SizedBox(height: 20),
        // Logo
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Container(width: 34, height: 34,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.logoGradient), borderRadius: BorderRadius.circular(9)),
              child: const Center(child: Text("D+", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)))),
            if (!_sidebarCollapsed) ...[const SizedBox(width: 8), const Expanded(child: Text("DemonTv Plus", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))],
          ])),
        const Divider(color: Colors.white12),
        Expanded(child: ListView(
          children: items.map((item) {
            final isFocused = _sideIdx == item.idx && !_inContent;
            final isSelected = _sideIdx == item.idx && _inContent;
            return Column(children: [
              GestureDetector(
                onTap: () { setState(() { _sideIdx = item.idx; _inContent = false; }); _selectItem(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  padding: EdgeInsets.symmetric(horizontal: _sidebarCollapsed ? 8 : 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: isFocused ? AppTheme.accentCyan.withOpacity(0.2) : isSelected ? AppTheme.accentCyan.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isFocused ? Border.all(color: AppTheme.accentCyan, width: 1.5) : null),
                  child: Row(mainAxisAlignment: _sidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
                    Icon(item.icon, color: item.isRed ? AppTheme.accentRed : isFocused || isSelected ? AppTheme.accentCyan : AppTheme.textSecondary, size: 18),
                    if (!_sidebarCollapsed) ...[const SizedBox(width: 8),
                      Expanded(child: Text(item.label, style: TextStyle(color: item.isRed ? AppTheme.accentRed : isFocused || isSelected ? AppTheme.accentCyan : AppTheme.textSecondary, fontSize: 12, fontWeight: isFocused || isSelected ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis)),
                      if (item.isProfile) Icon(_profileExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppTheme.accentCyan, size: 14),
                      if (item.isAdult) const Icon(Icons.lock, color: Colors.orange, size: 11),
                    ],
                  ]),
                ),
              ),
              if (item.isProfile && _profileExpanded && !_sidebarCollapsed) Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Row(children: [const Icon(Icons.email_outlined, color: AppTheme.accentCyan, size: 11), const SizedBox(width: 4), Expanded(child: Text(_userEmail, style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis))]),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 10), const SizedBox(width: 4), Text("Vence: $_userExpiry", style: const TextStyle(color: AppTheme.accentCyan, fontSize: 10))]),
                ])),
            ]);
          }).toList(),
        )),
        // Boton colapsar
        GestureDetector(
          onTap: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(_sidebarCollapsed ? Icons.chevron_right : Icons.chevron_left, color: AppTheme.textHint, size: 18))),
      ]),
    );
  }
}

class _SItem {
  final int idx;
  final IconData icon;
  final String label;
  final bool isRed, isProfile, isAdult;
  const _SItem(this.idx, this.icon, this.label, {this.isRed=false, this.isProfile=false, this.isAdult=false});
}

class _TVLiveScreen extends StatefulWidget {
  final VoidCallback onBack;
  final bool collapsed;
  const _TVLiveScreen({required this.onBack, this.collapsed = false});
  @override State<_TVLiveScreen> createState() => _TVLiveState();
}

class _TVLiveState extends State<_TVLiveScreen> {
  List<Channel> _all = [];
  Map<String, List<Channel>> _grouped = {};
  bool _loading = true;
  int _catIdx = 0;
  int _chIdx = 0;
  String _search = "";
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final Map<int, ScrollController> _rowCtrls = {};
  final Map<int, GlobalKey> _catKeys = {};

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    for (final c in _rowCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await ApiService.loadToken();
    try {
      final channels = await ApiService.getChannels(search: _search.isEmpty ? null : _search);
      final grouped = <String, List<Channel>>{};
      for (final ch in channels) grouped.putIfAbsent(ch.category, () => []).add(ch);
      setState(() { _all = channels; _grouped = grouped; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _onKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    final cats = _grouped.keys.toList();
    if (cats.isEmpty) return;
    final curCh = _grouped[cats[_catIdx]] ?? [];
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_chIdx > 0) { setState(() => _chIdx--); _scrollRow(); }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_chIdx < curCh.length - 1) { setState(() => _chIdx++); _scrollRow(); }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_catIdx < cats.length - 1) { setState(() { _catIdx++; _chIdx = 0; }); _scrollCat(); }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_catIdx > 0) { setState(() { _catIdx--; _chIdx = 0; }); _scrollCat(); }
      else if (_catIdx == 0) { setState(() => _showSearch = true); }
    } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
      if (curCh.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: curCh[_chIdx], playlist: curCh, initialIndex: _chIdx)));
    } else if (event.logicalKey == LogicalKeyboardKey.goBack) {
      widget.onBack();
    }
  }

  void _scrollCat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _catKeys[_catIdx];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(key!.currentContext!, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.1);
      }
    });
  }

  void _scrollRow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = _rowCtrls[_catIdx];
      if (ctrl != null && ctrl.hasClients) {
        ctrl.animateTo(_chIdx * 115.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: FocusNode()..requestFocus(),
    autofocus: true,
    onKey: _onKey,
    child: Container(
      color: AppTheme.background,
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A0A2E), Color(0xFF0A0A0A)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.live_tv, color: AppTheme.accentCyan, size: 18),
              const SizedBox(width: 8),
              const Text("TV en Vivo", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text("${_all.length} canales", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _showSearch = !_showSearch),
                child: Container(padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: _showSearch ? AppTheme.accentCyan.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: _showSearch ? Border.all(color: AppTheme.accentCyan) : null),
                  child: Icon(Icons.search, color: _showSearch ? AppTheme.accentCyan : AppTheme.textSecondary, size: 18))),
            ]),
            if (_showSearch) ...[const SizedBox(height: 10),
              TextField(
                controller: _searchCtrl, autofocus: true,
                onChanged: (v) { _search = v; _load(); },
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                  hintText: "Buscar canal...",
                  hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
                  filled: true, fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.close, color: AppTheme.textHint, size: 16), onPressed: () { _searchCtrl.clear(); _search = ""; _load(); }) : null)),
            ],
          ])),
        // Lista de categorias
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
          : _all.isEmpty
            ? const Center(child: Text("Sin canales", style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)))
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _grouped.length,
                itemBuilder: (ctx, catIdx) {
                  final cat = _grouped.keys.elementAt(catIdx);
                  final channels = _grouped[cat]!;
                  return Column(key: (_catKeys[catIdx] ??= GlobalKey()), crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(children: [
                        AnimatedContainer(duration: const Duration(milliseconds: 200), width: 3, height: 16,
                          decoration: BoxDecoration(color: catIdx == _catIdx ? AppTheme.accentCyan : Colors.transparent, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text(cat, style: TextStyle(color: catIdx == _catIdx ? AppTheme.accentCyan : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ])),
                    SizedBox(height: 110, child: ListView.builder(
                      controller: (_rowCtrls[catIdx] ??= ScrollController()),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: channels.length,
                      itemBuilder: (ctx, chIdx) {
                        final ch = channels[chIdx];
                        final sel = catIdx == _catIdx && chIdx == _chIdx;
                        return GestureDetector(
                          onTap: () { setState(() { _catIdx = catIdx; _chIdx = chIdx; }); Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch, playlist: channels, initialIndex: chIdx))); },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: sel ? 120 : 105,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.accentCyan.withOpacity(0.15) : AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: sel ? AppTheme.accentCyan : AppTheme.border, width: sel ? 2 : 0.5),
                              boxShadow: sel ? [BoxShadow(color: AppTheme.accentCyan.withOpacity(0.3), blurRadius: 10)] : null),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              ch.logoUrl.isNotEmpty
                                ? Image.network(ch.logoUrl, width: 52, height: 38, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: AppTheme.textHint, size: 28))
                                : const Icon(Icons.tv, color: AppTheme.textHint, size: 28),
                              const SizedBox(height: 6),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(ch.name, style: TextStyle(color: sel ? Colors.white : AppTheme.textSecondary, fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                            ]),
                          ),
                        );
                      })),
                  ]);
                })),
        // Info bar
        if (!_loading && _all.isNotEmpty) Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF0A0A0A),
          child: Row(children: [
            Builder(builder: (ctx) {
              final cats = _grouped.keys.toList();
              final ch = cats.isNotEmpty && _catIdx < cats.length
                ? (_grouped[cats[_catIdx]] ?? []).elementAtOrNull(_chIdx)
                : null;
              return Row(children: [
                const Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 14),
                const SizedBox(width: 6),
                Text(ch?.name ?? "", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                if (ch != null) Text("  •  ${ch.category}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ]);
            }),
            const Spacer(),
            const Text("<- Volver   OK Reproducir", style: TextStyle(color: AppTheme.textHint, fontSize: 10)),
          ])),
      ]),
    ),
  );
}

class _WelcomeChannels extends StatefulWidget {
  final Function(Channel, List<Channel>, int) onPlay;
  const _WelcomeChannels({required this.onPlay});
  @override State<_WelcomeChannels> createState() => _WelcomeChannelsState();
}

class _WelcomeChannelsState extends State<_WelcomeChannels> {
  Map<String, List<Channel>> _grouped = {};
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    await ApiService.loadToken();
    try {
      final channels = await ApiService.getChannels();
      final grouped = <String, List<Channel>>{};
      for (final ch in channels) grouped.putIfAbsent(ch.category, () => []).add(ch);
      if (mounted) setState(() { _grouped = grouped; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => _loading
    ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
    : _grouped.isEmpty
      ? const Center(child: Text("No hay canales", style: TextStyle(color: AppTheme.textSecondary)))
      : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _grouped.length,
          itemBuilder: (ctx, catIdx) {
            final cat = _grouped.keys.elementAt(catIdx);
            final channels = _grouped[cat]!;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(children: [
                  Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.accentCyan, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text(cat, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                ])),
              SizedBox(height: 110, child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: channels.length,
                itemBuilder: (ctx, chIdx) {
                  final ch = channels[chIdx];
                  return GestureDetector(
                    onTap: () => widget.onPlay(ch, channels, chIdx),
                    child: Container(
                      width: 105, margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border, width: 0.5)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        ch.logoUrl.isNotEmpty
                          ? Image.network(ch.logoUrl, width: 52, height: 38, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: AppTheme.textHint, size: 28))
                          : const Icon(Icons.tv, color: AppTheme.textHint, size: 28),
                        const SizedBox(height: 6),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(ch.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                      ]),
                    ),
                  );
                })),
            ]);
          });
}
