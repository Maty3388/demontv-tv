import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/update_checker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _State();
}

class _State extends State<SettingsScreen> {
  bool _autoPlay = true, _notifications = true, _tvMode = true, _adultBlocked = true;
  String _quality = 'Automática', _subtitleLang = 'Español';
  String _userEmail = '', _userExpiry = '';
  int _focusedIndex = 0;
  static const _orange = Color(0xFFFF8C00);
  final _focusNodes = List.generate(12, (_) => FocusNode());
  final _scrollCtrl = ScrollController();

  @override
  void initState() { super.initState(); _loadPrefs(); WidgetsBinding.instance.addPostFrameCallback((_) { FocusScope.of(context).requestFocus(_focusNodes[0]); }); }

  @override
  void dispose() { for (final f in _focusNodes) f.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('userEmail') ?? '';
      _userExpiry = prefs.getString('userExpiry') ?? '';
      _autoPlay = prefs.getBool('autoPlay') ?? true;
      _notifications = prefs.getBool('notifications') ?? true;
      _tvMode = prefs.getBool('tvMode') ?? true;
      _adultBlocked = prefs.getBool('adultBlocked') ?? true;
      _quality = prefs.getString('quality') ?? 'Automática';
      _subtitleLang = prefs.getString('subtitleLang') ?? 'Español';
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
    await prefs.remove('channel_cache'); await prefs.remove('channel_cache_time');
    await prefs.remove('channel_cache_v2'); await prefs.remove('channel_cache_time_v2');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caché eliminado'), backgroundColor: _orange));
  }

  void _showConfirm(String title, String msg, IconData icon, VoidCallback onOk) {
    final f1 = FocusNode(), f2 = FocusNode();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _orange, width: 2)),
      title: Row(children: [Icon(icon, color: _orange, size: 26), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)))]),
      content: Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [_Btn('Cancelar', f1, false, Navigator.of(context).pop), _Btn('Confirmar', f2, true, () { Navigator.pop(context); onOk(); })]
    )).then((_) { if (mounted) FocusScope.of(context).requestFocus(_focusNodes[_focusedIndex]); });
    WidgetsBinding.instance.addPostFrameCallback((_) => FocusScope.of(context).requestFocus(f2));
  }

  void _logout() => _showConfirm('¿Cerrar sesión?', 'Se cerrará tu sesión actual.', Icons.logout, () {
    ApiService.clearToken(); Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  });

  void _scrollToFocus(int idx) {
    final itemHeight = 56.0;
    final offset = idx * itemHeight;
    _scrollCtrl.animateTo(offset.clamp(0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  KeyEventResult _handleKey(KeyEvent e, int idx) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.arrowDown && idx < _focusNodes.length - 1) {
      setState(() => _focusedIndex = idx + 1); FocusScope.of(context).requestFocus(_focusNodes[idx + 1]);
      Future.delayed(const Duration(milliseconds: 50), () => _scrollToFocus(idx + 1));
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (idx > 0) { setState(() => _focusedIndex = idx - 1); FocusScope.of(context).requestFocus(_focusNodes[idx - 1]);
        Future.delayed(const Duration(milliseconds: 50), () => _scrollToFocus(idx - 1));
        return KeyEventResult.handled; }
      Navigator.pop(context); return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.goBack || e.logicalKey == LogicalKeyboardKey.escape) { Navigator.pop(context); return KeyEventResult.handled; }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D0D),
    body: SafeArea(child: Column(children: [
      Container(padding: const EdgeInsets.fromLTRB(16,20,16,16),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A0800), Color(0xFF0D0D0D)], end: Alignment.bottomCenter)),
        child: Row(children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
          const SizedBox(width: 12),
          const Icon(Icons.settings, color: _orange, size: 22),
          const SizedBox(width: 8),
          const Text('Configuración', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ])),
      Expanded(child: SingleChildScrollView(controller: _scrollCtrl, child: Column(children: [
        _card(_userEmail.isEmpty ? 'Sin email' : _userEmail, _userExpiry),
        _sec('Reproducción', [
          _item(0, 'Calidad de video', Icons.hd, sub: _quality, onTap: _showQualityPicker),
          _item(1, 'Auto-reproducción', Icons.play_circle_outline, trail: _sw(_autoPlay, (v) { setState(() => _autoPlay = v); _save('autoPlay', v); })),
          _item(2, 'Idioma subtítulos', Icons.subtitles_outlined, sub: _subtitleLang, onTap: _showSubtitlePicker),
        ]),
        _sec('Ajustes', [
          _item(3, 'Modo TV', Icons.tv, trail: _sw(_tvMode, (v) { setState(() => _tvMode = v); _save('tvMode', v); })),
          _item(4, 'Notificaciones', Icons.notifications_outlined, trail: _sw(_notifications, (v) { setState(() => _notifications = v); _save('notifications', v); })),
        ]),
        _sec('Control Parental', [
          _item(5, 'Protección adultos', Icons.shield_outlined,
            sub: _adultBlocked ? '🔒 BLOQUEADO' : '🔓 PERMITIDO',
            subColor: _adultBlocked ? Colors.green : Colors.red,
            trail: _sw(_adultBlocked, (v) { setState(() => _adultBlocked = v); _save('adultBlocked', v); }, color: _adultBlocked ? Colors.green : Colors.red)),
        ]),
        _sec('Almacenamiento', [
          _item(6, 'Limpiar caché', Icons.folder_outlined, sub: 'Liberar espacio', onTap: _clearCache),
          _item(7, 'Limpiar favoritos', Icons.favorite_border, sub: 'Eliminar todos', onTap: () => _showConfirm('¿Limpiar favoritos?', 'Se eliminarán todos los favoritos.', Icons.favorite_border, () async {
            try { final f = await ApiService.getFavorites(); for (final x in f) await ApiService.removeFavorite(x.id); } catch (_) {}
          })),
        ]),
        _sec('Información', [
          _item(9, 'Versión', Icons.info_outline, sub: 'DemonTV Plus v\${UpdateChecker.currentVersion}'),
        ]),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Focus(
          focusNode: _focusNodes[10],
          onFocusChange: (v) { if (v) setState(() => _focusedIndex = 10); },
          onKeyEvent: (_, e) { if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.select || e.logicalKey == LogicalKeyboardKey.enter)) { _logout(); return KeyEventResult.handled; } return _handleKey(e, 10); },
          child: Builder(builder: (ctx) {
            final focused = _focusedIndex == 10;
            return AnimatedContainer(duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(color: focused ? Colors.red.withOpacity(0.4) : const Color(0xFFB71C1C), borderRadius: BorderRadius.circular(12), border: Border.all(color: focused ? Colors.red : Colors.transparent, width: 3), boxShadow: focused ? [const BoxShadow(color: Colors.red, blurRadius: 14, spreadRadius: 2)] : null),
              child: Material(color: Colors.transparent, child: InkWell(onTap: _logout, borderRadius: BorderRadius.circular(12),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout, color: Colors.white), SizedBox(width: 8), Text('Cerrar sesión', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))])))));
          }))),
        const SizedBox(height: 32),
      ]))),
    ])));

  Widget _card(String email, String expiry) => Container(
    margin: const EdgeInsets.fromLTRB(16,8,16,0), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: _orange.withOpacity(0.3))),
    child: Row(children: [
      Container(width: 52, height: 52, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_orange, Color(0xFFFFB347)])), child: const Icon(Icons.person, color: Colors.white, size: 28)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(email, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text('Vence: ${expiry.isEmpty ? "—" : expiry}', style: const TextStyle(color: _orange, fontSize: 11)),
      ])),
    ]));

  Widget _sec(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16,12,16,6), child: Text(title, style: const TextStyle(color: _orange, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8))),
    Container(margin: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(14)), child: Column(children: children)),
  ]);

  Widget _item(int idx, String label, IconData icon, {String? sub, Color? subColor, Widget? trail, VoidCallback? onTap}) {
    final focused = _focusedIndex == idx;
    return Focus(
      focusNode: _focusNodes[idx],
      onFocusChange: (v) { if (v) setState(() => _focusedIndex = idx); },
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.select || e.logicalKey == LogicalKeyboardKey.enter)) { onTap?.call(); return KeyEventResult.handled; }
        return _handleKey(e, idx);
      },
      child: GestureDetector(onTap: onTap, child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: focused ? _orange.withOpacity(0.12) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: focused ? _orange : Colors.transparent, width: 2), boxShadow: focused ? [BoxShadow(color: _orange.withOpacity(0.25), blurRadius: 8)] : null),
        child: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: focused ? _orange.withOpacity(0.3) : _orange.withOpacity(0.12), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: _orange, size: 17)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: focused ? Colors.white : Colors.white70, fontSize: 13, fontWeight: focused ? FontWeight.bold : FontWeight.normal)),
            if (sub != null) Text(sub, style: TextStyle(color: subColor ?? (focused ? _orange : Colors.white38), fontSize: 10)),
          ])),
          if (trail != null) trail else if (onTap != null) Icon(Icons.chevron_right, color: focused ? _orange : Colors.white24, size: 18),
        ]))));
  }

  Widget _sw(bool val, ValueChanged<bool> cb, {Color? color}) => Switch(value: val, onChanged: cb, activeColor: color ?? _orange, activeTrackColor: (color ?? _orange).withOpacity(0.3), inactiveThumbColor: Colors.white30, inactiveTrackColor: Colors.white10);

  void _showQualityPicker() => _showOpts('Calidad', Icons.hd, ['Automática','1080p','720p','480p','360p'], _quality, (v) { setState(() => _quality = v); _save('quality', v); });
  void _showSubtitlePicker() => _showOpts('Subtítulos', Icons.subtitles_outlined, ['Español','Inglés','Portugués','Sin subtítulos'], _subtitleLang, (v) { setState(() => _subtitleLang = v); _save('subtitleLang', v); });

  void _showOpts(String title, IconData icon, List<String> opts, String cur, ValueChanged<String> onSel) {
    final fns = List.generate(opts.length, (_) => FocusNode());
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _orange, width: 2)),
      title: Row(children: [Icon(icon, color: _orange), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: List.generate(opts.length, (i) {
        final sel = opts[i] == cur;
        return Focus(focusNode: fns[i],
          onKeyEvent: (_, e) {
            if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.select || e.logicalKey == LogicalKeyboardKey.enter)) { onSel(opts[i]); Navigator.pop(ctx); return KeyEventResult.handled; }
            if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.arrowDown && i < opts.length-1) { FocusScope.of(ctx).requestFocus(fns[i+1]); return KeyEventResult.handled; }
            if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.arrowUp && i > 0) { FocusScope.of(ctx).requestFocus(fns[i-1]); return KeyEventResult.handled; }
            return KeyEventResult.ignored;
          },
          child: Builder(builder: (bctx) {
            final foc = Focus.of(bctx).hasFocus;
            return GestureDetector(onTap: () { onSel(opts[i]); Navigator.pop(ctx); },
              child: AnimatedContainer(duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(color: foc ? _orange.withOpacity(0.2) : sel ? _orange.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: foc ? _orange : sel ? _orange.withOpacity(0.4) : Colors.transparent, width: 2)),
                child: Row(children: [
                  Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: sel ? _orange : Colors.white38, size: 16),
                  const SizedBox(width: 10),
                  Text(opts[i], style: TextStyle(color: foc || sel ? _orange : Colors.white, fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                ])));
          }));
      })))));
    WidgetsBinding.instance.addPostFrameCallback((_) { final i = opts.indexOf(cur); if (i >= 0) FocusScope.of(context).requestFocus(fns[i]); });
  }
}

class _Btn extends StatefulWidget {
  final String label; final FocusNode fn; final bool primary; final VoidCallback onTap;
  const _Btn(this.label, this.fn, this.primary, this.onTap);
  @override State<_Btn> createState() => _BtnState();
}
class _BtnState extends State<_Btn> {
  bool _f = false;
  static const _o = Color(0xFFFF8C00);
  @override
  Widget build(BuildContext context) => Focus(focusNode: widget.fn, onFocusChange: (v) => setState(() => _f = v),
    onKeyEvent: (_, e) { if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.select || e.logicalKey == LogicalKeyboardKey.enter)) { widget.onTap(); return KeyEventResult.handled; } if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.arrowLeft || e.logicalKey == LogicalKeyboardKey.arrowRight)) { FocusScope.of(context).nextFocus(); return KeyEventResult.handled; } return KeyEventResult.ignored; },
    child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(color: _f ? (widget.primary ? _o : Colors.white24) : (widget.primary ? _o.withOpacity(0.15) : Colors.transparent), borderRadius: BorderRadius.circular(10), border: Border.all(color: _f ? (widget.primary ? _o : Colors.white) : (widget.primary ? _o.withOpacity(0.4) : Colors.white24), width: 2), boxShadow: _f ? [BoxShadow(color: (widget.primary ? _o : Colors.white).withOpacity(0.35), blurRadius: 10)] : null),
      child: Text(widget.label, style: TextStyle(color: _f ? Colors.white : (widget.primary ? _o : Colors.white54), fontSize: 14, fontWeight: FontWeight.bold)))));
}
