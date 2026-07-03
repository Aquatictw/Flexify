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
}
