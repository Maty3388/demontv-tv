import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _State();
}

class _State extends State<ProfileScreen> {
  final List<FocusNode> _focusNodes = List.generate(3, (_) => FocusNode());
  int _focused = 0;

  final _profiles = const [
    {'emoji': '😜', 'name': 'Perfil 1'},
    {'emoji': '🙂', 'name': 'Perfil 2'},
    {'emoji': '😎', 'name': 'Perfil 3'},
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

  void _selectProfile() => Navigator.pushReplacementNamed(context, '/main');

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF1A0A0A), AppTheme.background], stops: [0.0, 0.4])),
      child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Spacer(),
        const Text('Selecciona tu Perfil', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 48),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_profiles.length, (i) => Focus(
            focusNode: _focusNodes[i],
            onFocusChange: (v) { if (v) setState(() => _focused = i); },
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                  _selectProfile();
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowRight && i < _profiles.length - 1) {
                  FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft && i > 0) {
                  FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: _selectProfile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(_focused == i ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: _focused == i ? Border.all(color: AppTheme.accentCyan, width: 3) : null,
                  boxShadow: _focused == i ? [BoxShadow(color: AppTheme.accentCyan.withOpacity(0.4), blurRadius: 20)] : null),
                child: Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _focused == i ? 110 : 90,
                    height: _focused == i ? 110 : 90,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _focused == i ? AppTheme.accentCyan : AppTheme.border, width: 2)),
                    child: Center(child: Text(_profiles[i]['emoji']!, style: TextStyle(fontSize: _focused == i ? 54 : 44)))),
                  const SizedBox(height: 10),
                  Text(_profiles[i]['name']!, style: TextStyle(color: _focused == i ? AppTheme.accentCyan : AppTheme.textSecondary, fontSize: 14, fontWeight: _focused == i ? FontWeight.bold : FontWeight.normal)),
                ])),
            ),
          ))),
        const Spacer(),
        Padding(padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
          child: Text('Usa las flechas del control para navegar y OK para seleccionar',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 14))),
      ])),
    ),
  );
}
