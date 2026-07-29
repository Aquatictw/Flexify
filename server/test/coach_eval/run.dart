import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'tools.dart';

const Set<String> _caseKeys = <String>{
  'name',
  'description',
  'snapshot_ref',
  'snapshot',
  'utterance',
  'session_writes',
  'block_writes',
  'expect',
  'forbid',
  'absent_tools',
  'expect_no_tool_calls',
  'allow_no_tool_calls',
  'allow_read_only_calls',
};

const Set<String> _directives = <String>{
  r'$absent',
  r'$oneOf',
  r'$len',
  r'$all',
  r'$contains',
  r'$anyOfValues',
  r'$lt',
  r'$lte',
  r'$gt',
  r'$gte',
  r'$not',
};

class _Options {
  String? stubDir;
  bool listOnly = false;
  String? filter;
  String? jsonPath;
  bool help = false;
}

class _EvalCase {
  _EvalCase({
    required this.file,
    required this.name,
    required this.description,
    required this.snapshotName,
    required this.snapshot,
    required this.utterance,
    required this.sessionWrites,
    required this.blockWrites,
    required this.expect,
    required this.forbid,
    required this.absentTools,
    required this.expectNoToolCalls,
    required this.allowNoToolCalls,
    required this.allowReadOnlyCalls,
  });

  final File file;
  final String name;
  final String description;
  final String snapshotName;
  final Map<String, Object?> snapshot;
  final String utterance;
  final bool sessionWrites;
  final bool blockWrites;
  final List<Map<String, Object?>> expect;
  final List<String> forbid;
  final List<String> absentTools;
  final bool expectNoToolCalls;
  final bool allowNoToolCalls;

  /// When true, a turn whose only tool calls are read-only counts the same as
  /// a turn with no calls at all. Reaching for history before answering is
  /// legitimate coaching, not a contract violation.
  final bool allowReadOnlyCalls;
}

class _ToolCall {
  _ToolCall(this.name, this.arguments, {this.badJson = false, this.raw});

  final String name;
  final Object? arguments;
  final bool badJson;

  /// The undecoded `function.arguments` payload, kept so a `bad-json` failure
  /// is still diagnosable from the results file.
  final String? raw;

  /// Compact one-line rendering of what the model actually emitted.
  String get inline {
    if (badJson) {
      return '$name(<unparseable> ${raw ?? 'null'})';
    }
    return '$name(${jsonEncode(arguments)})';
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        'arguments': arguments,
        if (badJson) 'bad_json': true,
        if (badJson && raw != null) 'raw_arguments': raw,
      };
}

/// The assistant turn as returned by the provider: the tool calls plus any
/// prose. Prose is never asserted on, but it is recorded so prose-shaped
/// cases (06, 10) can be reviewed by a human from the results file.
class _Assistant {
  _Assistant(this.calls, this.content);

  final List<_ToolCall> calls;
  final String? content;
}

class _CaseResult {
  _CaseResult({
    required this.testCase,
    required this.calls,
    required this.reasons,
    this.content,
  });

  final _EvalCase testCase;
  final List<_ToolCall> calls;
  final List<String> reasons;
  final String? content;

  bool get passed => reasons.isEmpty;
}

class _ResponseFailure implements Exception {
  _ResponseFailure(this.reason);

  final String reason;
}

Future<void> main(List<String> arguments) async {
  final _Options options;
  try {
    options = _parseOptions(arguments);
  } on FormatException catch (error) {
    stderr.writeln('coach-eval: ${error.message}');
    stderr.writeln('Use --help for usage.');
    exitCode = 1;
    return;
  }

  if (options.help) {
    _printHelp();
    return;
  }

  final Directory root = File.fromUri(Platform.script).parent;
  final List<_EvalCase> cases;
  try {
    cases = _loadCases(root);
  } on FormatException catch (error) {
    stderr.writeln('coach-eval: ${error.message}');
    exitCode = 1;
    return;
  }

  // Comma-separated so a targeted re-run of several failures costs one
  // invocation rather than one per case.
  final List<String> filters = (options.filter ?? '')
      .split(',')
      .map((String part) => part.trim())
      .where((String part) => part.isNotEmpty)
      .toList();
  final List<_EvalCase> selected = cases
      .where(
        (_EvalCase testCase) =>
            filters.isEmpty ||
            filters.any((String part) => testCase.name.contains(part)),
      )
      .toList();
  if (filters.isNotEmpty && selected.isEmpty) {
    stderr.writeln('coach-eval: no cases matched --filter ${options.filter}');
    exitCode = 2;
    return;
  }

  if (options.listOnly) {
    _printCaseList(selected);
    return;
  }

  final Map<String, String> prodEnv = _readEnvFile(
    File.fromUri(root.uri.resolve('../../../scripts/prod.env')),
  );
  final String model = Platform.environment['COACH_EVAL_MODEL'] ??
      prodEnv['CHAT_MODEL'] ??
      '(server default)';

  String? baseUrl;
  String? apiKey;
  if (options.stubDir == null) {
    baseUrl =
        Platform.environment['COACH_EVAL_BASE_URL'] ?? prodEnv['JACKED_URL'];
    apiKey =
        Platform.environment['COACH_EVAL_API_KEY'] ?? prodEnv['JACKED_API_KEY'];
    if (baseUrl == null || baseUrl.isEmpty) {
      stderr.writeln(
        'coach-eval: set COACH_EVAL_BASE_URL or JACKED_URL in '
        'scripts/prod.env',
      );
      exitCode = 1;
      return;
    }
    if (apiKey == null || apiKey.isEmpty) {
      stderr.writeln(
        'coach-eval: set COACH_EVAL_API_KEY or JACKED_API_KEY in '
        'scripts/prod.env',
      );
      exitCode = 1;
      return;
    }
  }

  const String stubBanner =
      '*** STUB MODE — no model was called; these are not real results ***';
  if (options.stubDir != null) {
    stdout.writeln(stubBanner);
  }

  final Stopwatch stopwatch = Stopwatch()..start();
  final List<_CaseResult> results = <_CaseResult>[];
  final HttpClient? client = options.stubDir == null
      ? (HttpClient()..connectionTimeout = const Duration(seconds: 120))
      : null;
  try {
    for (final _EvalCase testCase in selected) {
      results.add(
        await _runCase(
          testCase,
          model: model,
          stubDir:
              options.stubDir == null ? null : _resolvePath(options.stubDir!),
          client: client,
          baseUrl: baseUrl,
          apiKey: apiKey,
        ),
      );
    }
  } finally {
    client?.close(force: true);
  }
  stopwatch.stop();

  _printResults(results);
  final int passed =
      results.where((_CaseResult result) => result.passed).length;
  final int failed = results.length - passed;
  stdout.writeln(
    'MODEL=$model  PASSED $passed/${results.length}  FAILED $failed  '
    'ELAPSED ${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s',
  );
  final bool? criticalPass = _criticalPairPass(results);
  stdout.writeln(
    'CRITICAL PAIR: 04/05 '
    '${criticalPass == null ? 'NOT RUN' : (criticalPass ? 'PASS' : 'FAIL')}',
  );

  if (options.jsonPath != null) {
    final File output = File(_resolvePath(options.jsonPath!).path);
    await output.parent.create(recursive: true);
    await output.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
            'model': model,
            'passed': passed,
            'failed': failed,
            'elapsed_seconds': stopwatch.elapsedMilliseconds / 1000,
            'critical_pair_pass': criticalPass,
            'results': results
                .map(
                  (_CaseResult result) => <String, Object?>{
                    'name': result.testCase.name,
                    'pass': result.passed,
                    'expected_tools': _expectedTools(result.testCase),
                    'actual_tools': result.calls
                        .map((_ToolCall call) => call.name)
                        .toList(),
                    // The whole point of the results file: what the model
                    // actually emitted, so a failure is diagnosable without
                    // paying for another run.
                    'tool_calls': result.calls
                        .map((_ToolCall call) => call.toJson())
                        .toList(),
                    'assistant_content': result.content,
                    'utterance': result.testCase.utterance,
                    'snapshot': result.testCase.snapshotName,
                    'expect': result.testCase.expect,
                    'reasons': result.reasons,
                  },
                )
                .toList(),
          })}\n',
    );
  }

  if (options.stubDir != null) {
    stdout.writeln(stubBanner);
  }
  if (failed != 0) {
    exitCode = 1;
  }
}

_Options _parseOptions(List<String> arguments) {
  final _Options options = _Options();
  for (var index = 0; index < arguments.length; index++) {
    final String argument = arguments[index];
    switch (argument) {
      case '--stub-dir':
        options.stubDir = _nextValue(arguments, ++index, argument);
        break;
      case '--list':
        options.listOnly = true;
        break;
      case '--filter':
        options.filter = _nextValue(arguments, ++index, argument);
        break;
      case '--json':
        options.jsonPath = _nextValue(arguments, ++index, argument);
        break;
      case '--help':
      case '-h':
        options.help = true;
        break;
      default:
        throw FormatException('unknown argument: $argument');
    }
  }
  return options;
}

String _nextValue(List<String> arguments, int index, String flag) {
  if (index >= arguments.length || arguments[index].startsWith('--')) {
    throw FormatException('$flag requires a value');
  }
  return arguments[index];
}

void _printHelp() {
  stdout.writeln('''
JackedLog AI Coach golden-set evaluator

Usage: dart run test/coach_eval/run.dart [options]

  --stub-dir <dir>     Read canned responses instead of using HTTP.
  --list               Validate and list cases without running them.
  --filter <list>      Run only case names containing any of the
                       comma-separated substrings, e.g. --filter 01,06,13.
  --json <path>        Also write machine-readable results.
  --help               Show this help.
''');
}

List<_EvalCase> _loadCases(Directory root) {
  final Directory snapshotsDir = Directory.fromUri(
    root.uri.resolve('snapshots/'),
  );
  final Map<String, Map<String, Object?>> snapshots =
      <String, Map<String, Object?>>{};
  final List<File> snapshotFiles = snapshotsDir
      .listSync()
      .whereType<File>()
      .where((File file) => file.path.endsWith('.json'))
      .toList()
    ..sort((File left, File right) => left.path.compareTo(right.path));
  for (final File file in snapshotFiles) {
    final Object? decoded = _decodeFile(file);
    if (decoded is! Map<String, Object?>) {
      throw FormatException('${file.path}: snapshot must be a JSON object');
    }
    snapshots[_basenameWithoutJson(file.path)] = decoded;
  }

  final Directory casesDir = Directory.fromUri(root.uri.resolve('cases/'));
  final List<File> caseFiles = casesDir
      .listSync()
      .whereType<File>()
      .where((File file) => file.path.endsWith('.json'))
      .toList()
    ..sort((File left, File right) => left.path.compareTo(right.path));
  final List<_EvalCase> cases = <_EvalCase>[];
  for (final File file in caseFiles) {
    final Object? decoded = _decodeFile(file);
    if (decoded is! Map<String, Object?>) {
      throw FormatException('${file.path}: case must be a JSON object');
    }
    final Set<String> unknownKeys = decoded.keys.toSet().difference(_caseKeys);
    if (unknownKeys.isNotEmpty) {
      throw FormatException(
        '${file.path}: unknown top-level key(s): '
        '${unknownKeys.toList()..sort()}',
      );
    }
    final bool hasRef = decoded.containsKey('snapshot_ref');
    final bool hasInline = decoded.containsKey('snapshot');
    if (hasRef == hasInline) {
      throw FormatException(
        '${file.path}: specify exactly one of snapshot_ref or snapshot',
      );
    }
    _validateDirectives(decoded, file.path);

    final String name = _requiredString(decoded, 'name', file);
    final String description = _requiredString(decoded, 'description', file);
    final String utterance = _requiredString(decoded, 'utterance', file);
    final String snapshotName;
    final Map<String, Object?> snapshot;
    if (hasRef) {
      snapshotName = _requiredString(decoded, 'snapshot_ref', file);
      final Map<String, Object?>? loaded = snapshots[snapshotName];
      if (loaded == null) {
        throw FormatException(
          '${file.path}: missing snapshot file snapshots/$snapshotName.json',
        );
      }
      snapshot = loaded;
    } else {
      snapshotName = '(inline)';
      final Object? inline = decoded['snapshot'];
      if (inline is! Map<String, Object?>) {
        throw FormatException('${file.path}: snapshot must be a JSON object');
      }
      snapshot = inline;
    }

    final List<Map<String, Object?>> expect = _expectations(decoded, file);
    final List<String> forbid = _stringList(decoded, 'forbid', file);
    final List<String> absentTools = _stringList(
      decoded,
      'absent_tools',
      file,
    );
    final Iterable<String> mentionedTools = <String>[
      ...expect.map((Map<String, Object?> item) => item['tool']! as String),
      ...forbid,
      ...absentTools,
    ];
    for (final String tool in mentionedTools) {
      if (!allToolNames.contains(tool)) {
        throw FormatException('${file.path}: unknown tool name "$tool"');
      }
    }

    final Object? workout = snapshot['workout'];
    final Object? block = snapshot['block'];
    cases.add(
      _EvalCase(
        file: file,
        name: name,
        description: description,
        snapshotName: snapshotName,
        snapshot: snapshot,
        utterance: utterance,
        sessionWrites: _optionalBool(
          decoded,
          'session_writes',
          workout != null,
          file,
        ),
        blockWrites: _optionalBool(
          decoded,
          'block_writes',
          block != null,
          file,
        ),
        expect: expect,
        forbid: forbid,
        absentTools: absentTools,
        expectNoToolCalls: _optionalBool(
          decoded,
          'expect_no_tool_calls',
          false,
          file,
        ),
        allowNoToolCalls: _optionalBool(
          decoded,
          'allow_no_tool_calls',
          false,
          file,
        ),
        allowReadOnlyCalls: _optionalBool(
          decoded,
          'allow_read_only_calls',
          false,
          file,
        ),
      ),
    );
  }
  return cases;
}

Object? _decodeFile(File file) {
  try {
    return jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    throw FormatException('${file.path}: invalid JSON: ${error.message}');
  }
}

String _requiredString(Map<String, Object?> map, String key, File file) {
  final Object? value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('${file.path}: $key must be a non-empty string');
  }
  return value;
}

bool _optionalBool(
  Map<String, Object?> map,
  String key,
  bool fallback,
  File file,
) {
  if (!map.containsKey(key)) {
    return fallback;
  }
  final Object? value = map[key];
  if (value is! bool) {
    throw FormatException('${file.path}: $key must be a boolean');
  }
  return value;
}

List<String> _stringList(Map<String, Object?> map, String key, File file) {
  final Object? value = map[key];
  if (value == null) {
    return <String>[];
  }
  if (value is! List<Object?> || value.any((Object? item) => item is! String)) {
    throw FormatException('${file.path}: $key must be a list of strings');
  }
  return value.cast<String>();
}

List<Map<String, Object?>> _expectations(
  Map<String, Object?> map,
  File file,
) {
  final Object? value = map['expect'];
  if (value is! List<Object?>) {
    throw FormatException('${file.path}: expect must be a list');
  }
  final List<Map<String, Object?>> result = <Map<String, Object?>>[];
  for (final Object? item in value) {
    if (item is! Map<String, Object?> ||
        item.keys.any(
          (String key) => key != 'tool' && key != 'args_match',
        ) ||
        item['tool'] is! String ||
        item['args_match'] is! Map<String, Object?>) {
      throw FormatException(
        '${file.path}: each expectation needs only tool and args_match',
      );
    }
    result.add(item);
  }
  return result;
}

void _validateDirectives(Object? value, String path) {
  if (value is Map<String, Object?>) {
    for (final String key in value.keys) {
      if (key.startsWith(r'$') && !_directives.contains(key)) {
        throw FormatException('$path: unknown matcher directive "$key"');
      }
    }
    final bool hasDirective =
        value.keys.any((String key) => key.startsWith(r'$'));
    if (hasDirective && value.keys.any((String key) => !key.startsWith(r'$'))) {
      throw FormatException(
        '$path: matcher directives cannot be mixed with literal keys',
      );
    }
    for (final Object? child in value.values) {
      _validateDirectives(child, path);
    }
  } else if (value is List<Object?>) {
    for (final Object? child in value) {
      _validateDirectives(child, path);
    }
  }
}

void _printCaseList(List<_EvalCase> cases) {
  for (final _EvalCase testCase in cases) {
    stdout.writeln(
      '${testCase.name}  snapshot=${testCase.snapshotName}  '
      'expected=${_displayTools(_expectedTools(testCase))}',
    );
  }
  stdout.writeln('Validated ${cases.length} case(s).');
}

Future<_CaseResult> _runCase(
  _EvalCase testCase, {
  required String model,
  required Directory? stubDir,
  required HttpClient? client,
  required String? baseUrl,
  required String? apiKey,
}) async {
  final List<Map<String, Object?>> tools = coachTools(
    sessionWrites: testCase.sessionWrites,
    blockWrites: testCase.blockWrites,
  );
  final List<String> offeredTools = tools
      .map(
        (Map<String, Object?> tool) =>
            (tool['function']! as Map<String, Object?>)['name']! as String,
      )
      .toList();
  final Map<String, Object?> body = <String, Object?>{
    'model': model,
    'messages': <Object?>[
      <String, Object?>{
        'role': 'user',
        'content': 'Current training state (session snapshot):\n'
            '${const JsonEncoder.withIndent('  ').convert(_sortJson(testCase.snapshot))}'
            '\n\n${testCase.utterance}',
      },
    ],
    'tools': tools,
    'tool_choice': 'auto',
  };

  final Object? responseBody;
  try {
    if (stubDir != null) {
      final File stub =
          File.fromUri(stubDir.uri.resolve('${testCase.name}.json'));
      if (!stub.existsSync()) {
        throw _ResponseFailure('no-stub');
      }
      responseBody = _decodeFile(stub);
    } else {
      responseBody = await _post(
        client!,
        baseUrl!,
        apiKey!,
        jsonEncode(body),
      );
    }
  } on _ResponseFailure catch (error) {
    return _CaseResult(
      testCase: testCase,
      calls: <_ToolCall>[],
      reasons: <String>[error.reason],
    );
  } on TimeoutException {
    return _CaseResult(
      testCase: testCase,
      calls: <_ToolCall>[],
      reasons: <String>['timeout'],
    );
  } on SocketException {
    return _CaseResult(
      testCase: testCase,
      calls: <_ToolCall>[],
      reasons: <String>['network-error'],
    );
  } on FormatException {
    return _CaseResult(
      testCase: testCase,
      calls: <_ToolCall>[],
      reasons: <String>['bad-response-json'],
    );
  }

  final _Assistant assistant;
  try {
    assistant = _extractAssistant(responseBody);
  } on _ResponseFailure catch (error) {
    return _CaseResult(
      testCase: testCase,
      calls: <_ToolCall>[],
      reasons: <String>[error.reason],
    );
  }
  return _evaluate(testCase, offeredTools, assistant);
}

Future<Object?> _post(
  HttpClient client,
  String baseUrl,
  String apiKey,
  String body,
) async {
  final String trimmedBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final Uri uri;
  try {
    uri = Uri.parse('$trimmedBase/api/chat');
  } on FormatException {
    throw _ResponseFailure('invalid-base-url');
  }
  final HttpClientRequest request =
      await client.postUrl(uri).timeout(const Duration(seconds: 120));
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
  request.headers.contentType = ContentType.json;
  request.write(body);
  final HttpClientResponse response =
      await request.close().timeout(const Duration(seconds: 120));
  final String responseText = await utf8.decoder
      .bind(response)
      .join()
      .timeout(const Duration(seconds: 120));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw _ResponseFailure('http ${response.statusCode}');
  }
  try {
    return jsonDecode(responseText);
  } on FormatException {
    throw _ResponseFailure('bad-response-json');
  }
}

_Assistant _extractAssistant(Object? responseBody) {
  if (responseBody is! Map<String, Object?>) {
    throw _ResponseFailure('bad-response-shape');
  }
  final Object? choicesValue = responseBody['choices'];
  if (choicesValue is! List<Object?> || choicesValue.isEmpty) {
    throw _ResponseFailure('bad-response-shape');
  }
  final Object? first = choicesValue.first;
  if (first is! Map<String, Object?>) {
    throw _ResponseFailure('bad-response-shape');
  }
  final Object? messageValue = first['message'];
  if (messageValue is! Map<String, Object?>) {
    throw _ResponseFailure('bad-response-shape');
  }
  final Object? contentValue = messageValue['content'];
  final String? content = contentValue is String ? contentValue : null;
  final Object? callsValue = messageValue['tool_calls'];
  if (callsValue == null) {
    return _Assistant(<_ToolCall>[], content);
  }
  if (callsValue is! List<Object?>) {
    throw _ResponseFailure('bad-response-shape');
  }
  final List<_ToolCall> calls = <_ToolCall>[];
  for (final Object? value in callsValue) {
    if (value is! Map<String, Object?> ||
        value['function'] is! Map<String, Object?>) {
      throw _ResponseFailure('bad-response-shape');
    }
    final Map<String, Object?> function =
        value['function']! as Map<String, Object?>;
    final Object? nameValue = function['name'];
    if (nameValue is! String) {
      throw _ResponseFailure('bad-response-shape');
    }
    final Object? argumentsValue = function['arguments'];
    if (argumentsValue is Map<String, Object?>) {
      calls.add(_ToolCall(nameValue, argumentsValue));
    } else if (argumentsValue is String) {
      try {
        final Object? decoded = jsonDecode(argumentsValue);
        if (decoded is! Map<String, Object?>) {
          calls.add(
            _ToolCall(nameValue, null, badJson: true, raw: argumentsValue),
          );
        } else {
          calls.add(_ToolCall(nameValue, decoded));
        }
      } on FormatException {
        calls.add(
          _ToolCall(nameValue, null, badJson: true, raw: argumentsValue),
        );
      }
    } else {
      calls.add(
        _ToolCall(
          nameValue,
          null,
          badJson: true,
          raw: jsonEncode(argumentsValue),
        ),
      );
    }
  }
  return _Assistant(calls, content);
}

_CaseResult _evaluate(
  _EvalCase testCase,
  List<String> offeredTools,
  _Assistant assistant,
) {
  final List<_ToolCall> calls = assistant.calls;
  final List<String> reasons = <String>[];
  final List<String> actualNames =
      calls.map((_ToolCall call) => call.name).toList();
  if (calls.any((_ToolCall call) => call.badJson)) {
    reasons.add('bad-json arguments');
  }
  for (final String tool in testCase.forbid) {
    if (actualNames.contains(tool)) {
      reasons.add('forbidden call $tool');
    }
  }
  for (final String tool in testCase.absentTools) {
    if (offeredTools.contains(tool)) {
      reasons.add('absent tool $tool was offered');
    }
    if (actualNames.contains(tool)) {
      reasons.add('absent tool $tool was called');
    }
  }
  if (testCase.expectNoToolCalls) {
    if (calls.isNotEmpty) {
      reasons.add('expected zero tool calls');
    }
  } else if (!(testCase.allowNoToolCalls &&
      _countsAsNoCalls(testCase, calls))) {
    final Set<int> usedCalls = <int>{};
    for (final Map<String, Object?> expectation in testCase.expect) {
      final String expectedName = expectation['tool']! as String;
      final Object? matcher = expectation['args_match'];
      int? matchedIndex;
      for (var index = 0; index < calls.length; index++) {
        final _ToolCall call = calls[index];
        if (!usedCalls.contains(index) &&
            !call.badJson &&
            call.name == expectedName &&
            _matches(matcher, call.arguments)) {
          matchedIndex = index;
          break;
        }
      }
      if (matchedIndex == null) {
        reasons.add(
          'missing $expectedName matching ${jsonEncode(matcher)}',
        );
      } else {
        usedCalls.add(matchedIndex);
      }
    }
  }
  return _CaseResult(
    testCase: testCase,
    calls: calls,
    reasons: reasons,
    content: assistant.content,
  );
}

bool _matches(Object? expected, Object? actual) {
  if (expected is Map<String, Object?>) {
    if (_isDirective(expected)) {
      return _matchesDirectives(expected, actual);
    }
    if (actual is! Map<String, Object?>) {
      return false;
    }
    for (final MapEntry<String, Object?> entry in expected.entries) {
      if (_isAbsentDirective(entry.value)) {
        if (actual.containsKey(entry.key)) {
          return false;
        }
      } else if (!actual.containsKey(entry.key) ||
          !_matches(entry.value, actual[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (expected is List<Object?>) {
    if (actual is! List<Object?> || expected.length > actual.length) {
      return false;
    }
    for (var index = 0; index < expected.length; index++) {
      if (!_matches(expected[index], actual[index])) {
        return false;
      }
    }
    return true;
  }
  if (expected is num && actual is num) {
    return (expected.toDouble() - actual.toDouble()).abs() <= 1e-9;
  }
  return expected == actual;
}

bool _isDirective(Map<String, Object?> value) =>
    value.isNotEmpty && value.keys.every((String key) => key.startsWith(r'$'));

bool _isAbsentDirective(Object? value) =>
    value is Map<String, Object?> &&
    value.length == 1 &&
    value[r'$absent'] == true;

bool _matchesDirectives(Map<String, Object?> directives, Object? actual) {
  for (final MapEntry<String, Object?> directive in directives.entries) {
    final Object? matcher = directive.value;
    switch (directive.key) {
      case r'$absent':
        return false;
      case r'$oneOf':
        if (matcher is! List<Object?> ||
            !matcher.any((Object? item) => _matches(item, actual))) {
          return false;
        }
        break;
      case r'$len':
        if (matcher is! num ||
            actual is! List<Object?> ||
            actual.length != matcher.toInt()) {
          return false;
        }
        break;
      case r'$all':
        if (actual is! List<Object?> ||
            actual.isEmpty ||
            !actual.every((Object? item) => _matches(matcher, item))) {
          return false;
        }
        break;
      case r'$contains':
        if (matcher is! List<Object?> ||
            actual is! List<Object?> ||
            !matcher.every(
              (Object? wanted) =>
                  actual.any((Object? item) => _matches(wanted, item)),
            )) {
          return false;
        }
        break;
      case r'$anyOfValues':
        if (matcher is! List<Object?> ||
            !matcher.any((Object? item) => _matches(item, actual))) {
          return false;
        }
        break;
      case r'$lt':
        if (!_numericComparison(
          actual,
          matcher,
          (double a, double b) => a < b,
        )) {
          return false;
        }
        break;
      case r'$lte':
        if (!_numericComparison(
          actual,
          matcher,
          (double a, double b) => a <= b,
        )) {
          return false;
        }
        break;
      case r'$gt':
        if (!_numericComparison(
          actual,
          matcher,
          (double a, double b) => a > b,
        )) {
          return false;
        }
        break;
      case r'$gte':
        if (!_numericComparison(
          actual,
          matcher,
          (double a, double b) => a >= b,
        )) {
          return false;
        }
        break;
      case r'$not':
        if (_matches(matcher, actual)) {
          return false;
        }
        break;
    }
  }
  return true;
}

bool _numericComparison(
  Object? actual,
  Object? expected,
  bool Function(double actual, double expected) compare,
) =>
    actual is num &&
    expected is num &&
    compare(actual.toDouble(), expected.toDouble());

Object? _sortJson(Object? value) {
  if (value is Map<String, Object?>) {
    final List<String> keys = value.keys.toList()..sort();
    return <String, Object?>{
      for (final String key in keys) key: _sortJson(value[key]),
    };
  }
  if (value is List<Object?>) {
    return value.map(_sortJson).toList();
  }
  return value;
}

Map<String, String> _readEnvFile(File file) {
  if (!file.existsSync()) {
    return <String, String>{};
  }
  final Map<String, String> values = <String, String>{};
  for (final String rawLine in file.readAsLinesSync()) {
    final String line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final int separator = line.indexOf('=');
    if (separator <= 0) {
      continue;
    }
    final String key = line.substring(0, separator).trim();
    String value = line.substring(separator + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    values[key] = value;
  }
  return values;
}

Directory _resolvePath(String path) => Directory(path).absolute;

String _basenameWithoutJson(String path) {
  final String filename = path.split(Platform.pathSeparator).last;
  return filename.substring(0, filename.length - '.json'.length);
}

List<String> _expectedTools(_EvalCase testCase) => testCase.expect
    .map((Map<String, Object?> item) => item['tool']! as String)
    .toList();

String _displayTools(List<String> tools) =>
    tools.isEmpty ? '-' : tools.join(',');

void _printResults(List<_CaseResult> results) {
  const int numberWidth = 3;
  const int nameWidth = 42;
  const int statusWidth = 7;
  const int toolsWidth = 29;
  stdout.writeln(
    '${'#'.padRight(numberWidth)}'
    '${'case name'.padRight(nameWidth)}'
    '${'status'.padRight(statusWidth)}'
    '${'expected tools'.padRight(toolsWidth)}'
    'actual tools',
  );
  stdout.writeln('-' * 115);
  for (var index = 0; index < results.length; index++) {
    final _CaseResult result = results[index];
    final String expected = _displayTools(_expectedTools(result.testCase));
    final String actual = _displayTools(
      result.calls.map((_ToolCall call) => call.name).toList(),
    );
    stdout.writeln(
      '${(index + 1).toString().padRight(numberWidth)}'
      '${_truncate(result.testCase.name, nameWidth - 1).padRight(nameWidth)}'
      '${(result.passed ? 'PASS' : 'FAIL').padRight(statusWidth)}'
      '${_truncate(expected, toolsWidth - 1).padRight(toolsWidth)}'
      '$actual',
    );
    for (final String reason in result.reasons) {
      stdout.writeln('    $reason');
    }
    // Only failures get the emitted arguments — on a passing run the table
    // stays readable, and on a failing one you can see what went wrong
    // without re-running against a paid endpoint.
    if (!result.passed) {
      if (result.calls.isEmpty) {
        stdout.writeln('    emitted: (no tool calls)');
      }
      for (final _ToolCall call in result.calls) {
        stdout.writeln('    emitted: ${call.inline}');
      }
    }
  }
}

String _truncate(String value, int maximum) {
  if (value.length <= maximum) {
    return value;
  }
  return '${value.substring(0, maximum - 3)}...';
}

const Set<String> _readOnlyTools = <String>{
  'get_exercise_history',
  'get_records',
  'get_block_history',
};

/// Whether [calls] should be treated as "the model declined to act". Read-only
/// calls count as declining when the case opts in: looking something up before
/// answering is not the behaviour these cases are guarding against.
bool _countsAsNoCalls(_EvalCase testCase, List<_ToolCall> calls) {
  if (calls.isEmpty) {
    return true;
  }
  return testCase.allowReadOnlyCalls &&
      calls.every((_ToolCall call) => _readOnlyTools.contains(call.name));
}

/// `true`/`false` when both cases of the silent-corruption pair ran, `null`
/// when a filtered run did not include them — reporting FAIL for cases that
/// were never executed would be a lie.
bool? _criticalPairPass(List<_CaseResult> results) {
  final List<_CaseResult> critical = results
      .where(
        (_CaseResult result) =>
            result.testCase.name.startsWith('04-') ||
            result.testCase.name.startsWith('05-'),
      )
      .toList();
  if (critical.length != 2) {
    return null;
  }
  return critical.every((_CaseResult result) => result.passed);
}
