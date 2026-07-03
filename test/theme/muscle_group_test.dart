import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/theme/tokens.dart';

void main() {
  test('category is authoritative', () {
    expect(muscleGroupOf('Chest', 'Anything'), MuscleGroup.push);
    expect(muscleGroupOf('Shoulders', 'x'), MuscleGroup.push);
    expect(muscleGroupOf('Back', 'x'), MuscleGroup.pull);
    expect(muscleGroupOf('Legs', 'Romanian Deadlift'), MuscleGroup.legs);
    expect(muscleGroupOf('Calves', 'x'), MuscleGroup.legs);
  });

  test('name fallback when category missing/unknown', () {
    expect(muscleGroupOf(null, 'Bench Press'), MuscleGroup.push);
    expect(muscleGroupOf(null, 'Tricep Pushdown'), MuscleGroup.push);
    expect(muscleGroupOf(null, 'Barbell Row'), MuscleGroup.pull);
    expect(muscleGroupOf(null, 'Pull Up'), MuscleGroup.pull);
    expect(muscleGroupOf(null, 'Squat'), MuscleGroup.legs);
    expect(muscleGroupOf(null, 'Leg Press'), MuscleGroup.legs);
  });

  test('core / cardio / unknown fall through to other', () {
    expect(muscleGroupOf('Core', 'Plank'), MuscleGroup.other);
    expect(muscleGroupOf(null, 'Treadmill'), MuscleGroup.other);
    expect(muscleGroupOf(null, 'Meditation'), MuscleGroup.other);
  });
}
