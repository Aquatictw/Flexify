import 'package:drift/drift.dart';

/// One coach conversation.
///
/// Two kinds, distinguished by [workoutId]:
///
/// - **Workout thread** (`workoutId` set) — exactly one per workout, created the
///   first time the in-workout sheet sends anything. Never listed in the Coach
///   tab's sidebar: its write tools target the *live* session, so reopening it
///   from outside that workout would put it in a context it was not written in.
/// - **Ad-hoc thread** (`workoutId` null) — many, one per conversation started
///   from the Coach tab, listed newest-first in the sidebar.
///
/// A thread row is only written once its first message is, so starting a new
/// conversation and backing out leaves no empty entry in the sidebar.
class ChatThreads extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Null = an ad-hoc thread; set = the thread for that workout.
  IntColumn get workoutId => integer().nullable()();

  /// Sidebar label, taken from the thread's first user message. Null until
  /// that message exists.
  TextColumn get title => text().nullable()();

  DateTimeColumn get created => dateTime()();

  /// Last message time, which is what the sidebar orders by.
  DateTimeColumn get updated => dateTime()();
}
