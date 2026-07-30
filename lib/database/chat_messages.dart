import 'package:drift/drift.dart';

/// One message in a coach conversation thread.
///
/// Persisted so a thread survives Android killing the app mid-workout.
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The `chat_threads` row this message belongs to — the authoritative scope
  /// key. Nullable only because the v72 migration adds it to existing rows;
  /// every row written since then sets it.
  IntColumn get threadId => integer().nullable()();

  /// Denormalised copy of the thread's workout, kept because every query that
  /// predates threads reads it. [threadId] is what scopes a conversation.
  IntColumn get workoutId => integer().nullable()();

  /// 'user' | 'assistant' | 'tool'
  TextColumn get role => text()();
  TextColumn get content => text().nullable()();

  /// Raw tool_calls JSON as emitted by the model, replayed verbatim.
  TextColumn get toolCalls => text().nullable()();

  /// tool_call_id for role='tool' rows.
  TextColumn get toolCallId => text().nullable()();
  DateTimeColumn get created => dateTime()();
}
