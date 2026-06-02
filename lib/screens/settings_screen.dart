import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _State();
}

class _State extends State<SettingsScreen> {
  bool _adultContent = false, _mobileMode = false;
  Map? _profile;
  String _userEmail = '';
  String _userExpiry = '';

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail  = prefs.getString('userEmail') ?? '';
      _userExpiry = prefs.getString('userExpiry') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: SafeArea(child: SingleChildScrollView(child: Column(children: [
      const SizedBox(height: 24),
      Center(child: Container(width: 90, height: 90,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: AppTheme.logoGradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24)),
        child: const Center(child: Text('😎', style: TextStyle(fontSize: 46))))),
      const SizedBox(height: 28),
      _SectionLabel('CUENTA'),
      _Item(icon: Icons.person_outline, label: _userEmail.isEmpty ? 'Sin email' : _userEmail, onTap: () {}),
      _Item(icon: Icons.calendar_today_outlined, label: _userExpiry.isEmpty ? 'Sin vencimiento' : _userExpiry, onTap: () {}),
      const _Div(),
      _SectionLabel('PREFERENCIAS'),
      _Toggle(icon: Icons.favorite_border, label: 'Contenido para adultos', value: _adultContent, onChanged: (v) => setState(() => _adultContent = v)),
      const _Div(),
      _SectionLabel('SISTEMA'),
      _Item(icon: Icons.pin_outlined, label: 'Resetear PIN', onTap: () {}),
      _Item(icon: Icons.download_outlined, label: 'Borrar caché', onTap: () => _confirm('¿Borrar caché?', 'Caché eliminado')),
      _Item(icon: Icons.delete_outline, label: 'Borrar historial', onTap: () => _confirm('¿Borrar historial?', 'Historial eliminado')),
      _Item(icon: Icons.refresh, label: 'Actualizar app', onTap: () {}),
      _Toggle(icon: Icons.phone_android, label: 'Modo Móvil', value: _mobileMode, onChanged: (v) => setState(() => _mobileMode = v)),
      ListTile(
        leading: const Icon(Icons.logout, color: AppTheme.accentRed),
        title: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.accentRed),
        onTap: _logout),
      const SizedBox(height: 24),
      const Text('Versión: 11.0.0 (3030000)', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
      const SizedBox(height: 32),
    ]))),
  );

  void _confirm(String title, String success) => showDialog(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: AppTheme.surface,
    title: Text(title, style: const TextStyle(color: Colors.white)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
      TextButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success), backgroundColor: AppTheme.accentCyan)); }, child: const Text('Confirmar', style: TextStyle(color: AppTheme.accentRed))),
    ]));

  void _logout() => showDialog(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: AppTheme.surface,
    title: const Text('¿Cerrar sesión?', style: TextStyle(color: Colors.white)),
    content: const Text('Se cerrará tu sesión actual.', style: TextStyle(color: AppTheme.textSecondary)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
      TextButton(onPressed: () { ApiService.clearToken(); Navigator.pop(ctx); Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false); }, child: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.accentRed))),
    ]));
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16,16,16,6),
    child: Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(color: AppTheme.textHint, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2))));
}

class _Item extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _Item({required this.icon, required this.label, required this.onTap});
  @override Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
    title: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
    trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint), onTap: onTap);
}

class _Toggle extends StatelessWidget {
  final IconData icon; final String label; final bool value; final ValueChanged<bool> onChanged;
  const _Toggle({required this.icon, required this.label, required this.value, required this.onChanged});
  @override Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
    title: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
    trailing: Switch(value: value, onChanged: onChanged, activeColor: AppTheme.accentCyan, inactiveThumbColor: const Color(0xFF5C5C5C), inactiveTrackColor: AppTheme.surface));
}

class _Div extends StatelessWidget {
  const _Div();
  @override Widget build(BuildContext context) => const Divider(color: AppTheme.border, height: 1, indent: 16, endIndent: 16);
}
