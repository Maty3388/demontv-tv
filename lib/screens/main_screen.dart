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
  int _sidebarIdx = 2;
  bool _inContent = false;
  bool _profileExpanded = false;
  String _userEmail = "";
  String _userExpiry = "";
  static const String _adultPin = "1234";
  final _menuItems = [
    {'label': 'Mi Perfil',    'icon': Icons.person_outline},
    {'label': 'Inicio',       'icon': Icons.home_outlined},
    {'label': 'TV en Vivo',   'icon': Icons.live_tv_outlined},
    {'label': 'Peliculas',    'icon': Icons.movie_outlined},
    {'label': 'Series',       'icon': Icons.video_library_outlined},
    {'label': 'Adultos',      'icon': Icons.eighteen_up_rating_outlined},
    {'label': 'Historial',    'icon': Icons.history_outlined},
    {'label': 'Actualizar',   'icon': Icons.refresh_outlined},
    {'label': 'Cerrar Sesion','icon': Icons.logout},
  ];

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
        if (_sidebarIdx > 0) setState(() => _sidebarIdx--);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_sidebarIdx < _menuItems.length - 1) setState(() => _sidebarIdx++);
      } else if (event.logicalKey == LogicalKeyboardKey.select ||
                 event.logicalKey == LogicalKeyboardKey.enter ||
                 event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _selectItem();
      }
    } else {
      if (event.logicalKey == LogicalKeyboardKey.goBack) {
        setState(() => _inContent = false);
      }
    }
  }

  void _selectItem() {
    switch (_sidebarIdx) {
      case 5: _showAdultPin(); break;
      case 6: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Historial borrado"), backgroundColor: AppTheme.accentCyan)); break;
      case 7: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lista actualizada"), backgroundColor: AppTheme.accentCyan)); break;
      case 8: ApiService.clearToken(); Navigator.pushReplacementNamed(context, "/login"); break;
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
            if (pin.text == _adultPin) { Navigator.pop(ctx); setState(() { _sidebarIdx = 4; _inContent = true; }); }
            else set(() => error = "PIN incorrecto");
          }, child: const Text("ENTRAR", style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold))),
        ],
      ),
    ));
  }

  Widget _buildContent() {
    switch (_sidebarIdx) {
      case 1: return _TVChannelGrid(onBack: () => setState(() => _inContent = false));
      case 2: return const VodScreen(type: "movies");
      case 3: return const VodScreen(type: "series");
      case 4: return _TVChannelGrid(onBack: () => setState(() => _inContent = false));
      default: return const SizedBox();
    }
  }


  Widget _buildHomeContent() => Container(
    color: AppTheme.background,
    child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A0A2E), Color(0xFF0A0A0A)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bienvenido', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const Text('que queres ver hoy?', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ])),
      const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text('TV en Vivo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
      const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Text('Selecciona TV en Vivo desde el menu lateral para ver los canales', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14))),
    ])),
  );

  Widget _buildHome() => Container(
    color: AppTheme.background,
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 100, height: 100,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.logoGradient), borderRadius: BorderRadius.circular(24)),
        child: const Center(child: Text("D+", style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)))),
      const SizedBox(height: 24),
      const Text("DemonTv Plus", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text("Selecciona una opcion del menu lateral", style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
    ])),
  );

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: FocusNode()..requestFocus(),
    autofocus: true,
    onKey: _onKey,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Row(children: [
        Container(
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
            Container(margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Row(children: [const Icon(Icons.person_outline, color: AppTheme.accentCyan, size: 13), const SizedBox(width: 4), Expanded(child: Text(_userEmail, style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis))]),
                const SizedBox(height: 2),
                Row(children: [const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 11), const SizedBox(width: 4), Text("Vence: $_userExpiry", style: const TextStyle(color: AppTheme.accentCyan, fontSize: 10))]),
              ])),
            const Divider(color: Colors.white12),
            Expanded(child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (ctx, i) {
                final item = _menuItems[i];
                final isFocused = _sidebarIdx == i && !_inContent;
                final isSelected = _sidebarIdx == i && _inContent;
                final isRed = i >= 5;
                return GestureDetector(
                  onTap: () { setState(() { _sidebarIdx = i; _inContent = false; }); _selectItem(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isFocused ? AppTheme.accentCyan.withOpacity(0.2) : isSelected ? AppTheme.accentCyan.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isFocused ? Border.all(color: AppTheme.accentCyan, width: 2) : null),
                    child: Row(children: [
                      Icon(item["icon"] as IconData, color: isRed ? AppTheme.accentRed : isFocused || isSelected ? AppTheme.accentCyan : AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item["label"] as String, style: TextStyle(color: isRed ? AppTheme.accentRed : isFocused || isSelected ? AppTheme.accentCyan : AppTheme.textSecondary, fontSize: 13, fontWeight: isFocused || isSelected ? FontWeight.bold : FontWeight.normal))),
                      if (i == 4) const Icon(Icons.lock, color: Colors.orange, size: 12),
                    ]),
                  ),
                );
              },
            )),
            Padding(padding: const EdgeInsets.all(8),
              child: Text(_inContent ? "Apreta Atras para volver" : "Flechas navegar  OK entrar",
                style: TextStyle(color: AppTheme.textHint.withOpacity(0.5), fontSize: 9), textAlign: TextAlign.center)),
          ])),
        Expanded(child: _inContent ? _buildContent() : _buildHome()),
      ]),
    ),
  );
}

class _TVChannelGrid extends StatefulWidget {
  final VoidCallback onBack;
  final bool adult;
  const _TVChannelGrid({required this.onBack, this.adult = false});
  @override State<_TVChannelGrid> createState() => _TVChannelGridState();
}

class _TVChannelGridState extends State<_TVChannelGrid> {
  List<Channel> _channels = [];
  bool _loading = true;
  int _selectedIdx = 0;
  final _scrollCtrl = ScrollController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    await ApiService.loadToken();
    try {
      final channels = await ApiService.getChannels();
      setState(() { _channels = channels; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _onKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    const cols = 4;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_selectedIdx % cols == 0) {
        widget.onBack();
      } else {
        setState(() => _selectedIdx--);
        _scrollToSelected();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_selectedIdx < _channels.length - 1) {
        setState(() => _selectedIdx++);
        _scrollToSelected();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_selectedIdx + cols < _channels.length) {
        setState(() => _selectedIdx += cols);
        _scrollToSelected();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_selectedIdx - cols >= 0) {
        setState(() => _selectedIdx -= cols);
        _scrollToSelected();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.select ||
               event.logicalKey == LogicalKeyboardKey.enter) {
      if (_channels.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: _channels[_selectedIdx])));
      }
    } else if (event.logicalKey == LogicalKeyboardKey.goBack) {
      widget.onBack();
    }
  }

  void _scrollToSelected() {
    const cols = 4;
    const itemHeight = 160.0;
    final row = (_selectedIdx / cols).floor();
    _scrollCtrl.animateTo(row * itemHeight, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
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
        : _channels.isEmpty
          ? const Center(child: Text("Sin canales", style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)))
          : Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(children: [
                  const Icon(Icons.live_tv, color: AppTheme.accentCyan, size: 22),
                  const SizedBox(width: 8),
                  const Text("TV en Vivo", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text("${_selectedIdx + 1} / ${_channels.length}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ])),
              Expanded(child: GridView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4),
                itemCount: _channels.length,
                itemBuilder: (ctx, i) {
                  final ch = _channels[i];
                  final isSelected = i == _selectedIdx;
                  return GestureDetector(
                    onTap: () { setState(() => _selectedIdx = i); Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch))); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accentCyan.withOpacity(0.2) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.accentCyan : AppTheme.border, width: isSelected ? 2.5 : 0.5),
                        boxShadow: isSelected ? [BoxShadow(color: AppTheme.accentCyan.withOpacity(0.4), blurRadius: 16)] : null),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        ch.logoUrl.isNotEmpty
                          ? Image.network(ch.logoUrl, width: 60, height: 45, fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: AppTheme.textHint, size: 32))
                          : const Icon(Icons.tv, color: AppTheme.textHint, size: 32),
                        const SizedBox(height: 8),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(ch.name, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                      ]),
                    ),
                  );
                },
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: const Color(0xFF0A0A0A),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Text(_channels[_selectedIdx].name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Text("<- Volver al menu   OK Reproducir", style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                ]),
              ),
            ]),
    ),
  );
}
