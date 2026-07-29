import 'dart:convert';
import 'dart:io';

import 'package:jackedlog/fivethreeone/schemes.dart';

const chapters = <(int, String)>[
  (14, 'Principles of the 5/3/1 Program'),
  (19, 'Warm-Up, Mobility and Flexibility'),
  (21, 'Jumps and Throws'),
  (27, 'Strength: Main and Supplemental Lifts'),
  (29, 'Programming Your Training'),
  (31, 'The Deload / 7th Week Protocol'),
  (36, 'Assistance Work'),
  (48, 'In the Beginning'),
  (50, 'Beginner Prep School'),
  (57, 'Boring But Big'),
  (71, 'First Set Last'),
  (87, '100% Awesome (Anchor)'),
  (89, 'S.V.R. II'),
  (93, 'The Morning Star'),
  (97, 'Volume and Strength'),
  (99, '5x5/3/1'),
  (109, "Portal's 5x5/3/1"),
  (113, 'Five and Dime'),
  (117, 'Simplest Strength Template'),
  (119, 'God Is a Beast'),
  (125, 'Full Body, Four Days'),
  (127, 'Black Army Jacket'),
  (131, "Spinal Tap, 5's PRO"),
  (135, 'Spinal Tap, H.S.'),
  (137, 'Coffin Worm'),
  (141, 'Second Set Last'),
  (143, 'Full Body, 85%'),
  (147, 'Boring But Strong'),
  (155, 'Supplemental Heaven'),
  (157, 'Full Body: Squat, Push, Pull'),
  (171, 'Pervertor'),
  (176, 'Original 5/3/1'),
  (183, '5/3/1 Prowler Challenge'),
  (185, 'Original 5/3/1 Challenge'),
  (189, 'Combination Template'),
  (193, 'Limited Time'),
  (197, 'Bodybuild the Upper / Athlete the Lower'),
  (199, 'Strength and Conditioning'),
  (204, 'The Wendler Classic'),
  (211, 'Leviathan'),
  (213, 'Conclavi Condio'),
  (217, 'Prep and Fat Loss Training'),
  (223, '5/3/1 Strength Circuits'),
  (230, "5's PRO Forever"),
  (236, 'Widowmaker Circuit'),
  (241, 'Ceremony of Opposites'),
  (243, '2x2x2'),
  (245, 'The Krypteia'),
  (256, 'Conditioning'),
  (259, 'The Prowler'),
  (261, 'Hills, Stairs and Everything Else'),
  (263, "Runnin' With the Devil"),
  (265, 'Easy Conditioning'),
  (267, 'Recovery'),
  (281, 'Active Recovery for the Older Athlete'),
];

const parts = <(int, String)>[
  (14, 'Part 1 — Principles and Programming'),
  (48, 'Part 2 — Templates'),
  (256, 'Part 3 — Conditioning and Recovery'),
];

final dropPages = <int>{
  ...List.generate(13, (index) => index + 1),
  ...List.generate(6, (index) => index + 21).where(
    (page) => page != 22 && page != 23,
  ),
  ...List.generate(9, (index) => index + 36),
  46,
  47,
  ...List.generate(7, (index) => index + 50),
  135,
  136,
  254,
  255,
};

final garbage = RegExp(
  [
    '"/o',
    '"lo',
    '"Io',
    '°/o',
    '°lo',
    'C/O"',
    r'\d\s*[xX]\s*\d\s*(reps|sets|@|$)',
    r'@\s*\d+\s*"',
    r"S'\w",
    '&nch',
    r'&r\b',
    r'J\)',
    '1t1',
    ',,,',
    'fofa',
    'fufa',
    'rofa',
    r'\bsefs?\b',
    r'\bsef\)',
    'Witiow',
    'Wif/ow',
    'Widowwi',
    'llssis',
    '1-ofo',
    'Mobilify',
    'Wei[59g]h[tf]ed',
    'Chi,,',
    'Chi11',
    'Oii,,',
    'Oii11',
    'W[ao]r1t',
    'Ju,,,ps',
    'JuMps',
    'Jumps!',
    'Ju,,,ps!',
    'J3J3',
    '5JC',
    r'x\.S/',
    'Assisf',
    r'\bfo/',
    r'liff\b',
    'Squof',
    'Squaf',
    r'\bReps?\s*$',
  ].join('|'),
);

final cell = RegExp(
  [
    '"/o',
    '"lo',
    '"Io',
    '°/o',
    '°lo',
    '%',
    r'\d\s*[xX]\s*\d',
    r'\bx\s*\d',
    r'@\s*\d',
    r'\bsets? of\b',
    r'\breps\b',
  ].join('|'),
);

const days = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

final weeks = <String>[
  ...[
    'ONE',
    'TWO',
    'THREE',
    'FOUR',
    'FIVE',
    'SIX',
    'SEVEN',
    'EIGHT',
    'NINE',
    'TEN',
  ].map((word) => 'WEEK$word'),
  ...['ONE', 'TWO', 'THREE'].map((word) => 'CYCLE$word'),
  ...List.generate(12, (index) => 'WEEK${index + 1}'),
];

/// pdftotext glues the first cell of a following table onto the last line of a
/// paragraph, e.g. `... which one you choose to do. WBBK ON I`. Those cells are
/// always an all-caps run after sentence punctuation, and the OCR mangles them
/// too badly for the fuzzy day/week matcher to recognise. Strip the run, unless
/// it ends in a full stop (which makes it a real emphatic sentence, `NO MORE.`).
final trailingTableCells = RegExp(
  r'''([.:;!?])((?:\s+[A-Z0-9][A-Z0-9'".\-]{0,7}){2,5})\s*$''',
);

String _stripTrailingTableCells(String text) {
  final match = trailingTableCells.firstMatch(text);
  if (match == null || match.group(2)!.endsWith('.')) {
    return text;
  }
  return text.substring(0, match.start) + match.group(1)!;
}

const systemPreamble = '''
# About this knowledge

This is prose extracted from *5/3/1 Forever* by Jim Wendler.
All numeric set tables were removed on purpose because the scan's OCR corrupts them.
Every percentage, rep count, and weight must come from `percentages.md` instead.
''';

Future<void> main(List<String> arguments) async {
  final scriptDirectory = File.fromUri(Platform.script).parent;
  final packageRoot = scriptDirectory.parent.parent;

  String? pdfArgument;
  String? outArgument;
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument != '--pdf' && argument != '--out') {
      _fail('Unknown argument: $argument');
    }
    if (index + 1 >= arguments.length) {
      _fail('Missing value for $argument');
    }
    final value = arguments[++index];
    if (argument == '--pdf') {
      pdfArgument = value;
    } else {
      outArgument = value;
    }
  }

  final pdf = _resolvePath(pdfArgument ?? '531forever.pdf', packageRoot);
  final home = Platform.environment['HOME'];
  if (outArgument == null && (home == null || home.isEmpty)) {
    _fail('HOME is not set; pass --out <dir>.');
  }
  final out = outArgument == null
      ? Directory('$home/.jackedlog/knowledge')
      : _resolveDirectory(outArgument, packageRoot);

  if (!await pdf.exists()) {
    _fail('PDF not found: ${pdf.path}');
  }

  late final String raw;
  try {
    raw = await _extractPdf(pdf);
  } on _BuildFailure catch (error) {
    _fail(error.message);
  }

  final documents = <(String, String)>[
    ('system.md', _buildSystem(raw)),
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

final class _BuildFailure implements Exception {
  const _BuildFailure(this.message);

  final String message;
}

Never _fail(String message) {
  stderr.writeln('Error: $message');
  exit(1);
}

Future<String> _extractPdf(File pdf) async {
  final temporaryDirectory = await Directory.systemTemp.createTemp(
    'jackedlog-knowledge-',
  );
  try {
    final extractedText = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}book.pdftotext.txt',
    );
    ProcessResult result;
    try {
      result = await Process.run('pdftotext', [pdf.path, extractedText.path]);
    } on ProcessException catch (error) {
      throw _BuildFailure(
        'Could not run pdftotext. Make sure it is installed and on PATH: '
        '${error.message}',
      );
    }
    if (result.exitCode != 0) {
      final detail = result.stderr.toString().trim();
      throw _BuildFailure(
        'pdftotext failed with exit code ${result.exitCode}'
        '${detail.isEmpty ? '.' : ': $detail'}',
      );
    }
    return utf8.decode(
      await extractedText.readAsBytes(),
      allowMalformed: true,
    );
  } finally {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  }
}

File _resolvePath(String path, Directory packageRoot) {
  final file = File(path);
  return file.isAbsolute ? file : File('${packageRoot.path}/$path');
}

Directory _resolveDirectory(String path, Directory packageRoot) {
  final directory = Directory(path);
  return directory.isAbsolute
      ? directory
      : Directory('${packageRoot.path}/$path');
}

int _levenshtein(String a, String b) {
  final previousRow = List.generate(b.length + 1, (index) => index);
  for (var i = 1; i <= a.length; i++) {
    var previous = previousRow[0];
    previousRow[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final current = previousRow[j];
      previousRow[j] = [
        previousRow[j] + 1,
        previousRow[j - 1] + 1,
        previous + (a[i - 1] == b[j - 1] ? 0 : 1),
      ].reduce((left, right) => left < right ? left : right);
      previous = current;
    }
  }
  return previousRow[b.length];
}

bool _isDayOrWeek(String value) {
  final normalized = value.replaceAll(RegExp('[^A-Za-z]'), '').toUpperCase();
  if (normalized.isEmpty || normalized.length > 14) {
    return false;
  }
  for (final word in [...days, ...weeks]) {
    if ((normalized.length - word.length).abs() <= 2 &&
        _levenshtein(normalized, word) <=
            (word.length ~/ 3 < 1 ? 1 : word.length ~/ 3)) {
      return true;
    }
  }
  return false;
}

bool _isHeaderLine(String line) {
  final condensed = line.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
  if (condensed.isEmpty) {
    return true;
  }
  if (RegExp(r'^[IJL|]{0,2}\d{1,3}[IJL|]{0,2}$').hasMatch(condensed)) {
    return true;
  }
  final flat = condensed.replaceAll('I', '1').replaceAll('L', '1');
  if (flat.contains('FOREVER') && RegExp('5.?3.?1').hasMatch(flat)) {
    return true;
  }
  final letters = RegExp('[A-Za-z]')
      .allMatches(line)
      .map((match) => match.group(0)!)
      .toList();
  if (letters.isNotEmpty &&
      letters.every((letter) => letter == letter.toUpperCase()) &&
      RegExp(r'[IJj|]\s*[\d\s]{1,6}$').hasMatch(line)) {
    return true;
  }
  return false;
}

String _buildSystem(String raw) {
  final wordCounts = <String, int>{};
  for (final match in RegExp('[A-Za-z]{2,}').allMatches(raw)) {
    final word = match.group(0)!.toLowerCase();
    wordCounts[word] = (wordCounts[word] ?? 0) + 1;
  }
  final commonWords = wordCounts.entries
      .where((entry) => entry.value >= 3)
      .map((entry) => entry.key)
      .toSet();

  String despace(String text) {
    for (var pass = 0; pass < 4; pass++) {
      final output = <String>[];
      final tokens = text.split(' ');
      var index = 0;
      var changed = false;
      while (index < tokens.length) {
        if (index + 1 < tokens.length) {
          final left = tokens[index];
          final right = tokens[index + 1];
          if (RegExp(r'^[A-Za-z]+$').hasMatch(left) &&
              RegExp(r'^[A-Za-z]+$').hasMatch(right)) {
            final merged = (left + right).toLowerCase();
            if ((wordCounts[merged] ?? 0) >= 5 &&
                (wordCounts[merged] ?? 0) >
                    3 * (wordCounts[right.toLowerCase()] ?? 0) &&
                (left.length == 1 ||
                    right.length <= 2 ||
                    !commonWords.contains(left.toLowerCase())) &&
                (left.length <= 3 || right.length <= 3)) {
              tokens[index + 1] = left + right;
              index++;
              changed = true;
              continue;
            }
          }
        }
        output.add(tokens[index]);
        index++;
      }
      text = output.join(' ');
      if (!changed) {
        break;
      }
    }
    return text;
  }

  String? chapterFor(int page) {
    String? title;
    for (final (start, name) in chapters) {
      if (page >= start) {
        title = name;
      }
    }
    return title;
  }

  String? partFor(int page) {
    String? title;
    for (final (start, name) in parts) {
      if (page >= start) {
        title = name;
      }
    }
    return title;
  }

  final output = <String>[];
  String? currentChapter;
  String? currentPart;
  final pages = raw.split('\f');
  for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
    final pageNumber = pageIndex + 1;
    if (dropPages.contains(pageNumber) || pageNumber > 283) {
      continue;
    }
    final lines = pages[pageIndex]
        .split('\n')
        .map((line) => line.trim().replaceAll(RegExp(r'\s+'), ' '))
        .toList();

    var seen = 0;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line.isEmpty) {
        continue;
      }
      if (seen >= 3) {
        break;
      }
      seen++;
      if (_isHeaderLine(line)) {
        lines[index] = '';
      }
    }

    final units = <List<String>>[];
    var currentUnit = <String>[];
    for (final line in lines) {
      if (line.isNotEmpty) {
        currentUnit.add(line);
      } else if (currentUnit.isNotEmpty) {
        units.add(currentUnit);
        currentUnit = <String>[];
      }
    }
    if (currentUnit.isNotEmpty) {
      units.add(currentUnit);
    }

    final kept = <String>[];
    var bullet = false;
    for (final unit in units) {
      var text = unit.join(' ');
      if (const {'•', '-', '·', '*', '■', '�'}.contains(text)) {
        bullet = true;
        continue;
      }
      if (bullet) {
        bullet = false;
        if (text.length >= 8 &&
            !garbage.hasMatch(text) &&
            !_isDayOrWeek(text)) {
          kept.add('- ${despace(text)}');
        }
        continue;
      }
      if (garbage.hasMatch(text)) {
        continue;
      }

      final trimmedUnit = List<String>.from(unit);
      bool junk(String line) =>
          line.length < 45 &&
          (_isDayOrWeek(line) || cell.hasMatch(line) || _isHeaderLine(line));
      while (trimmedUnit.isNotEmpty && junk(trimmedUnit.first)) {
        trimmedUnit.removeAt(0);
      }
      while (trimmedUnit.isNotEmpty && junk(trimmedUnit.last)) {
        trimmedUnit.removeLast();
      }
      if (trimmedUnit.isEmpty) {
        continue;
      }
      text = trimmedUnit.join(' ');
      if (_isDayOrWeek(text)) {
        continue;
      }
      if (text.length >= 70 &&
          trimmedUnit
                  .map((line) => line.length)
                  .reduce((left, right) => left > right ? left : right) >=
              62) {
        kept.add(_stripTrailingTableCells(despace(text)));
      }
    }

    if (kept.isEmpty) {
      continue;
    }
    final part = partFor(pageNumber);
    final chapter = chapterFor(pageNumber);
    if (part != currentPart) {
      output.add('\n# $part');
      currentPart = part;
      currentChapter = null;
    }
    if (chapter != currentChapter) {
      output.add('\n## $chapter');
      currentChapter = chapter;
    }
    output.add(kept.join('\n'));
  }

  var result = '${output.join('\n\n').trim()}\n';
  result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  // These damaged running week headers survive as suffixes on this scan's
  // otherwise valid prose lines, rather than as independently trimmable lines.
  result = result.replaceAll(
    RegExp(
      r'[ \t]+(?:WBBK|WBEK|WIBK|PBIDAY|MONDA:|WBDNISDAY|THUlSD|MDRDAY|PIIDAY)'
      r'(?:[ \t]+[A-Z:]+){0,3}(?=\n|$)',
    ),
    '',
  );
  return '$systemPreamble\n$result';
}

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
    ..writeln('# Trusted percentages and prescriptions')
    ..writeln()
    ..writeln(
      'This file is the ONLY trusted source of numbers and is generated from '
      '`lib/fivethreeone/schemes.dart`.',
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
      ..writeln('### Cycle $cycle — ${cycleNames[cycle]} '
          '(${getMainSchemeName(cycle)})')
      ..writeln();
    for (var week = 1; week <= cycleWeeks[cycle]; week++) {
      output.writeln(
        'Week $week: ${_renderScheme(getMainScheme(cycleType: cycle, week: week))}',
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
