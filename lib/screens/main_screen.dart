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
  String _userEmail = '';
  String _userExpiry = '';
  final List<FocusNode> _navFocus = List.generate(12, (_) => FocusNode());
  static const String _adultPin = '1234';

  final _screens = const [
    HomeScreen(),
    LiveTvScreen(),
    VodScreen(type: 'movies'),
    VodScreen(type: 'series'),
    LiveTvScreen(), // Adultos
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
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_navFocus[1]);
    });
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
      if (i == 0) {
        setState(() => _profileExpanded = !_profileExpanded);
      } else if (i <= _navItems.length) {
        final screenIdx = i - 1;
        if (screenIdx == 4) {
          _showAdultPin();
        } else {
          setState(() { _idx = screenIdx; _sidebarVisible = false; });
        }
      } else {
        _handleAction(i - _navItems.length - 1);
      }
    }
  }

  void _showAdultPin() {
    final pin = TextEditingController();
    String? error;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Contenido para Adultos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock, color: AppTheme.accentCyan, size: 48),
          const SizedBox(height: 16),
          const Text('Ingresa el PIN para continuar', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          TextField(
            controller: pin, obscureText: true, keyboardType: TextInputType.number,
            maxLength: 4, textAlign: TextAlign.center, autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              filled: true, fillColor: const Color(0xFF2A2A2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              errorText: error)),
          ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () {
            if (pin.text == _adultPin) {
              Navigator.pop(ctx);
              setState(() { _idx = 4; _sidebarVisible = false; });
            } else {
              set(() => error = 'PIN incorrecto');
            }
          }, child: const Text('ENTRAR', style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold))),
        ],
      ),
    ));
  }

  void _handleAction(int i) {
    switch (i) {
      case 0:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historial borrado'), backgroundColor: AppTheme.accentCyan));
        break;
      case 1:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lista actualizada'), backgroundColor: AppTheme.accentCyan));
        break;
      case 2:
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
          FocusScope.of(context).requestFocus(_navFocus[_idx + 1]);
        }
      },
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: _sidebarVisible ? 240 : 0,
          child: _sidebarVisible ? _buildSidebar() : const SizedBox()),
        Expanded(child: GestureDetector(
        onTap: () {
          setState(() => _sidebarVisible = true);
          FocusScope.of(context).requestFocus(_navFocus[_idx + 1]);
        },
        child: IndexedStack(index: _idx, children: _screens))),
      ]),
    ),
  );

  Widget _buildSidebar() => Container(
    width: 240,
    decoration: BoxDecoration(color: const Color(0xFF0A0A0A), border: Border(right: BorderSide(color: AppTheme.border, width: 0.5))),
    child: Column(children: [
      const SizedBox(height: 20),
      // Mi Perfil (expandible)
      Focus(
        focusNode: _navFocus[0],
        onFocusChange: (v) => setState(() {}),
        onKeyEvent: (node, event) { _handleNavKey(0, event); return KeyEventResult.handled; },
        child: Builder(builder: (ctx) {
          final focused = _navFocus[0].hasFocus;
          return GestureDetector(
            onTap: () => setState(() => _profileExpanded = !_profileExpanded),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: focused ? AppTheme.accentCyan.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: focused ? Border.all(color: AppTheme.accentCyan, width: 1.5) : null),
              child: Row(children: [
                const Icon(Icons.account_circle_outlined, color: AppTheme.accentCyan, size: 20),
                const SizedBox(width: 10),
                const Expanded(child: Text('Mi Perfil', style: TextStyle(color: AppTheme.accentCyan, fontSize: 14, fontWeight: FontWeight.bold))),
                Icon(_profileExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppTheme.accentCyan, size: 18),
              ]),
            ),
          );
        }),
      ),
      // Info del perfil expandible
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: _profileExpanded ? 80 : 0,
        child: _profileExpanded ? Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [const Icon(Icons.email_outlined, color: AppTheme.textSecondary, size: 14), const SizedBox(width: 6), Expanded(child: Text(_userEmail, style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis))]),
            const SizedBox(height: 6),
            Row(children: [const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary, size: 14), const SizedBox(width: 6), Text('Vence: $_userExpiry', style: const TextStyle(color: AppTheme.accentCyan, fontSize: 11))]),
          ]),
        ) : const SizedBox(),
      ),
      const Divider(color: Colors.white12),
      // Nav items
      ...List.generate(_navItems.length, (i) => _buildNavItem(i + 1, _navItems[i], i == _idx)),
      const Divider(color: Colors.white12),
      // Bottom items
      ...List.generate(_bottomItems.length, (i) => _buildNavItem(i + _navItems.length + 1, _bottomItems[i], false, isBottom: true)),
      const Spacer(),
      Padding(padding: const EdgeInsets.all(12),
        child: Text('← Menu | → Contenido', style: TextStyle(color: AppTheme.textHint.withOpacity(0.5), fontSize: 10), textAlign: TextAlign.center)),
    ]),
  );

  Widget _buildNavItem(int i, _NavData data, bool isSelected, {bool isBottom = false}) => Focus(
    focusNode: _navFocus[i],
    onFocusChange: (v) => setState(() {}),
    onKeyEvent: (node, event) { _handleNavKey(i, event); return KeyEventResult.handled; },
    child: Builder(builder: (ctx) {
      final focused = _navFocus[i].hasFocus;
      return GestureDetector(
        onTap: () {
          if (i <= _navItems.length) {
            final screenIdx = i - 1;
            if (screenIdx == 4) _showAdultPin();
            else setState(() { _idx = screenIdx; _sidebarVisible = false; });
          } else {
            _handleAction(i - _navItems.length - 1);
          }
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
            if (data.label == 'Adultos') ...[const Spacer(), const Icon(Icons.lock, color: Colors.orange, size: 14)],
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
