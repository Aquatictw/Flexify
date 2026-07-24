import 'package:drift/drift.dart';

import '../main.dart';
import '../records/records_service.dart';
import 'database.dart';

/// Helper class for complex database queries to optimize performance
class QueryHelpers {
  /// Loads exercise data in a single query instead of 3+ sequential queries.
  ///
  /// Returns a record containing:
  /// - previousSets: All sets from the most recent workout with this exercise
  /// - existingSets: Sets from current workout for this exercise instance
  /// - supersetInfo: Superset metadata if exercise is in a superset
  static Future<ExerciseLoadData> loadExerciseData({
    required String exerciseName,
    required int sequence,
    int? workoutId,
  }) async {
    List<GymSet> previousSets = [];
    List<GymSet> existingSets = [];
    String? supersetId;
    int? supersetPosition;
    int? supersetIndex;

    // Part 1: Get existing sets from current workout (if any)
    if (workoutId != null) {
      existingSets = await (db.gymSets.select()
            ..where(
              (tbl) =>
                  tbl.name.equals(exerciseName) &
                  tbl.workoutId.equals(workoutId) &
                  tbl.sequence.equals(sequence),
            )
            ..orderBy([
              (u) => OrderingTerm(
                    expression: const CustomExpression<int>(
                      'COALESCE(set_order, CAST((julianday(created) - 2440587.5) * 86400000 AS INTEGER))',
                    ),
                  ),
            ]))
          .get();

      // Load superset info from first existing set
      if (existingSets.isNotEmpty) {
        final firstSet = existingSets.first;
        supersetId = firstSet.supersetId;
        supersetPosition = firstSet.supersetPosition;

        // Calculate superset index if in a superset
        if (supersetId != null) {
          final allSupersets = await (db.gymSets.selectOnly(distinct: true)
                ..addColumns([db.gymSets.supersetId])
                ..where(
                  db.gymSets.workoutId.equals(workoutId) &
                      db.gymSets.supersetId.isNotNull(),
                )
                ..orderBy([
                  OrderingTerm(
                    expression: db.gymSets.created,
                  ),
                ]))
              .get();

          final supersetIds = allSupersets
              .map((row) => row.read(db.gymSets.supersetId))
              .where((id) => id != null)
              .toSet()
              .toList();

          supersetIndex = supersetIds.indexOf(supersetId);
        }
      }
    }

    // Part 2: Get previous sets from most recent completed workout
    // Use a subquery to find the most recent workout ID, then load sets
    final recentWorkoutQuery = db.gymSets.selectOnly()
      ..addColumns([db.gymSets.workoutId])
      ..where(
        db.gymSets.name.equals(exerciseName) &
            db.gymSets.hidden.equals(false) &
            db.gymSets.workoutId.isNotNull(),
      )
      ..orderBy([
        OrderingTerm(
          expression: db.gymSets.created,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(1);

    final recentWorkoutRow = await recentWorkoutQuery.getSingleOrNull();
    final recentWorkoutId = recentWorkoutRow?.read(db.gymSets.workoutId);

    if (recentWorkoutId != null) {
      previousSets = await (db.gymSets.select()
            ..where(
              (tbl) =>
                  tbl.name.equals(exerciseName) &
                  tbl.workoutId.equals(recentWorkoutId) &
                  tbl.hidden.equals(false),
            )
            ..orderBy([
              (u) => OrderingTerm(expression: u.created),
            ]))
          .get();
    }

    return ExerciseLoadData(
      previousSets: previousSets,
      existingSets: existingSets,
      supersetId: supersetId,
      supersetPosition: supersetPosition,
      supersetIndex: supersetIndex,
    );
  }

  /// Batch-loads record information for multiple sets at once.
  ///
  /// This replaces the N+1 query problem where each set calls getSetRecords()
  /// individually. Instead, we load all records for an exercise in one query.
  static Future<Map<int, Set<RecordType>>> batchLoadSetRecords({
    required String exerciseName,
    required List<GymSet> sets,
  }) async {
    if (sets.isEmpty) return {};

    final records = <int, Set<RecordType>>{};

    // Get all historical sets for this exercise to compare against
    final allSetsForExercise = await (db.gymSets.select()
          ..where(
            (tbl) =>
                tbl.name.equals(exerciseName) &
                tbl.hidden.equals(false) &
                tbl.warmup.equals(false),
          )
          ..orderBy([
            (u) => OrderingTerm(expression: u.created, mode: OrderingMode.desc),
          ]))
        .get();

    // For each set, determine records by comparing against historical data
    for (final set in sets) {
      if (set.hidden || set.warmup) {
        records[set.id] = {};
        continue;
      }

      final recordTypes = <RecordType>{};

      // Get all sets except this one for comparison
      final otherSets = allSetsForExercise.where((s) => s.id != set.id);

      if (set.cardio) {
        records[set.id] = calculateCardioRecords(set, otherSets);
        continue;
      }

      if (otherSets.isEmpty) {
        // No other sets exist - this must be a record
        if (set.weight > 0) recordTypes.add(RecordType.bestWeight);
        final set1RM = calculate1RM(set.weight, set.reps);
        if (set1RM > 0) recordTypes.add(RecordType.best1RM);
        final setVolume = calculateVolume(set.weight, set.reps);
        if (setVolume > 0) recordTypes.add(RecordType.bestVolume);
      } else {
        // Find best values from other sets
        double bestWeight = 0;
        double best1RM = 0;
        double bestVolume = 0;

        for (final other in otherSets) {
          if (other.weight > bestWeight) {
            bestWeight = other.weight;
          }
          final other1RM = calculate1RM(other.weight, other.reps);
          if (other1RM > best1RM) {
            best1RM = other1RM;
          }
          final otherVolume = calculateVolume(other.weight, other.reps);
          if (otherVolume > bestVolume) {
            bestVolume = otherVolume;
          }
        }

        // Check if this set beats the best of all OTHER sets
        if (set.weight > bestWeight) {
          recordTypes.add(RecordType.bestWeight);
        }

        final set1RM = calculate1RM(set.weight, set.reps);
        if (set1RM > best1RM) {
          recordTypes.add(RecordType.best1RM);
        }

        final setVolume = calculateVolume(set.weight, set.reps);
        if (setVolume > bestVolume) {
          recordTypes.add(RecordType.bestVolume);
        }
      }

      records[set.id] = recordTypes;
    }

    return records;
  }

  /// Loads all data needed to resume a workout in a single optimized query.
  ///
  /// Returns both active sets and tombstone markers for removed exercises.
  static Future<WorkoutResumeData> loadWorkoutResumeData({
    required int workoutId,
  }) async {
    // Load ALL sets for this workout including tombstones in one query
    final allSets = await (db.gymSets.select()
          ..where((s) => s.workoutId.equals(workoutId))
          ..orderBy([
            (s) => OrderingTerm(expression: s.sequence),
          ]))
        .get();

    // Separate active sets from tombstones
    final existingSets = allSets.where((s) => s.sequence >= 0).toList();

    final removedExercises =
        allSets.where((s) => s.sequence == -1).map((s) => s.name).toSet();

    return WorkoutResumeData(
      existingSets: existingSets,
      removedExercises: removedExercises,
    );
  }
}

/// Data returned by loadExerciseData query
class ExerciseLoadData {
  ExerciseLoadData({
    required this.previousSets,
    required this.existingSets,
    this.supersetId,
    this.supersetPosition,
    this.supersetIndex,
  });
  final List<GymSet> previousSets;
  final List<GymSet> existingSets;
  final String? supersetId;
  final int? supersetPosition;
  final int? supersetIndex;
}

/// Data returned by loadWorkoutResumeData
class WorkoutResumeData {
  WorkoutResumeData({
    required this.existingSets,
    required this.removedExercises,
  });
  final List<GymSet> existingSets;
  final Set<String> removedExercises;
}
