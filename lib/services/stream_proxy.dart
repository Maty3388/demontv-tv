import 'dart:io';
import 'package:http/http.dart' as http;

class StreamProxy {
  static HttpServer? _server;
  static int _port = 8765;

  static Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind('127.0.0.1', _port);
    _server!.listen((req) async {
      try {
        final encodedUrl = req.uri.queryParameters['url'];
        if (encodedUrl == null) { req.response.statusCode = 400; await req.response.close(); return; }
        final url = Uri.decodeComponent(encodedUrl);
        final headersParam = req.uri.queryParameters['headers'] ?? '';
        final headers = <String, String>{};
        if (headersParam.isNotEmpty) {
          for (final kv in headersParam.split('&')) {
            final idx = kv.indexOf('=');
            if (idx > 0) headers[kv.substring(0, idx)] = kv.substring(idx + 1);
          }
        }
        headers['User-Agent'] = headers['User-Agent'] ?? 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36';
        final response = await http.get(Uri.parse(url), headers: headers);
        req.response.statusCode = response.statusCode;
        response.headers.forEach((k, v) {
          try { req.response.headers.set(k, v); } catch (_) {}
        });
        req.response.add(response.bodyBytes);
        await req.response.close();
      } catch (e) {
        req.response.statusCode = 500;
        await req.response.close();
      }
    });
  }

  static String proxyUrl(String url, Map<String, String> headers) {
    if (headers.isEmpty) return url;
    final encoded = Uri.encodeComponent(url);
    final hdrs = headers.entries.map((e) => '\${e.key}=\${e.value}').join('&');
    return 'http://127.0.0.1:\$_port/stream?url=\$encoded&headers=\${Uri.encodeComponent(hdrs)}';
  }
}
