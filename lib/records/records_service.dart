import 'package:drift/drift.dart';
import '../database/database.dart';
import '../main.dart';

// Cache for batch workout records: workoutId -> (setId -> record types).
final _prCache = <String,
    ({Map<int, Map<int, Set<RecordType>>> records, DateTime cachedAt})>{};
const _cacheDuration = Duration(seconds: 30);

/// Clears the PR cache (call when new sets are added/modified)
void clearPRCache() {
  _prCache.clear();
}

/// Types of personal records that can be achieved
enum RecordType {
  /// Best estimated one-rep max (Brzycki formula)
  best1RM,

  /// Best single-set volume (weight × reps)
  bestVolume,

  /// Heaviest weight lifted
  bestWeight,

  /// Longest cardio duration
  bestDuration,

  /// Longest cardio distance
  bestDistance,

  /// Fastest cardio speed
  bestSpeed,

  /// Steepest cardio incline
  bestIncline,
}

/// Compact badge label for history cards, e.g. "1RM PR" / "Vol PR" / "Wt PR".
String recordShortLabel(RecordType t) => switch (t) {
      RecordType.best1RM => '1RM',
      RecordType.bestVolume => 'Vol',
      RecordType.bestWeight => 'Wt',
      RecordType.bestDuration => 'Time',
      RecordType.bestDistance => 'Dist',
      RecordType.bestSpeed => 'Speed',
      RecordType.bestIncline => 'Incl',
    };

/// Represents a personal record achievement
class RecordAchievement {
  const RecordAchievement({
    required this.type,
    required this.newValue,
    required this.unit,
    this.previousValue,
  });
  final RecordType type;
  final double newValue;
  final double? previousValue;
  final String unit;

  String get displayName {
    switch (type) {
      case RecordType.best1RM:
        return 'Best 1RM';
      case RecordType.bestVolume:
        return 'Best Volume';
      case RecordType.bestWeight:
        return 'Best Weight';
      case RecordType.bestDuration:
        return 'Best Time';
      case RecordType.bestDistance:
        return 'Best Distance';
      case RecordType.bestSpeed:
        return 'Best Speed';
      case RecordType.bestIncline:
        return 'Best Incline';
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
      case RecordType.bestDuration:
        return '⏱';
      case RecordType.bestDistance:
        return '📍';
      case RecordType.bestSpeed:
        return '⚡';
      case RecordType.bestIncline:
        return '⛰';
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

double calculateCardioSpeed(double distance, double durationMinutes) {
  if (durationMinutes <= 0) return 0;
  return distance / durationMinutes * 60;
}

Set<RecordType> calculateCardioRecords(GymSet set, Iterable<GymSet> otherSets) {
  final records = <RecordType>{};
  final others = otherSets.where((s) => s.cardio);

  if (others.isEmpty) {
    records
      ..add(RecordType.bestDuration)
      ..add(RecordType.bestDistance)
      ..add(RecordType.bestIncline);
    if (set.duration > 0) records.add(RecordType.bestSpeed);
    return records;
  }

  var bestDuration = 0.0;
  var bestDistance = 0.0;
  var bestSpeed = 0.0;
  var bestIncline = 0;
  for (final other in others) {
    if (other.duration > bestDuration) bestDuration = other.duration;
    if (other.distance > bestDistance) bestDistance = other.distance;
    final speed = calculateCardioSpeed(other.distance, other.duration);
    if (speed > bestSpeed) bestSpeed = speed;
    if ((other.incline ?? 0) > bestIncline) {
      bestIncline = other.incline ?? 0;
    }
  }

  if (set.duration > bestDuration) records.add(RecordType.bestDuration);
  if (set.distance > bestDistance) records.add(RecordType.bestDistance);
  if (calculateCardioSpeed(set.distance, set.duration) > bestSpeed) {
    records.add(RecordType.bestSpeed);
  }
  if ((set.incline ?? 0) > bestIncline) records.add(RecordType.bestIncline);
  return records;
}

/// Check if a completed set achieves any new records
/// Returns a list of record achievements (can be multiple if multiple records are broken)
Future<List<RecordAchievement>> checkForRecords({
  required String exerciseName,
  required double weight,
  required double reps,
  required String unit,
  required int? excludeSetId,
  bool cardio = false,
  double duration = 0,
  double distance = 0,
  int? incline,
}) async {
  final achievements = <RecordAchievement>[];

  if (cardio) {
    final bestQuery = '''
      SELECT
        MAX(duration) as best_duration,
        MAX(distance) as best_distance,
        MAX(CASE WHEN duration > 0 THEN distance / duration * 60 ELSE NULL END) as best_speed,
        MAX(incline) as best_incline
      FROM gym_sets
      WHERE name = ?
        AND hidden = 0
        AND warmup = 0
        AND cardio = 1
        ${excludeSetId != null ? 'AND id != ?' : ''}
    ''';

    final variables = <Variable>[Variable.withString(exerciseName)];
    if (excludeSetId != null) {
      variables.add(Variable.withInt(excludeSetId));
    }

    final result = await db
        .customSelect(
          bestQuery,
          variables: variables,
        )
        .getSingleOrNull();

    final previousBestDuration = result?.read<double?>('best_duration');
    final previousBestDistance = result?.read<double?>('best_distance');
    final previousBestSpeed = result?.read<double?>('best_speed');
    final previousBestIncline = result?.read<int?>('best_incline');
    final isFirst = previousBestDuration == null &&
        previousBestDistance == null &&
        previousBestSpeed == null &&
        previousBestIncline == null;
    final currentSpeed = duration > 0 ? distance / duration * 60 : 0.0;

    if (isFirst || duration > (previousBestDuration ?? 0)) {
      achievements.add(
        RecordAchievement(
          type: RecordType.bestDuration,
          newValue: duration,
          previousValue: previousBestDuration,
          unit: 'min',
        ),
      );
    }
    if (isFirst || distance > (previousBestDistance ?? 0)) {
      achievements.add(
        RecordAchievement(
          type: RecordType.bestDistance,
          newValue: distance,
          previousValue: previousBestDistance,
          unit: unit,
        ),
      );
    }
    if (duration > 0 && (isFirst || currentSpeed > (previousBestSpeed ?? 0))) {
      achievements.add(
        RecordAchievement(
          type: RecordType.bestSpeed,
          newValue: currentSpeed,
          previousValue: previousBestSpeed,
          unit: '$unit/h',
        ),
      );
    }
    if (isFirst || (incline ?? 0) > (previousBestIncline ?? 0)) {
      achievements.add(
        RecordAchievement(
          type: RecordType.bestIncline,
          newValue: (incline ?? 0).toDouble(),
          previousValue: previousBestIncline?.toDouble(),
          unit: '%',
        ),
      );
    }

    return achievements;
  }

  // Get current best values for this exercise (excluding the current set)
  final bestQuery = '''
    SELECT
      MAX(weight) as best_weight,
      MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END) as best_1rm,
      MAX(weight * reps) as best_volume
    FROM gym_sets
    WHERE name = ?
      AND hidden = 0
      AND warmup = 0
      AND cardio = 0
      ${excludeSetId != null ? 'AND id != ?' : ''}
  ''';

  final variables = <Variable>[Variable.withString(exerciseName)];
  if (excludeSetId != null) {
    variables.add(Variable.withInt(excludeSetId));
  }

  final result = await db
      .customSelect(
        bestQuery,
        variables: variables,
      )
      .getSingleOrNull();

  if (result == null) {
    // First set for this exercise - all records!
    achievements.add(
      RecordAchievement(
        type: RecordType.bestWeight,
        newValue: weight,
        unit: unit,
      ),
    );
    achievements.add(
      RecordAchievement(
        type: RecordType.best1RM,
        newValue: calculate1RM(weight, reps),
        unit: unit,
      ),
    );
    achievements.add(
      RecordAchievement(
        type: RecordType.bestVolume,
        newValue: calculateVolume(weight, reps),
        unit: unit,
      ),
    );
    return achievements;
  }

  final previousBestWeight = result.read<double?>('best_weight') ?? 0.0;
  final previousBest1RM = result.read<double?>('best_1rm') ?? 0.0;
  final previousBestVolume = result.read<double?>('best_volume') ?? 0.0;

  // Check each record type
  if (weight > previousBestWeight) {
    achievements.add(
      RecordAchievement(
        type: RecordType.bestWeight,
        newValue: weight,
        previousValue: previousBestWeight,
        unit: unit,
      ),
    );
  }

  final current1RM = calculate1RM(weight, reps);
  if (current1RM > previousBest1RM) {
    achievements.add(
      RecordAchievement(
        type: RecordType.best1RM,
        newValue: current1RM,
        previousValue: previousBest1RM,
        unit: unit,
      ),
    );
  }

  final currentVolume = calculateVolume(weight, reps);
  if (currentVolume > previousBestVolume) {
    achievements.add(
      RecordAchievement(
        type: RecordType.bestVolume,
        newValue: currentVolume,
        previousValue: previousBestVolume,
        unit: unit,
      ),
    );
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

  // Get current best values for this exercise (excluding this set)
  const bestQuery = '''
    SELECT
      MAX(weight) as best_weight,
      MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END) as best_1rm,
      MAX(weight * reps) as best_volume
    FROM gym_sets
    WHERE name = ?
      AND hidden = 0
      AND warmup = 0
      AND cardio = 0
      AND id != ?
  ''';

  final result = await db.customSelect(
    bestQuery,
    variables: [Variable.withString(exerciseName), Variable.withInt(setId)],
  ).getSingleOrNull();

  if (result == null) {
    // No other sets exist - this must be a record
    if (weight > 0) records.add(RecordType.bestWeight);
    final set1RM = calculate1RM(weight, reps);
    if (set1RM > 0) records.add(RecordType.best1RM);
    final setVolume = calculateVolume(weight, reps);
    if (setVolume > 0) records.add(RecordType.bestVolume);
    return records;
  }

  final bestWeight = result.read<double?>('best_weight') ?? 0.0;
  final best1RM = result.read<double?>('best_1rm') ?? 0.0;
  final bestVolume = result.read<double?>('best_volume') ?? 0.0;

  // Check if this set beats the best of all OTHER sets (strict >)
  if (weight > bestWeight) {
    records.add(RecordType.bestWeight);
  }

  final set1RM = calculate1RM(weight, reps);
  if (set1RM > best1RM) {
    records.add(RecordType.best1RM);
  }

  final setVolume = calculateVolume(weight, reps);
  if (setVolume > bestVolume) {
    records.add(RecordType.bestVolume);
  }

  return records;
}

/// Get all sets with records for a specific workout
/// Returns a map of setId -> `Set<RecordType>`
Future<Map<int, Set<RecordType>>> getWorkoutRecords(int workoutId) async {
  final recordsMap = <int, Set<RecordType>>{};

  // Get all completed sets in this workout
  final sets = await (db.gymSets.select()
        ..where(
          (s) =>
              s.workoutId.equals(workoutId) &
              s.hidden.equals(false) &
              s.warmup.equals(false) &
              s.cardio.equals(false),
        ))
      .get();

  // Group sets by exercise name
  final setsByExercise = <String, List<GymSet>>{};
  for (final set in sets) {
    setsByExercise.putIfAbsent(set.name, () => []).add(set);
  }

  // For each exercise, find the all-time bests and check which sets hold records
  for (final entry in setsByExercise.entries) {
    final exerciseName = entry.key;
    final exerciseSets = entry.value;

    // Get all-time bests for this exercise
    const bestQuery = '''
      SELECT
        MAX(weight) as best_weight,
        MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END) as best_1rm,
        MAX(weight * reps) as best_volume
      FROM gym_sets
      WHERE name = ?
        AND hidden = 0
        AND warmup = 0
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

    // Find the minimum set ID for each record type (tie-breaking)
    int? minIdForWeight;
    int? minIdForRM;
    int? minIdForVolume;

    // Get all sets for this exercise to find earliest record holders
    final allExerciseSets = await (db.gymSets.select()
          ..where(
            (s) =>
                s.name.equals(exerciseName) &
                s.hidden.equals(false) &
                s.warmup.equals(false) &
                s.cardio.equals(false),
          ))
        .get();

    for (final set in allExerciseSets) {
      if (set.weight == bestWeight && bestWeight > 0) {
        minIdForWeight = minIdForWeight == null
            ? set.id
            : (set.id < minIdForWeight ? set.id : minIdForWeight);
      }
      final set1RM = calculate1RM(set.weight, set.reps);
      if (set1RM == best1RM && best1RM > 0) {
        minIdForRM = minIdForRM == null
            ? set.id
            : (set.id < minIdForRM ? set.id : minIdForRM);
      }
      final setVolume = calculateVolume(set.weight, set.reps);
      if (setVolume == bestVolume && bestVolume > 0) {
        minIdForVolume = minIdForVolume == null
            ? set.id
            : (set.id < minIdForVolume ? set.id : minIdForVolume);
      }
    }

    // Check each set in this workout - only mark if it's the earliest with that value
    for (final set in exerciseSets) {
      final setRecords = <RecordType>{};

      if (set.weight == bestWeight && set.id == minIdForWeight) {
        setRecords.add(RecordType.bestWeight);
      }

      final set1RM = calculate1RM(set.weight, set.reps);
      if (set1RM == best1RM && set.id == minIdForRM) {
        setRecords.add(RecordType.best1RM);
      }

      final setVolume = calculateVolume(set.weight, set.reps);
      if (setVolume == bestVolume && set.id == minIdForVolume) {
        setRecords.add(RecordType.bestVolume);
      }

      if (setRecords.isNotEmpty) {
        recordsMap[set.id] = setRecords;
      }
    }
  }

  final cardioSets = await (db.gymSets.select()
        ..where(
          (s) =>
              s.workoutId.equals(workoutId) &
              s.hidden.equals(false) &
              s.warmup.equals(false) &
              s.cardio.equals(true),
        ))
      .get();

  for (final set in cardioSets) {
    final allExerciseSets = await (db.gymSets.select()
          ..where(
            (s) =>
                s.name.equals(set.name) &
                s.hidden.equals(false) &
                s.warmup.equals(false) &
                s.cardio.equals(true),
          ))
        .get();
    final recordTypes = calculateCardioRecords(
      set,
      allExerciseSets.where((other) => other.id != set.id),
    );
    if (recordTypes.isNotEmpty) recordsMap[set.id] = recordTypes;
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
  return records.values
      .fold<int>(0, (sum, recordSet) => sum + recordSet.length);
}

/// Get record counts for multiple workouts efficiently
/// Returns a map of workoutId -> number of record-breaking sets
Future<Map<int, int>> getBatchWorkoutRecordCounts(List<int> workoutIds) async {
  final records = await getBatchWorkoutRecords(workoutIds);
  return {
    for (final e in records.entries)
      e.key: e.value.values.fold<int>(0, (sum, types) => sum + types.length),
  };
}

/// Get record-holding sets for multiple workouts in one batch.
///
/// Returns workoutId -> (setId -> record types). This is the single-pass
/// engine behind the history feed: computing it once for the whole page
/// replaces the old per-workout [getWorkoutRecords] N+1 loop.
Future<Map<int, Map<int, Set<RecordType>>>> getBatchWorkoutRecords(
  List<int> workoutIds,
) async {
  if (workoutIds.isEmpty) return {};

  // Create cache key from sorted workout IDs
  final sortedIds = List<int>.from(workoutIds)..sort();
  final cacheKey = sortedIds.join(',');

  // Check cache
  final cached = _prCache[cacheKey];
  if (cached != null) {
    final age = DateTime.now().difference(cached.cachedAt);
    if (age < _cacheDuration) {
      return cached.records;
    }
  }

  // Clean up old cache entries (prevent memory leak)
  _prCache.removeWhere((key, value) {
    final age = DateTime.now().difference(value.cachedAt);
    return age >= _cacheDuration;
  });

  final workoutRecords = <int, Map<int, Set<RecordType>>>{};

  // Get all sets from these workouts
  final workoutSets = await (db.gymSets.select()
        ..where(
          (s) =>
              s.workoutId.isIn(workoutIds) &
              s.hidden.equals(false) &
              s.warmup.equals(false) &
              s.cardio.equals(false),
        ))
      .get();

  // Group by exercise name to get all-time bests
  final exerciseNames = workoutSets.map((s) => s.name).toSet();
  final exerciseBests =
      <String, ({double weight, double rm1, double volume})>{};

  // Get all-time bests for each exercise in a single batch
  for (final exerciseName in exerciseNames) {
    const bestQuery = '''
      SELECT
        MAX(weight) as best_weight,
        MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END) as best_1rm,
        MAX(weight * reps) as best_volume
      FROM gym_sets
      WHERE name = ?
        AND hidden = 0
        AND warmup = 0
        AND cardio = 0
    ''';

    final result = await db.customSelect(
      bestQuery,
      variables: [Variable.withString(exerciseName)],
    ).getSingleOrNull();

    if (result != null) {
      exerciseBests[exerciseName] = (
        weight: result.read<double?>('best_weight') ?? 0.0,
        rm1: result.read<double?>('best_1rm') ?? 0.0,
        volume: result.read<double?>('best_volume') ?? 0.0,
      );
    }
  }

  // Find minimum set IDs for each record type per exercise (tie-breaking)
  final recordHolders =
      <String, ({int? weightId, int? rm1Id, int? volumeId})>{};

  for (final exerciseName in exerciseNames) {
    final bests = exerciseBests[exerciseName];
    if (bests == null) continue;

    // Get all sets for this exercise to find earliest record holders
    final allSets = await (db.gymSets.select()
          ..where(
            (s) =>
                s.name.equals(exerciseName) &
                s.hidden.equals(false) &
                s.warmup.equals(false) &
                s.cardio.equals(false),
          ))
        .get();

    int? minIdForWeight;
    int? minIdForRM;
    int? minIdForVolume;

    for (final set in allSets) {
      if (set.weight == bests.weight && bests.weight > 0) {
        minIdForWeight = minIdForWeight == null
            ? set.id
            : (set.id < minIdForWeight ? set.id : minIdForWeight);
      }
      final set1RM = calculate1RM(set.weight, set.reps);
      if (set1RM == bests.rm1 && bests.rm1 > 0) {
        minIdForRM = minIdForRM == null
            ? set.id
            : (set.id < minIdForRM ? set.id : minIdForRM);
      }
      final setVolume = calculateVolume(set.weight, set.reps);
      if (setVolume == bests.volume && bests.volume > 0) {
        minIdForVolume = minIdForVolume == null
            ? set.id
            : (set.id < minIdForVolume ? set.id : minIdForVolume);
      }
    }

    recordHolders[exerciseName] = (
      weightId: minIdForWeight,
      rm1Id: minIdForRM,
      volumeId: minIdForVolume,
    );
  }

  // Check each set - only mark if it's the earliest with that record value
  for (final set in workoutSets) {
    final bests = exerciseBests[set.name];
    final holders = recordHolders[set.name];
    if (bests == null || holders == null || set.workoutId == null) continue;

    final types = <RecordType>{};

    if (set.weight == bests.weight && set.id == holders.weightId) {
      types.add(RecordType.bestWeight);
    }

    final set1RM = calculate1RM(set.weight, set.reps);
    if (set1RM == bests.rm1 && set.id == holders.rm1Id) {
      types.add(RecordType.best1RM);
    }

    final setVolume = calculateVolume(set.weight, set.reps);
    if (setVolume == bests.volume && set.id == holders.volumeId) {
      types.add(RecordType.bestVolume);
    }

    if (types.isNotEmpty) {
      (workoutRecords[set.workoutId!] ??= <int, Set<RecordType>>{})[set.id] =
          types;
    }
  }

  final cardioWorkoutSets = await (db.gymSets.select()
        ..where(
          (s) =>
              s.workoutId.isIn(workoutIds) &
              s.hidden.equals(false) &
              s.warmup.equals(false) &
              s.cardio.equals(true),
        ))
      .get();

  final cardioExerciseNames = cardioWorkoutSets.map((s) => s.name).toSet();
  for (final exerciseName in cardioExerciseNames) {
    final allExerciseSets = await (db.gymSets.select()
          ..where(
            (s) =>
                s.name.equals(exerciseName) &
                s.hidden.equals(false) &
                s.warmup.equals(false) &
                s.cardio.equals(true),
          ))
        .get();

    for (final set in cardioWorkoutSets
        .where((workoutSet) => workoutSet.name == exerciseName)) {
      if (set.workoutId == null) continue;
      final recordTypes = calculateCardioRecords(
        set,
        allExerciseSets.where((other) => other.id != set.id),
      );
      if (recordTypes.isNotEmpty) {
        (workoutRecords[set.workoutId!] ??= <int, Set<RecordType>>{})[set.id] =
            recordTypes;
      }
    }
  }

  // Store in cache before returning
  _prCache[cacheKey] = (records: workoutRecords, cachedAt: DateTime.now());

  return workoutRecords;
}
