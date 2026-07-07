import 'dart:io';

import 'package:jackedlog_server/services/dashboard_service.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late DashboardService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('jackedlog_dashboard_');
    service = DashboardService(tempDir.path);
  });

  tearDown(() {
    service.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('reads bodyweight entries from backups without notes column', () {
    final backup = File('${tempDir.path}/jackedlog_backup_2026-06-14.db');
    _writeBackup(backup, workoutCount: 1, includeBodyweightNotes: false);

    expect(service.ensureOpen(), isTrue);

    final data = service.getBodyweightData();
    final entries = data['entries'] as List<Map<String, dynamic>>;

    expect(entries, hasLength(1));
    expect(entries.single['weight'], 80.0);
    expect(entries.single['notes'], isNull);
  });

  test('reopens same filename when the backup file changes', () {
    final backup = File('${tempDir.path}/jackedlog_backup_2026-06-14.db');
    _writeBackup(backup, workoutCount: 1);
    backup.setLastModifiedSync(DateTime(2026, 6, 14, 10));

    expect(service.ensureOpen(), isTrue);
    expect(service.getOverviewStats()['workoutCount'], 1);

    _writeBackup(backup, workoutCount: 3);
    backup.setLastModifiedSync(DateTime(2026, 6, 14, 11));

    expect(service.ensureOpen(), isTrue);
    expect(service.getOverviewStats()['workoutCount'], 3);

    final progress = service.getExerciseProgress('Squat');
    expect(progress, hasLength(3));
    expect(progress.last['workoutId'], 3);
  });

  test('returns the active 5/3/1 block with cycle/week position', () {
    final backup = File('${tempDir.path}/jackedlog_backup_2026-06-14.db');
    _writeBackup(backup, workoutCount: 1, includeBlocks: true);

    expect(service.ensureOpen(), isTrue);

    final active = service.getActiveBlock();
    expect(active, isNotNull);
    expect(active!['currentCycle'], 1);
    expect(active['currentWeek'], 2);
    expect(active['squatTm'], 142.5);
    expect(active['startSquatTm'], 140.0);
    expect(active['unit'], 'kg');

    // Completed blocks query excludes the active one.
    expect(service.getCompletedBlocks(), isEmpty);
  });

  test('returns null active block when none is active', () {
    final backup = File('${tempDir.path}/jackedlog_backup_2026-06-14.db');
    _writeBackup(backup,
        workoutCount: 1, includeBlocks: true, activeBlock: false);

    expect(service.ensureOpen(), isTrue);
    expect(service.getActiveBlock(), isNull);
    expect(service.getCompletedBlocks(), hasLength(1));
  });

  test('returns workout detail with warmup and drop set flags', () {
    final backup = File('${tempDir.path}/jackedlog_backup_2026-06-14.db');
    _writeBackup(backup, workoutCount: 1);

    final db = sqlite3.open(backup.path);
    try {
      db.execute('''
        INSERT INTO gym_sets (
          name, weight, reps, unit, created, hidden, cardio, category,
          workout_id, sequence, exercise_type, set_order, warmup, drop_set
        ) VALUES
          ('Bench Press', 40.0, 8.0, 'kg', 1700086400, 0, 0, 'Chest', 1, 1, 'barbell', 1, 1, 0),
          ('Bench Press', 100.0, 5.0, 'kg', 1700086400, 0, 0, 'Chest', 1, 1, 'barbell', 2, 0, 0),
          ('Bench Press', 80.0, 8.0, 'kg', 1700086400, 0, 0, 'Chest', 1, 1, 'barbell', 3, 0, 1)
      ''');
    } finally {
      db.dispose();
    }

    expect(service.ensureOpen(), isTrue);

    final detail = service.getWorkoutDetail(1);
    final sets = detail['sets'] as List<Map<String, dynamic>>;

    // Seeded Squat set (sequence 0) plus the 3 Bench Press sets above.
    expect(sets, hasLength(4));
    expect(sets[0]['name'], 'Squat');
    expect(sets[0]['warmup'], isFalse);
    expect(sets[0]['dropSet'], isFalse);
    expect(sets[1]['warmup'], isTrue);
    expect(sets[1]['dropSet'], isFalse);
    expect(sets[2]['warmup'], isFalse);
    expect(sets[2]['dropSet'], isFalse);
    expect(sets[3]['warmup'], isFalse);
    expect(sets[3]['dropSet'], isTrue);
  });

  test('returns recent per-workout exercise history', () {
    final backup = File('${tempDir.path}/jackedlog_backup_2026-06-14.db');
    _writeBackup(backup, workoutCount: 2);

    final db = sqlite3.open(backup.path);
    try {
      db.execute('''
        INSERT INTO gym_sets (
          name, weight, reps, unit, created, hidden, cardio, category,
          workout_id, sequence
        ) VALUES
          ('Squat', 120.0, 3.0, 'kg', 1700086401, 0, 0, 'Legs', 1, 0),
          ('Squat', 110.0, 5.0, 'kg', 1700172801, 0, 0, 'Legs', 2, 0),
          ('Squat', 90.0, 8.0, 'kg', 1700172802, 0, 0, 'Legs', 2, 0),
          ('Squat', 200.0, 1.0, 'kg', 1700172803, 1, 0, 'Legs', 2, 0),
          ('Bench Press', 150.0, 1.0, 'kg', 1700172804, 0, 0, 'Chest', 2, 0),
          ('Squat', 300.0, 1.0, 'kg', 1700172805, 0, 0, 'Legs', NULL, 0)
      ''');
    } finally {
      db.dispose();
    }

    expect(service.ensureOpen(), isTrue);

    final history = service.getExerciseWorkoutHistory('Squat');

    expect(history, hasLength(2));
    expect(history.first['workoutId'], 2);
    expect(history.first['workoutName'], 'Workout 2');
    expect(history.first['date'], '2023-11-16');
    expect(history.first['setCount'], 3);
    expect(history.first['totalVolume'], 1770.0);
    expect(history.first['bestWeight'], 110.0);
    expect(history.first['category'], 'Legs');
    expect(history.first['unit'], 'kg');

    final bestSet = history.first['bestSet'] as Map<String, dynamic>;
    expect(bestSet['weight'], 110.0);
    expect(bestSet['reps'], 5.0);
    expect(bestSet['volume'], 550.0);
    expect(history.first['bestEstimated1RM'], closeTo(123.762, 0.001));

    expect(history.last['workoutId'], 1);
    expect(history.last['setCount'], 2);
    expect(history.last['totalVolume'], 860.0);

    expect(service.getExerciseWorkoutHistory('Squat', limit: 1), hasLength(1));
    expect(service.getExerciseWorkoutHistory('Missing'), isEmpty);
  });

  test('exercise workout history tolerates old gym set metadata columns', () {
    final backup = File('${tempDir.path}/jackedlog_backup_2026-06-14.db');
    _writeBackup(
      backup,
      workoutCount: 1,
      includeGymSetCategory: false,
      includeGymSetUnit: false,
    );

    expect(service.ensureOpen(), isTrue);

    final history = service.getExerciseWorkoutHistory('Squat');

    expect(history, hasLength(1));
    expect(history.single['category'], isNull);
    expect(history.single['unit'], isNull);

    final bestSet = history.single['bestSet'] as Map<String, dynamic>;
    expect(bestSet['unit'], isNull);
  });

  test('returns null active block when blocks table is missing', () {
    final backup = File('${tempDir.path}/jackedlog_backup_2026-06-14.db');
    _writeBackup(backup, workoutCount: 1);

    expect(service.ensureOpen(), isTrue);
    expect(service.getActiveBlock(), isNull);
  });
}

void _writeBackup(
  File file, {
  required int workoutCount,
  bool includeBodyweightNotes = true,
  bool includeBlocks = false,
  bool activeBlock = true,
  bool includeGymSetCategory = true,
  bool includeGymSetUnit = true,
}) {
  final db = sqlite3.open(file.path);
  try {
    db.execute('PRAGMA user_version = 66');
    db.execute('DROP TABLE IF EXISTS workouts');
    db.execute('DROP TABLE IF EXISTS gym_sets');
    db.execute('DROP TABLE IF EXISTS bodyweight_entries');
    db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        name TEXT,
        notes TEXT
      )
    ''');
    db.execute('''
      CREATE TABLE gym_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        weight REAL NOT NULL,
        reps REAL NOT NULL,
        ${includeGymSetUnit ? 'unit TEXT NOT NULL,' : ''}
        created INTEGER NOT NULL,
        hidden INTEGER NOT NULL DEFAULT 0,
        cardio INTEGER NOT NULL DEFAULT 0,
        ${includeGymSetCategory ? 'category TEXT,' : ''}
        workout_id INTEGER,
        sequence INTEGER NOT NULL DEFAULT 0,
        exercise_type TEXT,
        set_order INTEGER,
        warmup INTEGER NOT NULL DEFAULT 0,
        drop_set INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute('''
      CREATE TABLE bodyweight_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        unit TEXT NOT NULL,
        date INTEGER NOT NULL
        ${includeBodyweightNotes ? ', notes TEXT' : ''}
      )
    ''');

    final insertWorkout = db.prepare(
      'INSERT INTO workouts (start_time, end_time, name) VALUES (?, ?, ?)',
    );
    final gymSetColumns = [
      'name',
      'weight',
      'reps',
      if (includeGymSetUnit) 'unit',
      'created',
      'hidden',
      'cardio',
      if (includeGymSetCategory) 'category',
      'workout_id',
      'sequence',
    ];
    final gymSetValues = [
      '?',
      '?',
      '?',
      if (includeGymSetUnit) '?',
      '?',
      '0',
      '0',
      if (includeGymSetCategory) '?',
      '?',
      '0',
    ];
    final insertSet = db.prepare('''
      INSERT INTO gym_sets (${gymSetColumns.join(', ')})
      VALUES (${gymSetValues.join(', ')})
    ''');
    try {
      for (var i = 1; i <= workoutCount; i++) {
        final start = 1700000000 + i * 86400;
        insertWorkout.execute([start, start + 3600, 'Workout $i']);
        insertSet.execute([
          'Squat',
          100.0,
          5.0,
          if (includeGymSetUnit) 'kg',
          start,
          if (includeGymSetCategory) 'Legs',
          i,
        ]);
      }
    } finally {
      insertWorkout.dispose();
      insertSet.dispose();
    }

    final bodyweightSql = includeBodyweightNotes
        ? 'INSERT INTO bodyweight_entries (weight, unit, date, notes) VALUES (?, ?, ?, ?)'
        : 'INSERT INTO bodyweight_entries (weight, unit, date) VALUES (?, ?, ?)';
    db.execute(
      bodyweightSql,
      includeBodyweightNotes
          ? [80.0, 'kg', 1700000000, 'morning']
          : [80.0, 'kg', 1700000000],
    );

    if (includeBlocks) {
      db.execute('''
        CREATE TABLE five_three_one_blocks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          created INTEGER NOT NULL,
          squat_tm REAL NOT NULL,
          bench_tm REAL NOT NULL,
          deadlift_tm REAL NOT NULL,
          press_tm REAL NOT NULL,
          start_squat_tm REAL,
          start_bench_tm REAL,
          start_deadlift_tm REAL,
          start_press_tm REAL,
          unit TEXT NOT NULL,
          current_cycle INTEGER NOT NULL DEFAULT 0,
          current_week INTEGER NOT NULL DEFAULT 1,
          is_active INTEGER NOT NULL DEFAULT 1,
          completed INTEGER
        )
      ''');
      db.execute('''
        INSERT INTO five_three_one_blocks (
          created, squat_tm, bench_tm, deadlift_tm, press_tm,
          start_squat_tm, start_bench_tm, start_deadlift_tm, start_press_tm,
          unit, current_cycle, current_week, is_active, completed
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        1700000000,
        142.5,
        102.5,
        182.5,
        62.5,
        140.0,
        100.0,
        180.0,
        60.0,
        'kg',
        1,
        2,
        activeBlock ? 1 : 0,
        activeBlock ? null : 1700500000,
      ]);
    }
  } finally {
    db.dispose();
  }
}
