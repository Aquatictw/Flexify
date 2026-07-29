import 'package:drift/drift.dart';

/// One message in a coach conversation thread.
///
/// Threads are short-lived: one per workout (`workoutId` set) plus a single
/// rolling ad-hoc thread (`workoutId` null). Persisted so a thread survives
/// Android killing the app mid-workout.
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Null = the rolling ad-hoc thread; set = the thread for that workout.
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
