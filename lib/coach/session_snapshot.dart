import 'dart:collection';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../fivethreeone/fivethreeone_state.dart';
import '../fivethreeone/main_lifts.dart';
import '../fivethreeone/schemes.dart';
import '../main.dart';
import '../settings/settings_state.dart';
import '../workouts/workout_state.dart';

const _setOrderExpression =
    'COALESCE(set_order, CAST((julianday(created) - 2440587.5) * '
    '86400000 AS INTEGER))';

/// Builds the compact current-state payload sent to the coach on every turn.
///
/// Training-max values remain in the block's inherited unit even when it
/// differs from [unit]; converting them here would silently change the block.
Future<Map<String, Object?>> buildSessionSnapshot({
  required FiveThreeOneBlock? block,
  required Workout? workout,
  required String unit,
  int vocabularyLimit = 200,
}) async {
  final workoutRows =
      workout == null ? <GymSet>[] : await _loadWorkoutRows(workout.id);
  final sessionNames = <String>[];
  final seenNames = <String>{};

  for (final row in workoutRows) {
    if (seenNames.add(row.name)) sessionNames.add(row.name);
  }

  if (workout?.planId != null) {
    final planNames = await _loadPlanExerciseNames(workout!.planId!);
    for (final name in planNames) {
      // A plan fallback keeps a just-started, still-empty workout visible to
      // the coach without duplicating exercises that already have set rows.
      if (seenNames.add(name)) sessionNames.add(name);
    }
  }

  final recent = workout == null || sessionNames.isEmpty
      ? <String, Object?>{}
      : await _loadRecent(sessionNames, workout.id);
  final vocabulary = await _loadExerciseVocabulary(vocabularyLimit);

  final snapshot = <String, Object?>{
    'block': block == null ? null : _buildBlock(block),
    'exerciseVocabulary': vocabulary,
    'prescription': _buildPrescription(block, workout, sessionNames),
    'recent': recent,
    'unit': unit.trim().isEmpty ? 'kg' : unit,
    'workout': workout == null ? null : _buildWorkout(workout, workoutRows),
  };

  return _sortJson(snapshot) as Map<String, Object?>;
}

/// Builds a snapshot from the states already exposed above [context].
Future<Map<String, Object?>> buildSessionSnapshotFrom(BuildContext context) {
  final block = context.read<FiveThreeOneState>().activeBlock;
  final workout = context.read<WorkoutState>().activeWorkout;
  final unit = context.read<SettingsState>().value.strengthUnit;
  return buildSessionSnapshot(block: block, workout: workout, unit: unit);
}

/// Encodes [snapshot] as deterministic compact JSON.
String encodeSessionSnapshot(Map<String, Object?> snapshot) =>
    jsonEncode(_sortJson(snapshot));

Future<List<GymSet>> _loadWorkoutRows(int workoutId) {
  return (db.select(db.gymSets)
        ..where(
          (row) =>
              row.workoutId.equals(workoutId) &
              row.sequence.isNotValue(-1) &
              row.reps.isNotValue(-1),
        )
        ..orderBy([
          (row) => OrderingTerm(expression: row.sequence),
          (_) => OrderingTerm(
                expression: const CustomExpression<int>(_setOrderExpression),
              ),
          (row) => OrderingTerm(expression: row.created),
          (row) => OrderingTerm(expression: row.id),
        ]))
      .get();
}

Future<List<String>> _loadPlanExerciseNames(int planId) {
  return (db.select(db.planExercises)
        ..where(
          (row) => row.planId.equals(planId) & row.enabled.equals(true),
        )
        ..orderBy([
          (row) => OrderingTerm(expression: row.sequence),
          (row) => OrderingTerm(expression: row.id),
        ]))
      .map((row) => row.exercise)
      .get();
}

Future<Map<String, Object?>> _loadRecent(
  List<String> names,
  int currentWorkoutId,
) async {
  final placeholders = List.filled(names.length, '?').join(',');
  final variables = <Variable>[
    ...names.map(Variable.withString),
    Variable.withInt(currentWorkoutId),
    Variable.withInt(currentWorkoutId),
  ];
  final rows = await db
      .customSelect(
        '''
      SELECT name, reps, weight,
        DATE(created, 'unixepoch', 'localtime') AS day
      FROM gym_sets
      WHERE name IN ($placeholders)
        AND hidden = 0
        AND sequence != -1
        AND reps != -1
        AND (workout_id IS NULL OR workout_id != ?)
        AND DATE(created, 'unixepoch', 'localtime') = (
          SELECT MAX(DATE(g2.created, 'unixepoch', 'localtime'))
          FROM gym_sets g2
          WHERE g2.name = gym_sets.name
            AND g2.hidden = 0
            AND g2.sequence != -1
            AND g2.reps != -1
            AND (g2.workout_id IS NULL OR g2.workout_id != ?)
        )
      ORDER BY name, $_setOrderExpression, created, id
    ''',
        variables: variables,
        readsFrom: {db.gymSets},
      )
      .get();

  final sessions = <String, List<String>>{};
  final days = <String, String>{};
  for (final row in rows) {
    final name = row.read<String>('name');
    final sets = sessions.putIfAbsent(name, () => <String>[]);
    if (sets.length >= 12) continue;
    days[name] = row.read<String>('day');
    sets.add(
      '${_formatNumber(row.read<double>('reps'))}x'
      '${_formatNumber(row.read<double>('weight'))}',
    );
  }

  return {
    for (final entry in sessions.entries)
      entry.key: [
        <String, Object?>{
          'date': days[entry.key],
          'sets': entry.value,
        },
      ],
  };
}

/// The closed set of exercise names the coach is allowed to say, ranked by
/// real use so the cap sheds the least useful names first.
///
/// Ranking deliberately ignores `created` on unperformed rows. A fresh install
/// seeds the whole default catalogue (`defaultSets` in
/// `lib/database/defaults.dart`) as hidden rows stamped with the install time,
/// which is newer than any imported history — ordering by plain `MAX(created)`
/// therefore floats ~58 never-touched exercises above the lifts the user
/// actually trains, and the cap can evict the real ones. So exercises that have
/// been performed sort first, newest first; everything else follows in name
/// order. Never-performed names stay in the list because they are still
/// selectable, and the coach may legitimately suggest one.
Future<List<String>> _loadExerciseVocabulary(int limit) async {
  if (limit <= 0) return [];

  const lastPerformed = 'MAX(CASE WHEN hidden = 0 THEN created END)';
  final rows = await db
      .customSelect(
        '''
      SELECT name
      FROM gym_sets
      WHERE sequence != -1 AND reps != -1
      GROUP BY name
      ORDER BY $lastPerformed IS NULL,
               $lastPerformed DESC,
               name COLLATE NOCASE,
               name
      LIMIT ?
    ''',
        variables: [Variable.withInt(limit)],
        readsFrom: {db.gymSets},
      )
      .get();
  return rows.map((row) => row.read<String>('name')).toList();
}

Map<String, Object?> _buildBlock(FiveThreeOneBlock block) {
  final supplemental = supplementalName(
    supplementalForCycle(block.currentCycle, block.supplementals),
  );
  return {
    'cycle': cycleNames[block.currentCycle],
    'cycleIndex': _n(block.currentCycle.toDouble()),
    'mainScheme': getMainSchemeName(block.currentCycle),
    'supplemental': supplemental.isEmpty ? null : supplemental,
    'tmBumps': _n(block.tmBumps.toDouble()),
    'tms': <String, Object?>{
      'bench': _n(block.benchTm),
      'deadlift': _n(block.deadliftTm),
      'press': _n(block.pressTm),
      'squat': _n(block.squatTm),
    },
    'week': _n(block.currentWeek.toDouble()),
  };
}

Map<String, Object?> _buildWorkout(
  Workout workout,
  List<GymSet> rows,
) {
  final setsByName = <String, List<Object?>>{};
  for (final row in rows) {
    // Hidden workout rows are pending prescribed sets, not history-private
    // data. They stay in the payload and surface only as `done: false`.
    setsByName.putIfAbsent(row.name, () => <Object?>[]).add(
      <String, Object?>{
        'done': !row.hidden,
        'reps': _n(row.reps),
        'weight': _n(row.weight),
      },
    );
  }

  return {
    'exercises': [
      for (final entry in setsByName.entries)
        <String, Object?>{
          'name': entry.key,
          'sets': entry.value,
        },
    ],
    'id': _n(workout.id.toDouble()),
  };
}

List<Object?>? _buildPrescription(
  FiveThreeOneBlock? block,
  Workout? workout,
  List<String> sessionNames,
) {
  if (block == null || workout == null) return null;

  final prescriptions = <Object?>[];
  for (final name in sessionNames) {
    if (mainLiftTmKey(name) == null) continue;
    final sets = mainWorkPrescription(block: block, exerciseName: name);
    if (sets == null) continue;
    prescriptions.add(
      <String, Object?>{
        'exercise': name,
        'sets': [
          for (final set in sets)
            <String, Object?>{
              'amrap': set.amrap,
              'reps': _n(set.reps.toDouble()),
              'weight': _n(set.weight),
            },
        ],
      },
    );
  }
  return prescriptions.isEmpty ? null : prescriptions;
}

num _n(double v) => v == v.roundToDouble() ? v.toInt() : v;

String _formatNumber(double value) => _n(value).toString();

Object? _sortJson(Object? value) {
  if (value is Map) {
    final sorted = SplayTreeMap<String, Object?>();
    for (final entry in value.entries) {
      sorted[entry.key as String] = _sortJson(entry.value);
    }
    return sorted;
  }
  if (value is List) return value.map(_sortJson).toList();
  return value;
}
