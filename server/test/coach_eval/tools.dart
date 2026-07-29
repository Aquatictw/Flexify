const List<String> allToolNames = <String>[
  'apply_session_changes',
  'propose_block_changes',
  'get_exercise_history',
  'get_records',
  'get_block_history',
];

Map<String, Object?> _weightProperties() => <String, Object?>{
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

Map<String, Object?> _weightSpec() => <String, Object?>{
      'type': 'object',
      'description':
          'Set exactly one weight basis. Every pct_ value is a fraction, not '
              'percentage points. Never include a unit; the app infers it.',
      'additionalProperties': false,
      'properties': _weightProperties(),
      'oneOf': <Object?>[
        <String, Object?>{
          'required': <String>['pct_of_tm'],
          'properties': _weightProperties(),
        },
        <String, Object?>{
          'required': <String>['pct_of_prescribed'],
          'properties': _weightProperties(),
        },
        <String, Object?>{
          'required': <String>['pct_of_last_session'],
          'properties': _weightProperties(),
        },
        <String, Object?>{
          'required': <String>['absolute'],
          'properties': _weightProperties(),
        },
      ],
    };

Map<String, Object?> _setSpec() => <String, Object?>{
      'type': 'object',
      'description': 'Describe one prescribed set without a unit.',
      'additionalProperties': false,
      'required': <String>['weight_spec', 'reps'],
      'properties': <String, Object?>{
        'weight_spec': _weightSpec(),
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

Map<String, Object?> _sessionOp() => <String, Object?>{
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
          'items': _setSpec(),
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
        'weight_spec': _weightSpec(),
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

Map<String, Object?> _blockOp() => <String, Object?>{
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

List<Map<String, Object?>> coachTools({
  required bool sessionWrites,
  required bool blockWrites,
}) {
  return <Map<String, Object?>>[
    if (sessionWrites)
      _tool(
        'apply_session_changes',
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
              'items': _sessionOp(),
            },
          },
        },
      ),
    if (blockWrites)
      _tool(
        'propose_block_changes',
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
              'items': _blockOp(),
            },
            'rationale': <String, Object?>{
              'type': 'string',
              'description': 'Give one sentence of 5/3/1 doctrine.',
            },
          },
        },
      ),
    _tool(
      'get_exercise_history',
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
      'get_records',
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
      'get_block_history',
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
}
