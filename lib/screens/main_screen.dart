import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final List<FocusNode> _navFocus = List.generate(9, (_) => FocusNode());

  final _screens = const [
    HomeScreen(),
    LiveTvScreen(),
    VodScreen(type: 'movies'),
    VodScreen(type: 'series'),
    SettingsScreen(),
  ];

  final _navItems = const [
    _NavData(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
    _NavData(icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv, label: 'TV en Vivo'),
    _NavData(icon: Icons.movie_outlined, activeIcon: Icons.movie, label: 'Peliculas'),
    _NavData(icon: Icons.video_library_outlined, activeIcon: Icons.video_library, label: 'Series'),
    _NavData(icon: Icons.eighteen_up_rating_outlined, activeIcon: Icons.eighteen_up_rating, label: 'Adultos'),
  ];

  final _bottomItems = const [
    _NavData(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Borrar Historial'),
    _NavData(icon: Icons.refresh_outlined, activeIcon: Icons.refresh, label: 'Actualizar Lista'),
    _NavData(icon: Icons.logout, activeIcon: Icons.logout, label: 'Cerrar Sesion'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_navFocus[0]);
    });
  }

  @override
  void dispose() {
    for (final f in _navFocus) f.dispose();
    super.dispose();
  }

  void _handleNavKey(int i, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final next = i + 1;
      if (next < _navFocus.length) FocusScope.of(context).requestFocus(_navFocus[next]);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final prev = i - 1;
      if (prev >= 0) FocusScope.of(context).requestFocus(_navFocus[prev]);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() => _sidebarVisible = false);
    } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
      if (i < _navItems.length) {
        setState(() { _idx = i; _sidebarVisible = false; });
      } else {
        _handleAction(i - _navItems.length);
      }
    }
  }

  void _handleAction(int i) {
    switch (i) {
      case 0: // Borrar historial
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historial borrado'), backgroundColor: AppTheme.accentCyan));
        break;
      case 1: // Actualizar lista
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lista actualizada'), backgroundColor: AppTheme.accentCyan));
        break;
      case 2: // Cerrar sesion
        ApiService.clearToken();
        Navigator.pushReplacementNamed(context, '/login');
        break;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft && !_sidebarVisible) {
          setState(() => _sidebarVisible = true);
          FocusScope.of(context).requestFocus(_navFocus[_idx]);
        }
      },
      child: Row(children: [
        // Barra lateral
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: _sidebarVisible ? 240 : 0,
          child: _sidebarVisible ? _buildSidebar() : const SizedBox(),
        ),
        // Contenido
        Expanded(child: IndexedStack(index: _idx, children: _screens)),
      ]),
    ),
  );

  Widget _buildSidebar() => Container(
    width: 240,
    decoration: BoxDecoration(
      color: const Color(0xFF0A0A0A),
      border: Border(right: BorderSide(color: AppTheme.border, width: 0.5))),
    child: Column(children: [
      const SizedBox(height: 30),
      // Logo
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.logoGradient), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('D+', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 10),
          const Text('DemonTv Plus', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ])),
      const SizedBox(height: 10),
      const Divider(color: Colors.white12),
      // Nav items
      ...List.generate(_navItems.length, (i) => _buildNavItem(i, _navItems[i], i == _idx)),
      const Divider(color: Colors.white12),
      // Bottom items
      ...List.generate(_bottomItems.length, (i) => _buildNavItem(i + _navItems.length, _bottomItems[i], false, isBottom: true)),
      const Spacer(),
      // Hint
      Padding(padding: const EdgeInsets.all(12),
        child: Text('← Ocultar | → Navegar', style: TextStyle(color: AppTheme.textHint.withOpacity(0.6), fontSize: 10), textAlign: TextAlign.center)),
    ]),
  );

  Widget _buildNavItem(int i, _NavData data, bool isSelected, {bool isBottom = false}) => Focus(
    focusNode: _navFocus[i],
    onFocusChange: (v) => setState(() {}),
    onKeyEvent: (node, event) {
      _handleNavKey(i, event);
      return KeyEventResult.handled;
    },
    child: Builder(builder: (ctx) {
      final focused = _navFocus[i].hasFocus;
      return GestureDetector(
        onTap: () {
          if (i < _navItems.length) setState(() { _idx = i; _sidebarVisible = false; });
          else _handleAction(i - _navItems.length);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: focused ? AppTheme.accentCyan.withOpacity(0.2) : isSelected ? AppTheme.accentCyan.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: focused ? Border.all(color: AppTheme.accentCyan, width: 1.5) : null),
          child: Row(children: [
            Icon(isSelected ? data.activeIcon : data.icon,
              color: isBottom ? AppTheme.accentRed : isSelected || focused ? AppTheme.accentCyan : AppTheme.textSecondary, size: 20),
            const SizedBox(width: 10),
            Text(data.label, style: TextStyle(
              color: isBottom ? AppTheme.accentRed : isSelected || focused ? AppTheme.accentCyan : AppTheme.textSecondary,
              fontSize: 14, fontWeight: isSelected || focused ? FontWeight.bold : FontWeight.normal)),
          ]),
        ),
      );
    }),
  );
}

class _NavData {
  final IconData icon, activeIcon;
  final String label;
  const _NavData({required this.icon, required this.activeIcon, required this.label});
}
