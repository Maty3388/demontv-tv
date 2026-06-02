import 'home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  // Sidebar: 0=MiPerfil 1=Inicio 2=TVenVivo 3=Peliculas 4=Series 5=Adultos 6=Actualizar 7=CerrarSesion
  int _sideIdx = 1;
  bool _inContent = false;
  bool _backHandled = false;
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
      if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) {
        setState(() => _inContent = false);
      }
    }
  }


  void _showExitDialog() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Salir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("¿Deseás salir de DemonTv Plus?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancelar", style: TextStyle(color: Color(0xFF00CFDD)))),
          ElevatedButton(autofocus: true, onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Salir")),
        ]));
    if (exit == true && mounted) SystemNavigator.pop();
  }

  void _selectItem() {
    switch (_sideIdx) {
      case 0: setState(() => _profileExpanded = !_profileExpanded); break;
      case 5: _showAdultPin(); break;
      
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
            onChanged: (v) { if (v.length == 4) { if (v == _adultPin) { ApiService.clearCache(); Navigator.pop(ctx); setState(() { _sideIdx = 5; _inContent = true; }); } else { set(() => error = 'PIN incorrecto'); pin.clear(); } } },
            style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(counterText: "", filled: true, fillColor: const Color(0xFF2A2A2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              errorText: error)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () {
            if (pin.text == _adultPin) { ApiService.clearCache(); Navigator.pop(ctx); setState(() { _sideIdx = 5; _inContent = true; }); }
            else set(() => error = "PIN incorrecto");
          }, child: const Text("ENTRAR", style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold))),
        ],
      ),
    ));
  }

  Widget _buildContent() {
    switch (_sideIdx) {
      case 1: return const HomeScreen();
      case 2: return _TVLiveScreen(onBack: () { _backHandled = true; setState(() => _inContent = false); Future.delayed(const Duration(milliseconds: 600), () => _backHandled = false); }, collapsed: _sidebarCollapsed);
      case 3: return VodScreen(type: "movies", onBack: () { _backHandled = true; setState(() => _inContent = false); Future.delayed(const Duration(milliseconds: 300), () => _backHandled = false); });
      case 4: return VodScreen(type: "series", onBack: () { _backHandled = true; setState(() => _inContent = false); Future.delayed(const Duration(milliseconds: 300), () => _backHandled = false); });
      case 5: return _TVLiveScreen(onBack: () { _backHandled = true; setState(() => _inContent = false); Future.delayed(const Duration(milliseconds: 600), () => _backHandled = false); }, collapsed: _sidebarCollapsed, filterCategory: 'ADULTOS');
      default: return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: FocusNode()..requestFocus(),
    autofocus: true,
    onKey: _onKey,
    child: WillPopScope(
      onWillPop: () async { if (Navigator.canPop(context)) return true; if (_backHandled) { _backHandled = false; return false; } if (_inContent) { setState(() => _inContent = false); return false; } _showExitDialog(); return false; },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Row(children: [
        _buildSidebar(),
        Expanded(child: _inContent ? _buildContent() : const HomeScreen()),
      ]),
      )),
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
      _SItem(1, Icons.home_outlined, "Inicio"),
      _SItem(2, Icons.live_tv_outlined, "TV en Vivo"),
      _SItem(3, Icons.movie_outlined, "Peliculas"),
      _SItem(4, Icons.video_library_outlined, "Series"),
      _SItem(5, Icons.eighteen_up_rating_outlined, "Adultos", isAdult: true),
      
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
  final String? filterCategory;
  const _TVLiveScreen({required this.onBack, this.collapsed = false, this.filterCategory});
  @override State<_TVLiveScreen> createState() => _TVLiveState();
}

class _TVLiveState extends State<_TVLiveScreen> {
  List<Channel> _all = [];
  List<Channel> _featured = [];
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
      final channels = await ApiService.getChannels(search: _search.isEmpty ? null : _search, category: widget.filterCategory);
      if (widget.filterCategory == null) { final feat = await ApiService.getChannels(featured: true); if (mounted) setState(() => _featured = feat); }
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
    } else if (event.logicalKey == LogicalKeyboardKey.goBack || event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onBack(); return;
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
              const Text("TV en Vivo", style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                        Text(cat, style: TextStyle(color: catIdx == _catIdx ? const Color(0xFFFFD700) : const Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFD700), Colors.transparent])))),
                      ])),
                    SizedBox(height: 110, child: ListView.builder(
                      controller: (_rowCtrls[catIdx] ??= ScrollController()),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: channels.length,
                      itemBuilder: (ctx, chIdx) {
                        final ch = channels[chIdx];
                        final sel = catIdx == _catIdx && chIdx == _chIdx;
                        return _ChannelCard(channel: ch, selected: sel, onTap: () { setState(() { _catIdx = catIdx; _chIdx = chIdx; }); Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch, playlist: channels, initialIndex: chIdx))); });
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
                          ? CachedNetworkImage(imageUrl: ch.logoUrl, width: 52, height: 38, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(Icons.tv, color: AppTheme.textHint, size: 28), fadeInDuration: Duration.zero)
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

class _ChannelCard extends StatefulWidget {
  final dynamic channel;
  final bool selected;
  final VoidCallback onTap;
  const _ChannelCard({required this.channel, required this.selected, required this.onTap});
  @override State<_ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<_ChannelCard> {
  static const List<Color> _catColors = [
    Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460),
    Color(0xFF1B262C), Color(0xFF2C003E), Color(0xFF1A0A2E),
    Color(0xFF0D2137), Color(0xFF1E2D40), Color(0xFF2D1B33),
  ];
  
  Color get _bgColor {
    final idx = widget.channel.name.length % _catColors.length;
    return _catColors[idx];
  }

  @override
  void initState() { super.initState(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: widget.selected ? 120 : 105,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: widget.selected ? AppTheme.accentCyan.withOpacity(0.15) : _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.selected ? AppTheme.accentCyan : AppTheme.border, width: widget.selected ? 2 : 0.5),
        boxShadow: widget.selected ? [BoxShadow(color: AppTheme.accentCyan.withOpacity(0.3), blurRadius: 10)] : null),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        widget.channel.logoUrl.isNotEmpty
          ? CachedNetworkImage(imageUrl: widget.channel.logoUrl, width: 52, height: 38, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(Icons.tv, color: AppTheme.textHint, size: 28), fadeInDuration: Duration.zero)
          : const Icon(Icons.tv, color: AppTheme.textHint, size: 28),
        const SizedBox(height: 6),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(widget.channel.name, style: TextStyle(color: widget.selected ? Colors.white : AppTheme.textSecondary, fontSize: 10, fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
      ]),
    ),
  );
}
