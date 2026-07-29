import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/coach/weight_spec.dart';

void main() {
  group('parseWeightSpec', () {
    test('accepts each of the four bases', () {
      final cases = <String, WeightBasis>{
        'pct_of_tm': WeightBasis.pctOfTm,
        'pct_of_prescribed': WeightBasis.pctOfPrescribed,
        'pct_of_last_session': WeightBasis.pctOfLastSession,
        'absolute': WeightBasis.absolute,
      };
      for (final entry in cases.entries) {
        final value = entry.key == 'absolute' ? 60 : 0.9;
        final parsed = parseWeightSpec(<String, Object?>{entry.key: value});
        expect(parsed.isError, isFalse, reason: entry.key);
        expect(parsed.value!.basis, entry.value);
        expect(parsed.value!.value, value.toDouble());
      }
    });

    test('accepts a zero delta as "exactly as prescribed"', () {
      final parsed = parseWeightSpec(<String, Object?>{'pct_of_prescribed': 0});
      expect(parsed.isError, isFalse);
      expect(parsed.value!.value, 0);
    });

    test('rejects percentage points for pct_of_prescribed', () {
      // The Phase A regression: a live model emitted -5 for "5% lighter".
      final parsed = parseWeightSpec(<String, Object?>{'pct_of_prescribed': -5});
      expect(parsed.isError, isTrue);
      expect(parsed.error, contains('signed fraction'));
      expect(parsed.error, contains('-500%'));
    });

    test('rejects percentage points for pct_of_last_session', () {
      final parsed =
          parseWeightSpec(<String, Object?>{'pct_of_last_session': 10});
      expect(parsed.isError, isTrue);
      expect(parsed.error, contains('signed fraction'));
    });

    test('rejects a delta of -1 or beyond, which would mean zero weight', () {
      expect(
        parseWeightSpec(<String, Object?>{'pct_of_prescribed': -1}).isError,
        isTrue,
      );
      expect(
        parseWeightSpec(<String, Object?>{'pct_of_prescribed': -1.5}).isError,
        isTrue,
      );
    });

    test('accepts deltas at the edge of the allowed band', () {
      expect(
        parseWeightSpec(<String, Object?>{'pct_of_prescribed': -0.999}).isError,
        isFalse,
      );
      expect(
        parseWeightSpec(<String, Object?>{'pct_of_prescribed': 1}).isError,
        isFalse,
      );
    });

    test('rejects percentage points for pct_of_tm', () {
      final parsed = parseWeightSpec(<String, Object?>{'pct_of_tm': 90});
      expect(parsed.isError, isTrue);
      expect(parsed.error, contains('fraction of the training max'));
    });

    test('rejects a non-positive or absurd pct_of_tm', () {
      expect(parseWeightSpec(<String, Object?>{'pct_of_tm': 0}).isError, isTrue);
      expect(
        parseWeightSpec(<String, Object?>{'pct_of_tm': -0.9}).isError,
        isTrue,
      );
      expect(
        parseWeightSpec(<String, Object?>{'pct_of_tm': 1.6}).isError,
        isTrue,
      );
    });

    test('rejects two bases at once', () {
      final parsed = parseWeightSpec(<String, Object?>{
        'pct_of_tm': 0.9,
        'absolute': 100,
      });
      expect(parsed.isError, isTrue);
      expect(parsed.error, contains('exactly one'));
    });

    test('rejects an empty spec, a bare number and a null', () {
      expect(parseWeightSpec(<String, Object?>{}).isError, isTrue);
      expect(parseWeightSpec(60).isError, isTrue);
      expect(parseWeightSpec(null).isError, isTrue);
    });

    test('rejects a unit key: units are never in tool arguments', () {
      final parsed = parseWeightSpec(<String, Object?>{
        'absolute': 60,
        'unit': 'kg',
      });
      expect(parsed.isError, isTrue);
      expect(parsed.error, contains("does not take 'unit'"));
    });

    test('rejects a non-numeric or non-finite value', () {
      expect(
        parseWeightSpec(<String, Object?>{'absolute': '60'}).isError,
        isTrue,
      );
      expect(
        parseWeightSpec(<String, Object?>{'absolute': double.infinity}).isError,
        isTrue,
      );
    });

    test('rejects a non-positive absolute', () {
      expect(parseWeightSpec(<String, Object?>{'absolute': 0}).isError, isTrue);
      expect(parseWeightSpec(<String, Object?>{'absolute': -60}).isError, true);
    });
  });

  group('resolveWeightSpec', () {
    CoachResult<double> resolve(
      WeightSpec spec, {
      String unit = 'kg',
      WeightBases bases = const WeightBases(),
    }) =>
        resolveWeightSpec(
          spec: spec,
          exercise: 'Bench Press',
          unit: unit,
          bases: bases,
        );

    test('pct_of_tm multiplies the training max and rounds to plates', () {
      final result = resolve(
        const WeightSpec(WeightBasis.pctOfTm, 0.9),
        bases: const WeightBases(trainingMax: 102),
      );
      // 91.8 -> nearest 2.5 kg
      expect(result.value, 92.5);
    });

    test('pct_of_prescribed applies a signed delta to the prescribed weight',
        () {
      expect(
        resolve(
          const WeightSpec(WeightBasis.pctOfPrescribed, -0.05),
          bases: const WeightBases(prescribed: 70),
        ).value,
        67.5, // 66.5 -> 67.5
      );
      expect(
        resolve(
          const WeightSpec(WeightBasis.pctOfPrescribed, 0),
          bases: const WeightBases(prescribed: 80),
        ).value,
        80,
      );
      expect(
        resolve(
          const WeightSpec(WeightBasis.pctOfPrescribed, 0.1),
          bases: const WeightBases(prescribed: 90),
        ).value,
        100, // 99 -> 100
      );
    });

    test('pct_of_last_session applies a signed delta to last session', () {
      expect(
        resolve(
          const WeightSpec(WeightBasis.pctOfLastSession, -0.05),
          bases: const WeightBases(lastSession: 100),
        ).value,
        95,
      );
    });

    test('absolute passes the number through the plate rounding', () {
      expect(
        resolve(const WeightSpec(WeightBasis.absolute, 61)).value,
        60,
      );
    });

    test('rounds to 2.5 in kg and 5 in lb', () {
      const spec = WeightSpec(WeightBasis.absolute, 63);
      expect(resolve(spec).value, 62.5);
      expect(resolve(spec, unit: 'lb').value, 65);
    });

    test('a missing training max is a model-facing error, not a throw', () {
      final result = resolveWeightSpec(
        spec: const WeightSpec(WeightBasis.pctOfTm, 0.9),
        exercise: 'Lat Pulldown',
        unit: 'kg',
        bases: const WeightBases(),
      );
      expect(result.isError, isTrue);
      expect(result.value, isNull);
      expect(
        result.error,
        'Lat Pulldown has no training max; use an absolute weight or '
        'pct_of_last_session.',
      );
    });

    test('a zero training max is treated as unset', () {
      final result = resolve(
        const WeightSpec(WeightBasis.pctOfTm, 0.9),
        bases: const WeightBases(trainingMax: 0),
      );
      expect(result.isError, isTrue);
    });

    test('a missing prior session is a model-facing error', () {
      final result = resolve(
        const WeightSpec(WeightBasis.pctOfLastSession, -0.05),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('no previous session'));
    });

    test('a missing prescription is a model-facing error', () {
      final result = resolve(
        const WeightSpec(WeightBasis.pctOfPrescribed, -0.05),
      );
      expect(result.isError, isTrue);
      expect(result.error, contains('no prescribed weight'));
    });
  });
}
