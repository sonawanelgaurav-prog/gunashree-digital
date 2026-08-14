import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiService {
  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:4000',
            ),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path) {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalized$path');
  }

  String resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return _uri(url.startsWith('/') ? url : '/$url').toString();
  }

  Future<List<PosterTemplate>> fetchTemplates() async {
    final response = await _client.get(_uri('/api/templates'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Templates request failed');
    }
    final data = jsonDecode(response.body);
    if (data is! List) throw Exception('Invalid templates response');
    return data
        .whereType<Map>()
        .map((item) => PosterTemplate.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Category>> fetchCategories() async {
    final response = await _client.get(_uri('/api/categories'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Categories request failed');
    }
    final data = jsonDecode(response.body);
    if (data is! List) throw Exception('Invalid categories response');
    return data
        .whereType<Map>()
        .map((item) => Category.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _client.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data is! Map) {
      throw Exception(data is Map
          ? stringValue(data['error'], 'Login failed')
          : 'Login failed');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveDesign({
    required String token,
    required String name,
    required String? templateId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.post(
      _uri('/api/designs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'templateId': templateId,
        'data': data,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to sync design');
    }
  }
}
