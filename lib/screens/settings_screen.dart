import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _State();
}

class _State extends State<SettingsScreen> {
  bool _autoPlay = true;
  bool _notifications = true;
  bool _tvMode = true;
  bool _adultBlocked = true;
  String _quality = 'Automática';
  String _subtitleLang = 'Español';
  String _userEmail = '';
  String _userExpiry = '';
  static const _orange = Color(0xFFFF8C00);

  @override
  void initState() { super.initState(); _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail  = prefs.getString('userEmail') ?? '';
      _userExpiry = prefs.getString('userExpiry') ?? '';
      _autoPlay      = prefs.getBool('autoPlay') ?? true;
      _notifications = prefs.getBool('notifications') ?? true;
      _tvMode        = prefs.getBool('tvMode') ?? true;
      _adultBlocked  = prefs.getBool('adultBlocked') ?? true;
      _quality       = prefs.getString('quality') ?? 'Automática';
      _subtitleLang  = prefs.getString('subtitleLang') ?? 'Español';
    });
  }

  Future<void> _save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  Future<void> _clearCache() async {
    ApiService.clearCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('channel_cache');
    await prefs.remove('channel_cache_time');
    await prefs.remove('channel_cache_v2');
    await prefs.remove('channel_cache_time_v2');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caché eliminado'), backgroundColor: Color(0xFFFF8C00)));
  }

  Future<void> _clearFavorites() async {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Limpiar favoritos', style: TextStyle(color: Colors.white)),
      content: const Text('Se eliminarán todos los favoritos.', style: TextStyle(color: Colors.white54)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
        TextButton(onPressed: () async {
          Navigator.pop(ctx);
          try {
            final favs = await ApiService.getFavorites();
            for (final f in favs) await ApiService.removeFavorite(f.id);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Favoritos eliminados'), backgroundColor: Color(0xFFFF8C00)));
          } catch (_) {}
        }, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
      ]));
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: FocusNode()..requestFocus(),
    autofocus: true,
    onKey: (event) {
      if (event is RawKeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) {
          Navigator.pop(context);
        }
      }
    },
    child: Scaffold(
    backgroundColor: const Color(0xFF121212),
    body: SafeArea(child: Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
          const SizedBox(width: 12),
          const Text('Configuración', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ])),
      Expanded(child: SingleChildScrollView(child: Column(children: [
        // Perfil
        _buildProfileCard(),
        const SizedBox(height: 8),
        // Reproducción
        _buildSection('Reproducción', [
          _buildSelector('Calidad de video', Icons.hd, _quality, () => _showQualityPicker()),
          _buildToggle('Reproducción automática', Icons.play_circle_outline, _autoPlay, (v) { setState(() => _autoPlay = v); _save('autoPlay', v); }),
          _buildSelector('Idioma de subtítulos', Icons.subtitles_outlined, _subtitleLang, () => _showSubtitlePicker()),
        ]),
        const SizedBox(height: 8),
        // Ajustes
        _buildSection('Ajustes', [
          _buildToggle('Modo dispositivo TV', Icons.tv, _tvMode, (v) { setState(() => _tvMode = v); _save('tvMode', v); }),
          _buildToggle('Notificaciones', Icons.notifications_outlined, _notifications, (v) { setState(() => _notifications = v); _save('notifications', v); }),
        ]),
        const SizedBox(height: 8),
        // Control parental
        _buildSection('Control Parental', [
          _buildToggle('Protección contenido adulto', Icons.shield_outlined, _adultBlocked, (v) { setState(() => _adultBlocked = v); _save('adultBlocked', v); },
            subtitle: _adultBlocked ? 'Contenido adulto BLOQUEADO' : 'Contenido adulto PERMITIDO',
            activeColor: _adultBlocked ? Colors.green : Colors.red),
        ]),
        const SizedBox(height: 8),
        // Almacenamiento
        _buildSection('Almacenamiento', [
          _buildTile('Limpiar caché', Icons.folder_outlined, subtitle: 'Usando 8.7 MB', onTap: () => _clearCache()),
          _buildTile('Limpiar historial', Icons.history, subtitle: 'Eliminar historial de reproducción', onTap: () => _confirm('¿Limpiar historial?', 'Historial eliminado')),
          _buildTile('Limpiar favoritos', Icons.favorite_border, subtitle: 'Eliminar todos los favoritos guardados', onTap: () => _clearFavorites()),
        ]),
        const SizedBox(height: 8),
        // Info
        _buildSection('Información', [
          _buildTile('Versión de la app', Icons.info_outline, subtitle: 'v2.4.5 (Build 108)'),
        ]),
        const SizedBox(height: 16),
        // Cerrar sesión
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: _orange, width: 1))))),
        const SizedBox(height: 32),
      ]))),
    ])),
  ));

  Widget _buildProfileCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _orange.withOpacity(0.3))),
    child: Row(children: [
      Container(width: 56, height: 56,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [_orange, Color(0xFFFFB347)])),
        child: const Center(child: Icon(Icons.person, color: Colors.white, size: 30))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.email_outlined, color: _orange, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(_userEmail.isEmpty ? 'Sin email' : _userEmail,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.calendar_today, color: Colors.white54, size: 12),
          const SizedBox(width: 6),
          Text('Vence: ${_userExpiry.isEmpty ? "—" : _userExpiry}',
            style: const TextStyle(color: _orange, fontSize: 12)),
        ]),
      ])),
    ]));

  Widget _buildSection(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Text(title, style: const TextStyle(color: _orange, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.8))),
      Container(margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(14)),
        child: Column(children: children)),
    ]);

  Widget _buildToggle(String label, IconData icon, bool value, ValueChanged<bool> onChanged, {String? subtitle, Color? activeColor}) =>
    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: _orange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _orange, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          if (subtitle != null) Text(subtitle, style: TextStyle(color: activeColor ?? Colors.white54, fontSize: 11)),
        ])),
        Switch(value: value, onChanged: onChanged,
          activeColor: activeColor ?? _orange,
          activeTrackColor: (activeColor ?? _orange).withOpacity(0.3),
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white12),
      ]));

  Widget _buildSelector(String label, IconData icon, String value, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: _orange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _orange, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(value, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
        ])));

  Widget _buildTile(String label, IconData icon, {String? subtitle, VoidCallback? onTap}) =>
    GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: _orange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _orange, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ])),
          if (onTap != null) const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
        ])));

  Widget _wrapRkl(Widget child) => child;

  void _showQualityPicker() => showDialog(context: context, builder: (ctx) => SimpleDialog(
    backgroundColor: const Color(0xFF1E1E1E),
    title: const Text('Calidad de video', style: TextStyle(color: Colors.white)),
    children: ['Automática', '1080p', '720p', '480p', '360p'].map((q) => SimpleDialogOption(
      onPressed: () { setState(() => _quality = q); _save('quality', q); Navigator.pop(ctx); },
      child: Text(q, style: TextStyle(color: q == _quality ? _orange : Colors.white)))).toList()));

  void _showSubtitlePicker() => showDialog(context: context, builder: (ctx) => SimpleDialog(
    backgroundColor: const Color(0xFF1E1E1E),
    title: const Text('Idioma de subtítulos', style: TextStyle(color: Colors.white)),
    children: ['Español', 'Inglés', 'Portugués', 'Sin subtítulos'].map((l) => SimpleDialogOption(
      onPressed: () { setState(() => _subtitleLang = l); _save('subtitleLang', l); Navigator.pop(ctx); },
      child: Text(l, style: TextStyle(color: l == _subtitleLang ? _orange : Colors.white)))).toList()));

  void _confirm(String title, String success) => showDialog(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: const Color(0xFF1E1E1E),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
      TextButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success), backgroundColor: _orange)); },
        child: const Text('Confirmar', style: TextStyle(color: _orange))),
    ]));

  void _closeSettings() => Navigator.pop(context);

  void _logout() => showDialog(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: const Color(0xFF1E1E1E),
    title: const Text('¿Cerrar sesión?', style: TextStyle(color: Colors.white)),
    content: const Text('Se cerrará tu sesión actual.', style: TextStyle(color: Colors.white54)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
      TextButton(onPressed: () { ApiService.clearToken(); Navigator.pop(ctx); Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false); },
        child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red))),
    ]));
}
