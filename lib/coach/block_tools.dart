import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/exercise_names.dart';
import '../fivethreeone/fivethreeone_state.dart';
import '../fivethreeone/main_lifts.dart';
import '../fivethreeone/schemes.dart';
import '../main.dart';
import 'weight_spec.dart';

const String proposeBlockChangesTool = 'propose_block_changes';

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

Map<String, Object?> _blockOpSchema() => <String, Object?>{
      'type': 'object',
      'description': 'Propose one block-level change for confirmation.',
      'additionalProperties': false,
      'required': <String>['op'],
      'properties': <String, Object?>{
        'op': <String, Object?>{
          'type': 'string',
          'description':
              'Choose the operation. bump_tms moves all four TMs and counts as a '
                  'cycle bump; correct_tm fixes one TM without a cycle bump; '
                  'unbump_tms undoes the last bump.',
          'enum': <String>[
            'bump_tms',
            'unbump_tms',
            'correct_tm',
            'advance_week',
            'go_back_week',
            'set_supplemental',
            'create_exercise',
          ],
        },
        'lift': <String, Object?>{
          'type': 'string',
          'description': 'Choose the lift whose training max is corrected.',
          'enum': <String>['squat', 'bench', 'deadlift', 'press'],
        },
        'value': <String, Object?>{
          'type': 'number',
          'description': 'Set the corrected training max in the block unit.',
        },
        'cycle': <String, Object?>{
          'type': 'string',
          'description':
              'Choose the cycle receiving the supplemental template.',
          'enum': <String>['leader', 'anchor'],
        },
        'supplemental': <String, Object?>{
          'type': 'string',
          'description': 'Choose the supplemental template.',
          'enum': <String>['bbb', 'fsl'],
        },
        'exercise': <String, Object?>{
          'type': 'string',
          'description': 'Name the exercise to create.',
        },
      },
      'allOf': <Object?>[
        <String, Object?>{
          'if': <String, Object?>{
            'properties': <String, Object?>{
              'op': <String, Object?>{'const': 'correct_tm'},
            },
          },
          'then': <String, Object?>{
            'required': <String>['lift', 'value'],
          },
        },
        <String, Object?>{
          'if': <String, Object?>{
            'properties': <String, Object?>{
              'op': <String, Object?>{'const': 'set_supplemental'},
            },
          },
          'then': <String, Object?>{
            'required': <String>['cycle', 'supplemental'],
          },
        },
        <String, Object?>{
          'if': <String, Object?>{
            'properties': <String, Object?>{
              'op': <String, Object?>{'const': 'create_exercise'},
            },
          },
          'then': <String, Object?>{
            'required': <String>['exercise'],
          },
        },
      ],
    };

/// The model-facing contract is duplicated from the eval server deliberately:
/// this boundary is the authority boundary, so evaluation and device builds
/// must agree on exactly what can reach the confirmation screen.
Map<String, Object?> proposeBlockChangesToolSchema() => _tool(
      proposeBlockChangesTool,
      'Write nothing. Return a proposal the user must confirm. Include one '
      'sentence of 5/3/1 doctrine in rationale.',
      <String, Object?>{
        'type': 'object',
        'additionalProperties': false,
        'required': <String>['ops', 'rationale'],
        'properties': <String, Object?>{
          'ops': <String, Object?>{
            'type': 'array',
            'description': 'Propose one or more block operations.',
            'minItems': 1,
            'items': _blockOpSchema(),
          },
          'rationale': <String, Object?>{
            'type': 'string',
            'description': 'Give one sentence of 5/3/1 doctrine.',
          },
        },
      },
    );

enum BlockOpKind {
  bumpTms,
  unbumpTms,
  correctTm,
  advanceWeek,
  goBackWeek,
  setSupplemental,
  createExercise;

  String get wire => switch (this) {
        BlockOpKind.bumpTms => 'bump_tms',
        BlockOpKind.unbumpTms => 'unbump_tms',
        BlockOpKind.correctTm => 'correct_tm',
        BlockOpKind.advanceWeek => 'advance_week',
        BlockOpKind.goBackWeek => 'go_back_week',
        BlockOpKind.setSupplemental => 'set_supplemental',
        BlockOpKind.createExercise => 'create_exercise',
      };
}

/// Resolves the model's discriminator without guessing at a near match.
BlockOpKind? blockOpKindOf(String wire) {
  for (final kind in BlockOpKind.values) {
    if (kind.wire == wire) return kind;
  }
  return null;
}

/// A block mutation that has crossed schema and live-state validation.
class BlockOp {
  const BlockOp({
    required this.kind,
    this.lift,
    this.value,
    this.cycle,
    this.supplemental,
    this.exercise,
  });

  final BlockOpKind kind;
  final String? lift;
  final double? value;
  final String? cycle;
  final String? supplemental;
  final String? exercise;

  Map<String, Object?> toJson() => <String, Object?>{
        'op': kind.wire,
        if (lift != null) 'lift': lift,
        if (value != null) 'value': value,
        if (cycle != null) 'cycle': cycle,
        if (supplemental != null) 'supplemental': supplemental,
        if (exercise != null) 'exercise': exercise,
      };

  // The wire API requires a static decoder rather than a named constructor.
  // ignore: prefer_constructors_over_static_methods
  static BlockOp fromJson(Map<String, Object?> json) {
    final rawKind = json['op'];
    final kind = rawKind is String ? blockOpKindOf(rawKind) : null;
    if (kind == null) throw const FormatException('Invalid block operation.');
    final rawValue = json['value'];
    return BlockOp(
      kind: kind,
      lift: json['lift'] as String?,
      value: rawValue == null ? null : (rawValue as num).toDouble(),
      cycle: json['cycle'] as String?,
      supplemental: json['supplemental'] as String?,
      exercise: json['exercise'] as String?,
    );
  }
}

/// One reviewable line on the confirmation card.
class BlockChange {
  const BlockChange({
    required this.label,
    required this.before,
    required this.after,
    required this.detail,
  });

  final String label;
  final String? before;
  final String? after;
  final String detail;

  Map<String, Object?> toJson() => <String, Object?>{
        'label': label,
        'before': before,
        'after': after,
        'detail': detail,
      };

  // The wire API requires a static decoder rather than a named constructor.
  // ignore: prefer_constructors_over_static_methods
  static BlockChange fromJson(Map<String, Object?> json) => BlockChange(
        label: json['label']! as String,
        before: json['before'] as String?,
        after: json['after'] as String?,
        detail: json['detail']! as String,
      );
}

/// The complete immutable review surface stored with the tool result.
///
/// [bumpSemantics] is correctness data, not decorative copy: it tells apart a
/// cycle bump and a one-lift correction even when their displayed weights look
/// nearly identical.
class BlockProposal {
  const BlockProposal({
    required this.ops,
    required this.rationale,
    required this.changes,
    required this.bumpSemantics,
    required this.tmBumpsBefore,
    required this.tmBumpsAfter,
  });

  final List<BlockOp> ops;
  final String rationale;
  final List<BlockChange> changes;

  /// Always names what happens to the bump counter in plain words.
  final String bumpSemantics;
  final int tmBumpsBefore;
  final int tmBumpsAfter;

  bool get countsAsCycleBump => tmBumpsAfter > tmBumpsBefore;
  bool get decrementsCycleBump => tmBumpsAfter < tmBumpsBefore;

  Map<String, Object?> toJson() => <String, Object?>{
        'ops': ops.map((op) => op.toJson()).toList(),
        'rationale': rationale,
        'changes': changes.map((change) => change.toJson()).toList(),
        'bumpSemantics': bumpSemantics,
        'tmBumpsBefore': tmBumpsBefore,
        'tmBumpsAfter': tmBumpsAfter,
      };

  // The wire API requires a static decoder rather than a named constructor.
  // ignore: prefer_constructors_over_static_methods
  static BlockProposal fromJson(Map<String, Object?> json) => BlockProposal(
        ops: (json['ops']! as List<Object?>)
            .map(
              (op) => BlockOp.fromJson(
                Map<String, Object?>.from(op! as Map),
              ),
            )
            .toList(),
        rationale: json['rationale']! as String,
        changes: (json['changes']! as List<Object?>)
            .map(
              (change) => BlockChange.fromJson(
                Map<String, Object?>.from(change! as Map),
              ),
            )
            .toList(),
        bumpSemantics: json['bumpSemantics']! as String,
        tmBumpsBefore: (json['tmBumpsBefore']! as num).toInt(),
        tmBumpsAfter: (json['tmBumpsAfter']! as num).toInt(),
      );
}

const Set<String> _topLevelKeys = <String>{'ops', 'rationale'};
const Set<String> _opKeys = <String>{
  'op',
  'lift',
  'value',
  'cycle',
  'supplemental',
  'exercise',
};
const Set<String> _liftKeys = <String>{'squat', 'bench', 'deadlift', 'press'};
const String _opChoices =
    'bump_tms, unbump_tms, correct_tm, advance_week, go_back_week, '
    'set_supplemental, create_exercise';

/// Plans block-level changes without touching persistence.
///
/// A proposal is the last read-only boundary before an irreversible tap. In
/// particular, a one-lift correction must remain visibly distinct from
/// `_shiftTms`, whose bump counter controls later Back-button behaviour.
Future<Map<String, Object?>> proposeBlockChanges({
  required Map<String, Object?> arguments,
  required FiveThreeOneBlock? block,
  required List<String> exerciseVocabulary,
  required String settingsUnit,
}) async {
  if (block == null) {
    return _error(
      'There is no active 5/3/1 block, so there is nothing to change.',
    );
  }

  for (final key in arguments.keys) {
    if (!_topLevelKeys.contains(key)) {
      return _error(
        "propose_block_changes does not take '$key'. The allowed keys are "
        'ops and rationale.',
      );
    }
  }

  final rationale = arguments['rationale'];
  if (rationale is! String || rationale.trim().isEmpty) {
    return _error(
      'propose_block_changes needs a rationale: one sentence of 5/3/1 '
      'doctrine explaining the change.',
    );
  }
  final rawOps = arguments['ops'];
  if (rawOps is! List || rawOps.isEmpty) {
    return _error('propose_block_changes needs a non-empty ops array.');
  }

  final planner = _BlockPlanner(
    block: block,
    vocabulary: exerciseVocabulary,
  );
  final parsed = <BlockOp>[];
  for (var i = 0; i < rawOps.length; i++) {
    final result = planner.add(rawOps[i], i);
    if (result.isError) return _error(result.error!);
    parsed.add(result.value!);
  }

  final conflict = planner.conflictError(parsed);
  if (conflict != null) return _error(conflict);

  final proposal = planner.build(parsed, rationale.trim());
  return <String, Object?>{
    'ok': true,
    'status': 'pending_confirmation',
    'proposal': proposal.toJson(),
    'note': 'Nothing has been written. The user must tap Apply.',
  };
}

/// Commits only a proposal the user has explicitly confirmed.
///
/// Validation is repeated against live state because the block may have moved
/// while the card was visible. Every TM mutation stays behind
/// [FiveThreeOneState]: `bumpTms` owns `tmBumps`, while `updateTm` deliberately
/// does not. There is no undo layer after this authority boundary.
Future<Map<String, Object?>> applyBlockProposal({
  required BlockProposal proposal,
  required FiveThreeOneState fiveThreeOneState,
  required String settingsUnit,
}) async {
  // Only `create_exercise` consults the vocabulary, and only to refuse a name
  // that already exists. Reading every set row for the other six ops would be
  // a full table scan for nothing, so the query is scoped to distinct names
  // and skipped entirely when no op needs it.
  final needsVocabulary = proposal.ops
      .any((op) => op.kind == BlockOpKind.createExercise);
  final vocabulary = needsVocabulary
      ? (await db.customSelect(
          'SELECT DISTINCT name FROM gym_sets '
          'WHERE sequence != -1 AND reps != -1',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{db.gymSets},
        ).get())
          .map((row) => row.read<String>('name'))
          .toList(growable: false)
      : const <String>[];
  final validation = await proposeBlockChanges(
    arguments: <String, Object?>{
      'ops': proposal.ops.map((op) => op.toJson()).toList(),
      'rationale': proposal.rationale,
    },
    block: fiveThreeOneState.activeBlock,
    exerciseVocabulary: vocabulary,
    settingsUnit: settingsUnit,
  );
  if (validation['ok'] != true) {
    return <String, Object?>{
      'ok': false,
      'status': 'failed',
      'error': validation['error'],
    };
  }

  final applied = <Object?>[];
  try {
    await db.transaction(() async {
      // These are single-row writes on different concerns. They cannot be
      // folded into a raw batch without bypassing FiveThreeOneState methods
      // that keep tm_bumps consistent with the four training maxes.
      for (final op in proposal.ops) {
        switch (op.kind) {
          case BlockOpKind.bumpTms:
            await fiveThreeOneState.bumpTms();
          case BlockOpKind.unbumpTms:
            await fiveThreeOneState.unbumpTms();
          case BlockOpKind.correctTm:
            await fiveThreeOneState.updateTm(
              exercise: op.lift!,
              value: op.value!,
            );
          case BlockOpKind.advanceWeek:
            await fiveThreeOneState.advanceWeek();
          case BlockOpKind.goBackWeek:
            await fiveThreeOneState.goBackWeek();
          case BlockOpKind.setSupplemental:
            final current = fiveThreeOneState.activeBlock!;
            // This sanctioned column write changes only the supplemental
            // selection; it never touches a TM or tm_bumps column.
            await (db.update(db.fiveThreeOneBlocks)
                  ..where((row) => row.id.equals(current.id)))
                .write(
              FiveThreeOneBlocksCompanion(
                leaderSupplemental: op.cycle == 'leader'
                    ? Value(op.supplemental!)
                    : const Value.absent(),
                anchorSupplemental: op.cycle == 'anchor'
                    ? Value(op.supplemental!)
                    : const Value.absent(),
              ),
            );
            await fiveThreeOneState.refresh();
          case BlockOpKind.createExercise:
            final unit =
                settingsUnit.trim().isEmpty ? 'kg' : settingsUnit.trim();
            await db.into(db.gymSets).insert(
                  GymSetsCompanion.insert(
                    name: op.exercise!,
                    reps: 1,
                    weight: 0,
                    unit: unit,
                    created: DateTime.now(),
                    hidden: const Value(true),
                    sequence: const Value(0),
                    setOrder: const Value(0),
                  ),
                );
          // reps/sequence must not use the -1 tombstone sentinel: removed
          // rows are intentionally excluded from exerciseVocabulary.
        }
        applied.add(op.toJson());
      }
    });
  } catch (error) {
    await fiveThreeOneState.refresh();
    return <String, Object?>{
      'ok': false,
      'status': 'failed',
      'error': 'The block proposal could not be applied. Nothing was written.',
    };
  }

  await fiveThreeOneState.refresh();
  final block = fiveThreeOneState.activeBlock;
  if (block == null) {
    return <String, Object?>{
      'ok': false,
      'status': 'failed',
      'error': 'The active block disappeared before the proposal completed.',
    };
  }
  return <String, Object?>{
    'ok': true,
    'status': 'applied',
    'applied': applied,
    'tmBumps': block.tmBumps,
    'block': _blockSummary(block),
  };
}

/// Closes the model's proposal loop without creating an undoable mutation.
///
/// The explicit instruction prevents a declined change from being immediately
/// offered again as though the confirmation card had never been answered.
Map<String, Object?> declinedBlockProposalResult(BlockProposal proposal) =>
    <String, Object?>{
      'ok': true,
      'status': 'declined',
      'declined': proposal.ops.map((op) => op.kind.wire).toList(),
      'note': 'The user declined this proposal. Nothing was written. Do not '
          'propose the same change again unless they ask.',
    };

Map<String, Object?> _error(String message) => <String, Object?>{
      'ok': false,
      'error': message,
    };

Map<String, Object?> _blockSummary(FiveThreeOneBlock block) =>
    <String, Object?>{
      'cycle': block.currentCycle,
      'week': block.currentWeek,
      'position': cyclePositionLabel(
        block.currentCycle,
        block.currentWeek,
        block.supplementals,
      ),
      'squatTm': block.squatTm,
      'benchTm': block.benchTm,
      'deadliftTm': block.deadliftTm,
      'pressTm': block.pressTm,
      'unit': block.unit,
    };

class _BlockPlanner {
  _BlockPlanner({
    required this.block,
    required this.vocabulary,
  });

  final FiveThreeOneBlock block;
  final List<String> vocabulary;

  CoachResult<BlockOp> add(Object? raw, int index) {
    if (raw is! Map) {
      return CoachResult<BlockOp>.failed('ops[$index] must be an object.');
    }
    for (final key in raw.keys) {
      if (key is! String || !_opKeys.contains(key)) {
        return CoachResult<BlockOp>.failed(
          "ops[$index] does not take '$key'. The allowed keys are op, lift, "
          'value, cycle, supplemental, and exercise.',
        );
      }
    }

    final rawKind = raw['op'];
    final kind = rawKind is String ? blockOpKindOf(rawKind) : null;
    if (kind == null) {
      return CoachResult<BlockOp>.failed(
        'ops[$index].op must be one of $_opChoices.',
      );
    }
    final applicable = switch (kind) {
      BlockOpKind.correctTm => const <String>{'op', 'lift', 'value'},
      BlockOpKind.setSupplemental => const <String>{
          'op',
          'cycle',
          'supplemental',
        },
      BlockOpKind.createExercise => const <String>{'op', 'exercise'},
      _ => const <String>{'op'},
    };
    for (final key in raw.keys.cast<String>()) {
      if (!applicable.contains(key)) {
        return CoachResult<BlockOp>.failed(
          "ops[$index].${kind.wire} does not take '$key'. Remove it and retry.",
        );
      }
    }

    switch (kind) {
      case BlockOpKind.bumpTms:
        return const CoachResult<BlockOp>.ok(
          BlockOp(kind: BlockOpKind.bumpTms),
        );
      case BlockOpKind.unbumpTms:
        if (block.tmBumps == 0) {
          return const CoachResult<BlockOp>.failed(
            'This block has no TM bump to undo (tm_bumps is 0).',
          );
        }
        return const CoachResult<BlockOp>.ok(
          BlockOp(kind: BlockOpKind.unbumpTms),
        );
      case BlockOpKind.correctTm:
        return _correctTm(raw, index);
      case BlockOpKind.advanceWeek:
        if (block.currentCycle == cycleTmTest &&
            block.currentWeek >= cycleWeeks[cycleTmTest]) {
          return const CoachResult<BlockOp>.failed(
            'The block has finished the 7th Week TM Test; advancing would '
            'close it. Start a new block instead.',
          );
        }
        return const CoachResult<BlockOp>.ok(
          BlockOp(kind: BlockOpKind.advanceWeek),
        );
      case BlockOpKind.goBackWeek:
        if (block.currentCycle == 0 && block.currentWeek == 1) {
          return const CoachResult<BlockOp>.failed(
            'The block is already at its first week, so it cannot go back.',
          );
        }
        return const CoachResult<BlockOp>.ok(
          BlockOp(kind: BlockOpKind.goBackWeek),
        );
      case BlockOpKind.setSupplemental:
        return _setSupplemental(raw, index);
      case BlockOpKind.createExercise:
        return _createExercise(raw, index);
    }
  }

  CoachResult<BlockOp> _correctTm(Map raw, int index) {
    final lift = raw['lift'];
    if (lift is! String || !_liftKeys.contains(lift)) {
      return CoachResult<BlockOp>.failed(
        'ops[$index].lift must be one of squat, bench, deadlift, press.',
      );
    }
    final rawValue = raw['value'];
    if (rawValue is! num) {
      return CoachResult<BlockOp>.failed(
        'ops[$index].value must be a finite positive number.',
      );
    }
    final value = rawValue.toDouble();
    if (!value.isFinite || value <= 0) {
      return CoachResult<BlockOp>.failed(
        'ops[$index].value must be a finite positive number.',
      );
    }
    final max = block.unit == 'kg' ? 500 : 1100;
    if (value > max) {
      return CoachResult<BlockOp>.failed(
        'ops[$index].value must be no more than $max ${block.unit}.',
      );
    }
    final current = trainingMaxFor(block, lift);
    if ((current - value).abs() <= 0.05) {
      return CoachResult<BlockOp>.failed(
        '${_liftLabel(lift)} TM is already ${_number(current)} ${block.unit}; '
        'there is nothing to correct.',
      );
    }
    return CoachResult<BlockOp>.ok(
      BlockOp(kind: BlockOpKind.correctTm, lift: lift, value: value),
    );
  }

  CoachResult<BlockOp> _setSupplemental(Map raw, int index) {
    final cycle = raw['cycle'];
    if (cycle is! String || (cycle != 'leader' && cycle != 'anchor')) {
      return CoachResult<BlockOp>.failed(
        'ops[$index].cycle must be leader or anchor.',
      );
    }
    final supplemental = raw['supplemental'];
    if (supplemental is! String) {
      return CoachResult<BlockOp>.failed(
        'ops[$index].supplemental must be bbb or fsl.',
      );
    }
    if (supplemental != supplementalBbb && supplemental != supplementalFsl) {
      final closest = _looksHighVolume(supplemental) ? 'BBB' : 'FSL';
      return CoachResult<BlockOp>.failed(
        'This app can only represent the BBB and FSL supplementals; '
        "'$supplemental' is not available. The closest supported option is "
        '$closest.',
      );
    }
    if (cycle == 'anchor' &&
        !anchorSupplementalOptions.contains(supplemental)) {
      return const CoachResult<BlockOp>.failed(
        'Anchors run PR Sets, and FSL 5x5 is the only anchor supplemental '
        'this app can represent. The closest supported option is FSL.',
      );
    }
    final current =
        cycle == 'leader' ? block.leaderSupplemental : block.anchorSupplemental;
    if (current == supplemental) {
      return CoachResult<BlockOp>.failed(
        'The ${cycle == 'leader' ? 'Leader' : 'Anchor'} cycles already run '
        '${supplementalName(supplemental)}.',
      );
    }
    return CoachResult<BlockOp>.ok(
      BlockOp(
        kind: BlockOpKind.setSupplemental,
        cycle: cycle,
        supplemental: supplemental,
      ),
    );
  }

  CoachResult<BlockOp> _createExercise(Map raw, int index) {
    final rawExercise = raw['exercise'];
    if (rawExercise is! String || rawExercise.trim().isEmpty) {
      return CoachResult<BlockOp>.failed(
        'ops[$index].exercise must be a non-empty name.',
      );
    }
    final name = normalizeExerciseName(rawExercise).trim();
    final exists = vocabulary.any(
      (candidate) => candidate.trim().toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      return CoachResult<BlockOp>.failed(
        "'$name' already exists; use it directly with apply_session_changes "
        'instead of creating it.',
      );
    }
    return CoachResult<BlockOp>.ok(
      BlockOp(kind: BlockOpKind.createExercise, exercise: name),
    );
  }

  String? conflictError(List<BlockOp> ops) {
    final seenKinds = <BlockOpKind>{};
    final correctedLifts = <String>{};
    final supplementalCycles = <String>{};
    final exerciseNames = <String>{};
    for (final op in ops) {
      switch (op.kind) {
        case BlockOpKind.correctTm:
          if (!correctedLifts.add(op.lift!)) {
            return 'correct_tm appears twice for ${op.lift}; include one '
                'correction per lift.';
          }
        case BlockOpKind.setSupplemental:
          if (!supplementalCycles.add(op.cycle!)) {
            return 'set_supplemental appears twice for ${op.cycle}; include '
                'one change per cycle.';
          }
        case BlockOpKind.createExercise:
          if (!exerciseNames.add(op.exercise!.toLowerCase())) {
            return "create_exercise appears twice for '${op.exercise}'; "
                'include each new exercise once.';
          }
        default:
          if (!seenKinds.add(op.kind)) {
            return '${op.kind.wire} appears twice; include it only once.';
          }
      }
    }
    final kinds = ops.map((op) => op.kind).toSet();
    if (kinds.contains(BlockOpKind.bumpTms) &&
        kinds.contains(BlockOpKind.unbumpTms)) {
      return 'bump_tms and unbump_tms conflict; choose the direction the '
          'training maxes should move.';
    }
    if (kinds.contains(BlockOpKind.bumpTms) &&
        kinds.contains(BlockOpKind.correctTm)) {
      return 'bump_tms and correct_tm affect the same training maxes; decide '
          'whether this is a cycle bump or a correction.';
    }
    return null;
  }

  BlockProposal build(List<BlockOp> ops, String rationale) {
    var simulated = block;
    final proposesBump = ops.any((op) => op.kind == BlockOpKind.bumpTms);
    final changes = <BlockChange>[];
    for (final op in ops) {
      switch (op.kind) {
        case BlockOpKind.bumpTms:
          final next = _shifted(simulated, 1);
          changes.addAll(_tmChanges(simulated, next, 'counts as a cycle bump'));
          simulated = next;
        case BlockOpKind.unbumpTms:
          final next = _shifted(simulated, -1);
          changes.addAll(
            _tmChanges(simulated, next, 'decrements the bump counter'),
          );
          simulated = next;
        case BlockOpKind.correctTm:
          final before = trainingMaxFor(simulated, op.lift!);
          changes.add(
            BlockChange(
              label: '${_liftLabel(op.lift!)} TM',
              before: _weight(before, simulated.unit),
              after: _weight(op.value!, simulated.unit),
              detail: 'does not count as a cycle bump',
            ),
          );
          simulated = _corrected(simulated, op.lift!, op.value!);
        case BlockOpKind.advanceWeek:
          final next = _advanced(simulated);
          changes.add(
            BlockChange(
              label: 'Cycle position',
              before: _position(simulated),
              after: _position(next),
              // The block UI offers the TM bump when the last week of a
              // bumping cycle is completed. Advancing through the coach
              // bypasses that dialog, so the card has to say so out loud
              // rather than leaving tm_bumps quietly one short.
              detail: _endsBumpingCycle(simulated) && !proposesBump
                  ? 'advances the block by one week — this finishes a bumping '
                      'cycle without applying the TM bump; add bump_tms if the '
                      'cycle is done'
                  : 'advances the block by one week',
            ),
          );
          simulated = next;
        case BlockOpKind.goBackWeek:
          final next = _back(simulated);
          changes.add(
            BlockChange(
              label: 'Cycle position',
              before: _position(simulated),
              after: _position(next),
              detail: 'moves the block back by one week',
            ),
          );
          simulated = next;
        case BlockOpKind.setSupplemental:
          final before = op.cycle == 'leader'
              ? simulated.leaderSupplemental
              : simulated.anchorSupplemental;
          changes.add(
            BlockChange(
              label: op.cycle == 'leader'
                  ? 'Leader supplemental'
                  : 'Anchor supplemental',
              before: supplementalName(before),
              after: supplementalName(op.supplemental),
              detail: 'changes the ${op.cycle} supplemental template',
            ),
          );
          simulated = simulated.copyWith(
            leaderSupplemental: op.cycle == 'leader'
                ? op.supplemental
                : simulated.leaderSupplemental,
            anchorSupplemental: op.cycle == 'anchor'
                ? op.supplemental
                : simulated.anchorSupplemental,
          );
        case BlockOpKind.createExercise:
          changes.add(
            BlockChange(
              label: 'New exercise',
              before: null,
              after: op.exercise,
              detail: 'creates a new exercise — its history starts fresh',
            ),
          );
      }
    }

    final kinds = ops.map((op) => op.kind).toSet();
    final before = block.tmBumps;
    final after = simulated.tmBumps;
    final semantics = kinds.contains(BlockOpKind.bumpTms)
        ? "Counts as a cycle bump: the block's bump counter goes from $before "
            'to $after.'
        : kinds.contains(BlockOpKind.unbumpTms)
            ? "Undoes a cycle bump: the block's bump counter goes from $before "
                'to $after.'
            : kinds.contains(BlockOpKind.correctTm)
                ? 'Does not count as a cycle bump: the bump counter stays at '
                    '$before.'
                : 'Training maxes and the bump counter are unchanged.';
    return BlockProposal(
      ops: List<BlockOp>.unmodifiable(ops),
      rationale: rationale,
      changes: List<BlockChange>.unmodifiable(changes),
      bumpSemantics: semantics,
      tmBumpsBefore: before,
      tmBumpsAfter: after,
    );
  }
}

FiveThreeOneBlock _shifted(FiveThreeOneBlock block, int direction) {
  double shift(double tm, double by) =>
      double.parse((tm + by * direction).toStringAsFixed(1));
  return block.copyWith(
    squatTm: shift(block.squatTm, tmBumpLower),
    benchTm: shift(block.benchTm, tmBumpUpper),
    deadliftTm: shift(block.deadliftTm, tmBumpLower),
    pressTm: shift(block.pressTm, tmBumpUpper),
    tmBumps: block.tmBumps + direction,
  );
}

FiveThreeOneBlock _corrected(
  FiveThreeOneBlock block,
  String lift,
  double value,
) =>
    switch (lift) {
      'squat' => block.copyWith(squatTm: value),
      'bench' => block.copyWith(benchTm: value),
      'deadlift' => block.copyWith(deadliftTm: value),
      'press' => block.copyWith(pressTm: value),
      _ => block,
    };

FiveThreeOneBlock _advanced(FiveThreeOneBlock block) {
  if (block.currentWeek < cycleWeeks[block.currentCycle]) {
    return block.copyWith(currentWeek: block.currentWeek + 1);
  }
  return block.copyWith(
    currentCycle: block.currentCycle + 1,
    currentWeek: 1,
  );
}

FiveThreeOneBlock _back(FiveThreeOneBlock block) {
  if (block.currentWeek > 1) {
    return block.copyWith(currentWeek: block.currentWeek - 1);
  }
  final previousCycle = block.currentCycle - 1;
  return block.copyWith(
    currentCycle: previousCycle,
    currentWeek: cycleWeeks[previousCycle],
  );
}

List<BlockChange> _tmChanges(
  FiveThreeOneBlock before,
  FiveThreeOneBlock after,
  String detail,
) =>
    <BlockChange>[
      for (final entry in <(String, double, double)>[
        ('Squat TM', before.squatTm, after.squatTm),
        ('Bench TM', before.benchTm, after.benchTm),
        ('Deadlift TM', before.deadliftTm, after.deadliftTm),
        ('Press TM', before.pressTm, after.pressTm),
      ])
        BlockChange(
          label: entry.$1,
          before: _weight(entry.$2, before.unit),
          after: _weight(entry.$3, before.unit),
          detail: detail,
        ),
    ];

/// Mirrors `FiveThreeOneState.needsTmBump`: the block sits on the last week of
/// a cycle that bumps training maxes when it completes.
bool _endsBumpingCycle(FiveThreeOneBlock block) =>
    block.currentWeek >= cycleWeeks[block.currentCycle] &&
    cycleBumpsTm[block.currentCycle];

String _position(FiveThreeOneBlock block) => cyclePositionLabel(
      block.currentCycle,
      block.currentWeek,
      block.supplementals,
    );

String _weight(double value, String unit) => '${_number(value)} $unit';

String _number(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

String _liftLabel(String lift) => switch (lift) {
      'squat' => 'Squat',
      'bench' => 'Bench',
      'deadlift' => 'Deadlift',
      'press' => 'Press',
      _ => lift,
    };

bool _looksHighVolume(String value) {
  final lower = value.toLowerCase();
  return lower.contains('volume') ||
      lower.contains('hypertrophy') ||
      lower.contains('5x10') ||
      lower.contains('widowmaker');
}
