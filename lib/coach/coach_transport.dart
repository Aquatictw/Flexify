import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CoachTransportException implements Exception {
  CoachTransportException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class CoachTransport {
  Future<Map<String, Object?>> send({
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> tools,
  });
}

class HttpCoachTransport implements CoachTransport {
  HttpCoachTransport({
    required this.baseUrl,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final http.Client _client;

  @override
  Future<Map<String, Object?>> send({
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> tools,
  }) async {
    final trimmedBase = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    try {
      final response = await _client
          .post(
            Uri.parse('$trimmedBase/api/chat'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(<String, Object?>{
              'messages': messages,
              if (tools.isNotEmpty) 'tools': tools,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body.trim();
        final excerpt = body.length <= 200 ? body : body.substring(0, 200);
        throw CoachTransportException(
          'Server returned ${response.statusCode}: $excerpt',
        );
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          throw CoachTransportException(
            'Malformed response from the server.',
          );
        }
        return Map<String, Object?>.from(decoded);
      } on CoachTransportException {
        rethrow;
      } on FormatException {
        throw CoachTransportException('Malformed response from the server.');
      }
    } on CoachTransportException {
      rethrow;
    } on SocketException {
      throw CoachTransportException(
        'Could not reach the server. Check your connection.',
      );
    } on TimeoutException {
      throw CoachTransportException(
        'Could not reach the server. Check your connection.',
      );
    } on http.ClientException {
      throw CoachTransportException(
        'Could not reach the server. Check your connection.',
      );
    }
  }
}

CoachTransport? coachTransportFor({
  required String? serverUrl,
  required String? apiKey,
}) {
  final url = serverUrl?.trim() ?? '';
  final key = apiKey?.trim() ?? '';
  if (url.isEmpty || key.isEmpty) return null;
  return HttpCoachTransport(baseUrl: url, apiKey: key);
}
