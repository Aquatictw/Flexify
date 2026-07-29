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
          child: Material(
            clipBehavior: Clip.antiAlias,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
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
          ),
        );
      },
    ),
  );
}
