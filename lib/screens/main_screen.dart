import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'live_tv_screen.dart';
import 'vod_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _State();
}

class _State extends State<MainScreen> {
  int _idx = 0;
  bool _sidebarVisible = true;
  bool _profileExpanded = false;
  bool _sidebarFocused = true;
  int _sidebarPos = 0;
  String _userEmail = '';
  String _userExpiry = '';
  static const String _adultPin = '1234';

  final _screens = const [
    HomeScreen(),
    LiveTvScreen(),
    VodScreen(type: 'movies'),
    VodScreen(type: 'series'),
    LiveTvScreen(),
    SettingsScreen(),
  ];

  final _navLabels = ['Inicio', 'TV en Vivo', 'Peliculas', 'Series', 'Adultos'];
  final _navIcons = [Icons.home_outlined, Icons.live_tv_outlined, Icons.movie_outlined, Icons.video_library_outlined, Icons.eighteen_up_rating_outlined];
  final _navActiveIcons = [Icons.home, Icons.live_tv, Icons.movie, Icons.video_library, Icons.eighteen_up_rating];
  final _bottomLabels = ['Borrar Historial', 'Actualizar Lista', 'Cerrar Sesion'];
  final _bottomIcons = [Icons.history_outlined, Icons.refresh_outlined, Icons.logout];

  int get _totalItems => 1 + _navLabels.length + _bottomLabels.length; // 1 = Mi Perfil

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userEmail  = prefs.getString('userEmail') ?? '';
        _userExpiry = prefs.getString('userExpiry') ?? '';
      });
    } catch (_) {}
  }

  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    if (!_sidebarVisible) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.contextMenu) {
        setState(() { _sidebarVisible = true; _sidebarFocused = true; });
      }
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_sidebarPos > 0) setState(() => _sidebarPos--);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_sidebarPos < _totalItems - 1) setState(() => _sidebarPos++);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() { _sidebarVisible = false; _sidebarFocused = false; });
    } else if (event.logicalKey == LogicalKeyboardKey.select ||
               event.logicalKey == LogicalKeyboardKey.enter) {
      _selectItem(_sidebarPos);
    }
  }

  void _selectItem(int pos) {
    if (pos == 0) {
      setState(() => _profileExpanded = !_profileExpanded);
      return;
    }
    final navPos = pos - 1;
    if (navPos < _navLabels.length) {
      if (navPos == 4) { _showAdultPin(); return; }
      setState(() { _idx = navPos; _sidebarVisible = false; _sidebarFocused = false; });
      return;
    }
    final bottomPos = navPos - _navLabels.length;
    switch (bottomPos) {
      case 0: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historial borrado'), backgroundColor: AppTheme.accentCyan)); break;
      case 1: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lista actualizada'), backgroundColor: AppTheme.accentCyan)); break;
      case 2: ApiService.clearToken(); Navigator.pushReplacementNamed(context, '/login'); break;
    }
  }

  void _showAdultPin() {
    final pin = TextEditingController();
    String? error;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Contenido Adultos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock, color: AppTheme.accentCyan, size: 48),
          const SizedBox(height: 16),
          TextField(controller: pin, obscureText: true, keyboardType: TextInputType.number,
            maxLength: 4, textAlign: TextAlign.center, autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(counterText: '', filled: true, fillColor: const Color(0xFF2A2A2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              errorText: error)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () {
            if (pin.text == _adultPin) { Navigator.pop(ctx); setState(() { _idx = 4; _sidebarVisible = false; }); }
            else set(() => error = 'PIN incorrecto');
          }, child: const Text('ENTRAR', style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold))),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: FocusNode(),
    autofocus: _sidebarVisible,
    onKey: _sidebarVisible ? _handleKey : (_) {},
    child: Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _sidebarVisible ? 240 : 0,
          child: _sidebarVisible ? _buildSidebar() : const SizedBox()),
        Expanded(child: IndexedStack(index: _idx, children: _screens)),
      ]),
    ),
  );

  Widget _buildSidebar() => Container(
    width: 240,
    color: const Color(0xFF0A0A0A),
    child: Column(children: [
      const SizedBox(height: 20),
      // Logo
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.logoGradient), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('D+', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 10),
          const Text('DemonTv Plus', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ])),
      const Divider(color: Colors.white12),
      // Mi Perfil
      _buildItem(0, Icons.account_circle_outlined, 'Mi Perfil', isProfile: true),
      if (_profileExpanded) Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.email_outlined, color: AppTheme.textSecondary, size: 12), const SizedBox(width: 4), Expanded(child: Text(_userEmail, style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis))]),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 12), const SizedBox(width: 4), Text('Vence: $_userExpiry', style: const TextStyle(color: AppTheme.accentCyan, fontSize: 10))]),
        ])),
      const Divider(color: Colors.white12),
      // Nav items
      ...List.generate(_navLabels.length, (i) => _buildItem(i + 1, _navIcons[i], _navLabels[i], activeIcon: _navActiveIcons[i], isSelected: i == _idx, isAdult: i == 4)),
      const Divider(color: Colors.white12),
      // Bottom items
      ...List.generate(_bottomLabels.length, (i) => _buildItem(i + 1 + _navLabels.length, _bottomIcons[i], _bottomLabels[i], isBottom: true)),
      const Spacer(),
      Padding(padding: const EdgeInsets.all(8),
        child: Text('↑↓ Navegar  OK Seleccionar  → Contenido', style: TextStyle(color: AppTheme.textHint.withOpacity(0.5), fontSize: 9), textAlign: TextAlign.center)),
    ]),
  );

  Widget _buildItem(int pos, IconData icon, String label, {IconData? activeIcon, bool isSelected = false, bool isBottom = false, bool isProfile = false, bool isAdult = false}) {
    final isFocused = _sidebarPos == pos && _sidebarVisible;
    return GestureDetector(
      onTap: () { setState(() => _sidebarPos = pos); _selectItem(pos); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFocused ? AppTheme.accentCyan.withOpacity(0.25) : isSelected ? AppTheme.accentCyan.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isFocused ? Border.all(color: AppTheme.accentCyan, width: 2) : null),
        child: Row(children: [
          Icon(isSelected && activeIcon != null ? activeIcon : icon,
            color: isBottom ? AppTheme.accentRed : isFocused || isSelected ? AppTheme.accentCyan : AppTheme.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(
            color: isBottom ? AppTheme.accentRed : isFocused || isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
            fontSize: 13, fontWeight: isFocused || isSelected ? FontWeight.bold : FontWeight.normal))),
          if (isProfile) Icon(_profileExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppTheme.accentCyan, size: 16),
          if (isAdult) const Icon(Icons.lock, color: Colors.orange, size: 13),
        ]),
      ),
    );
  }
}
