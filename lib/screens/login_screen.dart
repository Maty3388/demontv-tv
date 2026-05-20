import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _email     = TextEditingController();
  final _pass      = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  final _btnFocus   = FocusNode();
  bool _loading = false;
  bool _showPass = false;
  String? _error;
  int _focusIdx = 0; // 0=email 1=pass 2=btn

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setFocus(0));
  }

  void _setFocus(int idx) {
    setState(() => _focusIdx = idx);
    if (idx == 0) FocusScope.of(context).requestFocus(_emailFocus);
    else if (idx == 1) FocusScope.of(context).requestFocus(_passFocus);
    else FocusScope.of(context).requestFocus(_btnFocus);
  }

  @override
  void dispose() {
    _email.dispose(); _pass.dispose();
    _emailFocus.dispose(); _passFocus.dispose(); _btnFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Completa todos los campos'); return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.login(_email.text.trim(), _pass.text.trim());
      if (!mounted) return;
      if (r['token'] != null) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        setState(() => _error = r['error'] ?? 'Error al iniciar sesion');
      }
    } catch (e) {
      setState(() => _error = 'Sin conexion con el servidor');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_focusIdx < 2) _setFocus(_focusIdx + 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_focusIdx > 0) _setFocus(_focusIdx - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
      if (_focusIdx == 2) _login();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKey,
      child: Row(children: [
        // Panel izquierdo
        Expanded(flex: 4, child: Container(
          color: const Color(0xFF0D0D0D),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 130, height: 130,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppTheme.logoGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(32)),
              child: const Center(child: Text('D+', style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 24),
            const Text('Bienvenido a', style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 6),
            const Text('DemonTv Plus', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('v1.2.0', style: TextStyle(color: Colors.white30, fontSize: 13)),
          ]),
        )),
        Container(width: 1, color: Colors.white12),
        // Panel derecho
        Expanded(flex: 6, child: Container(
          color: const Color(0xFF0D0D0D),
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Email
            _field(
              controller: _email, focusNode: _emailFocus, focused: _focusIdx == 0,
              hint: 'Correo electronico', icon: Icons.email_outlined,
              onTap: () => _setFocus(0),
            ),
            const SizedBox(height: 16),
            // Password
            _field(
              controller: _pass, focusNode: _passFocus, focused: _focusIdx == 1,
              hint: 'Contrasena', icon: Icons.lock_outline,
              obscure: !_showPass, onTap: () => _setFocus(1),
              suffix: GestureDetector(
                onTap: () => setState(() => _showPass = !_showPass),
                child: Padding(padding: const EdgeInsets.all(14),
                  child: Icon(_showPass ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 22))),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppTheme.accentRed, fontSize: 14), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 28),
            // Boton
            GestureDetector(
              onTap: _loading ? null : _login,
              child: Focus(
                focusNode: _btnFocus,
                child: Builder(builder: (ctx) {
                  final focused = _btnFocus.hasFocus || _focusIdx == 2;
                  return Container(height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFFAA00FF)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(28),
                      border: focused ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: focused ? [const BoxShadow(color: Colors.white24, blurRadius: 20)] : null),
                    child: Center(child: _loading
                      ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)
                      : const Text('Iniciar Sesion', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold))));
                }),
              ),
            ),
            const SizedBox(height: 16),
            const Text('↑↓ Navegar   OK Confirmar', style: TextStyle(color: Colors.white24, fontSize: 12), textAlign: TextAlign.center),
          ]),
        )),
      ]),
    ),
  );

  Widget _field({required TextEditingController controller, required FocusNode focusNode, required bool focused,
    required String hint, required IconData icon, bool obscure = false, VoidCallback? onTap, Widget? suffix}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12),
          border: focused ? Border.all(color: AppTheme.accentCyan, width: 2) : Border.all(color: Colors.transparent, width: 2)),
        child: Row(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Icon(icon, color: Colors.white54, size: 22)),
          Expanded(child: TextField(
            controller: controller, focusNode: focusNode, obscureText: obscure,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: hint, hintStyle: const TextStyle(color: Colors.white38),
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 18)),
          )),
          if (suffix != null) suffix,
        ]),
      ),
    );
  }
}
