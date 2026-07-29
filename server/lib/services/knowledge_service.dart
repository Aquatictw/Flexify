import 'dart:io';

const _roleAndCoachingStance = '''
You are a strength coach for the JackedLog app, specialising in Jim Wendler's 5/3/1 training system.
For session-level requests, be compliant: execute the request without argument.
For block-level requests involving a training max, cycle position, or supplemental template, first give exactly one sentence of 5/3/1 doctrine, then give the proposal.''';

const _toolUseRules = '''
Never state a weight that you did not receive from a tool result.
The exercise argument must be an exact name from the session snapshot's exercise vocabulary; never invent one.
bump_tms moves all four training maxes and counts as a cycle bump.
correct_tm fixes a single training max and does not count as a cycle bump.
Every pct_ value is a fraction, never percentage points: 0.9 means 90%, 0.6 means 60%, and -0.05 means 5% lighter. Sending -5 for "5% lighter" is a serious error.
pct_of_prescribed and pct_of_last_session are signed deltas from that baseline, so 0 means exactly as prescribed and -0.1 means 10% below it.
When the snapshot's prescription lists the lift you are writing, use pct_of_prescribed against it; do not restate the scheme percentages as pct_of_tm, because the prescription is already computed for this cycle and week.
Use pct_of_tm only for work the prescription does not cover, such as supplemental sets or a percentage the user names directly.''';

class KnowledgeService {
  KnowledgeService._(this.systemPrompt);

  factory KnowledgeService.load(String knowledgeDir) {
    final directory = Directory(knowledgeDir);
    if (!directory.existsSync()) {
      throw Exception(
        'Knowledge directory does not exist: ${directory.path} '
        '(KNOWLEDGE_DIR=$knowledgeDir). Create it and provide system.md, '
        'percentages.md, and capabilities.md.',
      );
    }

    final system = _readRequiredFile(knowledgeDir, 'system.md');
    final percentages = _readRequiredFile(knowledgeDir, 'percentages.md');
    final capabilities = _readRequiredFile(knowledgeDir, 'capabilities.md');
    final prompt = [
      _roleAndCoachingStance.trim(),
      _toolUseRules.trim(),
      system,
      percentages,
      capabilities,
    ].join('\n\n');

    return KnowledgeService._(prompt);
  }

  final String systemPrompt;

  int get promptLength => systemPrompt.length;

  static String _readRequiredFile(String knowledgeDir, String filename) {
    final path = '$knowledgeDir${Platform.pathSeparator}$filename';
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception(
        'Required knowledge file is missing: $path '
        '(KNOWLEDGE_DIR=$knowledgeDir). Create and populate $path.',
      );
    }

    final contents = file.readAsStringSync();
    if (contents.trim().isEmpty) {
      throw Exception(
        'Required knowledge file is empty: $path '
        '(KNOWLEDGE_DIR=$knowledgeDir). Add content to $path.',
      );
    }
    return contents.trim();
  }
}
