/// Read-only coach tools for bounded access to deeper training history.
///
/// The current session already travels with every coach turn. These tools keep
/// older history opt-in so a phone-sized context window is not spent on data
/// the model did not ask to see.
library;

import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/exercise_names.dart';
import '../database/gym_sets.dart';
import '../fivethreeone/schemes.dart';
import '../main.dart';
import 'weight_spec.dart';

/// Tool name for reading performed sessions for one exercise.
const String getExerciseHistoryTool = 'get_exercise_history';

/// Tool name for reading the app's own exercise records.
const String getRecordsTool = 'get_records';

/// Tool name for reading completed 5/3/1 blocks.
const String getBlockHistoryTool = 'get_block_history';

/// Names accepted by [runReadTool].
const Set<String> readToolNames = <String>{
  getExerciseHistoryTool,
  getRecordsTool,
  getBlockHistoryTool,
};

const String _setOrderExpression =
    'COALESCE(set_order, CAST((julianday(created) - 2440587.5) * '
    '86400000 AS INTEGER))';

const Set<String> _historyKeys = <String>{'exercise', 'limit'};
const Set<String> _recordsKeys = <String>{'exercise'};
const Set<String> _blockKeys = <String>{'limit'};

Map<String, Object?> _tool(
  String name,
  String description,
  Map<String, Object?> parameters,
) =>
    <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': name,
        'description': description,
        'parameters': parameters,
      },
    };

/// Returns the three always-available, read-only tool schemas.
///
/// They carry no authority tier because reading bounded history cannot mutate
/// training data.
List<Map<String, Object?>> readTools() => <Map<String, Object?>>[
      _tool(
        getExerciseHistoryTool,
        'Read recent history for one exercise.',
        <String, Object?>{
          'type': 'object',
          'additionalProperties': false,
          'required': <String>['exercise'],
          'properties': <String, Object?>{
            'exercise': <String, Object?>{
              'type': 'string',
              'description': 'Use an exact name from exerciseVocabulary.',
            },
            'limit': <String, Object?>{
              'type': 'integer',
              'description': 'Limit the returned sessions.',
              'default': 10,
              'maximum': 25,
            },
          },
        },
      ),
      _tool(
        getRecordsTool,
        'Read records for one exercise.',
        <String, Object?>{
          'type': 'object',
          'additionalProperties': false,
          'required': <String>['exercise'],
          'properties': <String, Object?>{
            'exercise': <String, Object?>{
              'type': 'string',
              'description': 'Use an exact name from exerciseVocabulary.',
            },
          },
        },
      ),
      _tool(
        getBlockHistoryTool,
        'Read recent training-block history.',
        <String, Object?>{
          'type': 'object',
          'additionalProperties': false,
          'properties': <String, Object?>{
            'limit': <String, Object?>{
              'type': 'integer',
              'description': 'Limit the returned blocks.',
              'default': 5,
              'maximum': 20,
            },
          },
        },
      ),
    ];

/// Dispatches one read tool without ever throwing an error back at the model.
///
/// [completedBlocks] is how the orchestrator supplies
/// `FiveThreeOneState.getCompletedBlocks`; direct callers may omit it.
Future<Map<String, Object?>> runReadTool({
  required String name,
  required Map<String, Object?> arguments,
  required List<String> exerciseVocabulary,
  required String settingsUnit,
  Future<List<FiveThreeOneBlock>> Function()? completedBlocks,
}) {
  switch (name) {
    case getExerciseHistoryTool:
      return getExerciseHistoryResult(
        arguments: arguments,
        exerciseVocabulary: exerciseVocabulary,
        settingsUnit: settingsUnit,
      );
    case getRecordsTool:
      return getRecordsResult(
        arguments: arguments,
        exerciseVocabulary: exerciseVocabulary,
        settingsUnit: settingsUnit,
      );
    case getBlockHistoryTool:
      return getBlockHistoryResult(
        arguments: arguments,
        completedBlocks: completedBlocks,
      );
    default:
      return Future<Map<String, Object?>>.value(
        _error(
          "unknown read tool '$name'; use one of "
          '${readToolNames.join(', ')}.',
        ),
      );
  }
}

/// Reads recent performed strength sessions for one known exercise.
///
/// `hidden = 0` is essential: hidden rows are prescriptions and seeded
/// catalogue entries, not work the user actually performed. Warm-ups, cardio,
/// and tombstones are excluded for the same reason. Two bounded SQL reads are
/// used regardless of how many sessions or sets are returned.
Future<Map<String, Object?>> getExerciseHistoryResult({
  required Map<String, Object?> arguments,
  required List<String> exerciseVocabulary,
  required String settingsUnit,
}) async {
  final keys = _validateKeys(
    getExerciseHistoryTool,
    arguments,
    _historyKeys,
  );
  if (keys.isError) return _error(keys.error!);

  final exercise = _resolveExercise(
    arguments['exercise'],
    exerciseVocabulary,
  );
  if (exercise.isError) return _error(exercise.error!);

  final limit = _parseLimit(
    arguments['limit'],
    defaultValue: 10,
    maximum: 25,
    toolName: getExerciseHistoryTool,
  );
  if (limit.isError) return _error(limit.error!);

  final name = exercise.value!;
  final rows = await db.customSelect(
    '''
    SELECT id, weight, reps, unit, created,
      DATE(created, 'unixepoch', 'localtime') AS day
    FROM gym_sets
    WHERE name = ?
      AND hidden = 0
      AND sequence != -1
      AND reps != -1
      AND warmup = 0
      AND cardio = 0
      AND DATE(created, 'unixepoch', 'localtime') IN (
        SELECT DATE(created, 'unixepoch', 'localtime')
        FROM gym_sets
        WHERE name = ?
          AND hidden = 0
          AND sequence != -1
          AND reps != -1
          AND warmup = 0
          AND cardio = 0
        GROUP BY 1
        ORDER BY 1 DESC
        LIMIT ?
      )
    ORDER BY day DESC, $_setOrderExpression, created, id
  ''',
    variables: <Variable>[
      Variable.withString(name),
      Variable.withString(name),
      Variable.withInt(limit.value!),
    ],
    readsFrom: {db.gymSets},
  ).get();

  final countRow = await db.customSelect(
    '''
    SELECT COUNT(DISTINCT DATE(created, 'unixepoch', 'localtime')) AS total
    FROM gym_sets
    WHERE name = ?
      AND hidden = 0
      AND sequence != -1
      AND reps != -1
      AND warmup = 0
      AND cardio = 0
  ''',
    variables: <Variable>[Variable.withString(name)],
    readsFrom: {db.gymSets},
  ).getSingle();

  if (rows.isEmpty) {
    return _ok('No performed sets recorded for $name.');
  }

  var newest = rows.first;
  for (final row in rows.skip(1)) {
    final created = row.read<int>('created');
    final newestCreated = newest.read<int>('created');
    if (created > newestCreated ||
        (created == newestCreated &&
            row.read<int>('id') > newest.read<int>('id'))) {
      newest = row;
    }
  }
  final displayUnit = newest.read<String>('unit');
  final sessions = <String, List<String>>{};
  for (final row in rows) {
    final day = row.read<String>('day');
    final weight = _convertWeight(
      row.read<double>('weight'),
      from: row.read<String>('unit'),
      to: displayUnit,
    );
    sessions.putIfAbsent(day, () => <String>[]).add(
          '${_n(weight)}x${_n(row.read<double>('reps'))}',
        );
  }

  final total = countRow.read<int>('total');
  final shown = sessions.length;
  final summary = shown < total
      ? '$shown most recent of $total sessions'
      : '$shown sessions';
  final lines = <String>['$name — $summary ($displayUnit)'];
  for (final entry in sessions.entries) {
    lines.add('${entry.key}: ${_collapseSets(entry.value)}');
  }
  return _ok(lines.join('\n'));
}

/// Reads the same all-time records shown by the app's strength records UI.
///
/// Delegating to the database record helpers keeps the coach's 1RM formula,
/// filters, and rep-record rules identical to the rest of the app.
Future<Map<String, Object?>> getRecordsResult({
  required Map<String, Object?> arguments,
  required List<String> exerciseVocabulary,
  required String settingsUnit,
}) async {
  final keys = _validateKeys(getRecordsTool, arguments, _recordsKeys);
  if (keys.isError) return _error(keys.error!);

  final exercise = _resolveExercise(
    arguments['exercise'],
    exerciseVocabulary,
  );
  if (exercise.isError) return _error(exercise.error!);

  final name = exercise.value!;
  final unit = settingsUnit.trim().isEmpty ? 'kg' : settingsUnit.trim();
  final records = await getExerciseRecords(name: name, targetUnit: unit);
  final repRecords = await getRepRecords(name: name, targetUnit: unit);
  final nonZeroRepRecords =
      repRecords.where((record) => record.weight != 0).toList(growable: false);

  final lines = <String>['$name records ($unit)'];
  if (records.bestWeight != 0) {
    lines.add(
      'Best weight: ${_n(records.bestWeight)}'
      '${_setDetail(records.bestWeightReps, records.bestWeightDate)}',
    );
  }
  if (records.best1RM != 0) {
    lines.add(
      'Best e1RM: ${records.best1RM.toStringAsFixed(1)}'
      '${_sourceDetail(
        records.best1RMWeight,
        records.best1RMReps,
        records.best1RMDate,
      )}',
    );
  }
  if (records.bestVolume != 0) {
    lines.add(
      'Best set volume: ${_n(records.bestVolume)}'
      '${_sourceDetail(
        records.bestVolumeWeight,
        records.bestVolumeReps,
        records.bestVolumeDate,
      )}',
    );
  }
  if (nonZeroRepRecords.isNotEmpty) {
    lines.add(
      'Rep PRs: ${nonZeroRepRecords.map(
            (record) => '${record.reps}:${_n(record.weight)}',
          ).join(', ')}',
    );
  }

  if (lines.length == 1) return _ok('No records for $name yet.');
  return _ok(lines.join('\n'));
}

/// Reads bounded completed-block history without changing block state.
///
/// The injected callback is how the orchestrator passes
/// `FiveThreeOneState.getCompletedBlocks`. The fallback deliberately mirrors
/// that method: inactive, completed rows ordered newest-first.
Future<Map<String, Object?>> getBlockHistoryResult({
  required Map<String, Object?> arguments,
  Future<List<FiveThreeOneBlock>> Function()? completedBlocks,
}) async {
  final keys = _validateKeys(getBlockHistoryTool, arguments, _blockKeys);
  if (keys.isError) return _error(keys.error!);

  final limit = _parseLimit(
    arguments['limit'],
    defaultValue: 5,
    maximum: 20,
    toolName: getBlockHistoryTool,
  );
  if (limit.isError) return _error(limit.error!);

  final blocks = completedBlocks != null
      ? await completedBlocks()
      : await (db.select(db.fiveThreeOneBlocks)
            ..where((block) => block.isActive.equals(false))
            ..where((block) => block.completed.isNotNull())
            ..orderBy([
              (block) => OrderingTerm(
                    expression: block.completed,
                    mode: OrderingMode.desc,
                  ),
            ]))
          .get();
  if (blocks.isEmpty) return _ok('No completed blocks yet.');

  final shown = blocks.take(limit.value!).toList(growable: false);
  final summary = shown.length < blocks.length
      ? '${shown.length} most recent of ${blocks.length} completed blocks'
      : '${shown.length} completed blocks';
  final lines = <String>['Block history — $summary'];
  for (final block in shown) {
    lines.add(_formatBlock(block));
  }
  return _ok(lines.join('\n'));
}

CoachResult<void> _validateKeys(
  String toolName,
  Map<String, Object?> arguments,
  Set<String> allowed,
) {
  for (final key in arguments.keys) {
    if (!allowed.contains(key)) {
      return CoachResult<void>.failed(
        "$toolName does not take '$key'. Allowed keys are "
        '${allowed.join(', ')}.',
      );
    }
  }
  return const CoachResult<void>.ok(null);
}

CoachResult<int> _parseLimit(
  Object? raw, {
  required int defaultValue,
  required int maximum,
  required String toolName,
}) {
  if (raw == null) return CoachResult<int>.ok(defaultValue);
  if (raw is! num || !raw.isFinite || raw != raw.roundToDouble()) {
    return CoachResult<int>.failed(
      '$toolName.limit must be a whole number.',
    );
  }
  final value = raw.toInt();
  if (value < 1) {
    return CoachResult<int>.failed(
      '$toolName.limit must be at least 1.',
    );
  }
  return CoachResult<int>.ok(value > maximum ? maximum : value);
}

CoachResult<String> _resolveExercise(
  Object? raw,
  List<String> vocabulary,
) {
  if (raw is! String || raw.trim().isEmpty) {
    return const CoachResult<String>.failed(
      'exercise must be a non-empty name from exerciseVocabulary.',
    );
  }
  final requested = normalizeExerciseName(raw).trim();
  final known = <String, String>{};
  for (final name in vocabulary) {
    known.putIfAbsent(name.trim().toLowerCase(), () => name);
  }
  final canonical = known[requested.toLowerCase()];
  if (canonical != null) return CoachResult<String>.ok(canonical);

  final candidates = _nearest(requested, known);
  if (candidates.isEmpty) {
    return CoachResult<String>.failed(
      "unknown exercise '$requested'; use an exact name from "
      'exerciseVocabulary.',
    );
  }
  return CoachResult<String>.failed(
    "unknown exercise '$requested'; did you mean "
    '${candidates.map((name) => "'$name'").join(' or ')}?',
  );
}

// Deliberately duplicated from session_tools.dart so read tools preserve the
// same closed-vocabulary suggestions without widening either file's surface.
List<String> _nearest(String requested, Map<String, String> known) {
  final query = requested.trim().toLowerCase();
  final scored = <(int, String)>[];
  for (final entry in known.entries) {
    final candidate = entry.key;
    final distance = candidate.contains(query) || query.contains(candidate)
        ? 0
        : _distance(query, candidate);
    if (distance <= 4) scored.add((distance, entry.value));
  }
  scored.sort((a, b) {
    final byDistance = a.$1.compareTo(b.$1);
    return byDistance != 0 ? byDistance : a.$2.compareTo(b.$2);
  });
  return scored.take(3).map((entry) => entry.$2).toList();
}

int _distance(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      final substitution = previous[j - 1] + cost;
      current[j] = deletion < insertion ? deletion : insertion;
      if (substitution < current[j]) current[j] = substitution;
    }
    previous = current;
  }
  return previous[b.length];
}

double _convertWeight(
  double value, {
  required String from,
  required String to,
}) {
  // Converted weights are rounded: a raw 45.359237 costs tokens and reads as
  // false precision next to the whole numbers everything else prints.
  if (from == 'lb' && to == 'kg') {
    return double.parse((value * 0.45359237).toStringAsFixed(1));
  }
  if (from == 'kg' && to == 'lb') {
    return double.parse((value * 2.20462262).toStringAsFixed(1));
  }
  return value;
}

String _collapseSets(List<String> sets) {
  final collapsed = <String>[];
  var previous = sets.first;
  var count = 1;
  for (final set in sets.skip(1)) {
    if (set == previous) {
      count++;
      continue;
    }
    collapsed.add(count == 1 ? previous : '$previous (x$count)');
    previous = set;
    count = 1;
  }
  collapsed.add(count == 1 ? previous : '$previous (x$count)');
  return collapsed.join(', ');
}

String _setDetail(double? reps, DateTime? date) {
  final set = reps == null ? '' : ' x ${_n(reps)}';
  final when = date == null ? '' : ' (${_date(date)})';
  return '$set$when';
}

String _sourceDetail(double? weight, double? reps, DateTime? date) {
  final source =
      weight != null && reps != null ? '${_n(weight)} x ${_n(reps)}' : null;
  if (source == null && date == null) return '';
  return ' (${<String>[
    if (source != null) source,
    if (date != null) _date(date),
  ].join(', ')})';
}

String _formatBlock(FiveThreeOneBlock block) {
  final startSquat = block.startSquatTm ?? block.squatTm;
  final startBench = block.startBenchTm ?? block.benchTm;
  final startDeadlift = block.startDeadliftTm ?? block.deadliftTm;
  final startPress = block.startPressTm ?? block.pressTm;
  final leader = supplementalName(block.leaderSupplemental);
  final anchor = supplementalName(block.anchorSupplemental);
  return '${_date(block.created)} to ${_date(block.completed!)} '
      '(${block.unit}): '
      'squat ${_n(startSquat)}->${_n(block.squatTm)}, '
      'bench ${_n(startBench)}->${_n(block.benchTm)}, '
      'deadlift ${_n(startDeadlift)}->${_n(block.deadliftTm)}, '
      'press ${_n(startPress)}->${_n(block.pressTm)}; '
      'leader $leader, anchor $anchor';
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String _n(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

Map<String, Object?> _ok(String text) => <String, Object?>{
      'ok': true,
      'text': text,
    };

Map<String, Object?> _error(String message) => <String, Object?>{
      'ok': false,
      'error': message,
    };
