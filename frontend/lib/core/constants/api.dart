import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'regions.dart';

class Api {
  static const _key = 'xsmb_api_base_url';
  static const _compiled = String.fromEnvironment('API_BASE_URL');
  static String normalizeBase(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'Nhập URL http/https hợp lệ, không kèm tài khoản hoặc tham số',
      );
    }
    var path = uri.path;
    if (path.isEmpty || path == '/') path = '/api/';
    if (path.endsWith('/results')) path = path.substring(0, path.length - 7);
    if (!path.endsWith('/')) path += '/';
    return uri.replace(path: path).toString();
  }

  static Future<String> baseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key) ?? _compiled;
    if (value.isEmpty) {
      throw StateError(
        'Chưa cấu hình máy chủ. Nhấn biểu tượng cài đặt để nhập URL backend sau khi deploy.',
      );
    }
    return normalizeBase(value);
  }

  static Future<void> saveBase(String value) async {
    final normalized = normalizeBase(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, normalized);
  }

  static Future<http.Response> safeGet(
    String endpoint,
    RegionConfig region,
  ) async {
    final base = await baseUrl();
    return http
        .get(
          Uri.parse(base + endpoint),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));
  }
}
