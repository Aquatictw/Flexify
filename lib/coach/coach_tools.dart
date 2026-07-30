import 'block_tools.dart';
import 'read_tools.dart';

const String applySessionChangesTool = 'apply_session_changes';

Map<String, Object?> _weightProperties(bool trainingMaxBasis) =>
    <String, Object?>{
      if (trainingMaxBasis)
        'pct_of_tm': <String, Object?>{
          'type': 'number',
          'description':
              'Set a fraction of the training max: 0.9 means 90%, 0.6 means 60%. '
                  'Use only for work the snapshot prescription does not cover.',
        },
      'pct_of_prescribed': <String, Object?>{
        'type': 'number',
        'description':
            'Set a signed delta, as a fraction, from the prescribed weight for '
                'that set: 0 means exactly as prescribed, -0.05 means 5% '
                'lighter, 0.1 means 10% heavier. Never percentage points; -5 '
                'would mean 500% lighter. Prefer this whenever the snapshot '
                'prescription lists the lift.',
      },
      'pct_of_last_session': <String, Object?>{
        'type': 'number',
        'description':
            'Set a signed delta, as a fraction, from the matching set last '
                'session: 0 means the same weight, 0.05 means 5% heavier, '
                '-0.05 means 5% lighter. Never percentage points.',
      },
      'absolute': <String, Object?>{
        'type': 'number',
        'description':
            'Set a literal weight only when the user states the number.',
      },
    };

Map<String, Object?> _weightSpec(bool trainingMaxBasis) => <String, Object?>{
      'type': 'object',
      'description':
          'Set exactly one weight basis. Every pct_ value is a fraction, not '
              'percentage points. Never include a unit; the app infers it.',
      'additionalProperties': false,
      'properties': _weightProperties(trainingMaxBasis),
      'oneOf': <Object?>[
        if (trainingMaxBasis)
          <String, Object?>{
            'required': <String>['pct_of_tm'],
            'properties': _weightProperties(trainingMaxBasis),
          },
        <String, Object?>{
          'required': <String>['pct_of_prescribed'],
          'properties': _weightProperties(trainingMaxBasis),
        },
        <String, Object?>{
          'required': <String>['pct_of_last_session'],
          'properties': _weightProperties(trainingMaxBasis),
        },
        <String, Object?>{
          'required': <String>['absolute'],
          'properties': _weightProperties(trainingMaxBasis),
        },
      ],
    };

Map<String, Object?> _setSpec(bool trainingMaxBasis) => <String, Object?>{
      'type': 'object',
      'description': 'Describe one prescribed set without a unit.',
      'additionalProperties': false,
      'required': <String>['weight_spec', 'reps'],
      'properties': <String, Object?>{
        'weight_spec': _weightSpec(trainingMaxBasis),
        'reps': <String, Object?>{
          'type': 'integer',
          'description': 'Set the prescribed repetition count.',
        },
        'amrap': <String, Object?>{
          'type': 'boolean',
          'description': 'Mark the set as as-many-reps-as-possible.',
          'default': false,
        },
      },
    };

Map<String, Object?> _sessionOp(bool trainingMaxBasis) => <String, Object?>{
      'type': 'object',
      'description':
          'Apply one change to prescribed, unperformed session work.',
      'additionalProperties': false,
      'required': <String>['op', 'exercise'],
      'properties': <String, Object?>{
        'op': <String, Object?>{
          'type': 'string',
          'description': 'Choose the operation discriminator.',
          'enum': <String>[
            'add_exercise',
            'add_sets',
            'edit_set',
            'remove_sets',
          ],
        },
        'exercise': <String, Object?>{
          'type': 'string',
          'description': 'Use an exact name from exerciseVocabulary.',
        },
        'sets': <String, Object?>{
          'type': 'array',
          'description': 'Supply sets for add_exercise or add_sets.',
          'minItems': 1,
          'items': _setSpec(trainingMaxBasis),
        },
        'set_index': <String, Object?>{
          'type': 'integer',
          'minimum': 0,
          'description':
              'Select a 0-based set index within this workout exercise for edit_set.',
        },
        'set_indices': <String, Object?>{
          'type': 'array',
          'description': 'Select 0-based set indices to remove.',
          'minItems': 1,
          'items': <String, Object?>{
            'type': 'integer',
            'minimum': 0,
            'description': 'Select a 0-based set index.',
          },
        },
        'weight_spec': _weightSpec(trainingMaxBasis),
        'reps': <String, Object?>{
          'type': 'integer',
          'description': 'Replace the repetition count for edit_set.',
        },
        'create_new': <String, Object?>{
          'type': 'boolean',
          'description':
              'Set true only for a genuinely new exercise outside the vocabulary.',
          'default': false,
        },
      },
      'allOf': <Object?>[
        <String, Object?>{
          'if': <String, Object?>{
            'properties': <String, Object?>{
              'op': <String, Object?>{'const': 'add_exercise'},
            },
          },
          'then': <String, Object?>{
            'required': <String>['sets'],
          },
        },
        <String, Object?>{
          'if': <String, Object?>{
            'properties': <String, Object?>{
              'op': <String, Object?>{'const': 'add_sets'},
            },
          },
          'then': <String, Object?>{
            'required': <String>['sets'],
          },
        },
        <String, Object?>{
          'if': <String, Object?>{
            'properties': <String, Object?>{
              'op': <String, Object?>{'const': 'edit_set'},
            },
          },
          'then': <String, Object?>{
            'required': <String>['set_index'],
          },
        },
        <String, Object?>{
          'if': <String, Object?>{
            'properties': <String, Object?>{
              'op': <String, Object?>{'const': 'remove_sets'},
            },
          },
          'then': <String, Object?>{
            'required': <String>['set_indices'],
          },
        },
      ],
    };

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

/// Assembles the tool set for one turn, tier by tier (PRD decision 2: the tool
/// boundary is the authority boundary).
///
/// - Auto-apply session writes exist only while a workout is active.
/// - The confirm-tier block tool exists only while a block is active; without
///   one there is no training max, cycle position, or supplemental to change.
/// - Read tools are unconditional. They mutate nothing, so they carry no
///   authority tier and stay answerable with neither a workout nor a block.
List<Map<String, Object?>> coachTools({
  required bool sessionWrites,
  required bool trainingMaxBasis,
}) =>
    <Map<String, Object?>>[
      if (sessionWrites)
        _tool(
          applySessionChangesTool,
          'Auto-apply changes confined to prescribed, not-yet-performed sets '
          'in the current workout. Never carry units or bare weights.',
          <String, Object?>{
            'type': 'object',
            'additionalProperties': false,
            'required': <String>['ops'],
            'properties': <String, Object?>{
              'ops': <String, Object?>{
                'type': 'array',
                'description': 'Apply one or more current-session operations.',
                'minItems': 1,
                'items': _sessionOp(trainingMaxBasis),
              },
            },
          },
        ),
      if (trainingMaxBasis) proposeBlockChangesToolSchema(),
      ...readTools(),
    ];
