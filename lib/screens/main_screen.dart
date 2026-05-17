import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/device_type.dart';
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

  final _screens = const [
    HomeScreen(),
    LiveTvScreen(),
    VodScreen(type: 'movies'),
    VodScreen(type: 'series'),
    SettingsScreen(),
  ];

  final _navItems = const [
    _NavData(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
    _NavData(icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv, label: 'TV'),
    _NavData(icon: Icons.movie_outlined, activeIcon: Icons.movie, label: 'Peliculas'),
    _NavData(icon: Icons.video_library_outlined, activeIcon: Icons.video_library, label: 'Series'),
    _NavData(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Mi Cuenta'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      if (true) return _buildTV();
      return _buildPhone();
    });
  }

  Widget _buildPhone() => Scaffold(
    backgroundColor: AppTheme.background,
    body: IndexedStack(index: _idx, children: _screens),
    bottomNavigationBar: Container(
      decoration: BoxDecoration(color: const Color(0xFF111111), border: Border(top: BorderSide(color: AppTheme.border, width: 0.5))),
      child: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (i) => _PhoneNavItem(
            data: _navItems[i], index: i, selected: _idx, onTap: (i) => setState(() => _idx = i))))))),
  );

  Widget _buildTV() => Scaffold(
    backgroundColor: AppTheme.background,
    body: Row(children: [
      // Barra lateral
      Container(
        width: 220,
        decoration: BoxDecoration(color: const Color(0xFF0A0A0A), border: Border(right: BorderSide(color: AppTheme.border, width: 0.5))),
        child: Column(children: [
          const SizedBox(height: 40),
          // Logo
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.logoGradient), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('D+', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 10),
              const Text('DemonTv Plus', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ])),
          const SizedBox(height: 20),
          // Items
          ...List.generate(_navItems.length, (i) => _TVNavItem(
            data: _navItems[i], index: i, selected: _idx, onTap: (i) => setState(() => _idx = i))),
          const Spacer(),
          // Version
          const Padding(padding: EdgeInsets.all(16),
            child: Text('v1.0.0', style: TextStyle(color: AppTheme.textHint, fontSize: 12))),
        ]),
      ),
      // Contenido
      Expanded(child: IndexedStack(index: _idx, children: _screens)),
    ]),
  );
}

class _NavData {
  final IconData icon, activeIcon;
  final String label;
  const _NavData({required this.icon, required this.activeIcon, required this.label});
}

class _PhoneNavItem extends StatelessWidget {
  final _NavData data;
  final int index, selected;
  final void Function(int) onTap;
  const _PhoneNavItem({required this.data, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          isSelected
            ? ShaderMask(blendMode: BlendMode.srcIn,
                shaderCallback: (b) => const LinearGradient(colors: AppTheme.buttonGradient, begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(b),
                child: Icon(data.activeIcon, size: 24, color: Colors.white))
            : Icon(data.icon, size: 24, color: const Color(0xFF5C5C5C)),
          const SizedBox(height: 2),
          Text(data.label, style: TextStyle(color: isSelected ? AppTheme.accentCyan : const Color(0xFF5C5C5C), fontSize: 9, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          if (isSelected) Container(margin: const EdgeInsets.only(top: 3), width: 4, height: 4,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: AppTheme.buttonGradient))),
        ])),
    );
  }
}

class _TVNavItem extends StatelessWidget {
  final _NavData data;
  final int index, selected;
  final void Function(int) onTap;
  const _TVNavItem({required this.data, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentCyan.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.accentCyan.withOpacity(0.3), width: 1) : null),
        child: Row(children: [
          Icon(isSelected ? data.activeIcon : data.icon,
            color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary, size: 22),
          const SizedBox(width: 12),
          Text(data.label, style: TextStyle(color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary, fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          if (isSelected) ...[const Spacer(), Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentCyan))],
        ])),
    );
  }
}
