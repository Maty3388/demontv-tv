import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _State();
}

class _State extends State<LoginScreen> {
  final _email     = TextEditingController();
  final _pass      = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  final _btnFocus   = FocusNode();
  bool _loading = false, _showPass = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocus);
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passFocus.dispose();
    _btnFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.login(_email.text.trim(), _pass.text.trim());
      if (r['token'] != null) {
        Navigator.pushReplacementNamed(context, '/profile');
      } else {
        setState(() => _error = r['error'] ?? 'Error al iniciar sesion');
      }
    } catch (e) {
      setState(() => _error = 'Sin conexion con el servidor');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Row(children: [
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
        ]),
      )),
      Container(width: 1, color: Colors.white12),
      Expanded(flex: 6, child: Container(
        color: const Color(0xFF0D0D0D),
        padding: const EdgeInsets.symmetric(horizontal: 80),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _TVField(controller: _email, focusNode: _emailFocus, hint: 'Correo electronico', icon: Icons.email_outlined,
            textInputAction: TextInputAction.next, onSubmitted: (_) => FocusScope.of(context).requestFocus(_passFocus)),
          const SizedBox(height: 16),
          _TVField(controller: _pass, focusNode: _passFocus, hint: 'Contrasena', icon: Icons.lock_outline,
            obscure: !_showPass, textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).requestFocus(_btnFocus),
            suffix: IconButton(focusColor: Colors.transparent,
              icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
              onPressed: () => setState(() => _showPass = !_showPass))),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.accentRed, fontSize: 14), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 28),
          Focus(
            focusNode: _btnFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
                _login();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Builder(builder: (ctx) {
              final focused = _btnFocus.hasFocus;
              return GestureDetector(
                onTap: _loading ? null : _login,
                child: Container(height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFFAA00FF)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(28),
                    border: focused ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: focused ? [const BoxShadow(color: Colors.white24, blurRadius: 20)] : null),
                  child: Center(child: _loading
                    ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)
                    : const Text('Iniciar Sesion', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)))));
            }),
          ),
        ]),
      )),
    ]),
  );
}

class _TVField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  const _TVField({required this.controller, required this.focusNode, required this.hint, required this.icon,
    this.obscure = false, this.textInputAction = TextInputAction.next, this.onSubmitted, this.suffix});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12),
      border: focusNode.hasFocus ? Border.all(color: AppTheme.accentCyan, width: 2) : Border.all(color: Colors.transparent, width: 2)),
    child: TextField(
      controller: controller, focusNode: focusNode, obscureText: obscure,
      textInputAction: textInputAction, onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white54, size: 22), suffixIcon: suffix,
        hintText: hint, hintStyle: const TextStyle(color: Colors.white38),
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18))));
}
