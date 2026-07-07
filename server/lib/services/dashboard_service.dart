import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Filename validation pattern for backup files.
final _backupPattern = RegExp(r'^jackedlog_backup_\d{4}-\d{2}-\d{2}\.db$');

/// Query layer for dashboard analytics.
///
/// Opens uploaded SQLite backup files in read-only mode and provides
/// methods to extract workout statistics, history, and details.
class DashboardService {
  final String dataDir;
  Database? _db;
  String? _currentFile;
  DateTime? _currentModified;
  int? _currentSize;

  DashboardService(this.dataDir);

  bool get isOpen => _db != null;
  String? get currentFile => _currentFile;

  /// Keep the dashboard handle pointed at the requested backup.
  ///
  /// Same-day uploads replace the existing file in place, so checking only the
  /// filename is not enough. Reopen when the path, mtime, or size changes.
  bool ensureOpen({String? filename}) {
    final filePath = _resolveBackupPath(filename);
    if (filePath == null) {
      close();
      return false;
    }

    final stat = File(filePath).statSync();
    if (_db != null &&
        _currentFile == filePath &&
        _currentModified == stat.modified &&
        _currentSize == stat.size) {
      return true;
    }

    return open(filename: filename);
  }

  /// Open the latest (or specified) backup file in read-only mode.
  /// Returns false if no backup exists or schema version < 48.
  bool open({String? filename}) {
    close();

    final filePath = _resolveBackupPath(filename);
    if (filePath == null) return false;

    try {
      final stat = File(filePath).statSync();
      final db = sqlite3.open(filePath, mode: OpenMode.readOnly);
      final versionResult = db.select('PRAGMA user_version');
      final version = versionResult.isNotEmpty
          ? versionResult.first.values.first as int
          : 0;
      if (version < 48) {
        db.close();
        return false;
      }
      _db = db;
      _currentFile = filePath;
      _currentModified = stat.modified;
      _currentSize = stat.size;
      return true;
    } catch (e) {
      close();
      return false;
    }
  }

  /// Close the current database handle.
  void close() {
    _db?.close();
    _db = null;
    _currentFile = null;
    _currentModified = null;
    _currentSize = null;
  }

  /// Get overview statistics for the dashboard.
  ///
  /// Returns a map with keys: workoutCount, totalVolume, currentStreak,
  /// totalTimeSeconds, hasData. Supports period filtering (week/month/year/all).
  Map<String, dynamic> getOverviewStats({String? period}) {
    if (_db == null) {
      return {
        'workoutCount': 0,
        'totalVolume': 0.0,
        'currentStreak': 0,
        'totalTimeSeconds': 0,
        'hasData': false,
      };
    }

    final startEpochSeconds = _periodToEpoch(period);

    // Workout count
    final countResult = _db!.select(
      'SELECT COUNT(DISTINCT id) as workout_count FROM workouts WHERE start_time >= ?',
      [startEpochSeconds],
    );
    final workoutCount = countResult.first['workout_count'] as int;

    // Total volume
    final volumeResult = _db!.select(
      'SELECT COALESCE(SUM(weight * reps), 0) as total_volume FROM gym_sets WHERE created >= ? AND hidden = 0 AND cardio = 0',
      [startEpochSeconds],
    );
    final totalVolume = (volumeResult.first['total_volume'] as num).toDouble();

    // Training time
    final timeResult = _db!.select(
      'SELECT COALESCE(SUM(end_time - start_time), 0) as total_seconds FROM workouts WHERE start_time >= ? AND end_time IS NOT NULL',
      [startEpochSeconds],
    );
    final totalSeconds = timeResult.first['total_seconds'] as int;

    // Current streak
    final streak = _calculateStreak();

    return {
      'workoutCount': workoutCount,
      'totalVolume': totalVolume,
      'currentStreak': streak,
      'totalTimeSeconds': totalSeconds,
      'hasData': true,
    };
  }

  /// Get paginated workout history with aggregated stats per workout.
  ///
  /// Returns a map with keys: workouts (list), totalCount, page, pageSize.
  /// Supports optional date range filtering via startEpoch/endEpoch (seconds).
  Map<String, dynamic> getWorkoutHistory({
    int page = 1,
    int pageSize = 20,
    int? startEpoch,
    int? endEpoch,
  }) {
    if (_db == null) {
      return {
        'workouts': <Map<String, dynamic>>[],
        'totalCount': 0,
        'page': page,
        'pageSize': pageSize,
      };
    }

    // Build WHERE clause with optional date range
    final whereParts = <String>['1=1'];
    final whereParams = <Object>[];

    if (startEpoch != null) {
      whereParts.add('w.start_time >= ?');
      whereParams.add(startEpoch);
    }
    if (endEpoch != null) {
      whereParts.add('w.start_time <= ?');
      whereParams.add(endEpoch);
    }

    final whereClause = 'WHERE ${whereParts.join(' AND ')}';

    // Count query
    final countResult = _db!.select(
      'SELECT COUNT(DISTINCT w.id) as total FROM workouts w $whereClause',
      whereParams,
    );
    final totalCount = countResult.first['total'] as int;

    // Data query with aggregated stats
    final offset = (page - 1) * pageSize;
    final dataResult = _db!.select('''
      SELECT w.id, w.start_time, w.end_time, w.name, w.notes,
        COUNT(DISTINCT gs.name) as exercise_count,
        COUNT(gs.id) as set_count,
        COALESCE(SUM(gs.weight * gs.reps), 0) as total_volume
      FROM workouts w
      LEFT JOIN gym_sets gs ON w.id = gs.workout_id AND gs.hidden = 0 AND gs.sequence >= 0
      $whereClause
      GROUP BY w.id
      ORDER BY w.start_time DESC
      LIMIT ? OFFSET ?
    ''', [...whereParams, pageSize, offset]);

    final workouts = dataResult
        .map((row) => {
              'id': row['id'],
              'startTime': row['start_time'],
              'endTime': row['end_time'],
              'name': row['name'],
              'notes': row['notes'],
              'exerciseCount': row['exercise_count'],
              'setCount': row['set_count'],
              'totalVolume': row['total_volume'],
            })
        .toList();

    return {
      'workouts': workouts,
      'totalCount': totalCount,
      'page': page,
      'pageSize': pageSize,
    };
  }

  /// Get workout detail with all non-hidden sets ordered by sequence.
  ///
  /// Returns a map with keys: workout (map or null), sets (list of maps).
  Map<String, dynamic> getWorkoutDetail(int workoutId) {
    if (_db == null) {
      return {'workout': null, 'sets': <Map<String, dynamic>>[]};
    }

    // Workout metadata
    final workoutResult = _db!.select(
      'SELECT id, start_time, end_time, name, notes FROM workouts WHERE id = ?',
      [workoutId],
    );

    if (workoutResult.isEmpty) {
      return {'workout': null, 'sets': <Map<String, dynamic>>[]};
    }

    final w = workoutResult.first;
    final workout = {
      'id': w['id'],
      'startTime': w['start_time'],
      'endTime': w['end_time'],
      'name': w['name'],
      'notes': w['notes'],
    };

    // Sets ordered by sequence, then set_order/created
    final setsResult = _db!.select('''
      SELECT id, name, reps, weight, unit, created, category,
        exercise_type, warmup, drop_set, set_order, sequence
      FROM gym_sets
      WHERE workout_id = ? AND hidden = 0 AND sequence >= 0
      ORDER BY sequence, COALESCE(set_order, created)
    ''', [workoutId]);

    final sets = setsResult
        .map((row) => {
              'id': row['id'],
              'name': row['name'],
              'reps': row['reps'],
              'weight': row['weight'],
              'unit': row['unit'],
              'created': row['created'],
              'category': row['category'],
              'exerciseType': row['exercise_type'],
              'warmup': row['warmup'] == 1,
              'dropSet': row['drop_set'] == 1,
              'setOrder': row['set_order'],
              'sequence': row['sequence'],
            })
        .toList();

    return {'workout': workout, 'sets': sets};
  }

  /// Get personal records for a specific exercise.
  ///
  /// Returns a map with keys: exerciseName, bestWeight, best1RM, bestVolume,
  /// hasRecords. Uses Brzycki formula for 1RM estimation.
  Map<String, dynamic> getExerciseRecords(String exerciseName) {
    if (_db == null) {
      return {
        'exerciseName': exerciseName,
        'bestWeight': null,
        'best1RM': null,
        'bestVolume': null,
        'hasRecords': false,
      };
    }

    final result = _db!.select('''
      SELECT
        MAX(weight) as best_weight,
        MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps)
            ELSE weight * (1.0278 - 0.0278 * reps) END) as best_1rm,
        MAX(weight * reps) as best_volume
      FROM gym_sets WHERE name = ? AND hidden = 0 AND reps > 0
    ''', [exerciseName]);

    final row = result.first;
    final hasRecords = row['best_weight'] != null;

    return {
      'exerciseName': exerciseName,
      'bestWeight': hasRecords ? (row['best_weight'] as num).toDouble() : null,
      'best1RM': hasRecords ? (row['best_1rm'] as num).toDouble() : null,
      'bestVolume': hasRecords ? (row['best_volume'] as num).toDouble() : null,
      'hasRecords': hasRecords,
    };
  }

  /// Get best weight at each rep count (1-15) for a specific exercise.
  ///
  /// Returns a map with keys: exerciseName, records (list of maps with
  /// repCount, maxWeight, created, unit, workoutId).
  Map<String, dynamic> getRepRecords(String exerciseName) {
    if (_db == null) {
      return {
        'exerciseName': exerciseName,
        'records': <Map<String, dynamic>>[]
      };
    }

    final result = _db!.select('''
      SELECT CAST(reps AS INTEGER) as rep_count,
        MAX(weight) as max_weight, created, unit, workout_id
      FROM gym_sets
      WHERE name = ? AND hidden = 0
        AND reps BETWEEN 1 AND 15
        AND reps = CAST(reps AS INTEGER)
      GROUP BY CAST(reps AS INTEGER)
      ORDER BY rep_count ASC
    ''', [exerciseName]);

    final records = result
        .map((row) => {
              'repCount': row['rep_count'],
              'maxWeight': row['max_weight'],
              'created': row['created'],
              'unit': row['unit'],
              'workoutId': row['workout_id'],
            })
        .toList();

    return {'exerciseName': exerciseName, 'records': records};
  }

  /// Get recent per-workout history for a specific exercise.
  ///
  /// Returns a list of maps with workout date/metadata, set count, volume,
  /// best weight, best estimated 1RM, and the best set for that workout.
  List<Map<String, dynamic>> getExerciseWorkoutHistory(
    String exerciseName, {
    int limit = 20,
  }) {
    if (_db == null || limit <= 0) return [];

    final categoryExpr =
        _hasColumn('gym_sets', 'category') ? 'gs.category' : 'NULL';
    final unitExpr = _hasColumn('gym_sets', 'unit') ? 'gs.unit' : 'NULL';

    final result = _db!.select('''
      SELECT gs.id, gs.weight, gs.reps, $unitExpr as unit, gs.created,
        $categoryExpr as category,
        CASE WHEN gs.weight >= 0 THEN gs.weight / (1.0278 - 0.0278 * gs.reps)
          ELSE gs.weight * (1.0278 - 0.0278 * gs.reps) END as estimated_1rm,
        w.id as workout_id, w.name as workout_name,
        w.start_time, w.end_time, DATE(w.start_time, 'unixepoch') as workout_date
      FROM gym_sets gs
      INNER JOIN workouts w ON w.id = gs.workout_id
      WHERE gs.name = ? AND gs.hidden = 0 AND gs.sequence >= 0 AND gs.reps > 0
      ORDER BY w.start_time DESC, gs.created DESC, gs.id DESC
    ''', [exerciseName]);

    final history = <Map<String, dynamic>>[];
    Map<String, dynamic>? current;
    int? currentWorkoutId;

    for (final row in result) {
      final workoutId = row['workout_id'] as int;
      if (workoutId != currentWorkoutId) {
        if (history.length >= limit) break;
        currentWorkoutId = workoutId;
        current = {
          'date': row['workout_date'],
          'workoutId': workoutId,
          'workoutName': row['workout_name'],
          'startTime': row['start_time'],
          'endTime': row['end_time'],
          'setCount': 0,
          'totalVolume': 0.0,
          'bestWeight': null,
          'bestEstimated1RM': null,
          'bestSet': null,
          'category': row['category'],
          'unit': row['unit'],
        };
        history.add(current);
      }

      final weight = (row['weight'] as num).toDouble();
      final reps = (row['reps'] as num).toDouble();
      final estimated1RM = (row['estimated_1rm'] as num).toDouble();
      final bestEstimated1RM = current!['bestEstimated1RM'] as double?;

      current['setCount'] = (current['setCount'] as int) + 1;
      current['totalVolume'] =
          (current['totalVolume'] as double) + weight * reps;
      if (current['bestWeight'] == null ||
          weight > (current['bestWeight'] as double)) {
        current['bestWeight'] = weight;
      }
      if (bestEstimated1RM == null || estimated1RM > bestEstimated1RM) {
        current['bestEstimated1RM'] = estimated1RM;
        current['bestSet'] = {
          'id': row['id'],
          'weight': weight,
          'reps': reps,
          'unit': row['unit'],
          'created': row['created'],
          'estimated1RM': estimated1RM,
          'volume': weight * reps,
        };
      }
      current['category'] ??= row['category'];
      current['unit'] ??= row['unit'];
    }

    return history;
  }

  /// Get all distinct non-null category names from exercises.
  List<String> getCategories() {
    if (_db == null) return [];

    final result = _db!.select('''
      SELECT DISTINCT category FROM gym_sets
      WHERE category IS NOT NULL AND hidden = 0
      ORDER BY category
    ''');

    return result.map((row) => row['category'] as String).toList();
  }

  /// Search exercises by name substring with optional category filter.
  ///
  /// Returns a map with keys: exercises (list of maps with name, category,
  /// lastUsed, setCount, workoutCount), totalCount.
  Map<String, dynamic> searchExercises({
    String search = '',
    String? category,
  }) {
    if (_db == null) {
      return {
        'exercises': <Map<String, dynamic>>[],
        'totalCount': 0,
      };
    }

    final categoryClause = category != null ? 'AND category = ?' : '';
    final params = <Object>['%$search%'];
    if (category != null) params.add(category);

    final result = _db!.select('''
      SELECT name, category, MAX(created) as last_used,
        COUNT(*) as set_count, COUNT(DISTINCT workout_id) as workout_count
      FROM gym_sets
      WHERE hidden = 0
        AND name LIKE ?
        $categoryClause
      GROUP BY name
      ORDER BY workout_count DESC
    ''', params);

    final exercises = result
        .map((row) => {
              'name': row['name'],
              'category': row['category'],
              'lastUsed': row['last_used'],
              'setCount': row['set_count'],
              'workoutCount': row['workout_count'],
            })
        .toList();

    return {
      'exercises': exercises,
      'totalCount': exercises.length,
    };
  }

  /// Get training days with set counts for heatmap display.
  ///
  /// Returns a map of date strings (YYYY-MM-DD) to set counts.
  Map<String, int> getTrainingDays({String? period}) {
    if (_db == null) return {};

    final startEpochSeconds = _periodToEpoch(period);

    final result = _db!.select('''
      SELECT DATE(w.start_time, 'unixepoch') as workout_date,
        COUNT(gs.id) as set_count
      FROM workouts w
      INNER JOIN gym_sets gs ON w.id = gs.workout_id
      WHERE w.start_time >= ? AND gs.hidden = 0
      GROUP BY workout_date
      ORDER BY workout_date
    ''', [startEpochSeconds]);

    final map = <String, int>{};
    for (final row in result) {
      map[row['workout_date'] as String] = row['set_count'] as int;
    }
    return map;
  }

  /// Get total volume per muscle group for bar chart.
  ///
  /// Returns a list of maps with keys: muscle, volume.
  List<Map<String, dynamic>> getMuscleGroupVolumes({String? period}) {
    if (_db == null) return [];

    final startEpochSeconds = _periodToEpoch(period);

    final result = _db!.select('''
      SELECT gs.category as muscle,
        SUM(gs.weight * gs.reps) as total_volume
      FROM gym_sets gs
      WHERE gs.created >= ? AND gs.hidden = 0
        AND gs.category IS NOT NULL AND gs.cardio = 0
      GROUP BY gs.category
      ORDER BY total_volume DESC
    ''', [startEpochSeconds]);

    return result
        .map((row) => <String, dynamic>{
              'muscle': row['muscle'],
              'volume': (row['total_volume'] as num).toDouble(),
            })
        .toList();
  }

  /// Get set counts per muscle group for bar chart.
  ///
  /// Returns a list of maps with keys: muscle, sets.
  List<Map<String, dynamic>> getMuscleGroupSetCounts({String? period}) {
    if (_db == null) return [];

    final startEpochSeconds = _periodToEpoch(period);

    final result = _db!.select('''
      SELECT gs.category as muscle,
        COUNT(*) as set_count
      FROM gym_sets gs
      WHERE gs.created >= ? AND gs.hidden = 0
        AND gs.category IS NOT NULL
      GROUP BY gs.category
      ORDER BY set_count DESC
    ''', [startEpochSeconds]);

    return result
        .map((row) => <String, dynamic>{
              'muscle': row['muscle'],
              'sets': row['set_count'] as int,
            })
        .toList();
  }

  /// Get exercise progress over time for line chart.
  ///
  /// Returns a list of daily-best data points with keys: created, value,
  /// weight, reps, unit, workoutId. Metric can be 'bestWeight', 'oneRepMax',
  /// or 'volume'.
  List<Map<String, dynamic>> getExerciseProgress(
    String exerciseName, {
    String metric = 'bestWeight',
    String? period,
  }) {
    if (_db == null) return [];

    final startEpochSeconds = _periodToEpoch(period);

    String metricExpr;
    switch (metric) {
      case 'oneRepMax':
        metricExpr =
            'CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) '
            'ELSE weight * (1.0278 - 0.0278 * reps) END';
      case 'volume':
        metricExpr = 'weight * reps';
      default: // 'bestWeight'
        metricExpr = 'weight';
    }

    final result = _db!.select('''
      SELECT created, weight, reps, unit, workout_id,
        $metricExpr as metric_value,
        DATE(created, 'unixepoch') as day
      FROM gym_sets
      WHERE name = ? AND hidden = 0 AND reps > 0
        AND created >= ?
      ORDER BY day, metric_value DESC
    ''', [exerciseName, startEpochSeconds]);

    // Group by day, take daily best
    final dailyBest = <String, Map<String, dynamic>>{};
    for (final row in result) {
      final day = row['day'] as String;
      if (!dailyBest.containsKey(day)) {
        dailyBest[day] = {
          'created': row['created'],
          'value': (row['metric_value'] as num).toDouble(),
          'weight': row['weight'] as num,
          'reps': row['reps'] as num,
          'unit': row['unit'] as String,
          'workoutId': row['workout_id'],
        };
      }
    }

    return dailyBest.values.toList();
  }

  /// Get completed 5/3/1 blocks with TM progression data.
  ///
  /// Returns a list of maps with keys: id, created, completed, squatTm,
  /// benchTm, deadliftTm, pressTm, startSquatTm, startBenchTm,
  /// startDeadliftTm, startPressTm, unit, currentCycle.
  /// Returns empty list if table doesn't exist (old backups).
  List<Map<String, dynamic>> getCompletedBlocks() {
    if (_db == null) return [];

    // Check table existence (old backups may not have this table)
    final tableCheck = _db!.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='five_three_one_blocks'",
    );
    if (tableCheck.isEmpty) return [];

    final result = _db!.select('''
      SELECT id, created, completed,
        squat_tm, bench_tm, deadlift_tm, press_tm,
        COALESCE(start_squat_tm, squat_tm) as start_squat_tm,
        COALESCE(start_bench_tm, bench_tm) as start_bench_tm,
        COALESCE(start_deadlift_tm, deadlift_tm) as start_deadlift_tm,
        COALESCE(start_press_tm, press_tm) as start_press_tm,
        unit, current_cycle
      FROM five_three_one_blocks
      WHERE is_active = 0 AND completed IS NOT NULL
      ORDER BY completed DESC
    ''');

    return result
        .map((row) => <String, dynamic>{
              'id': row['id'],
              'created': row['created'],
              'completed': row['completed'],
              'squatTm': (row['squat_tm'] as num).toDouble(),
              'benchTm': (row['bench_tm'] as num).toDouble(),
              'deadliftTm': (row['deadlift_tm'] as num).toDouble(),
              'pressTm': (row['press_tm'] as num).toDouble(),
              'startSquatTm': (row['start_squat_tm'] as num).toDouble(),
              'startBenchTm': (row['start_bench_tm'] as num).toDouble(),
              'startDeadliftTm': (row['start_deadlift_tm'] as num).toDouble(),
              'startPressTm': (row['start_press_tm'] as num).toDouble(),
              'unit': row['unit'] as String,
              'currentCycle': row['current_cycle'] as int,
            })
        .toList();
  }

  /// Get the currently active 5/3/1 block, or null if none.
  ///
  /// Returns a map with keys: id, created, squatTm, benchTm, deadliftTm,
  /// pressTm, startSquatTm, startBenchTm, startDeadliftTm, startPressTm, unit,
  /// currentCycle, currentWeek. Returns null if the table is missing (old
  /// backups) or no block is active.
  Map<String, dynamic>? getActiveBlock() {
    if (_db == null) return null;

    final tableCheck = _db!.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='five_three_one_blocks'",
    );
    if (tableCheck.isEmpty) return null;

    try {
      final result = _db!.select('''
        SELECT id, created,
          squat_tm, bench_tm, deadlift_tm, press_tm,
          COALESCE(start_squat_tm, squat_tm) as start_squat_tm,
          COALESCE(start_bench_tm, bench_tm) as start_bench_tm,
          COALESCE(start_deadlift_tm, deadlift_tm) as start_deadlift_tm,
          COALESCE(start_press_tm, press_tm) as start_press_tm,
          unit, current_cycle, current_week
        FROM five_three_one_blocks
        WHERE is_active = 1
        ORDER BY created DESC
        LIMIT 1
      ''');

      if (result.isEmpty) return null;
      final row = result.first;
      return <String, dynamic>{
        'id': row['id'],
        'created': row['created'],
        'squatTm': (row['squat_tm'] as num).toDouble(),
        'benchTm': (row['bench_tm'] as num).toDouble(),
        'deadliftTm': (row['deadlift_tm'] as num).toDouble(),
        'pressTm': (row['press_tm'] as num).toDouble(),
        'startSquatTm': (row['start_squat_tm'] as num).toDouble(),
        'startBenchTm': (row['start_bench_tm'] as num).toDouble(),
        'startDeadliftTm': (row['start_deadlift_tm'] as num).toDouble(),
        'startPressTm': (row['start_press_tm'] as num).toDouble(),
        'unit': row['unit'] as String,
        'currentCycle': row['current_cycle'] as int,
        'currentWeek': row['current_week'] as int,
      };
    } catch (_) {
      // Older schema may lack current_week / start_* columns.
      return null;
    }
  }

  /// Get bodyweight entries with stats and moving averages.
  ///
  /// Returns a map with keys: entries, stats, ma3, ma7, ma14.
  /// Returns empty result if table doesn't exist (old backups).
  Map<String, dynamic> getBodyweightData({String? period}) {
    final emptyResult = {
      'entries': <Map<String, dynamic>>[],
      'stats': <String, dynamic>{},
      'ma3': <double?>[],
      'ma7': <double?>[],
      'ma14': <double?>[],
    };

    if (_db == null) return emptyResult;

    // Check table existence (old backups may not have this table)
    final tableCheck = _db!.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='bodyweight_entries'",
    );
    if (tableCheck.isEmpty) return emptyResult;

    final startEpochSeconds = _periodToEpoch(period);

    final notesSelect =
        _hasColumn('bodyweight_entries', 'notes') ? 'notes' : 'NULL AS notes';

    final result = _db!.select('''
      SELECT id, weight, unit, date, $notesSelect
      FROM bodyweight_entries
      WHERE date >= ?
      ORDER BY date ASC
    ''', [startEpochSeconds]);

    if (result.isEmpty) return emptyResult;

    final entries = result
        .map((row) => <String, dynamic>{
              'id': row['id'] as int,
              'weight': (row['weight'] as num).toDouble(),
              'unit': row['unit'] as String,
              'date': row['date'] as int,
              'notes': row['notes'],
            })
        .toList();

    // Calculate stats
    final weights = entries.map((e) => e['weight'] as double).toList();
    final current = weights.last;
    final average = double.parse(
      (weights.reduce((a, b) => a + b) / weights.length).toStringAsFixed(1),
    );
    final change = weights.length >= 2 ? weights.last - weights.first : null;
    final lastUnit = entries.last['unit'] as String;

    final stats = <String, dynamic>{
      'current': current,
      'average': average,
      'change': change,
      'entries': entries.length,
      'unit': lastUnit,
    };

    // Compute moving averages
    final ma3 = _calculateMovingAverage(entries, 3);
    final ma7 = _calculateMovingAverage(entries, 7);
    final ma14 = _calculateMovingAverage(entries, 14);

    return {
      'entries': entries,
      'stats': stats,
      'ma3': ma3,
      'ma7': ma7,
      'ma14': ma14,
    };
  }

  // --- Private helpers ---

  /// Convert a period string to epoch seconds for query filtering.
  int _periodToEpoch(String? period) {
    if (period == null || period == 'all') return 0;
    final now = DateTime.now();
    DateTime start;
    switch (period) {
      case 'week':
      case '7d':
        start = now.subtract(const Duration(days: 7));
      case 'month':
      case '1m':
        start = DateTime(now.year, now.month - 1, now.day);
      case '3m':
        start = DateTime(now.year, now.month - 3, now.day);
      case '6m':
        start = DateTime(now.year, now.month - 6, now.day);
      case 'year':
      case '1y':
        start = DateTime(now.year - 1, now.month, now.day);
      default:
        return 0;
    }
    return start.millisecondsSinceEpoch ~/ 1000;
  }

  /// Calculate current workout streak by walking backwards from today.
  int _calculateStreak() {
    if (_db == null) return 0;
    int streak = 0;
    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);

    while (true) {
      final dateStr = '${checkDate.year.toString().padLeft(4, '0')}-'
          '${checkDate.month.toString().padLeft(2, '0')}-'
          '${checkDate.day.toString().padLeft(2, '0')}';
      final result = _db!.select(
        "SELECT COUNT(*) as count FROM workouts WHERE DATE(start_time, 'unixepoch') = ?",
        [dateStr],
      );
      if ((result.first['count'] as int) > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Calculate moving average using a calendar-day trailing window.
  ///
  /// For each entry, averages all entries within the past [windowDays] days.
  /// Ported from lib/utils/bodyweight_calculations.dart.
  List<double?> _calculateMovingAverage(
    List<Map<String, dynamic>> entries,
    int windowDays,
  ) {
    if (entries.isEmpty) return [];

    final result = <double?>[];
    for (var i = 0; i < entries.length; i++) {
      final currentEpoch = entries[i]['date'] as int;
      final currentDate =
          DateTime.fromMillisecondsSinceEpoch(currentEpoch * 1000);
      final windowStart = currentDate.subtract(Duration(days: windowDays - 1));

      double sum = 0;
      int count = 0;
      for (var j = 0; j <= i; j++) {
        final entryEpoch = entries[j]['date'] as int;
        final entryDate =
            DateTime.fromMillisecondsSinceEpoch(entryEpoch * 1000);
        if (!entryDate.isBefore(windowStart) &&
            !entryDate.isAfter(currentDate)) {
          sum += entries[j]['weight'] as double;
          count++;
        }
      }

      if (count > 0) {
        result.add(double.parse((sum / count).toStringAsFixed(1)));
      } else {
        result.add(null);
      }
    }

    return result;
  }

  /// Find the path to the latest backup file in dataDir.
  String? _findLatestBackupPath() {
    final dir = Directory(dataDir);
    if (!dir.existsSync()) return null;

    final backups = dir
        .listSync()
        .whereType<File>()
        .where((f) => _backupPattern.hasMatch(f.uri.pathSegments.last))
        .toList();

    if (backups.isEmpty) return null;

    // Sort by filename descending (date is in the name: YYYY-MM-DD)
    backups.sort(
        (a, b) => b.uri.pathSegments.last.compareTo(a.uri.pathSegments.last));

    return backups.first.path;
  }

  String? _resolveBackupPath(String? filename) {
    if (filename != null && filename.isNotEmpty) {
      if (!_backupPattern.hasMatch(filename)) return null;

      final file = File('$dataDir/$filename');
      return file.existsSync() ? file.path : null;
    }

    return _findLatestBackupPath();
  }

  bool _hasColumn(String tableName, String columnName) {
    if (_db == null) return false;

    final result = _db!.select('PRAGMA table_info($tableName)');
    return result.any((row) => row['name'] == columnName);
  }
}
