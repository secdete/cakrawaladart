import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/models/bimbel_program.dart';

class LandingApiException implements Exception {
  final String message;

  const LandingApiException(this.message);

  @override
  String toString() => message;
}

class LandingApiService {
  LandingApiService({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _baseUri = baseUri ?? _defaultBaseUri;

  static const _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/',
  );

  static final Uri _defaultBaseUri = Uri.parse(
    _configuredBaseUrl.endsWith('/')
        ? _configuredBaseUrl
        : '$_configuredBaseUrl/',
  );

  final http.Client _client;
  final Uri _baseUri;

  Future<List<BimbelProgram>> fetchPrograms(String grade) async {
    try {
      final uri = _baseUri
          .resolve('programs')
          .replace(queryParameters: grade.isEmpty ? null : {'grade': grade});
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 3));
      final body = _decodeResponse(response);
      final items = body['items'];
      if (items is! List) {
        throw const LandingApiException(
          'Format katalog dari server tidak valid.',
        );
      }
      return items
          .map(
            (item) =>
                BimbelProgram.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } catch (e) {
      // Fallback to dummy data if server is unreachable
      debugPrint('Failed to fetch from server: $e. Using dummy data fallback.');
      return BimbelProgram.dummyPrograms;
    }
  }

  Future<void> submitLead({
    required String name,
    required String phone,
    required String grade,
    required String source,
    required bool consent,
    String? email,
    String? programId,
    String? message,
  }) async {
    final response = await _client
        .post(
          _baseUri.resolve('leads'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode({
            'name': name.trim(),
            'phone': phone.trim(),
            'email': email?.trim() ?? '',
            'grade': grade,
            'source': source,
            'consent': consent,
            if (programId != null) 'programId': programId,
            'message': message?.trim() ?? '',
          }),
        )
        .timeout(const Duration(seconds: 12));
    _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } on Object {
      throw const LandingApiException(
        'Server mengirim respons yang tidak valid.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LandingApiException(
        body['error'] as String? ??
            'Permintaan ke server gagal (${response.statusCode}).',
      );
    }
    return body;
  }

  void close() => _client.close();
}
