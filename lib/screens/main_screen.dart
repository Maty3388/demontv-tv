import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'player_screen.dart';
import 'vod_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _State();
}

class _State extends State<MainScreen> {
  // 0=MiPerfil 1=Inicio 2=TVenvivo 3=Peliculas 4=Series 5=Adultos 6=Historial 7=Actualizar 8=CerrarSesion
  int _idx = 2;
  bool _inContent = false;
  bool _profileExpanded = false;
  String _userEmail = "";
  String _userExpiry = "";
  static const String _adultPin = "1234";

  @override
  void initState() { super.initState(); _loadProfile(); }

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
        if (_idx > 0) setState(() => _idx--);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_idx < 8) setState(() => _idx++);
      } else if (event.logicalKey == LogicalKeyboardKey.select ||
                 event.logicalKey == LogicalKeyboardKey.enter ||
                 event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _selectItem();
      }
    } else {
      if (event.logicalKey == LogicalKeyboardKey.goBack ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() => _inContent = false);
      }
    }
  }

  void _selectItem() {
    switch (_idx) {
      case 0: setState(() => _profileExpanded = !_profileExpanded); break;
      case 1: setState(() => _inContent = true); break;
      case 2: setState(() => _inContent = true); break;
      case 3: setState(() => _inContent = true); break;
      case 4: setState(() => _inContent = true); break;
      case 5: _showAdultPin(); break;
      case 6: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Historial borrado"), backgroundColor: AppTheme.accentCyan)); break;
      case 7: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lista actualizada"), backgroundColor: AppTheme.accentCyan)); break;
      case 8: ApiService.clearToken(); Navigator.pushReplacementNamed(context, "/login"); break;
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
            if (pin.text == _adultPin) { Navigator.pop(ctx); setState(() { _idx = 5; _inContent = true; }); }
            else set(() => error = "PIN incorrecto");
          }, child: const Text("ENTRAR", style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold))),
        ],
      ),
    ));
  }

  Widget _buildContent() {
    switch (_idx) {
      case 1: return _buildHomeContent();
      case 2: return _TVChannelGrid(onBack: () => setState(() => _inContent = false));
      case 3: return const VodScreen(type: "movies");
      case 4: return const VodScreen(type: "series");
      case 5: return _TVChannelGrid(onBack: () => setState(() => _inContent = false));
      default: return const SizedBox();
    }
  }

  Widget _buildHomeContent() => Container(
    color: AppTheme.background,
    padding: const EdgeInsets.all(32),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A0A2E), Color(0xFF0A0A1E)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Bienvenido", style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 4),
          const Text("Que queres ver hoy?", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ])),
      const SizedBox(height: 32),
      const Text("Navegacion", style: TextStyle(color: AppTheme.accentCyan, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
      const SizedBox(height: 12),
      _HelpRow(icon: Icons.arrow_upward, text: "Flecha arriba/abajo: navegar el menu"),
      _HelpRow(icon: Icons.arrow_forward, text: "OK o flecha derecha: entrar al contenido"),
      _HelpRow(icon: Icons.arrow_back, text: "Atras o flecha izquierda: volver al menu"),
      _HelpRow(icon: Icons.tv, text: "TV en Vivo: navegar canales con flechas"),
    ]),
  );

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: FocusNode()..requestFocus(),
    autofocus: true,
    onKey: _onKey,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Row(children: [
        _buildSidebar(),
        Expanded(child: _inContent ? _buildContent() : _buildDefaultHome()),
      ]),
    ),
  );

  Widget _buildDefaultHome() => Container(
    color: AppTheme.background,
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 100, height: 100,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.logoGradient), borderRadius: BorderRadius.circular(24)),
        child: const Center(child: Text("D+", style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 24),
      const Text("DemonTv Plus", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text("Selecciona una opcion del menu", style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
    ])),
  );

  Widget _buildSidebar() {
    final items = [
      _SideItem(0,  Icons.person_outline,           "Mi Perfil",      isProfile: true),
      _SideItem(1,  Icons.home_outlined,            "Inicio"),
      _SideItem(2,  Icons.live_tv_outlined,         "TV en Vivo"),
      _SideItem(3,  Icons.movie_outlined,           "Peliculas"),
      _SideItem(4,  Icons.video_library_outlined,   "Series"),
      _SideItem(5,  Icons.eighteen_up_rating_outlined, "Adultos",   isAdult: true),
      _SideItem(6,  Icons.history_outlined,         "Historial",     isRed: true),
      _SideItem(7,  Icons.refresh_outlined,         "Actualizar",    isRed: true),
      _SideItem(8,  Icons.logout,                   "Cerrar Sesion", isRed: true),
    ];
    return Container(
      width: 220, color: const Color(0xFF0D0D0D),
      child: Column(children: [
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.logoGradient), borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text("D+", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 8),
            const Text("DemonTv Plus", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ])),
        const Divider(color: Colors.white12),
        Expanded(child: ListView(
          children: items.map((item) {
            final isFocused = _idx == item.idx && !_inContent;
            final isSelected = _idx == item.idx && _inContent;
            return Column(children: [
              GestureDetector(
                onTap: () { setState(() { _idx = item.idx; _inContent = false; }); _selectItem(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isFocused ? AppTheme.accentCyan.withOpacity(0.2) : isSelected ? AppTheme.accentCyan.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isFocused ? Border.all(color: AppTheme.accentCyan, width: 2) : null),
                  child: Row(children: [
                    Icon(item.icon, color: item.isRed ? AppTheme.accentRed : isFocused || isSelected ? AppTheme.accentCyan : AppTheme.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.label, style: TextStyle(color: item.isRed ? AppTheme.accentRed : isFocused || isSelected ? AppTheme.accentCyan : AppTheme.textSecondary, fontSize: 13, fontWeight: isFocused || isSelected ? FontWeight.bold : FontWeight.normal))),
                    if (item.isProfile) Icon(_profileExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppTheme.accentCyan, size: 16),
                    if (item.isAdult) const Icon(Icons.lock, color: Colors.orange, size: 12),
                  ]),
                ),
              ),
              // Info perfil expandible
              if (item.isProfile && _profileExpanded) Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Row(children: [const Icon(Icons.email_outlined, color: AppTheme.accentCyan, size: 12), const SizedBox(width: 4), Expanded(child: Text(_userEmail, style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis))]),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 12), const SizedBox(width: 4), Text("Vence: $_userExpiry", style: const TextStyle(color: AppTheme.accentCyan, fontSize: 10))]),
                ]),
              ),
            ]);
          }).toList(),
        )),
        Padding(padding: const EdgeInsets.all(8),
          child: Text(_inContent ? "Atras para volver" : "Flechas navegar  OK entrar",
            style: TextStyle(color: AppTheme.textHint.withOpacity(0.5), fontSize: 9), textAlign: TextAlign.center)),
      ]),
    );
  }
}

class _SideItem {
  final int idx;
  final IconData icon;
  final String label;
  final bool isRed, isProfile, isAdult;
  const _SideItem(this.idx, this.icon, this.label, {this.isRed=false, this.isProfile=false, this.isAdult=false});
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HelpRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, color: AppTheme.accentCyan, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
    ]));
}

class _TVChannelGrid extends StatefulWidget {
  final VoidCallback onBack;
  const _TVChannelGrid({required this.onBack});
  @override State<_TVChannelGrid> createState() => _TVChannelGridState();
}

class _TVChannelGridState extends State<_TVChannelGrid> {
  List<Channel> _all = [];

  Map<String, List<Channel>> _grouped = {};
  bool _loading = true;
  int _catIdx = 0;
  int _chIdx = 0;
  final _scrollCtrl = ScrollController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    await ApiService.loadToken();
    try {
      final channels = await ApiService.getChannels();
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
      if (_chIdx == 0) { widget.onBack(); return; }
      setState(() => _chIdx--);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_chIdx < curCh.length - 1) setState(() => _chIdx++);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_catIdx < cats.length - 1) setState(() { _catIdx++; _chIdx = 0; });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_catIdx > 0) setState(() { _catIdx--; _chIdx = 0; });
    } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
      if (curCh.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: curCh[_chIdx])));
    } else if (event.logicalKey == LogicalKeyboardKey.goBack) {
      widget.onBack();
    }
  }

  void _scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _catIdx * 160.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
      child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
        : _all.isEmpty
          ? const Center(child: Text("Sin canales", style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)))
          : Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(20,16,20,8),
                child: Row(children: [
                  const Icon(Icons.live_tv, color: AppTheme.accentCyan, size: 22),
                  const SizedBox(width: 8),
                  const Text("TV en Vivo", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text("${_all.length} canales", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ])),
              Expanded(child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _grouped.length,
                itemBuilder: (ctx, catIdx) {
                  final cat = _grouped.keys.elementAt(catIdx);
                  final channels = _grouped[cat]!;
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                      child: Text(cat, style: const TextStyle(color: AppTheme.accentCyan, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1))),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3),
                      itemCount: channels.length,
                      itemBuilder: (ctx, i) {
                        final ch = channels[i];
                        final globalIdx = _all.indexOf(ch);
                        final sel = catIdx == _catIdx && i == _chIdx;
                        return GestureDetector(
                          onTap: () { setState(() { _catIdx = catIdx; _chIdx = i; }); Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch))); },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.accentCyan.withOpacity(0.2) : AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: sel ? AppTheme.accentCyan : AppTheme.border, width: sel ? 2.5 : 0.5),
                              boxShadow: sel ? [BoxShadow(color: AppTheme.accentCyan.withOpacity(0.4), blurRadius: 16)] : null),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              ch.logoUrl.isNotEmpty
                                ? Image.network(ch.logoUrl, width: 55, height: 42, fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: AppTheme.textHint, size: 36))
                                : const Icon(Icons.tv, color: AppTheme.textHint, size: 36),
                              const SizedBox(height: 8),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(ch.name, style: TextStyle(color: sel ? Colors.white : AppTheme.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                            ]),
                          ),
                        );
                      }),
                  ]);
                },
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: const Color(0xFF0A0A0A),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Builder(builder: (ctx) { final cats = _grouped.keys.toList(); final ch = cats.isNotEmpty ? (_grouped[cats[_catIdx]] ?? [])[_chIdx.clamp(0, (_grouped[cats[_catIdx]]?.length ?? 1) - 1)] : null; return Row(children: [ const Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 16), const SizedBox(width: 8), Text(ch?.name ?? "", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), Text("  •  \${ch?.category ?? ""}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)), const Spacer(), const Text("<- Volver   OK Reproducir", style: TextStyle(color: AppTheme.textHint, fontSize: 11)), ]); }),
                  const Spacer(),
                  const Text("<- Volver   OK Reproducir", style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                ]),
              ),
            ]),
    ),
  );
}
