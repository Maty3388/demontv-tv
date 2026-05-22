import 'dart:convert';
import 'package:http/http.dart' as http;

class VixService {
  static const String _apiBase = 'http://149.104.92.205:25461';
  static const String _adminEmail = 'admin@demontv.com';
  static const String _adminPass = 'admin2026';
  static String? _token;

  static bool isVixUrl(String url) =>
      url.contains('vix.com') || url.contains('vix://');

  static Future<String?> _getToken() async {
    if (_token != null) return _token;
    try {
      final r = await http.post(
        Uri.parse('$_apiBase/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _adminEmail, 'password': _adminPass}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(r.body);
      _token = data['token'];
      return _token;
    } catch (e) { return null; }
  }

  static Future<String?> extractStream(String vixUrl) async {
    try {
      final token = await _getToken();
      if (token == null) return null;
      final r = await http.post(
        Uri.parse('$_apiBase/admin/vix/extract'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'url': vixUrl}),
      ).timeout(const Duration(seconds: 45));
      if (r.statusCode == 401) { _token = null; return extractStream(vixUrl); }
      final data = jsonDecode(r.body);
      if (data['ok'] == true) return data['stream'];
      return null;
    } catch (e) { return null; }
  }
}
