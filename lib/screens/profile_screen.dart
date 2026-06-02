import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _State();
}

class _State extends State<ProfileScreen> {
  final List<FocusNode> _focusNodes = List.generate(3, (_) => FocusNode());
  int _focused = 0;
  static const _orange = Color(0xFFFF8C00);
  static const _orangeLight = Color(0xFFFFB347);

  final _profiles = const [
    {'emoji': '😜', 'name': 'Perfil 1', 'color': Color(0xFFFF8C00)},
    {'emoji': '🙂', 'name': 'Perfil 2', 'color': Color(0xFF00CFDD)},
    {'emoji': '😎', 'name': 'Perfil 3', 'color': Color(0xFF7B2FFF)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  Future<void> _selectProfile(int idx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedProfile', idx);
    await prefs.setString('profileName', _profiles[idx]['name'] as String);
    if (mounted) Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D0D),
    body: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF1A0800), Color(0xFF0D0D0D)], stops: [0.0, 0.5])),
      child: SafeArea(child: Column(children: [
        const Spacer(),
        // Logo
        Container(width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_orange, _orangeLight]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _orange.withOpacity(0.4), blurRadius: 24, spreadRadius: 2)]),
          child: const Center(child: Text('D+', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)))),
        const SizedBox(height: 24),
        const Text('¿Quién está viendo?', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Seleccioná tu perfil para continuar', style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 48),
        // Perfiles
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_profiles.length, (i) {
            final color = _profiles[i]['color'] as Color;
            final isFocused = _focused == i;
            return Focus(
              focusNode: _focusNodes[i],
              onFocusChange: (v) { if (v) setState(() => _focused = i); },
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                    _selectProfile(i); return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight && i < _profiles.length - 1) {
                    FocusScope.of(context).requestFocus(_focusNodes[i + 1]); return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft && i > 0) {
                    FocusScope.of(context).requestFocus(_focusNodes[i - 1]); return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: GestureDetector(
                onTap: () => _selectProfile(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isFocused ? 120 : 96,
                      height: isFocused ? 120 : 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.15),
                        border: Border.all(color: isFocused ? color : Colors.white24, width: isFocused ? 3 : 1.5),
                        boxShadow: isFocused ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 24, spreadRadius: 2)] : null),
                      child: Center(child: Text(_profiles[i]['emoji'] as String,
                        style: TextStyle(fontSize: isFocused ? 52 : 42)))),
                    const SizedBox(height: 12),
                    Text(_profiles[i]['name'] as String,
                      style: TextStyle(
                        color: isFocused ? color : Colors.white54,
                        fontSize: isFocused ? 15 : 13,
                        fontWeight: isFocused ? FontWeight.bold : FontWeight.normal)),
                    if (isFocused) ...[
                      const SizedBox(height: 4),
                      Container(width: 24, height: 3,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                    ],
                  ]),
                ),
              ),
            );
          })),
        const Spacer(),
        Padding(padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
          child: Text('Usá las flechas del control para navegar y OK para seleccionar',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13))),
      ])),
    ),
  );
}
