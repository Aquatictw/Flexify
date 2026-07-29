import '../database/database.dart';
import 'schemes.dart';

/// The four 5/3/1 main lifts, mapped to the training max they load from.
///
/// Matching is exact (case-insensitive) rather than a substring test, so
/// accessory work like "Incline Bench Press", "Leg Press" or "Front Squat"
/// never gets auto-filled from a training max it does not belong to.
const Map<String, String> mainLiftTmKeys = {
  'bench press': 'bench',
  'squat': 'squat',
  'deadlift': 'deadlift',
  'overhead press': 'press',
  'seated overhead press': 'press',
};

/// The training-max key for [exerciseName], or null if it is not a main lift.
String? mainLiftTmKey(String exerciseName) =>
    mainLiftTmKeys[exerciseName.trim().toLowerCase()];

/// The training max [block] holds for [tmKey], in `block.unit`.
double trainingMaxFor(FiveThreeOneBlock block, String tmKey) {
  switch (tmKey) {
    case 'squat':
      return block.squatTm;
    case 'bench':
      return block.benchTm;
    case 'deadlift':
      return block.deadliftTm;
    case 'press':
      return block.pressTm;
    default:
      return 0;
  }
}

/// One prescribed set: bar weight already rounded to a loadable increment.
typedef PrescribedSet = ({double weight, int reps, bool amrap});

/// Rounds to the nearest increment that can actually be loaded on the bar —
/// 2.5 kg or 5 lb, matching the 5/3/1 calculator.
double roundToPlate(double weight, String unit) {
  final increment = unit == 'kg' ? 2.5 : 5.0;
  return (weight / increment).round() * increment;
}

/// The main-work prescription for [exerciseName] at [block]'s current cycle and
/// week, or null when the exercise is not a main lift, its training max is
/// unset, or the block sits on a position with no scheme.
///
/// Set count follows the scheme: 3 for Leader/Anchor weeks, 4 for the 7th-week
/// protocols. Supplemental work (BBB/FSL) is deliberately not included —
/// auto-fill covers main work only.
List<PrescribedSet>? mainWorkPrescription({
  required FiveThreeOneBlock block,
  required String exerciseName,
}) {
  final tmKey = mainLiftTmKey(exerciseName);
  if (tmKey == null) return null;

  final tm = trainingMaxFor(block, tmKey);
  if (tm <= 0) return null;

  final scheme = getMainScheme(
    cycleType: block.currentCycle,
    week: block.currentWeek,
  );
  if (scheme.isEmpty) return null;

  return scheme
      .map(
        (set) => (
          weight: roundToPlate(tm * set.percentage, block.unit),
          reps: set.reps,
          amrap: set.amrap,
        ),
      )
      .toList();
}
