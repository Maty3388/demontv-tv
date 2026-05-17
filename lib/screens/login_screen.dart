import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../utils/device_type.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _State();
}

class _State extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _loading = false, _showPass = false;
  String? _error;

  Future<void> _login() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Completá todos los campos');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.login(_email.text.trim(), _pass.text.trim());
      if (r['token'] != null) {
        Navigator.pushReplacementNamed(context, '/profile');
      } else {
        setState(() => _error = r['error'] ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      setState(() => _error = 'Sin conexión con el servidor');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _buildTV();
  }

  Widget _buildTV() => Scaffold(
    backgroundColor: const Color(0xFF0D0D0D),
    body: Row(children: [
      // Panel izquierdo - Logo
      Expanded(flex: 4, child: Container(
        color: const Color(0xFF0D0D0D),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 130, height: 130,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppTheme.logoGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(32)),
            child: const Center(child: Text('∞', style: TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 24),
          const Text('Bienvenido a', style: TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('DemonTv Plus', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ]),
      )),
      // Separador vertical
      Container(width: 1, height: double.infinity, color: Colors.white12),
      // Panel derecho - Formulario
      Expanded(flex: 6, child: Container(
        color: const Color(0xFF0D0D0D),
        padding: const EdgeInsets.symmetric(horizontal: 80),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Campo email
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _email, autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined, color: Colors.white54, size: 22),
                hintText: 'Correo electrónico',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18)))),
          const SizedBox(height: 16),
          // Campo contraseña
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _pass, obscureText: !_showPass,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54, size: 22),
                suffixIcon: IconButton(icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20), onPressed: () => setState(() => _showPass = !_showPass)),
                hintText: 'Contraseña',
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)))),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.accentRed, fontSize: 14), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight,
            child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: AppTheme.accentCyan.withOpacity(0.8), fontSize: 13))),
          const SizedBox(height: 28),
          // Botón
          GestureDetector(
            onTap: _loading ? null : _login,
            child: Container(height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFFAA00FF)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(28)),
              child: Center(child: _loading
                ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)
                : const Text('Iniciar Sesion', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold))))),
        ]),
      )),
    ]),
  );

  Widget _buildPhone() => Scaffold(
    backgroundColor: AppTheme.background,
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        const SizedBox(height: 60),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.logoGradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text('∞', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 16),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bienvenido a', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            Text('DemonTv Plus', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ]),
        ]),
        const SizedBox(height: 48),
        Container(decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
          child: TextField(controller: _email, style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary, size: 20), hintText: 'Correo electrónico', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)))),
        const SizedBox(height: 14),
        Container(decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
          child: TextField(controller: _pass, obscureText: !_showPass, style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 20), suffixIcon: IconButton(icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary, size: 20), onPressed: () => setState(() => _showPass = !_showPass)), hintText: 'Contraseña', border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)))),
        if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: AppTheme.accentRed, fontSize: 13), textAlign: TextAlign.center)],
        const SizedBox(height: 28),
        GradientButton(text: _loading ? '' : 'Iniciar Sesión', onPressed: _loading ? () {} : _login, isLoading: _loading),
        const SizedBox(height: 32),
      ]),
    )),
  );
}
