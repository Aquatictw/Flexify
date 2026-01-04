import 'package:drift/drift.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';

/// Types of personal records that can be achieved
enum RecordType {
  /// Best estimated one-rep max (Brzycki formula)
  best1RM,

  /// Best single-set volume (weight × reps)
  bestVolume,

  /// Heaviest weight lifted
  bestWeight,
}

/// Represents a personal record achievement
class RecordAchievement {
  final RecordType type;
  final double newValue;
  final double? previousValue;
  final String unit;

  const RecordAchievement({
    required this.type,
    required this.newValue,
    this.previousValue,
    required this.unit,
  });

  String get displayName {
    switch (type) {
      case RecordType.best1RM:
        return 'Best 1RM';
      case RecordType.bestVolume:
        return 'Best Volume';
      case RecordType.bestWeight:
        return 'Best Weight';
    }
  }

  String get emoji {
    switch (type) {
      case RecordType.best1RM:
        return '💪';
      case RecordType.bestVolume:
        return '🔥';
      case RecordType.bestWeight:
        return '🏆';
    }
  }

  double get improvement {
    if (previousValue == null || previousValue == 0) return 0;
    return ((newValue - previousValue!) / previousValue!) * 100;
  }
}

/// Calculates estimated 1RM using Brzycki formula
double calculate1RM(double weight, double reps) {
  if (reps <= 0) return 0;
  if (reps == 1) return weight;
  // Brzycki formula: weight / (1.0278 - 0.0278 * reps)
  if (weight >= 0) {
    return weight / (1.0278 - 0.0278 * reps);
  } else {
    return weight * (1.0278 - 0.0278 * reps);
  }
}

/// Calculates volume for a single set
double calculateVolume(double weight, double reps) {
  return weight * reps;
}

/// Check if a completed set achieves any new records
/// Returns a list of record achievements (can be multiple if multiple records are broken)
Future<List<RecordAchievement>> checkForRecords({
  required String exerciseName,
  required double weight,
  required double reps,
  required String unit,
  required int? excludeSetId,
}) async {
  final achievements = <RecordAchievement>[];

  // Get current best values for this exercise (excluding the current set)
  final bestQuery = '''
    SELECT
      MAX(weight) as best_weight,
      MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END) as best_1rm,
      MAX(weight * reps) as best_volume
    FROM gym_sets
    WHERE name = ?
      AND hidden = 0
      ${excludeSetId != null ? 'AND id != ?' : ''}
  ''';

  final variables = <Variable>[Variable.withString(exerciseName)];
  if (excludeSetId != null) {
    variables.add(Variable.withInt(excludeSetId));
  }

  final result = await db.customSelect(
    bestQuery,
    variables: variables,
  ).getSingleOrNull();

  if (result == null) {
    // First set for this exercise - all records!
    achievements.add(RecordAchievement(
      type: RecordType.bestWeight,
      newValue: weight,
      previousValue: null,
      unit: unit,
    ));
    achievements.add(RecordAchievement(
      type: RecordType.best1RM,
      newValue: calculate1RM(weight, reps),
      previousValue: null,
      unit: unit,
    ));
    achievements.add(RecordAchievement(
      type: RecordType.bestVolume,
      newValue: calculateVolume(weight, reps),
      previousValue: null,
      unit: unit,
    ));
    return achievements;
  }

  final previousBestWeight = result.read<double?>('best_weight') ?? 0.0;
  final previousBest1RM = result.read<double?>('best_1rm') ?? 0.0;
  final previousBestVolume = result.read<double?>('best_volume') ?? 0.0;

  // Check each record type
  if (weight > previousBestWeight) {
    achievements.add(RecordAchievement(
      type: RecordType.bestWeight,
      newValue: weight,
      previousValue: previousBestWeight,
      unit: unit,
    ));
  }

  final current1RM = calculate1RM(weight, reps);
  if (current1RM > previousBest1RM) {
    achievements.add(RecordAchievement(
      type: RecordType.best1RM,
      newValue: current1RM,
      previousValue: previousBest1RM,
      unit: unit,
    ));
  }

  final currentVolume = calculateVolume(weight, reps);
  if (currentVolume > previousBestVolume) {
    achievements.add(RecordAchievement(
      type: RecordType.bestVolume,
      newValue: currentVolume,
      previousValue: previousBestVolume,
      unit: unit,
    ));
  }

  return achievements;
}

/// Check if a specific set holds any records for its exercise
/// Returns a set of record types that this set holds
Future<Set<RecordType>> getSetRecords({
  required int setId,
  required String exerciseName,
  required double weight,
  required double reps,
}) async {
  final records = <RecordType>{};

  // Get current best values for this exercise
  final bestQuery = '''
    SELECT
      MAX(weight) as best_weight,
      MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END) as best_1rm,
      MAX(weight * reps) as best_volume
    FROM gym_sets
    WHERE name = ?
      AND hidden = 0
  ''';

  final result = await db.customSelect(
    bestQuery,
    variables: [Variable.withString(exerciseName)],
  ).getSingleOrNull();

  if (result == null) return records;

  final bestWeight = result.read<double?>('best_weight') ?? 0.0;
  final best1RM = result.read<double?>('best_1rm') ?? 0.0;
  final bestVolume = result.read<double?>('best_volume') ?? 0.0;

  // Check if this set's values match the best values
  if (weight >= bestWeight && weight > 0) {
    records.add(RecordType.bestWeight);
  }

  final set1RM = calculate1RM(weight, reps);
  if (set1RM >= best1RM && set1RM > 0) {
    records.add(RecordType.best1RM);
  }

  final setVolume = calculateVolume(weight, reps);
  if (setVolume >= bestVolume && setVolume > 0) {
    records.add(RecordType.bestVolume);
  }

  return records;
}

/// Get all sets with records for a specific workout
/// Returns a map of setId -> Set<RecordType>
Future<Map<int, Set<RecordType>>> getWorkoutRecords(int workoutId) async {
  final recordsMap = <int, Set<RecordType>>{};

  // Get all completed sets in this workout
  final sets = await (db.gymSets.select()
        ..where((s) =>
            s.workoutId.equals(workoutId) &
            s.hidden.equals(false) &
            s.cardio.equals(false)))
      .get();

  // Group sets by exercise name
  final setsByExercise = <String, List<GymSet>>{};
  for (final set in sets) {
    setsByExercise.putIfAbsent(set.name, () => []).add(set);
  }

  // For each exercise, find the all-time bests and check which sets in this workout match
  for (final entry in setsByExercise.entries) {
    final exerciseName = entry.key;
    final exerciseSets = entry.value;

    // Get all-time bests for this exercise
    final bestQuery = '''
      SELECT
        MAX(weight) as best_weight,
        MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END) as best_1rm,
        MAX(weight * reps) as best_volume
      FROM gym_sets
      WHERE name = ?
        AND hidden = 0
        AND cardio = 0
    ''';

    final result = await db.customSelect(
      bestQuery,
      variables: [Variable.withString(exerciseName)],
    ).getSingleOrNull();

    if (result == null) continue;

    final bestWeight = result.read<double?>('best_weight') ?? 0.0;
    final best1RM = result.read<double?>('best_1rm') ?? 0.0;
    final bestVolume = result.read<double?>('best_volume') ?? 0.0;

    // Check each set in this workout
    for (final set in exerciseSets) {
      final setRecords = <RecordType>{};

      if (set.weight >= bestWeight && bestWeight > 0) {
        setRecords.add(RecordType.bestWeight);
      }

      final set1RM = calculate1RM(set.weight, set.reps);
      if (set1RM >= best1RM && best1RM > 0) {
        setRecords.add(RecordType.best1RM);
      }

      final setVolume = calculateVolume(set.weight, set.reps);
      if (setVolume >= bestVolume && bestVolume > 0) {
        setRecords.add(RecordType.bestVolume);
      }

      if (setRecords.isNotEmpty) {
        recordsMap[set.id] = setRecords;
      }
    }
  }

  return recordsMap;
}

/// Check if a workout contains any record-breaking sets
Future<bool> workoutHasRecords(int workoutId) async {
  final records = await getWorkoutRecords(workoutId);
  return records.isNotEmpty;
}

/// Get the count of records in a workout
Future<int> getWorkoutRecordCount(int workoutId) async {
  final records = await getWorkoutRecords(workoutId);
  return records.values.fold<int>(0, (sum, recordSet) => sum + recordSet.length);
}
