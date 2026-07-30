import 'dart:io';

import 'package:jackedlog/fivethreeone/schemes.dart';

const _systemPreamble = '''
# About this knowledge

This is an original, manually reviewed distillation of *5/3/1 Forever*. It keeps
the program's actionable doctrine, templates, assistance guidance,
conditioning, and recovery rules while removing anecdotes, repetition, and
OCR-damaged text.

# Source hierarchy

For anything the app can execute, `CURRENT_STATE` and `percentages.md` are
authoritative. They are computed from JackedLog's tested program code. If a
template card conflicts with either one, follow `CURRENT_STATE` and
`percentages.md`.

Template cards may contain exact book prescriptions for explaining templates
that JackedLog cannot configure. Discuss those prescriptions, but never write
them into a block unless `capabilities.md` says the template is supported.
Never guess a missing percentage, set, rep, or schedule.''';

const _requiredSections = <String>[
  '# Core doctrine',
  '# Assistance work',
  '# Template reference',
  '# Conditioning',
  '# Recovery',
];

const _requiredTemplateTopics = <String>[
  'Beginner Prep School',
  'Boring But Big (BBB)',
  'First Set Last (FSL) family',
  'Full Body, 1000% Awesome',
  'SVR II',
  'The Morning Star',
  'Volume and Strength',
  '5×5/3/1 family',
  'Five and Dime',
  'Simplest Strength Template (SST)',
  'God Is a Beast',
  'Full Body, Four Days',
  'Black Army Jacket',
  'Spinal Tap variants',
  'Coffinworm',
  'Second Set Last (SSL)',
  'Full Body, 85%',
  'Boring But Strong (BBS)',
  'Supplemental Heaven',
  'Full Body: Squat, Push, Pull',
  'Pervertor',
  'Original 5/3/1',
  'Original 5/3/1 and First Set Last',
  '5/3/1 Prowler Challenge',
  'Original 5/3/1 Challenge',
  'Combination Template',
  'Limited Time',
  'Bodybuild the Upper / Athlete the Lower',
  'Strength and Conditioning',
  'Wendler Classic and WaLRUS',
  'Leviathan',
  'Con Clavi Con Dio',
  'Prep and Fat Loss Training',
  '5/3/1 Strength Circuits',
  "5's PRO Forever",
  'Titanium Knickknack Challenge',
  'Widowmaker Circuit',
  'Ceremony of Opposites',
  '2×2×2',
  'Krypteia',
];

const _forbiddenOcrFragments = <String>[
  '"/o',
  '"lo',
  '"Io',
  '°/o',
  '°lo',
  'WBBK',
  'WBEK',
  'WIBK',
  'PBIDAY',
  'MONDA:',
  'WBDNISDAY',
  'THUlSD',
  'MDRDAY',
  'PIIDAY',
  'J)eodliff',
  'J)eadliff',
  'S�uof',
  'Spi,,al',
  'Mobilify',
  '�',
];

Future<void> main(List<String> arguments) async {
  final scriptDirectory = File.fromUri(Platform.script).parent;
  final packageRoot = scriptDirectory.parent.parent;

  String? pdfArgument;
  String? sourceArgument;
  String? outArgument;
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument != '--pdf' && argument != '--source' && argument != '--out') {
      _fail('Unknown argument: $argument');
    }
    if (index + 1 >= arguments.length) {
      _fail('Missing value for $argument');
    }
    final value = arguments[++index];
    switch (argument) {
      case '--pdf':
        pdfArgument = value;
      case '--source':
        sourceArgument = value;
      case '--out':
        outArgument = value;
    }
  }

  // Keep --pdf as a provenance check and for compatibility with the previous
  // build command. The PDF is no longer OCR'd during every build: its reviewed
  // facts live in the tracked, byte-stable curated source.
  final pdf = _resolveFile(pdfArgument ?? '531forever.pdf', packageRoot);
  final source = _resolveFile(
    sourceArgument ?? 'tools/knowledge/curated_knowledge.md',
    packageRoot,
  );
  final home = Platform.environment['HOME'];
  if (outArgument == null && (home == null || home.isEmpty)) {
    _fail('HOME is not set; pass --out <dir>.');
  }
  final out = outArgument == null
      ? Directory('$home/.jackedlog/knowledge')
      : _resolveDirectory(outArgument, packageRoot);

  if (!await pdf.exists()) {
    _fail('Source PDF not found: ${pdf.path}');
  }
  if (!await source.exists()) {
    _fail('Curated knowledge source not found: ${source.path}');
  }

  final curated = await source.readAsString();
  _validateCuratedKnowledge(curated);

  final documents = <(String, String)>[
    ('system.md', _buildSystem(curated)),
    ('percentages.md', _buildPercentages()),
    ('capabilities.md', _buildCapabilities()),
  ];

  await out.create(recursive: true);
  var totalCharacters = 0;
  for (final (name, content) in documents) {
    await File(
      '${out.path}${Platform.pathSeparator}$name',
    ).writeAsString(content, flush: true);
    totalCharacters += content.length;
    stdout.writeln(
      '$name: ${content.length} chars, ${content.length ~/ 4} estimated tokens',
    );
  }
  stdout.writeln(
    'Total: $totalCharacters chars, '
    '${totalCharacters ~/ 4} estimated tokens',
  );
}

Never _fail(String message) {
  stderr.writeln('Error: $message');
  exit(1);
}

File _resolveFile(String path, Directory packageRoot) {
  final file = File(path);
  return file.isAbsolute ? file : File('${packageRoot.path}/$path');
}

Directory _resolveDirectory(String path, Directory packageRoot) {
  final directory = Directory(path);
  return directory.isAbsolute
      ? directory
      : Directory('${packageRoot.path}/$path');
}

void _validateCuratedKnowledge(String source) {
  if (source.trim().isEmpty) {
    _fail('Curated knowledge source is empty.');
  }
  for (final section in _requiredSections) {
    if (!source.contains(section)) {
      _fail('Curated knowledge is missing required section: $section');
    }
  }
  for (final topic in _requiredTemplateTopics) {
    if (!source.contains('## $topic')) {
      _fail('Curated knowledge is missing template topic: $topic');
    }
  }
  for (final fragment in _forbiddenOcrFragments) {
    if (source.contains(fragment)) {
      _fail('Curated knowledge contains OCR fragment: $fragment');
    }
  }
}

String _buildSystem(String curated) =>
    '$_systemPreamble\n\n${curated.trim()}\n';

String _formatPercentage(double percentage) {
  final value = percentage * 100;
  final rounded = value.round();
  if ((value - rounded).abs() < 0.000000001) {
    return '$rounded%';
  }
  return '${value.toStringAsFixed(1)}%';
}

String _renderScheme(List<SetScheme> scheme) => scheme
    .map(
      (set) => '${_formatPercentage(set.percentage)} x ${set.reps}'
          '${set.amrap ? '+' : ''}',
    )
    .join(', ');

String _buildPercentages() {
  final output = StringBuffer()
    ..writeln('# Trusted app percentages and prescriptions')
    ..writeln()
    ..writeln(
      'This file is the authoritative source for work JackedLog can execute. '
      'It is generated from `lib/fivethreeone/schemes.dart`.',
    )
    ..writeln()
    ..writeln('All percentages are percentages of the TRAINING MAX.')
    ..writeln()
    ..writeln('## Fixed block structure')
    ..writeln();

  for (var cycle = 0; cycle < cycleNames.length; cycle++) {
    output.writeln(
      'Cycle $cycle: ${cycleNames[cycle]}; ${cycleWeeks[cycle]} '
      '${cycleWeeks[cycle] == 1 ? 'week' : 'weeks'}; TM '
      '${cycleBumpsTm[cycle] ? 'bumps after this cycle' : 'does not bump after this cycle'}.',
    );
  }
  output
    ..writeln()
    ..writeln('Total block weeks: $totalBlockWeeks.')
    ..writeln()
    ..writeln('## Main work')
    ..writeln();

  for (var cycle = 0; cycle < cycleNames.length; cycle++) {
    output
      ..writeln(
        '### Cycle $cycle — ${cycleNames[cycle]} '
        '(${getMainSchemeName(cycle)})',
      )
      ..writeln();
    for (var week = 1; week <= cycleWeeks[cycle]; week++) {
      output.writeln(
        'Week $week: '
        '${_renderScheme(getMainScheme(cycleType: cycle, week: week))}',
      );
    }
    output.writeln();
  }

  output
    ..writeln('## Supplemental schemes')
    ..writeln()
    ..writeln(
      '${supplementalName(supplementalBbb)}: ${_renderScheme(bbbScheme)}',
    )
    ..writeln(
      'Compact: ${supplementalName(supplementalBbb)} — '
      '${supplementalDetail(supplementalBbb)}.',
    )
    ..writeln();
  for (var week = 1; week <= 3; week++) {
    output.writeln(
      '${supplementalName(supplementalFsl)} week $week: '
      '${_renderScheme(getFslScheme(week: week))}',
    );
  }
  output
    ..writeln(
      'Compact: ${supplementalName(supplementalFsl)} — '
      '${supplementalDetail(supplementalFsl)}.',
    )
    ..writeln()
    ..writeln('## Supplemental selection by cycle')
    ..writeln();

  for (final leader in leaderSupplementalOptions) {
    for (final anchor in anchorSupplementalOptions) {
      final selection = (leader: leader, anchor: anchor);
      output
        ..writeln(
          'Leader selection ${supplementalName(leader)}; '
          'Anchor selection ${supplementalName(anchor)}:',
        )
        ..writeln();
      for (var cycle = 0; cycle < cycleNames.length; cycle++) {
        final supplemental = supplementalForCycle(cycle, selection);
        output.writeln(
          '- Cycle $cycle (${cycleNames[cycle]}): '
          '${supplemental == null ? 'none' : supplementalName(supplemental)}',
        );
      }
      output.writeln();
    }
  }

  output
    ..writeln('## Training Max bump steps')
    ..writeln()
    ..writeln(
      "Lower-body lifts: $tmBumpLower in the block's configured unit.",
    )
    ..writeln(
      "Upper-body lifts: $tmBumpUpper in the block's configured unit.",
    )
    ..writeln(
      'Bumps apply only after cycles where `cycleBumpsTm` is true.',
    );

  return output.toString();
}

String _buildCapabilities() {
  final supportedSupplementals = <String>[
    ...leaderSupplementalOptions,
    ...anchorSupplementalOptions.where(
      (option) => !leaderSupplementalOptions.contains(option),
    ),
  ];
  final output = StringBuffer()
    ..writeln('# App block capabilities')
    ..writeln()
    ..writeln('## Fixed cycle sequence')
    ..writeln();

  for (var cycle = 0; cycle < cycleNames.length; cycle++) {
    output.writeln(
      '${cycle + 1}. ${cycleNames[cycle]} — ${cycleWeeks[cycle]} '
      '${cycleWeeks[cycle] == 1 ? 'week' : 'weeks'} — '
      '${getMainSchemeName(cycle)} main work.',
    );
  }
  output
    ..writeln()
    ..writeln(
      'These five cycle types total $totalBlockWeeks weeks. Their order is '
      'fixed and is not reorderable.',
    )
    ..writeln()
    ..writeln('## Supplemental templates')
    ..writeln()
    ..writeln(
      'Exactly ${supportedSupplementals.length} supplemental templates exist:',
    );
  for (final supplemental in supportedSupplementals) {
    output.writeln(
      '- `$supplemental`: ${supplementalName(supplemental)} — '
      '${supplementalDetail(supplemental)}',
    );
  }
  output
    ..writeln()
    ..writeln(
      'Leader cycles may use: '
      '${leaderSupplementalOptions.map((value) => '`$value`').join(', ')}.',
    )
    ..writeln(
      'The Anchor cycle may use: '
      '${anchorSupplementalOptions.map((value) => '`$value`').join(', ')} '
      '(currently FSL only).',
    )
    ..writeln()
    ..writeln(
      'Any other template from the book (BBS, SSL, Widowmaker, Krypteia, '
      'etc.) may be DISCUSSED but cannot be configured as a block in this app. '
      'Offer the closest supported alternative instead.',
    );

  return output.toString();
}
