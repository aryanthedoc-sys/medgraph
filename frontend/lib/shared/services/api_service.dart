import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_storage.dart';

/// Handles all HTTP calls to the MedGraph backend.
/// The base URL is set from compile-time env or falls back to localhost.
class ApiService {
  ApiService._();

  // Set BACKEND_URL at build time: --dart-define=BACKEND_URL=https://...
  // Defaults to the production Render URL so release builds work without flags.
  static const String _base = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://medgraph-backend-2py8.onrender.com',
  );

  static String get _token => AuthStorage.token;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  // ── Standard JSON verbs ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'), headers: _headers);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.put(
      Uri.parse('$_base$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.patch(
      Uri.parse('$_base$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(Uri.parse('$_base$path'), headers: _headers);
    return _parse(res);
  }

  // ── Multipart file upload ─────────────────────────────────────────────────
  // Streams [fileBytes] to the backend as multipart/form-data.
  // [fieldName] must match the multer field name on the server.
  static Future<Map<String, dynamic>> uploadFile({
    required String path,
    required String fieldName,
    required List<int> fileBytes,
    required String filename,
    required String mimeType,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base$path'),
    );
    request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );
    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _parse(http.Response res) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(
        data['error'] as String? ?? 'Unknown error',
        res.statusCode,
        debugInfo: data['debug'] as Map<String, dynamic>?,
      );
    }
    return data;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode, {this.debugInfo});
  final String message;
  final int statusCode;
  final Map<String, dynamic>? debugInfo;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
