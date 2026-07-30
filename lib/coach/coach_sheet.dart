import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'coach_state.dart';
import 'widgets/coach_thread.dart';

/// How much of the screen the in-workout sheet takes, fixed.
///
/// It used to be a [DraggableScrollableSheet], which grew as the thread was
/// scrolled — the height changing under a conversation you are reading is
/// distracting, and it never reached full screen anyway.
const double _sheetHeightFraction = 0.75;

/// Floor on what is left for the thread once the keyboard has taken its cut.
/// On a short screen a tall keyboard could otherwise eat the whole sheet.
const double _minContent = 180;

/// Opens the in-workout coach over the live session.
///
/// The sheet binds to the app-level [WorkoutCoachState] rather than creating a
/// [CoachState] of its own — a turn keeps running after the sheet is dismissed,
/// and a state that dies with the sheet takes the thinking indicator and every
/// row written after that point with it. It is deliberately *not* the state the
/// Coach tab is bound to: one notifier holds one thread scope at a time, so
/// sharing it would let the tab's ad-hoc thread and this workout thread fight
/// over that scope while both are mounted (PRD decision 6).
Future<void> showCoachSheet(
  BuildContext context, {
  required int workoutId,
  void Function(CoachSessionChange change)? onSessionChanged,
}) {
  final coach = context.read<WorkoutCoachState>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The Plans tab runs its own nested Navigator, whose overlay sits *below*
    // the home Stack's active-workout bar and pill nav — a sheet pushed there
    // has its composer painted under both, and the modal barrier leaves the
    // nav tappable. Every other modal in the app roots itself for the same
    // reason, including the plate calculator in this same app bar.
    useRootNavigator: true,
    builder: (context) {
      final height =
          MediaQuery.sizeOf(context).height * _sheetHeightFraction;
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      // No Material/rounding here: bottomSheetTheme already supplies the
      // surface colour and the rounded top, and its showDragHandle draws the
      // grabber. Re-adding either nests a second rounded panel and a second
      // handle inside the real ones.
      return SizedBox(
        // Fixed, and the keyboard inset is applied *inside* it rather than
        // around it. Padding the outside would lift the whole sheet by the
        // keyboard's height, moving the top edge; padding the inside pulls the
        // composer up off the keyboard while the top edge stays put.
        height: height,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(
            bottom: math.min(bottomInset, math.max(0, height - _minContent)),
          ),
          child: ChangeNotifierProvider<CoachState>.value(
            value: coach,
            child: CoachThread(
              workoutId: workoutId,
              onSessionChanged: onSessionChanged,
              autofocus: true,
            ),
          ),
        ),
      );
    },
  );
}
