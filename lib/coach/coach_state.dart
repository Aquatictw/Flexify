import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/database.dart';
import '../main.dart';
import 'coach_tools.dart';
import 'coach_transport.dart';
import 'session_snapshot.dart';
import 'session_tools.dart';

/// The live state a turn is evaluated against, read from providers by the UI.
class CoachTurn {
  const CoachTurn({
    required this.block,
    required this.workout,
    required this.unit,
  });

  final FiveThreeOneBlock? block;
  final Workout? workout;
  final String unit;
}

typedef CoachSnapshotBuilder = Future<Map<String, Object?>> Function(
  CoachTurn turn,
);
typedef CoachToolInvoker = Future<Map<String, Object?>> Function(
  String name,
  Map<String, Object?> arguments,
  CoachTurn turn,
);

class CoachState extends ChangeNotifier {
  CoachState({
    CoachSnapshotBuilder? snapshotBuilder,
    CoachToolInvoker? toolInvoker,
    this.maxIterations = defaultMaxIterations,
  })  : _snapshotBuilder = snapshotBuilder ?? _defaultSnapshotBuilder,
        _toolInvoker = toolInvoker;

  static const int defaultMaxIterations = 10;

  final CoachSnapshotBuilder _snapshotBuilder;
  final CoachToolInvoker? _toolInvoker;
  final int maxIterations;

  int? _workoutId;
  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _busy = false;
  String? _error;
  String? _draftRestore;
  String? _retryText;
  bool _canRetry = false;
  int _sessionRevision = 0;
  Map<String, Object?>? _lastSnapshot;

  int? get workoutId => _workoutId;
  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get busy => _busy;
  String? get error => _error;
  String? get draftRestore => _draftRestore;
  bool get canRetry => _canRetry;
  int get sessionRevision => _sessionRevision;

  static Future<Map<String, Object?>> _defaultSnapshotBuilder(CoachTurn turn) =>
      buildSessionSnapshot(
        block: turn.block,
        workout: turn.workout,
        unit: turn.unit,
      );

  Future<void> openThread(int? workoutId) async {
    _workoutId = workoutId;
    final rows = await (db.select(db.chatMessages)
          ..where(
            (row) => workoutId == null
                ? row.workoutId.isNull()
                : row.workoutId.equals(workoutId),
          )
          ..orderBy(<OrderClauseGenerator<$ChatMessagesTable>>[
            (row) => OrderingTerm(expression: row.id),
          ]))
        .get();
    _messages
      ..clear()
      ..addAll(rows);
    _error = null;
    _draftRestore = null;
    _retryText = null;
    _canRetry = false;
    notifyListeners();
  }

  Future<void> send(
    String text, {
    required CoachTransport transport,
    required CoachTurn turn,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _busy) return;
    _error = null;
    _draftRestore = null;
    _retryText = null;
    _canRetry = false;
    await _appendRow(role: 'user', content: trimmed);
    notifyListeners();
    await _run(transport, turn, rollbackText: trimmed);
  }

  Future<void> retry({
    required CoachTransport transport,
    required CoachTurn turn,
  }) async {
    if (_busy || !_canRetry) return;
    final restored = _draftRestore ?? _retryText;
    _error = null;
    _canRetry = false;
    if (restored != null) {
      _draftRestore = null;
      _retryText = null;
      await send(restored, transport: transport, turn: turn);
      return;
    }
    notifyListeners();
    await _run(transport, turn);
  }

  Future<void> clearThread() async {
    await (db.delete(db.chatMessages)
          ..where(
            (row) => _workoutId == null
                ? row.workoutId.isNull()
                : row.workoutId.equals(_workoutId!),
          ))
        .go();
    _messages.clear();
    _error = null;
    _draftRestore = null;
    _retryText = null;
    _canRetry = false;
    notifyListeners();
  }

  void clearDraftRestore() {
    if (_draftRestore == null) return;
    _draftRestore = null;
    notifyListeners();
  }

  Future<void> _run(
    CoachTransport transport,
    CoachTurn turn, {
    String? rollbackText,
  }) async {
    _busy = true;
    notifyListeners();
    var iterations = 0;
    var producedAssistantRowThisTurn = false;
    try {
      while (true) {
        if (iterations >= maxIterations) {
          await _appendAssistant(
            'Gave up after $maxIterations steps without finishing. '
            'Try a narrower request.',
          );
          break;
        }
        iterations++;
        final payload = await _buildRequestMessages(turn);
        final tools = coachTools(
          sessionWrites: turn.workout != null,
          trainingMaxBasis: turn.block != null,
        );
        final reply = await transport.send(messages: payload, tools: tools);
        final message = _messageOf(reply);
        final calls = _toolCallsOf(message);
        final content = message['content'] as String?;
        if (calls.isEmpty) {
          await _appendAssistant(
            (content ?? '').trim().isEmpty ? '(no reply)' : content!.trim(),
          );
          producedAssistantRowThisTurn = true;
          break;
        }

        await _appendAssistantToolCalls(content, calls);
        producedAssistantRowThisTurn = true;
        for (final call in calls) {
          final id = call['id'] as String? ?? '';
          final fn =
              _asObjectMap(call['function']) ?? const <String, Object?>{};
          final name = fn['name'] as String? ?? '';
          Map<String, Object?> result;
          final rawArgs = fn['arguments'];
          Map<String, Object?>? args;
          if (rawArgs is String) {
            try {
              final decoded = jsonDecode(rawArgs.isEmpty ? '{}' : rawArgs);
              args = _asObjectMap(decoded);
            } on FormatException {
              args = null;
            }
          } else {
            args = _asObjectMap(rawArgs);
          }
          if (args == null) {
            result = <String, Object?>{
              'ok': false,
              'error': 'Could not parse the arguments for $name as JSON. '
                  'Send them again as a JSON object.',
            };
          } else {
            result = await _invoke(name, args, turn);
          }
          await _appendToolResult(id, name, result);
          if (name == applySessionChangesTool && result['ok'] == true) {
            _sessionRevision++;
          }
        }
      }
    } on CoachTransportException catch (exception) {
      _error = exception.message;
      if (!producedAssistantRowThisTurn && rollbackText != null) {
        await _rollbackLastUserRow();
        _draftRestore = rollbackText;
        _retryText = rollbackText;
      }
      _canRetry = true;
    } catch (exception) {
      _error = 'Coach failed: $exception';
      _canRetry = true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, Object?>>> _buildRequestMessages(
    CoachTurn turn,
  ) async {
    final snapshot = await _snapshotBuilder(turn);
    _lastSnapshot = snapshot;
    return <Map<String, Object?>>[
      <String, Object?>{
        'role': 'user',
        'content': 'CURRENT_STATE\n${encodeSessionSnapshot(snapshot)}',
      },
      ..._messages.map(_wire),
    ];
  }

  Future<Map<String, Object?>> _invoke(
    String name,
    Map<String, Object?> args,
    CoachTurn turn,
  ) async {
    try {
      if (_toolInvoker != null) return await _toolInvoker(name, args, turn);
      if (name != applySessionChangesTool) {
        return <String, Object?>{
          'ok': false,
          'error': "Unknown tool '$name'.",
        };
      }
      final rawVocabulary = _lastSnapshot?['exerciseVocabulary'];
      final vocabulary = rawVocabulary is List
          ? rawVocabulary.whereType<String>().toList(growable: false)
          : <String>[];
      return await applySessionChanges(
        arguments: args,
        block: turn.block,
        workout: turn.workout,
        exerciseVocabulary: vocabulary,
        settingsUnit: turn.unit,
      );
    } catch (exception) {
      return <String, Object?>{'ok': false, 'error': '$exception'};
    }
  }

  Map<String, Object?> _messageOf(Map<String, Object?> reply) {
    final choices = reply['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('Response has no message choice.');
    }
    final choice = _asObjectMap(choices.first);
    final message = _asObjectMap(choice?['message']);
    if (message == null) {
      throw const FormatException('Response has no assistant message.');
    }
    return message;
  }

  List<Map<String, Object?>> _toolCallsOf(Map<String, Object?> message) {
    final raw = message['tool_calls'];
    if (raw == null) return <Map<String, Object?>>[];
    if (raw is! List) {
      throw const FormatException('Assistant tool_calls is not a list.');
    }
    return raw
        .map(_asObjectMap)
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
  }

  Map<String, Object?> _wire(ChatMessage row) {
    switch (row.role) {
      case 'user':
        return <String, Object?>{
          'role': 'user',
          'content': row.content ?? '',
        };
      case 'assistant':
        return <String, Object?>{
          'role': 'assistant',
          'content': row.content,
          if (row.toolCalls != null) 'tool_calls': jsonDecode(row.toolCalls!),
        };
      case 'tool':
        return <String, Object?>{
          'role': 'tool',
          'tool_call_id': row.toolCallId ?? '',
          'content': row.content ?? '',
        };
      default:
        return <String, Object?>{
          'role': row.role,
          'content': row.content ?? '',
        };
    }
  }

  Future<ChatMessage> _appendRow({
    required String role,
    String? content,
    String? toolCalls,
    String? toolCallId,
  }) async {
    final row = await db.into(db.chatMessages).insertReturning(
          ChatMessagesCompanion.insert(
            workoutId: Value(_workoutId),
            role: role,
            content: Value(content),
            toolCalls: Value(toolCalls),
            toolCallId: Value(toolCallId),
            created: DateTime.now(),
          ),
        );
    _messages.add(row);
    return row;
  }

  Future<void> _appendAssistant(String content) async {
    await _appendRow(role: 'assistant', content: content);
    notifyListeners();
  }

  Future<void> _appendAssistantToolCalls(
    String? content,
    List<Map<String, Object?>> calls,
  ) async {
    await _appendRow(
      role: 'assistant',
      content: content,
      toolCalls: jsonEncode(calls),
    );
    notifyListeners();
  }

  Future<void> _appendToolResult(
    String id,
    String name,
    Map<String, Object?> result,
  ) async {
    await _appendRow(
      role: 'tool',
      content: jsonEncode(result),
      toolCallId: id,
    );
    notifyListeners();
  }

  Future<void> _rollbackLastUserRow() async {
    final index = _messages.lastIndexWhere((row) => row.role == 'user');
    if (index < 0) return;
    final row = _messages[index];
    await (db.delete(db.chatMessages)..where((item) => item.id.equals(row.id)))
        .go();
    _messages.removeAt(index);
  }
}

Map<String, Object?>? _asObjectMap(Object? value) {
  if (value is! Map) return null;
  if (value.keys.any((key) => key is! String)) return null;
  return value.map(
    (key, mapValue) => MapEntry(key as String, mapValue as Object?),
  );
}
