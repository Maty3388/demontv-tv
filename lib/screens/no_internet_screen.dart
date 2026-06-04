import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const NoInternetScreen({super.key, required this.onRetry});

  static const _orange = Color(0xFFFF8C00);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter)) {
          onRetry();
        }
      },
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 80, height: 80,
          decoration: BoxDecoration(
            color: _orange.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: _orange.withOpacity(0.3), width: 2)),
          child: const Icon(Icons.wifi_off, color: _orange, size: 40)),
        const SizedBox(height: 24),
        const Text('Sin conexión', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Verificá tu conexión a internet', style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_orange, Color(0xFFFFB347)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: _orange.withOpacity(0.4), blurRadius: 16)]),
            child: const Text('Reintentar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
        const SizedBox(height: 16),
        const Text('Presioná OK para reintentar', style: TextStyle(color: Colors.white24, fontSize: 12)),
      ])),
    ),
  );
}
