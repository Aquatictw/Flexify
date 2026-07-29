import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import '../config.dart';
import '../services/knowledge_service.dart';

final _openRouterUri =
    Uri.parse('https://openrouter.ai/api/v1/chat/completions');

Future<Response> chatHandler(
  Request request,
  ServerConfig config,
  KnowledgeService knowledge,
) async {
  final dynamic decoded;
  try {
    decoded = jsonDecode(await request.readAsString());
  } on FormatException catch (error) {
    return _badRequest('Malformed JSON: ${error.message}');
  }

  if (decoded is! Map<String, dynamic>) {
    return _badRequest('Request body must be a JSON object');
  }

  final messages = decoded['messages'];
  if (messages is! List) {
    return _badRequest('messages is required and must be a JSON list');
  }

  final tools = decoded['tools'];
  if (tools != null && tools is! List) {
    return _badRequest('tools must be a JSON list when provided');
  }

  final systemMessage = {
    'role': 'system',
    'content': [
      {
        'type': 'text',
        'text': knowledge.systemPrompt,
        'cache_control': {'type': 'ephemeral'},
      },
    ],
  };
  final payload = Map<String, dynamic>.from(decoded)
    ..['model'] = config.chatModel
    ..['messages'] = [systemMessage, ...messages];
  if (tools == null) {
    payload.remove('tools');
  }
  // Without an explicit cap the provider assumes its own maximum (65k on some
  // models) and reserves credit for it up front, which returns 402 on a turn
  // that would actually have emitted a few hundred tokens. A coach reply plus
  // tool calls fits in 4k many times over.
  payload['max_tokens'] ??= 4096;

  // Encode once so we can send a real content-length: without it dart:io
  // falls back to chunked transfer-encoding, which not every proxy in front
  // of an upstream accepts.
  final encoded = utf8.encode(jsonEncode(payload));

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final upstreamRequest = await client.postUrl(_openRouterUri);
    upstreamRequest.headers
      ..set(
        HttpHeaders.authorizationHeader,
        'Bearer ${config.openRouterApiKey}',
      )
      ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8')
      ..set(HttpHeaders.refererHeader, 'https://github.com/Aquatictw/JackedLog')
      ..set('x-title', 'JackedLog');
    upstreamRequest.contentLength = encoded.length;
    upstreamRequest.add(encoded);

    return await upstreamRequest.close().then((upstreamResponse) async {
      final body = await upstreamResponse.transform(utf8.decoder).join();
      _logUsage(config.chatModel, body);
      return Response(
        upstreamResponse.statusCode,
        body: body,
        headers: {'content-type': 'application/json'},
      );
    }).timeout(const Duration(seconds: 120));
  } on SocketException catch (error) {
    return _upstreamFailure(error);
  } on TimeoutException catch (error) {
    return _upstreamFailure(error);
  } on HttpException catch (error) {
    return _upstreamFailure(error);
  } catch (error) {
    return _upstreamFailure(error);
  } finally {
    client.close(force: true);
  }
}

void _logUsage(String model, String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      print('[chat] model=$model');
      return;
    }

    final usage = decoded['usage'];
    final fields = <String>['model=$model'];
    if (usage is Map<String, dynamic>) {
      _addIfPresent(fields, usage, 'prompt_tokens');
      _addIfPresent(fields, usage, 'completion_tokens');
      final details = usage['prompt_tokens_details'];
      if (details is Map<String, dynamic> &&
          details.containsKey('cached_tokens')) {
        fields.add('cached_tokens=${details['cached_tokens']}');
      }
      _addIfPresent(fields, usage, 'cache_creation_input_tokens');
      _addIfPresent(fields, usage, 'cache_discount');
    }
    print('[chat] ${fields.join(' ')}');
  } catch (_) {
    print('[chat] model=$model');
  }
}

void _addIfPresent(
  List<String> fields,
  Map<String, dynamic> usage,
  String name,
) {
  if (usage.containsKey(name)) {
    fields.add('$name=${usage[name]}');
  }
}

Response _badRequest(String message) => Response(
      400,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );

Response _upstreamFailure(Object error) => Response(
      502,
      body: jsonEncode({'error': 'Upstream request failed: $error'}),
      headers: {'content-type': 'application/json'},
    );
