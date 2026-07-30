import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/database.dart';
import '../fivethreeone/fivethreeone_state.dart';
import '../main.dart';
import 'block_tools.dart';
import 'coach_tools.dart';
import 'coach_transport.dart';
import 'read_tools.dart';
import 'session_snapshot.dart';
import 'session_tools.dart';

/// The live state a turn is evaluated against, read from providers by the UI.
class CoachTurn {
  const CoachTurn({
    required this.block,
    required this.workout,
    required this.unit,
    this.completedBlocks,
  });

  final FiveThreeOneBlock? block;
  final Workout? workout;
  final String unit;

  /// Injected `FiveThreeOneState.getCompletedBlocks`, used only by
  /// `get_block_history` so this state class never reaches into a provider.
  final Future<List<FiveThreeOneBlock>> Function()? completedBlocks;
}

/// What an applied session write did, handed to the workout screen so it can
/// refresh and echo the app's own feedback for it.
class CoachSessionChange {
  const CoachSessionChange({this.addedExercises = const <String>[]});

  /// Exercises the write added to the session, in the order they were applied.
  /// Empty for a change that only touched sets of exercises already present.
  final List<String> addedExercises;
}

typedef CoachSnapshotBuilder = Future<Map<String, Object?>> Function(
  CoachTurn turn,
);
typedef CoachToolInvoker = Future<Map<String, Object?>> Function(
  String name,
  Map<String, Object?> arguments,
  CoachTurn turn,
);

/// One conversation the state has open: its thread row, its messages, its
/// in-flight turn and its half-written prompt.
///
/// Everything a turn touches lives here rather than on [CoachState], because a
/// turn belongs to the conversation it was started in — not to whichever
/// conversation the sidebar happens to be showing when the reply lands. The
/// state used to keep a single scope, so switching conversations mid-turn
/// redirected every append (assistant reply, tool result) into the newly opened
/// thread.
class _Conversation {
  _Conversation({required this.workoutId, this.threadId});

  /// Null for a workout thread; set for one of the Coach tab's ad-hoc threads.
  final int? workoutId;

  /// Null until the first message creates the row.
  int? threadId;

  final List<ChatMessage> messages = <ChatMessage>[];

  /// True from the moment a turn starts until it stops writing to this
  /// conversation, per conversation — so a reply generating in the background
  /// never blocks the composer of the conversation you switched to.
  bool busy = false;
  String? error;
  bool canRetry = false;
  String? retryText;

  /// The composer's unsent text, kept here so switching away and back restores
  /// the prompt you were half way through in *this* conversation only.
  String draft = '';

  /// Bumped only when the state itself rewrites [draft] (a rolled-back send),
  /// which is the composer's cue to overwrite what it is holding.
  int draftRevision = 0;

  /// Set once the thread is deleted underneath a running turn: the loop stops
  /// at the next step and writes nothing more, rather than appending orphan
  /// rows to a thread that no longer exists.
  bool discarded = false;

  /// The snapshot the last request was built from, which resolves tool
  /// arguments against this conversation's own turn.
  Map<String, Object?>? lastSnapshot;
}

class CoachState extends ChangeNotifier {
  CoachState({
    CoachSnapshotBuilder? snapshotBuilder,
    CoachToolInvoker? toolInvoker,
    this.maxIterations = defaultMaxIterations,
  })  : _snapshotBuilder = snapshotBuilder ?? _defaultSnapshotBuilder,
        _toolInvoker = toolInvoker {
    _conversations.add(_current);
  }

  static const int defaultMaxIterations = 10;

  final CoachSnapshotBuilder _snapshotBuilder;
  final CoachToolInvoker? _toolInvoker;
  final int maxIterations;

  /// Every conversation this state has touched, so switching away from one
  /// keeps its messages, its running turn and its draft intact.
  final List<_Conversation> _conversations = <_Conversation>[];
  _Conversation _current = _Conversation(workoutId: null);
  bool _opened = false;
  final List<ChatThread> _threads = <ChatThread>[];
  int _sessionRevision = 0;
  CoachSessionChange _lastSessionChange = const CoachSessionChange();

  int? get workoutId => _current.workoutId;

  /// The open thread's row id, or null while it is still unsaved — a new
  /// conversation writes no row until its first message.
  int? get threadId => _current.threadId;
  List<ChatMessage> get messages =>
      List<ChatMessage>.unmodifiable(_current.messages);

  /// Ad-hoc threads for the sidebar, newest activity first. Empty while this
  /// state is scoped to a workout, which never lists threads.
  List<ChatThread> get threads => List<ChatThread>.unmodifiable(_threads);

  bool get busy => _current.busy;
  String? get error => _current.error;
  bool get canRetry => _current.canRetry;
  int get sessionRevision => _sessionRevision;

  /// Opaque identity of the open conversation. The composer swaps its contents
  /// whenever this changes, which is what keeps a half-written prompt with the
  /// conversation it was typed in.
  Object get conversationKey => _current;

  /// The open conversation's unsent composer text.
  String get draftText => _current.draft;
  int get draftRevision => _current.draftRevision;

  /// Threads with a turn still running, so the sidebar can show that a reply is
  /// generating in a conversation you are not looking at.
  Set<int> get runningThreadIds => <int>{
        for (final conversation in _conversations)
          if (conversation.busy && conversation.threadId != null)
            conversation.threadId!,
      };

  /// The change behind the current [sessionRevision].
  CoachSessionChange get lastSessionChange => _lastSessionChange;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Notifies listeners unless this notifier is already gone.
  ///
  /// The in-workout sheet owns its own [CoachState] and disposes it the moment
  /// it closes, which can happen while a turn is still in flight — and a bare
  /// `notifyListeners()` after that throws, aborting the run mid-turn. The
  /// damage lands in the thread: an assistant row with a tool call whose result
  /// never gets written, which the provider then rejects on every later send.
  /// The turn has to finish writing even with nobody watching.
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  static Future<Map<String, Object?>> _defaultSnapshotBuilder(CoachTurn turn) =>
      buildSessionSnapshot(
        block: turn.block,
        workout: turn.workout,
        unit: turn.unit,
      );

  /// Binds this state to a workout's thread, or (null) to the most recent
  /// ad-hoc thread — a fresh one if there is none yet.
  ///
  /// Re-entrant on purpose: the in-workout sheet no longer owns a state, so
  /// every reopen calls this again while a turn may still be running. An
  /// already-open scope is left exactly as it is, so a reopen never reloads the
  /// message list underneath the appends still to come.
  Future<void> openThread(int? workoutId) async {
    if (_opened && _current.workoutId == workoutId) {
      _notify();
      return;
    }
    final thread = await (db.select(db.chatThreads)
          ..where(
            (row) => workoutId == null
                ? row.workoutId.isNull()
                : row.workoutId.equals(workoutId),
          )
          ..orderBy(<OrderClauseGenerator<$ChatThreadsTable>>[
            (row) => OrderingTerm(
                  expression: row.updated,
                  mode: OrderingMode.desc,
                ),
            (row) => OrderingTerm(expression: row.id, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    await _select(workoutId: workoutId, threadId: thread?.id);
  }

  /// Switches the sidebar to an existing ad-hoc thread.
  Future<void> openThreadById(int threadId) =>
      _select(workoutId: null, threadId: threadId);

  /// Starts an empty conversation. Nothing is written until its first message,
  /// so backing out leaves no stub in the sidebar.
  Future<void> startNewThread() async {
    // An unsaved conversation already sitting empty *is* a new conversation;
    // making a second one would strand the draft typed into the first.
    final blank = _conversations.firstWhere(
      (conversation) =>
          conversation.workoutId == null &&
          conversation.threadId == null &&
          conversation.messages.isEmpty &&
          !conversation.busy,
      orElse: () => _register(_Conversation(workoutId: null)),
    );
    await _selectConversation(blank);
  }

  /// Deletes a thread and its messages. If it was the open one, the state falls
  /// back to a fresh empty conversation.
  Future<void> deleteThread(int threadId) async {
    await db.transaction(() async {
      await (db.delete(db.chatMessages)
            ..where((row) => row.threadId.equals(threadId)))
          .go();
      await (db.delete(db.chatThreads)..where((row) => row.id.equals(threadId)))
          .go();
    });
    final open = _current.threadId == threadId;
    final openWorkoutId = _current.workoutId;
    for (final conversation in _conversations.toList()) {
      if (conversation.threadId != threadId) continue;
      // A turn still running against it must stop writing; its rows have
      // nowhere left to go.
      conversation.discarded = true;
      _conversations.remove(conversation);
    }
    if (open) {
      // Clearing a workout thread leaves that workout's conversation empty; it
      // must not fall through to an ad-hoc one, whose write tools would then be
      // pointed at a session it was never opened in.
      if (openWorkoutId != null) {
        await _selectConversation(
          _register(_Conversation(workoutId: openWorkoutId)),
        );
        return;
      }
      await startNewThread();
      return;
    }
    await _refreshThreads();
    _notify();
  }

  /// Finds — or loads — the conversation for a scope and makes it the open one.
  Future<void> _select({required int? workoutId, required int? threadId}) async {
    for (final conversation in _conversations) {
      if (conversation.workoutId != workoutId) continue;
      if (threadId == null
          ? conversation.threadId == null && conversation.messages.isEmpty
          : conversation.threadId == threadId) {
        await _selectConversation(conversation);
        return;
      }
    }
    final conversation = _register(
      _Conversation(workoutId: workoutId, threadId: threadId),
    );
    if (threadId != null) {
      conversation.messages.addAll(
        await (db.select(db.chatMessages)
              ..where((row) => row.threadId.equals(threadId))
              ..orderBy(<OrderClauseGenerator<$ChatMessagesTable>>[
                (row) => OrderingTerm(expression: row.id),
              ]))
            .get(),
      );
    }
    await _selectConversation(conversation);
  }

  _Conversation _register(_Conversation conversation) {
    _conversations.add(conversation);
    return conversation;
  }

  Future<void> _selectConversation(_Conversation conversation) async {
    _opened = true;
    _current = conversation;
    await _refreshThreads();
    _notify();
  }

  Future<void> _refreshThreads() async {
    // Only the Coach tab lists threads, and only ad-hoc ones: a workout thread's
    // write tools target the live session, so reopening one from the tab would
    // put it in a context it was never written in.
    if (_current.workoutId != null) {
      _threads.clear();
      return;
    }
    final rows = await (db.select(db.chatThreads)
          ..where((row) => row.workoutId.isNull())
          ..orderBy(<OrderClauseGenerator<$ChatThreadsTable>>[
            (row) => OrderingTerm(
                  expression: row.updated,
                  mode: OrderingMode.desc,
                ),
            (row) => OrderingTerm(expression: row.id, mode: OrderingMode.desc),
          ]))
        .get();
    _threads
      ..clear()
      ..addAll(rows);
  }

  /// Sends into the conversation that is open *now*; the turn stays bound to it
  /// however the sidebar moves afterwards.
  Future<void> send(
    String text, {
    required CoachTransport transport,
    required CoachTurn turn,
  }) async {
    final conversation = _current;
    final trimmed = text.trim();
    if (trimmed.isEmpty || conversation.busy) return;
    conversation
      ..error = null
      ..retryText = null
      ..canRetry = false
      ..draft = '';
    await _appendRow(conversation, role: 'user', content: trimmed);
    _notify();
    await _run(conversation, transport, turn, rollbackText: trimmed);
  }

  Future<void> retry({
    required CoachTransport transport,
    required CoachTurn turn,
  }) async {
    final conversation = _current;
    if (conversation.busy || !conversation.canRetry) return;
    final restored = conversation.retryText;
    conversation
      ..error = null
      ..canRetry = false;
    if (restored != null) {
      conversation.retryText = null;
      await send(restored, transport: transport, turn: turn);
      return;
    }
    _notify();
    await _run(conversation, transport, turn);
  }

  /// Discards the open conversation entirely, leaving an empty one in its place.
  Future<void> clearThread() async {
    final threadId = _current.threadId;
    if (threadId != null) {
      await deleteThread(threadId);
      return;
    }
    _current.messages.clear();
    _setDraft(_current, '');
  }

  /// Stores the composer's unsent text against the open conversation.
  ///
  /// Deliberately silent: this runs on every keystroke, and notifying would
  /// rebuild the whole thread each character. Nothing else reads the draft while
  /// it is being typed.
  set draftText(String text) => _current.draft = text;

  void _setDraft(_Conversation conversation, String text) {
    conversation.draft = text;
    conversation.draftRevision++;
    _notify();
  }

  Future<void> _run(
    _Conversation conversation,
    CoachTransport transport,
    CoachTurn turn, {
    String? rollbackText,
  }) async {
    conversation.busy = true;
    _notify();
    var iterations = 0;
    var producedAssistantRowThisTurn = false;
    try {
      while (true) {
        if (conversation.discarded) break;
        if (iterations >= maxIterations) {
          await _appendAssistant(
            conversation,
            'Gave up after $maxIterations steps without finishing. '
            'Try a narrower request.',
          );
          break;
        }
        iterations++;
        final payload = await _buildRequestMessages(conversation, turn);
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
            conversation,
            (content ?? '').trim().isEmpty ? '(no reply)' : content!.trim(),
          );
          producedAssistantRowThisTurn = true;
          break;
        }

        await _appendAssistantToolCalls(conversation, content, calls);
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
            result = await _invoke(conversation, name, args, turn);
          }
          await _appendToolResult(conversation, id, result);
          if (name == applySessionChangesTool && result['ok'] == true) {
            _sessionRevision++;
            _lastSessionChange = _sessionChangeOf(result);
            // The workout screen behind the sheet refreshes off this
            // notification, so the write announces itself as it lands rather
            // than whenever the turn happens to end.
            _notify();
          }
        }
      }
    } on CoachTransportException catch (exception) {
      conversation.error = exception.message;
      if (!producedAssistantRowThisTurn && rollbackText != null) {
        await _rollbackLastUserRow(conversation);
        conversation.retryText = rollbackText;
        // Back into the composer, but only this conversation's — the draft the
        // failed send came from belongs to the thread it was sent in.
        _setDraft(conversation, rollbackText);
      }
      conversation.canRetry = true;
    } catch (exception) {
      conversation.error = 'Coach failed: $exception';
      conversation.canRetry = true;
    } finally {
      conversation.busy = false;
      _notify();
    }
  }

  Future<List<Map<String, Object?>>> _buildRequestMessages(
    _Conversation conversation,
    CoachTurn turn,
  ) async {
    final snapshot = await _snapshotBuilder(turn);
    conversation.lastSnapshot = snapshot;
    return <Map<String, Object?>>[
      <String, Object?>{
        'role': 'user',
        'content': 'CURRENT_STATE\n${encodeSessionSnapshot(snapshot)}',
      },
      ..._repairToolCalls(conversation.messages.map(_wire).toList()),
    ];
  }

  /// Answers every tool call the stored thread left unanswered.
  ///
  /// A turn interrupted between the assistant's tool call and its result — a
  /// failed write, a killed process — leaves a call id with no `role: tool`
  /// reply, and the provider rejects the whole request ("No tool output found
  /// for function call ..."). That wedges the thread for good: every later send
  /// replays the same gap, so the only way out would be clearing the history.
  /// The history is real and worth keeping, so the gap is closed with an
  /// explicit interrupted result instead.
  static List<Map<String, Object?>> _repairToolCalls(
    List<Map<String, Object?>> wire,
  ) {
    final repaired = <Map<String, Object?>>[];
    for (var i = 0; i < wire.length; i++) {
      final message = wire[i];
      repaired.add(message);
      if (message['role'] != 'assistant') continue;
      final calls = message['tool_calls'];
      if (calls is! List || calls.isEmpty) continue;

      // Results for these calls are the run of tool messages that follows.
      final answered = <String>{};
      for (var j = i + 1; j < wire.length && wire[j]['role'] == 'tool'; j++) {
        final id = wire[j]['tool_call_id'];
        if (id is String) answered.add(id);
      }

      for (final call in calls) {
        final id = _asObjectMap(call)?['id'];
        if (id is! String || id.isEmpty || answered.contains(id)) continue;
        repaired.add(<String, Object?>{
          'role': 'tool',
          'tool_call_id': id,
          'content': jsonEncode(<String, Object?>{
            'ok': false,
            'error': 'This call was interrupted before it finished, so nothing '
                'was written. Call it again if the change is still wanted.',
          }),
        });
      }
    }
    return repaired;
  }

  Future<Map<String, Object?>> _invoke(
    _Conversation conversation,
    String name,
    Map<String, Object?> args,
    CoachTurn turn,
  ) async {
    try {
      if (_toolInvoker != null) return await _toolInvoker(name, args, turn);
      final vocabulary = _vocabulary(conversation);
      if (readToolNames.contains(name)) {
        return await runReadTool(
          name: name,
          arguments: args,
          exerciseVocabulary: vocabulary,
          settingsUnit: turn.unit,
          completedBlocks: turn.completedBlocks,
        );
      }
      if (name == proposeBlockChangesTool) {
        // Returns a proposal for the confirmation card; it writes nothing.
        return await proposeBlockChanges(
          arguments: args,
          block: turn.block,
          exerciseVocabulary: vocabulary,
          settingsUnit: turn.unit,
        );
      }
      if (name != applySessionChangesTool) {
        return <String, Object?>{
          'ok': false,
          'error': "Unknown tool '$name'.",
        };
      }
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

  List<String> _vocabulary(_Conversation conversation) {
    final raw = conversation.lastSnapshot?['exerciseVocabulary'];
    return raw is List
        ? raw.whereType<String>().toList(growable: false)
        : <String>[];
  }

  /// Commits a proposal the user confirmed on the card, then reports the
  /// outcome back into the thread so the model knows the block moved.
  ///
  /// This is the only path that writes block-level state; `propose_block_changes`
  /// itself never does.
  Future<Map<String, Object?>> applyProposal({
    required BlockProposal proposal,
    required FiveThreeOneState fiveThreeOneState,
    required String unit,
  }) async {
    // The card is only tappable in the conversation on screen, and the outcome
    // belongs in that one's transcript.
    final conversation = _current;
    Map<String, Object?> result;
    try {
      result = await applyBlockProposal(
        proposal: proposal,
        fiveThreeOneState: fiveThreeOneState,
        settingsUnit: unit,
      );
    } catch (exception) {
      result = <String, Object?>{
        'ok': false,
        'status': 'failed',
        'error': '$exception',
      };
    }
    await _appendConfirmationOutcome(conversation, result);
    if (result['ok'] == true) {
      _sessionRevision++;
      // A block write is not a session add; nothing for the workout screen to
      // echo, and the previous change must not be replayed against it.
      _lastSessionChange = const CoachSessionChange();
    }
    _notify();
    return result;
  }

  /// Records a declined proposal so the model stops re-offering it.
  Future<void> declineProposal(BlockProposal proposal) async {
    await _appendConfirmationOutcome(
      _current,
      declinedBlockProposalResult(proposal),
    );
    _notify();
  }

  Future<void> _appendConfirmationOutcome(
    _Conversation conversation,
    Map<String, Object?> result,
  ) =>
      _appendRow(conversation, role: 'tool', content: jsonEncode(result));

  /// Reads the applied ops back out of a successful `apply_session_changes`
  /// result. The tool result is the authority on what landed — the arguments
  /// the model sent are only what it asked for.
  static CoachSessionChange _sessionChangeOf(Map<String, Object?> result) {
    final applied = result['applied'];
    if (applied is! List) return const CoachSessionChange();
    final added = <String>[];
    for (final entry in applied) {
      final op = _asObjectMap(entry);
      if (op == null || op['op'] != 'add_exercise') continue;
      final exercise = op['exercise'];
      if (exercise is String && exercise.isNotEmpty) added.add(exercise);
    }
    return CoachSessionChange(addedExercises: added);
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
        final id = row.toolCallId;
        // A confirmation outcome answers a tap, not an outstanding tool call —
        // the proposal's own tool result was already sent under that id. It
        // rides back as a user turn so the transcript stays well formed while
        // the model still learns what the user decided.
        if (id == null || id.isEmpty) {
          return <String, Object?>{
            'role': 'user',
            'content': 'TOOL_RESULT\n${row.content ?? ''}',
          };
        }
        return <String, Object?>{
          'role': 'tool',
          'tool_call_id': id,
          'content': row.content ?? '',
        };
      default:
        return <String, Object?>{
          'role': row.role,
          'content': row.content ?? '',
        };
    }
  }

  /// Appends one row to [conversation] — never to whichever conversation is
  /// open at the time, which is the whole point: a turn's rows land in the
  /// thread it was started in.
  Future<ChatMessage?> _appendRow(
    _Conversation conversation, {
    required String role,
    String? content,
    String? toolCalls,
    String? toolCallId,
  }) async {
    if (conversation.discarded) return null;
    final now = DateTime.now();
    final threadId = await _ensureThread(conversation, now);
    final row = await db.into(db.chatMessages).insertReturning(
          ChatMessagesCompanion.insert(
            threadId: Value(threadId),
            workoutId: Value(conversation.workoutId),
            role: role,
            content: Value(content),
            toolCalls: Value(toolCalls),
            toolCallId: Value(toolCallId),
            created: now,
          ),
        );
    conversation.messages.add(row);
    await _touchThread(
      threadId,
      now,
      title: role == 'user' ? _titleFrom(content) : null,
    );
    return row;
  }

  /// Creates the thread row on the first message of a new conversation.
  Future<int> _ensureThread(_Conversation conversation, DateTime now) async {
    final existing = conversation.threadId;
    if (existing != null) return existing;
    final row = await db.into(db.chatThreads).insertReturning(
          ChatThreadsCompanion.insert(
            workoutId: Value(conversation.workoutId),
            created: now,
            updated: now,
          ),
        );
    conversation.threadId = row.id;
    return row.id;
  }

  /// Keeps the sidebar's ordering and label current. The title is only ever
  /// written once, from the conversation's first user message.
  Future<void> _touchThread(
    int threadId,
    DateTime now, {
    String? title,
  }) async {
    await (db.update(db.chatThreads)..where((row) => row.id.equals(threadId)))
        .write(ChatThreadsCompanion(updated: Value(now)));
    if (title != null) {
      await (db.update(db.chatThreads)
            ..where((row) => row.id.equals(threadId) & row.title.isNull()))
          .write(ChatThreadsCompanion(title: Value(title)));
    }
    await _refreshThreads();
  }

  static String? _titleFrom(String? content) {
    final trimmed = content?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length <= 60 ? trimmed : '${trimmed.substring(0, 57)}…';
  }

  Future<void> _appendAssistant(
    _Conversation conversation,
    String content,
  ) async {
    await _appendRow(conversation, role: 'assistant', content: content);
    _notify();
  }

  Future<void> _appendAssistantToolCalls(
    _Conversation conversation,
    String? content,
    List<Map<String, Object?>> calls,
  ) async {
    await _appendRow(
      conversation,
      role: 'assistant',
      content: content,
      toolCalls: jsonEncode(calls),
    );
    _notify();
  }

  Future<void> _appendToolResult(
    _Conversation conversation,
    String id,
    Map<String, Object?> result,
  ) async {
    await _appendRow(
      conversation,
      role: 'tool',
      content: jsonEncode(result),
      toolCallId: id,
    );
    _notify();
  }

  Future<void> _rollbackLastUserRow(_Conversation conversation) async {
    final messages = conversation.messages;
    final index = messages.lastIndexWhere((row) => row.role == 'user');
    if (index < 0) return;
    final row = messages[index];
    await (db.delete(db.chatMessages)..where((item) => item.id.equals(row.id)))
        .go();
    messages.removeAt(index);
    // A failed first send would otherwise leave an untitled empty thread
    // sitting in the sidebar; put the conversation back to unsaved instead.
    final threadId = conversation.threadId;
    if (messages.isEmpty && threadId != null) {
      await (db.delete(db.chatThreads)..where((item) => item.id.equals(threadId)))
          .go();
      conversation.threadId = null;
      await _refreshThreads();
    }
  }
}

/// The [CoachState] the in-workout sheet binds to.
///
/// A distinct type only so both it and the Coach tab's state can be top-level
/// providers — they must be two instances, because one notifier holds one
/// thread scope at a time (PRD decision 6). Living above the sheet is the
/// point: the sheet used to create its own, so closing it mid-turn dropped the
/// thinking indicator and every row the turn wrote after that only appeared on
/// the next open.
class WorkoutCoachState extends CoachState {}

Map<String, Object?>? _asObjectMap(Object? value) {
  if (value is! Map) return null;
  if (value.keys.any((key) => key is! String)) return null;
  return value.map(
    (key, mapValue) => MapEntry(key as String, mapValue as Object?),
  );
}
