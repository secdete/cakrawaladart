import 'dart:convert';

import 'package:http/http.dart' as http;

class PortalApiService {
  PortalApiService._();
  static final PortalApiService instance = PortalApiService._();
  static const _configured = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/',
  );
  final Uri _base = Uri.parse(
    _configured.endsWith('/') ? _configured : '$_configured/',
  );
  final http.Client _client = http.Client();
  String? token;
  Map<String, dynamic>? user;
  Map<String, dynamic>? lastDashboard;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = _base.resolve(path);
    final response = switch (method) {
      'POST' =>
        await _client
            .post(uri, headers: _headers, body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 12)),
      'PATCH' =>
        await _client
            .patch(uri, headers: _headers, body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 12)),
      _ =>
        await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 12)),
    };
    final decoded = jsonDecode(response.body);
    final data = Map<String, dynamic>.from(decoded as Map);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '${data['error'] ?? 'Permintaan gagal (${response.statusCode}).'} '
        '(${response.statusCode} ${method == 'POST' ? 'POST' : 'GET'} $uri)',
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _request(
      'auth/login',
      method: 'POST',
      body: {'email': email, 'password': password},
    );
    token = result['token'] as String;
    user = Map<String, dynamic>.from(result['user'] as Map);
    return user!;
  }

  Future<void> logout() async {
    try {
      await _request('auth/logout', method: 'POST');
    } finally {
      token = null;
      user = null;
    }
  }

  Future<Map<String, dynamic>> dashboard(String role) async {
    lastDashboard = await _request('$role/dashboard');
    return lastDashboard!;
  }

  Future<Map<String, dynamic>> sendQuestion(String question) async => _request(
    'student/questions',
    method: 'POST',
    body: {'question': question},
  );
  Future<Map<String, dynamic>> fetchQuestion() async =>
      _request('tryouts/sample/question');
  Future<Map<String, dynamic>> answerQuestion(int selectedIndex) async =>
      _request(
        'tryouts/sample/answer',
        method: 'POST',
        body: {'selectedIndex': selectedIndex},
      );
  Future<void> saveTutorNote(Map<String, dynamic> note) async {
    await _request('tutor/notes', method: 'POST', body: note);
  }

  Future<void> updateSession(String id, String status) async {
    await _request(
      'tutor/sessions/$id',
      method: 'PATCH',
      body: {'status': status},
    );
  }

  Future<void> replyToQuestion(String id, String reply) async {
    await _request(
      'tutor/questions/$id/reply',
      method: 'POST',
      body: {'reply': reply},
    );
  }
}
