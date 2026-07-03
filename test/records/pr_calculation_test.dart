import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/records/records_service.dart';

void main() {
  group('calculate1RM (Brzycki)', () {
    test('5 reps: weight / (1.0278 - 0.0278 * reps)', () {
      expect(calculate1RM(225, 5), closeTo(253.15, 0.01));
    });

    test('10 reps', () {
      expect(calculate1RM(135, 10), closeTo(180.05, 0.01));
    });

    test('1 rep returns the weight unchanged', () {
      expect(calculate1RM(315, 1), 315.0);
    });

    test('0 reps returns 0', () {
      expect(calculate1RM(100, 0), 0.0);
    });

    test('negative reps returns 0', () {
      expect(calculate1RM(100, -3), 0.0);
    });

    test('0 weight returns 0', () {
      expect(calculate1RM(0, 10), 0.0);
    });

    test('estimated 1RM is >= the lifted weight for multi-rep sets', () {
      expect(calculate1RM(100, 8), greaterThan(100));
    });

    test('negative weight (assisted lift) uses inverted formula', () {
      // weight * (1.0278 - 0.0278 * reps) keeps the result negative and
      // makes a less-assisted (heavier, i.e. closer to 0) set rank higher.
      expect(calculate1RM(-50, 5), closeTo(-44.44, 0.01));
      expect(calculate1RM(-30, 5), greaterThan(calculate1RM(-50, 5)));
    });
  });

  group('calculateVolume', () {
    test('weight * reps', () {
      expect(calculateVolume(225, 10), 2250.0);
    });

    test('zero weight', () {
      expect(calculateVolume(0, 10), 0.0);
    });

    test('zero reps', () {
      expect(calculateVolume(100, 0), 0.0);
    });

    test('fractional reps', () {
      expect(calculateVolume(100, 5.5), 550.0);
    });
  });

  group('RecordAchievement.improvement', () {
    test('percentage gain over previous best', () {
      const a = RecordAchievement(
        type: RecordType.best1RM,
        newValue: 110,
        previousValue: 100,
        unit: 'kg',
      );
      expect(a.improvement, closeTo(10.0, 0.001));
    });

    test('no previous value returns 0', () {
      const a = RecordAchievement(
        type: RecordType.bestWeight,
        newValue: 100,
        unit: 'kg',
      );
      expect(a.improvement, 0);
    });

    test('previous value of 0 returns 0 (avoids divide-by-zero)', () {
      const a = RecordAchievement(
        type: RecordType.bestWeight,
        newValue: 100,
        previousValue: 0,
        unit: 'kg',
      );
      expect(a.improvement, 0);
    });
  });
}
