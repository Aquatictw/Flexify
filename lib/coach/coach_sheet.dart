import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'coach_state.dart';
import 'widgets/coach_thread.dart';

/// Opens the in-workout coach over the live session.
///
/// The sheet runs on its own [CoachState], deliberately *not* the one the
/// Coach tab is bound to: a single notifier can only hold one thread scope at
/// a time, so sharing it would let the tab's ad-hoc thread and this workout
/// thread fight over that scope while both are mounted (PRD decision 6 —
/// two threads, never mixed).
Future<void> showCoachSheet(
  BuildContext context, {
  required int workoutId,
  VoidCallback? onSessionChanged,
}) {
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
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(bottom: bottomInset),
          // No Material/rounding here: bottomSheetTheme already supplies the
          // surface colour and the rounded top, and its showDragHandle draws
          // the grabber. Re-adding either nests a second rounded panel and a
          // second handle inside the real ones.
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Row(
                  children: [
                    Text(
                      'Coach',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ChangeNotifierProvider<CoachState>(
                  create: (_) => CoachState(),
                  child: CoachThread(
                    workoutId: workoutId,
                    onSessionChanged: onSessionChanged,
                    scrollController: scrollController,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
