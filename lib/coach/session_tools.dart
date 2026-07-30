import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/exercise_names.dart';
import '../fivethreeone/main_lifts.dart';
import '../main.dart';
import 'weight_spec.dart';

/// Ordering used to number an exercise's sets, matching `session_snapshot.dart`
/// so the indices the model sees are the indices this tool writes to.
const String _setOrderExpression =
    'COALESCE(set_order, CAST((julianday(created) - 2440587.5) * '
    '86400000 AS INTEGER))';

const Set<String> _opNames = <String>{
  'add_exercise',
  'add_sets',
  'edit_set',
  'remove_sets',
};

const Set<String> _opKeys = <String>{
  'op',
  'exercise',
  'sets',
  'set_index',
  'set_indices',
  'weight_spec',
  'reps',
  'create_new',
};

const Set<String> _setKeys = <String>{'weight_spec', 'reps', 'amrap'};

/// Applies the auto-apply write tier: `apply_session_changes(ops[])`.
///
/// Every op is confined to `hidden = 1` rows — prescribed but not performed —
/// in the *current* workout, and the whole call lands in one Drift transaction
/// (CLAUDE.md: never a loop of per-row writes). Validation happens in full
/// before any write, so a rejected call writes nothing at all.
///
/// Returns a structured tool result. On success:
/// `{ok: true, workoutId, unit..., applied: [...]}`, where each applied entry
/// carries the resolved weight × reps and its unit — the model must report
/// weights from this result rather than from its own arithmetic. On failure:
/// `{ok: false, error: '...'}`, a sentence the model can act on and retry.
Future<Map<String, Object?>> applySessionChanges({
  required Map<String, Object?> arguments,
  required FiveThreeOneBlock? block,
  required Workout? workout,
  required List<String> exerciseVocabulary,
  required String settingsUnit,
}) async {
  if (workout == null) {
    return _error(
      'There is no active workout, so session sets cannot be written. Start '
      'the workout first.',
    );
  }

  final rawOps = arguments['ops'];
  if (rawOps is! List || rawOps.isEmpty) {
    return _error('apply_session_changes needs a non-empty ops array.');
  }

  final planner = _SessionPlanner(
    block: block,
    workout: workout,
    settingsUnit: settingsUnit.trim().isEmpty ? 'kg' : settingsUnit.trim(),
    vocabulary: exerciseVocabulary,
  );

  final String? loadError = await planner.load();
  if (loadError != null) return _error(loadError);

  final applied = <Object?>[];
  for (var i = 0; i < rawOps.length; i++) {
    final rawOp = rawOps[i];
    if (rawOp is! Map) {
      return _error('ops[$i] must be an object.');
    }
    final result = await planner.plan(rawOp, i);
    if (result.isError) return _error(result.error!);
    applied.add(result.value);
  }

  await planner.commit();

  return <String, Object?>{
    'ok': true,
    'workoutId': workout.id,
    'applied': applied,
  };
}

Map<String, Object?> _error(String message) => <String, Object?>{
      'ok': false,
      'error': message,
    };

/// One set row as planned, before anything is written.
class _PlannedRow {
  _PlannedRow.existing(GymSet row)
      : id = row.id,
        performed = !row.hidden,
        weight = row.weight,
        reps = row.reps,
        storedSetOrder = row.setOrder,
        unit = row.unit,
        amrap = false,
        isNew = false;

  _PlannedRow.fresh({
    required this.weight,
    required this.reps,
    required this.unit,
    required this.amrap,
  })  : id = null,
        performed = false,
        storedSetOrder = null,
        isNew = true;

  final int? id;

  /// `hidden = 0`: the user actually did this set. Off limits to this tier.
  final bool performed;
  final bool isNew;
  final int? storedSetOrder;

  double weight;
  double reps;
  String unit;

  /// Requested AMRAP flag, reported back in the tool result but deliberately
  /// not stored.
  ///
  /// An AMRAP set is written at its floor rep count — "5+" is logged as 5 —
  /// which is the same row the user then edits up to whatever they actually hit.
  /// `gym_sets` gets no amrap column: the flag would only ever restate the
  /// prescription, and the performed reps already carry the real answer.
  bool amrap;

  bool removed = false;
  bool edited = false;
  int? newSetOrder;
}

/// The planned state of one exercise within the current workout.
class _ExerciseState {
  _ExerciseState({
    required this.name,
    required this.rows,
    required this.sequence,
    required this.unit,
    required this.reference,
    required this.existedBefore,
  });

  final String name;
  final List<_PlannedRow> rows;
  final int sequence;
  final String unit;

  /// A row to copy exercise metadata (category, brand, rest…) from.
  final GymSet? reference;
  final bool existedBefore;

  List<PrescribedSet>? prescription;
  List<double>? lastSessionWeights;
  double? trainingMax;
  bool basesLoaded = false;

  List<_PlannedRow> get live =>
      rows.where((row) => !row.removed).toList(growable: false);
}

class _SessionPlanner {
  _SessionPlanner({
    required this.block,
    required this.workout,
    required this.settingsUnit,
    required this.vocabulary,
  });

  final FiveThreeOneBlock? block;
  final Workout workout;
  final String settingsUnit;
  final List<String> vocabulary;

  final Map<String, _ExerciseState> _states = <String, _ExerciseState>{};

  /// Canonical name by lower-cased name, for every name this tool may write.
  final Map<String, String> _known = <String, String>{};
  final List<GymSet> _workoutRows = <GymSet>[];
  int _maxSequence = -1;

  Future<String?> load() async {
    final rows = await (db.select(db.gymSets)
          ..where(
            (row) =>
                row.workoutId.equals(workout.id) &
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
    _workoutRows.addAll(rows);
    for (final row in rows) {
      if (row.sequence > _maxSequence) _maxSequence = row.sequence;
    }

    // The closed vocabulary (PRD decision 11) is the snapshot's list plus
    // anything already in this session or on its plan: a plan exercise that
    // has never been logged is legitimately absent from the history-derived
    // vocabulary, and refusing it would be wrong.
    for (final name in vocabulary) {
      _known.putIfAbsent(name.trim().toLowerCase(), () => name);
    }
    for (final row in rows) {
      _known.putIfAbsent(row.name.trim().toLowerCase(), () => row.name);
    }
    if (workout.planId != null) {
      final planNames = await (db.select(db.planExercises)
            ..where(
              (row) =>
                  row.planId.equals(workout.planId!) & row.enabled.equals(true),
            ))
          .map((row) => row.exercise)
          .get();
      for (final name in planNames) {
        _known.putIfAbsent(name.trim().toLowerCase(), () => name);
      }
    }
    return null;
  }

  Future<CoachResult<Map<String, Object?>>> plan(
    Map<Object?, Object?> raw,
    int index,
  ) async {
    for (final key in raw.keys) {
      if (key is! String || !_opKeys.contains(key)) {
        // Catches a bare `weight` or a `unit` smuggled into an op: neither is
        // ever allowed in tool arguments.
        return CoachResult<Map<String, Object?>>.failed(
          "ops[$index] does not take '$key'. Allowed keys are "
          '${_opKeys.join(', ')}.',
        );
      }
    }

    final op = raw['op'];
    if (op is! String || !_opNames.contains(op)) {
      return CoachResult<Map<String, Object?>>.failed(
        'ops[$index].op must be one of ${_opNames.join(', ')}.',
      );
    }

    final rawExercise = raw['exercise'];
    if (rawExercise is! String || rawExercise.trim().isEmpty) {
      return CoachResult<Map<String, Object?>>.failed(
        'ops[$index] needs an exercise name from exerciseVocabulary.',
      );
    }

    if (raw['create_new'] == true) {
      return CoachResult<Map<String, Object?>>.failed(
        "Creating '${rawExercise.trim()}' is not an auto-apply change; "
        'propose it with propose_block_changes (op create_exercise) so the '
        'user can confirm it.',
      );
    }

    final requested = normalizeExerciseName(rawExercise);
    final canonical = _known[requested.trim().toLowerCase()];
    if (canonical == null) {
      // Never fuzzy-match and proceed: `mainLiftTmKeys` is deliberately
      // exact-match so 'Squat' cannot resolve to 'Front Squat'.
      return CoachResult<Map<String, Object?>>.failed(
        _unknownExerciseMessage(requested),
      );
    }

    final state = await _stateFor(canonical);

    switch (op) {
      case 'add_exercise':
        return _planAdd(state, raw, index, requireAbsent: true);
      case 'add_sets':
        return _planAdd(state, raw, index, requireAbsent: false);
      case 'edit_set':
        return _planEdit(state, raw, index);
      default:
        return _planRemove(state, raw, index);
    }
  }

  Future<CoachResult<Map<String, Object?>>> _planAdd(
    _ExerciseState state,
    Map<Object?, Object?> raw,
    int index, {
    required bool requireAbsent,
  }) async {
    final present = state.live.isNotEmpty;
    if (requireAbsent && present) {
      return CoachResult<Map<String, Object?>>.failed(
        '${state.name} is already in this workout; use add_sets to append to '
        'it.',
      );
    }
    if (!requireAbsent && !present) {
      return CoachResult<Map<String, Object?>>.failed(
        '${state.name} is not in this workout yet; use add_exercise to add it.',
      );
    }

    final rawSets = raw['sets'];
    if (rawSets is! List || rawSets.isEmpty) {
      return CoachResult<Map<String, Object?>>.failed(
        'ops[$index] needs a non-empty sets array.',
      );
    }

    await _loadBases(state);
    final written = <Object?>[];
    for (var i = 0; i < rawSets.length; i++) {
      final rawSet = rawSets[i];
      if (rawSet is! Map) {
        return CoachResult<Map<String, Object?>>.failed(
          'ops[$index].sets[$i] must be an object.',
        );
      }
      for (final key in rawSet.keys) {
        if (key is! String || !_setKeys.contains(key)) {
          return CoachResult<Map<String, Object?>>.failed(
            "ops[$index].sets[$i] does not take '$key'. Allowed keys are "
            '${_setKeys.join(', ')}.',
          );
        }
      }

      final reps = _parseReps(rawSet['reps']);
      if (reps.isError) {
        return CoachResult<Map<String, Object?>>.failed(
          'ops[$index].sets[$i]: ${reps.error}',
        );
      }

      // The set's index once written decides which prescribed / last-session
      // weight it is measured against.
      final targetIndex = state.live.length;
      final weight = _resolveAt(state, rawSet['weight_spec'], targetIndex);
      if (weight.isError) {
        return CoachResult<Map<String, Object?>>.failed(
          'ops[$index].sets[$i]: ${weight.error}',
        );
      }

      final amrap = rawSet['amrap'] == true;
      state.rows.add(
        _PlannedRow.fresh(
          weight: weight.value!,
          reps: reps.value!.toDouble(),
          unit: state.unit,
          amrap: amrap,
        ),
      );
      written.add(
        _describeSet(weight.value!, reps.value!.toDouble(), state.unit, amrap),
      );
    }

    return CoachResult<Map<String, Object?>>.ok(<String, Object?>{
      'op': requireAbsent ? 'add_exercise' : 'add_sets',
      'exercise': state.name,
      'sets': written,
    });
  }

  Future<CoachResult<Map<String, Object?>>> _planEdit(
    _ExerciseState state,
    Map<Object?, Object?> raw,
    int index,
  ) async {
    final target = _rowAt(state, raw['set_index'], index, 'set_index');
    if (target.isError) {
      return CoachResult<Map<String, Object?>>.failed(target.error!);
    }
    final row = target.value!;

    final hasWeight = raw['weight_spec'] != null;
    final hasReps = raw['reps'] != null;
    if (!hasWeight && !hasReps) {
      return CoachResult<Map<String, Object?>>.failed(
        'ops[$index] (edit_set) needs weight_spec, reps, or both.',
      );
    }

    if (hasReps) {
      final reps = _parseReps(raw['reps']);
      if (reps.isError) {
        return CoachResult<Map<String, Object?>>.failed(
          'ops[$index]: ${reps.error}',
        );
      }
      row.reps = reps.value!.toDouble();
    }

    if (hasWeight) {
      await _loadBases(state);
      final position = state.live.indexOf(row);
      final weight = _resolveAt(state, raw['weight_spec'], position);
      if (weight.isError) {
        return CoachResult<Map<String, Object?>>.failed(
          'ops[$index]: ${weight.error}',
        );
      }
      row.weight = weight.value!;
    }

    row.edited = true;
    return CoachResult<Map<String, Object?>>.ok(<String, Object?>{
      'op': 'edit_set',
      'exercise': state.name,
      'setIndex': (raw['set_index']! as num).toInt(),
      'set': _describeSet(row.weight, row.reps, row.unit, row.amrap),
    });
  }

  Future<CoachResult<Map<String, Object?>>> _planRemove(
    _ExerciseState state,
    Map<Object?, Object?> raw,
    int index,
  ) async {
    final rawIndices = raw['set_indices'];
    if (rawIndices is! List || rawIndices.isEmpty) {
      return CoachResult<Map<String, Object?>>.failed(
        'ops[$index] (remove_sets) needs a non-empty set_indices array.',
      );
    }

    final seen = <int>{};
    final removed = <int>[];
    // Resolve every index against the same pre-op snapshot so a list like
    // [0, 1] does not shift under itself as rows are marked removed.
    final before = state.live;
    for (final rawIndex in rawIndices) {
      final target = _rowIn(before, state, rawIndex, index, 'set_indices');
      if (target.isError) {
        return CoachResult<Map<String, Object?>>.failed(target.error!);
      }
      final row = target.value!;
      if (!seen.add((rawIndex as num).toInt())) continue;
      row.removed = true;
      removed.add(rawIndex.toInt());
    }

    // Prescribed rows that survive close the gap, mirroring how the workout
    // card renumbers set_order after a delete. Performed rows keep theirs.
    var position = 0;
    for (final row in state.live) {
      if (!row.performed && !row.isNew) row.newSetOrder = position;
      position++;
    }

    return CoachResult<Map<String, Object?>>.ok(<String, Object?>{
      'op': 'remove_sets',
      'exercise': state.name,
      'setIndices': removed,
      'removed': removed.length,
    });
  }

  CoachResult<_PlannedRow> _rowAt(
    _ExerciseState state,
    Object? rawIndex,
    int opIndex,
    String field,
  ) =>
      _rowIn(state.live, state, rawIndex, opIndex, field);

  CoachResult<_PlannedRow> _rowIn(
    List<_PlannedRow> rows,
    _ExerciseState state,
    Object? rawIndex,
    int opIndex,
    String field,
  ) {
    if (rawIndex is! num || rawIndex != rawIndex.roundToDouble()) {
      return CoachResult<_PlannedRow>.failed(
        'ops[$opIndex].$field must be a 0-based integer set index.',
      );
    }
    final index = rawIndex.toInt();
    if (index < 0 || index >= rows.length) {
      return CoachResult<_PlannedRow>.failed(
        '${state.name} has ${rows.length} set(s) in this workout, so index '
        '$index does not exist. Indices are 0-based and count every set, '
        'performed ones included.',
      );
    }
    final row = rows[index];
    if (row.performed) {
      // Never a silent no-op: the model must know it aimed at done work.
      return CoachResult<_PlannedRow>.failed(
        '${state.name} set $index is already performed, so it cannot be '
        'changed here. Changing performed work needs propose_block_changes '
        "and the user's confirmation.",
      );
    }
    return CoachResult<_PlannedRow>.ok(row);
  }

  CoachResult<double> _resolveAt(
    _ExerciseState state,
    Object? rawSpec,
    int position,
  ) {
    final parsed = parseWeightSpec(rawSpec);
    if (parsed.isError) return CoachResult<double>.failed(parsed.error!);

    final prescription = state.prescription;
    final last = state.lastSessionWeights;
    return resolveWeightSpec(
      spec: parsed.value!,
      exercise: state.name,
      unit: state.unit,
      bases: WeightBases(
        trainingMax: state.trainingMax,
        prescribed: prescription != null && position < prescription.length
            ? prescription[position].weight
            : null,
        // Beyond the sets logged last session, the last set stands in — an
        // extra set is naturally "same as the last one".
        lastSession: last == null || last.isEmpty
            ? null
            : last[position < last.length ? position : last.length - 1],
      ),
    );
  }

  CoachResult<int> _parseReps(Object? raw) {
    if (raw is! num || raw != raw.roundToDouble()) {
      return const CoachResult<int>.failed('reps must be a whole number.');
    }
    final reps = raw.toInt();
    if (reps < 1 || reps > 100) {
      return CoachResult<int>.failed('reps must be between 1 and 100, got $reps.');
    }
    return CoachResult<int>.ok(reps);
  }

  Future<_ExerciseState> _stateFor(String name) async {
    final cached = _states[name];
    if (cached != null) return cached;

    final rows = _workoutRows.where((row) => row.name == name).toList();
    final unit = await _resolveUnit(name, rows);
    final reference = rows.isNotEmpty
        ? rows.first
        : await (db.select(db.gymSets)
              ..where(
                (row) =>
                    row.name.equals(name) &
                    row.sequence.isNotValue(-1) &
                    row.reps.isNotValue(-1),
              )
              ..orderBy([
                (row) => OrderingTerm(
                      expression: row.created,
                      mode: OrderingMode.desc,
                    ),
              ])
              ..limit(1))
            .getSingleOrNull();

    final state = _ExerciseState(
      name: name,
      rows: rows.map(_PlannedRow.existing).toList(),
      sequence: rows.isNotEmpty ? rows.first.sequence : _maxSequence + 1,
      unit: unit,
      reference: reference,
      existedBefore: rows.isNotEmpty,
    );
    if (rows.isEmpty) _maxSequence += 1;
    _states[name] = state;
    return state;
  }

  /// Units are inherited, never taken from the model (PRD decision 12):
  /// main lifts follow the block, accessories follow their own last set, and
  /// the app's strength unit is the final fallback.
  Future<String> _resolveUnit(String name, List<GymSet> workoutRows) async {
    if (block != null && mainLiftTmKey(name) != null) return block!.unit;
    if (workoutRows.isNotEmpty) return workoutRows.last.unit;

    final recent = await (db.select(db.gymSets)
          ..where(
            (row) =>
                row.name.equals(name) &
                row.sequence.isNotValue(-1) &
                row.reps.isNotValue(-1),
          )
          ..orderBy([
            (row) =>
                OrderingTerm(expression: row.created, mode: OrderingMode.desc),
            (row) => OrderingTerm(expression: row.id, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    return recent?.unit ?? settingsUnit;
  }

  Future<void> _loadBases(_ExerciseState state) async {
    if (state.basesLoaded) return;
    state.basesLoaded = true;

    final activeBlock = block;
    if (activeBlock != null) {
      final tmKey = mainLiftTmKey(state.name);
      if (tmKey != null) {
        final tm = trainingMaxFor(activeBlock, tmKey);
        state.trainingMax = tm > 0 ? tm : null;
      }
      state.prescription = mainWorkPrescription(
        block: activeBlock,
        exerciseName: state.name,
      );
    }

    final rows = await db.customSelect(
      '''
      SELECT weight
      FROM gym_sets
      WHERE name = ?
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
      ORDER BY $_setOrderExpression, created, id
    ''',
      variables: <Variable>[
        Variable.withString(state.name),
        Variable.withInt(workout.id),
        Variable.withInt(workout.id),
      ],
      readsFrom: {db.gymSets},
    ).get();
    state.lastSessionWeights =
        rows.map((row) => row.read<double>('weight')).toList();
  }

  /// Writes every planned change in one transaction. Drift's batch wraps the
  /// whole set of statements in a single transaction, so a multi-op call is
  /// one commit and one fsync rather than one per row (CLAUDE.md).
  Future<void> commit() async {
    final inserts = <GymSetsCompanion>[];
    final updates = <(int, GymSetsCompanion)>[];
    final deletions = <int>[];
    final created = DateTime.now().toLocal();

    for (final state in _states.values) {
      var position = 0;
      for (final row in state.rows) {
        if (row.removed) {
          if (row.id != null) deletions.add(row.id!);
          continue;
        }
        if (row.isNew) {
          inserts.add(_insertFor(state, row, position, created));
        } else if (row.edited || row.newSetOrder != null) {
          final companion = GymSetsCompanion(
            weight: row.edited ? Value(row.weight) : const Value.absent(),
            reps: row.edited ? Value(row.reps) : const Value.absent(),
            setOrder: row.newSetOrder != null
                ? Value(row.newSetOrder)
                : const Value.absent(),
          );
          updates.add((row.id!, companion));
        }
        position++;
      }
    }

    if (inserts.isEmpty && updates.isEmpty && deletions.isEmpty) return;

    await db.batch((batch) {
      if (inserts.isNotEmpty) batch.insertAll(db.gymSets, inserts);
      for (final (id, companion) in updates) {
        batch.update(
          db.gymSets,
          companion,
          where: (row) => row.id.equals(id),
        );
      }
      if (deletions.isNotEmpty) {
        batch.deleteWhere(db.gymSets, (row) => row.id.isIn(deletions));
      }
    });
  }

  GymSetsCompanion _insertFor(
    _ExerciseState state,
    _PlannedRow row,
    int position,
    DateTime created,
  ) {
    final reference = state.reference;
    return GymSetsCompanion.insert(
      name: state.name,
      reps: row.reps,
      weight: row.weight,
      unit: row.unit,
      created: created,
      workoutId: Value(workout.id),
      planId: Value(workout.planId),
      sequence: Value(state.sequence),
      setOrder: Value(position),
      // hidden = 1 is the existing "prescribed but not performed" state; the
      // normal UI flips it to 0 when the user completes the set.
      hidden: const Value(true),
      category: Value(reference?.category),
      image: Value(reference?.image),
      exerciseType: Value(reference?.exerciseType),
      brandName: Value(reference?.brandName),
      restMs: Value(reference?.restMs),
      supersetId: Value(state.existedBefore ? reference?.supersetId : null),
      supersetPosition:
          Value(state.existedBefore ? reference?.supersetPosition : null),
    );
  }

  String _unknownExerciseMessage(String requested) {
    final candidates = _nearest(requested);
    if (candidates.isEmpty) {
      return "unknown exercise '$requested'; use an exact name from "
          'exerciseVocabulary.';
    }
    return "unknown exercise '$requested'; did you mean "
        '${candidates.map((name) => "'$name'").join(' or ')}?';
  }

  List<String> _nearest(String requested) {
    final query = requested.trim().toLowerCase();
    final scored = <(int, String)>[];
    for (final entry in _known.entries) {
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
}

Map<String, Object?> _describeSet(
  double weight,
  double reps,
  String unit,
  bool amrap,
) =>
    <String, Object?>{
      'weight': _n(weight),
      'reps': _n(reps),
      'unit': unit,
      if (amrap) 'amrap': true,
    };

num _n(double value) =>
    value == value.roundToDouble() ? value.toInt() : value;
