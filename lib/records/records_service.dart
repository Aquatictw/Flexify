import 'dart:math';

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

typedef _StrengthBest = ({double weight, double rm1, double volume});
typedef _StrengthHolders = ({int? weightId, int? rm1Id, int? volumeId});

// SQLite spelling of [calculate1RM], used to pick the earliest set holding the
// 1RM record. Must stay bit-for-bit identical to the Dart function, since the
// caller compares its result to a Dart-computed value.
const _sqlDart1RM = '''
  CASE
    WHEN g.reps <= 0 THEN 0
    WHEN g.reps = 1 THEN g.weight
    WHEN g.weight >= 0 THEN g.weight / (1.0278 - 0.0278 * g.reps)
    ELSE g.weight * (1.0278 - 0.0278 * g.reps)
  END''';

/// All-time strength bests and their earliest holders for [names], in one
/// grouped query per chunk instead of two full-history queries per name.
///
/// Record semantics are unchanged: hidden/warmup/cardio rows are excluded, the
/// bests use the same MAX expressions as everywhere else, and ties resolve to
/// the lowest set id (only when the best is > 0, as before).
Future<
    ({
      Map<String, _StrengthBest> exerciseBests,
      Map<String, _StrengthHolders> recordHolders
    })> _strengthBests(Set<String> names) async {
  final exerciseBests = <String, _StrengthBest>{};
  final recordHolders = <String, _StrengthHolders>{};
  if (names.isEmpty)
    return (exerciseBests: exerciseBests, recordHolders: recordHolders);

  // Chunked so a large exercise library can't blow SQLite's variable limit.
  final all = names.toList();
  for (var start = 0; start < all.length; start += 400) {
    final chunk = all.sublist(start, min(start + 400, all.length));
    final placeholders = List.filled(chunk.length, '?').join(',');

    final rows = await db.customSelect(
      '''
      WITH bests AS (
        SELECT name,
          MAX(weight) AS bw,
          MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END) AS b1,
          MAX(weight * reps) AS bv
        FROM gym_sets
        WHERE hidden = 0 AND warmup = 0 AND cardio = 0 AND name IN ($placeholders)
        GROUP BY name
      )
      SELECT b.name AS name,
        b.bw AS best_weight, b.b1 AS best_1rm, b.bv AS best_volume,
        MIN(CASE WHEN b.bw > 0 AND g.weight = b.bw THEN g.id END) AS weight_id,
        MIN(CASE WHEN b.b1 > 0 AND ($_sqlDart1RM) = b.b1 THEN g.id END) AS rm1_id,
        MIN(CASE WHEN b.bv > 0 AND g.weight * g.reps = b.bv THEN g.id END) AS volume_id
      FROM bests b
      JOIN gym_sets g ON g.name = b.name
      WHERE g.hidden = 0 AND g.warmup = 0 AND g.cardio = 0
      GROUP BY b.name
      ''',
      variables: chunk.map(Variable.withString).toList(),
    ).get();

    for (final row in rows) {
      final name = row.read<String>('name');
      exerciseBests[name] = (
        weight: row.read<double?>('best_weight') ?? 0.0,
        rm1: row.read<double?>('best_1rm') ?? 0.0,
        volume: row.read<double?>('best_volume') ?? 0.0,
      );
      recordHolders[name] = (
        weightId: row.read<int?>('weight_id'),
        rm1Id: row.read<int?>('rm1_id'),
        volumeId: row.read<int?>('volume_id'),
      );
    }
  }

  return (exerciseBests: exerciseBests, recordHolders: recordHolders);
}

/// Get all sets with records for a specific workout
/// Returns a map of setId -> `Set<RecordType>`
///
/// Thin wrapper over [getBatchWorkoutRecords] so both entry points share one
/// record definition (and one bounded set of queries).
Future<Map<int, Set<RecordType>>> getWorkoutRecords(int workoutId) async {
  final records = await getBatchWorkoutRecords([workoutId]);
  return records[workoutId] ?? <int, Set<RecordType>>{};
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

  // All-time bests plus the earliest set holding each of them, for every
  // exercise on the page, in one grouped query. (Was two full-history queries
  // per distinct exercise name.)
  final (:exerciseBests, :recordHolders) =
      await _strengthBests(workoutSets.map((s) => s.name).toSet());

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

  final cardioExerciseNames =
      cardioWorkoutSets.map((s) => s.name).toSet().toList();
  if (cardioExerciseNames.isNotEmpty) {
    // One query for every cardio exercise on the page, not one per name.
    final cardioHistory = await (db.gymSets.select()
          ..where(
            (s) =>
                s.name.isIn(cardioExerciseNames) &
                s.hidden.equals(false) &
                s.warmup.equals(false) &
                s.cardio.equals(true),
          ))
        .get();

    final historyByName = <String, List<GymSet>>{};
    for (final set in cardioHistory) {
      (historyByName[set.name] ??= []).add(set);
    }

    for (final set in cardioWorkoutSets) {
      if (set.workoutId == null) continue;
      final recordTypes = calculateCardioRecords(
        set,
        (historyByName[set.name] ?? const <GymSet>[])
            .where((other) => other.id != set.id),
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
