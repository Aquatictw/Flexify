import '../fivethreeone/main_lifts.dart';

/// The four bases the coach may name for a set's weight.
///
/// The model never emits a bar weight (PRD decision 3): it tags a basis and
/// Dart does the arithmetic, so every number that reaches a barbell comes out
/// of tested code.
enum WeightBasis {
  pctOfTm,
  pctOfPrescribed,
  pctOfLastSession,
  absolute,
}

/// Tool-argument key for each basis. These strings are the wire contract with
/// the model and match `server/test/coach_eval/tools.dart`.
const Map<String, WeightBasis> weightSpecKeys = <String, WeightBasis>{
  'pct_of_tm': WeightBasis.pctOfTm,
  'pct_of_prescribed': WeightBasis.pctOfPrescribed,
  'pct_of_last_session': WeightBasis.pctOfLastSession,
  'absolute': WeightBasis.absolute,
};

/// The tool-argument key for [basis].
String weightSpecKeyOf(WeightBasis basis) => weightSpecKeys.entries
    .firstWhere((entry) => entry.value == basis)
    .key;

/// Upper bound for `pct_of_tm`. Anything above this is percentage points that
/// slipped through the schema, not a real prescription — 5/3/1 never programs
/// main work above a TM test's 100%, and the 1.5 headroom is generous.
const double maxTmFraction = 1.5;

/// Either a resolved value or a retryable, model-facing error string.
///
/// Coach tools never throw at the model. An error is a sentence the model can
/// act on inside the same tool loop, which is how it self-corrects instead of
/// confidently writing something wrong.
class CoachResult<T> {
  const CoachResult.ok(T this.value) : error = null;

  const CoachResult.failed(String this.error) : value = null;

  final T? value;
  final String? error;

  bool get isError => error != null;
}

/// A validated, single-basis weight spec.
class WeightSpec {
  const WeightSpec(this.basis, this.value);

  final WeightBasis basis;

  /// Fraction for the `pct_` bases, a literal weight for [WeightBasis.absolute].
  final double value;

  String get key => weightSpecKeyOf(basis);

  @override
  String toString() => 'WeightSpec($key: $value)';
}

/// The numbers a spec can resolve against, all in the target unit's terms.
///
/// A null field means that basis is unavailable for this set, which resolves
/// to a tool error rather than a guess.
class WeightBases {
  const WeightBases({
    this.trainingMax,
    this.prescribed,
    this.lastSession,
  });

  /// The block's training max for this lift, in `block.unit`.
  final double? trainingMax;

  /// `mainWorkPrescription()` weight for the set position being written.
  final double? prescribed;

  /// The matching set's weight from this exercise's previous session.
  final double? lastSession;
}

const String _oneOfMessage =
    'weight_spec must be an object with exactly one of pct_of_tm, '
    'pct_of_prescribed, pct_of_last_session, absolute. Never include a unit.';

/// Parses one `weight_spec` tool argument.
///
/// Rejects percentage points masquerading as fractions: in the Phase A eval a
/// live model emitted `pct_of_prescribed: -5` for "5% lighter", which as a
/// fraction is 500% lighter. The tool schema and system prompt both say
/// "fraction", but the bar does not care what the prompt said, so the bound is
/// enforced here as well.
CoachResult<WeightSpec> parseWeightSpec(Object? raw) {
  if (raw is! Map) return const CoachResult<WeightSpec>.failed(_oneOfMessage);

  final present = <String, Object?>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    if (key is! String || !weightSpecKeys.containsKey(key)) {
      return CoachResult<WeightSpec>.failed(
        "weight_spec does not take '$key'. $_oneOfMessage",
      );
    }
    if (entry.value == null) continue;
    present[key] = entry.value;
  }

  if (present.length != 1) {
    return CoachResult<WeightSpec>.failed(
      present.isEmpty
          ? _oneOfMessage
          : 'weight_spec set ${present.keys.join(' and ')} together. '
              '$_oneOfMessage',
    );
  }

  final key = present.keys.first;
  final rawValue = present[key];
  if (rawValue is! num) {
    return CoachResult<WeightSpec>.failed('weight_spec.$key must be a number.');
  }
  final value = rawValue.toDouble();
  if (!value.isFinite) {
    return CoachResult<WeightSpec>.failed(
      'weight_spec.$key must be a finite number.',
    );
  }

  final basis = weightSpecKeys[key]!;
  switch (basis) {
    case WeightBasis.pctOfTm:
      if (value <= 0 || value > maxTmFraction) {
        return CoachResult<WeightSpec>.failed(
          'pct_of_tm is a fraction of the training max, not percentage '
          'points: 0.9 means 90%. Got ${_show(value)}, which is outside '
          '0 to $maxTmFraction.',
        );
      }
    case WeightBasis.pctOfPrescribed:
    case WeightBasis.pctOfLastSession:
      if (!(value > -1 && value <= 1)) {
        return CoachResult<WeightSpec>.failed(
          '$key is a signed fraction, not percentage points: 0 means '
          'unchanged and -0.05 means 5% lighter. Got ${_show(value)}, which '
          'would mean ${_show(value * 100)}%.',
        );
      }
    case WeightBasis.absolute:
      if (value <= 0) {
        return const CoachResult<WeightSpec>.failed(
          'absolute must be a positive weight in the unit the app already '
          'uses for that exercise.',
        );
      }
  }

  return CoachResult<WeightSpec>.ok(WeightSpec(basis, value));
}

/// Resolves [spec] to a loadable bar weight in [unit].
///
/// Every branch terminates in [roundToPlate], which branches on the unit
/// (2.5 kg vs 5 lb) — a wrong unit changes the rounding, not just the label,
/// so units are inherited from the app and never taken from the model
/// (PRD decision 12).
CoachResult<double> resolveWeightSpec({
  required WeightSpec spec,
  required String exercise,
  required String unit,
  required WeightBases bases,
}) {
  switch (spec.basis) {
    case WeightBasis.pctOfTm:
      final tm = bases.trainingMax;
      if (tm == null || tm <= 0) {
        return CoachResult<double>.failed(
          '$exercise has no training max; use an absolute weight or '
          'pct_of_last_session.',
        );
      }
      return CoachResult<double>.ok(roundToPlate(tm * spec.value, unit));
    case WeightBasis.pctOfPrescribed:
      final prescribed = bases.prescribed;
      if (prescribed == null) {
        return CoachResult<double>.failed(
          '$exercise has no prescribed weight for that set this session; use '
          'pct_of_tm, pct_of_last_session, or an absolute weight.',
        );
      }
      return CoachResult<double>.ok(
        roundToPlate(prescribed * (1 + spec.value), unit),
      );
    case WeightBasis.pctOfLastSession:
      final last = bases.lastSession;
      if (last == null) {
        return CoachResult<double>.failed(
          '$exercise has no previous session on record; use an absolute '
          'weight or pct_of_tm.',
        );
      }
      return CoachResult<double>.ok(
        roundToPlate(last * (1 + spec.value), unit),
      );
    case WeightBasis.absolute:
      return CoachResult<double>.ok(roundToPlate(spec.value, unit));
  }
}

String _show(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';
