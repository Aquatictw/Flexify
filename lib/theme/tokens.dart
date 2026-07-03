import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../timer/timer_state.dart';
import '../workouts/workout_state.dart';

// Design tokens — the single source of truth for the "Forged iron" identity.
// See .planning/design/DESIGN-PLAN.md.

// Spacing
const space4 = 4.0;
const space8 = 8.0;
const space12 = 12.0;
const space16 = 16.0;
const space24 = 24.0;
const space32 = 32.0;

// Radii
const radiusSm = 10.0;
const radiusMd = 16.0;
const radiusLg = 24.0;
const radiusPill = 999.0;
const brSm = BorderRadius.all(Radius.circular(radiusSm));
const brMd = BorderRadius.all(Radius.circular(radiusMd));
const brLg = BorderRadius.all(Radius.circular(radiusLg));
const brPill = BorderRadius.all(Radius.circular(radiusPill));

// Motion
const durFast = Duration(milliseconds: 150);
const durMed = Duration(milliseconds: 250);
const durSlow = Duration(milliseconds: 400);
const curveStandard = Curves.easeOutCubic;
const curveEmphasized = Curves.easeInOutCubicEmphasized;

/// Bottom padding for scrollables on the home tabs so content clears the
/// floating pill nav plus whichever timer/active-workout bars are visible.
/// Call from build(); it watches the relevant states.
double bottomBarClearance(BuildContext context) {
  var clearance = 96.0; // pill nav + breathing room
  final timer = context.watch<TimerState>().timer;
  if (timer.getDuration() != Duration.zero &&
      timer.getRemaining().inSeconds > 0) {
    clearance += 56;
  }
  if (context.watch<WorkoutState>().activeWorkout != null) clearance += 64;
  return clearance;
}

/// Brightness-aware semantic colors. Usage: `context.jl.warmup`.
extension JlColorsX on BuildContext {
  JlColors get jl => JlColors(Theme.of(this).colorScheme);
}

class JlColors {
  const JlColors(this._scheme);
  final ColorScheme _scheme;

  bool get _dark => _scheme.brightness == Brightness.dark;

  Color get working => _scheme.primary;
  Color get warmup => _dark ? const Color(0xFFFFB74D) : const Color(0xFFB26A00);
  Color get dropSet =>
      _dark ? const Color(0xFFCE93D8) : const Color(0xFF7B1FA2);
  Color get pr => _dark ? const Color(0xFFFFD54F) : const Color(0xFF9A7B00);
  Color get success =>
      _dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
  Color get danger => _scheme.error;

  // Push / Pull / Legs identity colors for the history feed. Fixed hues,
  // independent of the app theme, so the rails stay distinguishable (orange /
  // blue / green) whatever primary color the user picks.
  Color get push => _dark ? const Color(0xFFFF8A65) : const Color(0xFFE64A19);
  Color get pull => _dark ? const Color(0xFF9575CD) : const Color(0xFF5E35B1);
  Color get legs =>
      _dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
  Color get otherMuscle => _scheme.onSurfaceVariant;

  Color muscleColor(MuscleGroup g) => switch (g) {
        MuscleGroup.push => push,
        MuscleGroup.pull => pull,
        MuscleGroup.legs => legs,
        MuscleGroup.other => otherMuscle,
      };
}

enum MuscleGroup { push, pull, legs, other }

String muscleLabel(MuscleGroup g) => switch (g) {
      MuscleGroup.push => 'Push',
      MuscleGroup.pull => 'Pull',
      MuscleGroup.legs => 'Legs',
      MuscleGroup.other => 'Other',
    };

/// Bucket a set into Push / Pull / Legs. The stored `category` is authoritative
/// when recognized; otherwise fall back to keywords in the exercise name.
/// Core, cardio, and anything unknown fall through to `other` (grey).
// ponytail: keyword heuristic, not a real muscle DB — good enough for freeform
// logs; swap for a name→muscle table if it ever misclassifies noticeably.
MuscleGroup muscleGroupOf(String? category, String name) {
  final c = category?.toLowerCase().trim() ?? '';
  if (c.contains('chest') ||
      c.contains('shoulder') ||
      c.contains('tricep') ||
      c == 'push') return MuscleGroup.push;
  if (c.contains('back') || c.contains('bicep') || c == 'pull')
    return MuscleGroup.pull;
  if (c.contains('leg') ||
      c.contains('quad') ||
      c.contains('hamstring') ||
      c.contains('glute') ||
      c.contains('calf') ||
      c.contains('calv')) return MuscleGroup.legs;

  // Name fallback — order matters: legs first catches "leg press"/"leg curl".
  final n = name.toLowerCase();
  bool has(List<String> ks) => ks.any(n.contains);
  if (has(const [
    'squat', 'leg', 'calf', 'calv', 'lunge', 'hamstring', 'quad', 'glute',
  ])) {
    return MuscleGroup.legs;
  }
  if (has(const [
    'row', 'pull', 'deadlift', 'curl', 'chin', 'shrug', 'face', 'rear',
  ])) {
    return MuscleGroup.pull;
  }
  if (has(const [
    'bench', 'press', 'dip', 'fly', 'pushdown', 'skull', 'tricep', 'overhead',
    'lateral', 'push',
  ])) {
    return MuscleGroup.push;
  }
  return MuscleGroup.other;
}
