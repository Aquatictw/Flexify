import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../plan/start_plan_page.dart';
import '../theme/tokens.dart';
import '../timer/timer_state.dart';
import 'selfie_capture_dialog.dart';
import 'workout_state.dart';

class ActiveWorkoutBar extends StatefulWidget {
  const ActiveWorkoutBar({super.key});

  @override
  State<ActiveWorkoutBar> createState() => _ActiveWorkoutBarState();
}

class _ActiveWorkoutBarState extends State<ActiveWorkoutBar> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return; // Exit early if widget disposed

      final workoutState = context.read<WorkoutState>();
      if (workoutState.activeWorkout != null) {
        setState(() {
          _elapsed = DateTime.now()
              .difference(workoutState.activeWorkout!.startTime);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Future<void> _navigateToWorkout(
      GlobalKey<NavigatorState>? navKey, Plan plan,) async {
    // Wait for navigator to be ready (up to 2 seconds)
    int attempts = 0;
    while (navKey?.currentState == null && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (navKey?.currentState == null) return;

    final navigator = navKey!.currentState!;

    // Check if we're already on the StartPlanPage for this plan by popping until we find it
    bool foundTargetPage = false;

    navigator.popUntil((route) {
      if (route.settings.name == 'StartPlanPage_${plan.id}') {
        // Found the target page, stop popping here
        foundTargetPage = true;
        return true;
      }
      // Continue popping until we reach the first route
      return route.isFirst;
    });

    // If we found the target page, we're already there - do nothing
    if (foundTargetPage) {
      return;
    }

    // Target page not found in stack, push it
    navigator.push(
      MaterialPageRoute(
        builder: (context) => StartPlanPage(plan: plan),
        settings: RouteSettings(name: 'StartPlanPage_${plan.id}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = context.watch<WorkoutState>();
    final workout = workoutState.activeWorkout;
    final plan = workoutState.activePlan;

    if (workout == null) return const SizedBox.shrink();

    _elapsed = DateTime.now().difference(workout.startTime);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (plan != null) {
          final navKey = workoutState.plansNavigatorKey;
          final tabController = workoutState.tabController;
          final plansIndex = workoutState.plansTabIndex;

          // First, switch to Plans tab if not already there
          if (tabController != null && plansIndex >= 0) {
            if (tabController.index != plansIndex) {
              tabController.animateTo(plansIndex);
            }
          }

          // Navigate to workout (will wait for navigator to be ready)
          _navigateToWorkout(navKey, plan);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(
            left: space12, right: space12, top: space8, bottom: space4,),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: brSm,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: space12, vertical: space8,),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(space8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: brSm,
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      workout.name ?? 'Workout',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: space4),
                    Text(
                      _formatDuration(_elapsed),
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
              // Discard button
              IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Discard Workout?'),
                      content: const Text(
                        'All sets from this workout will be permanently deleted. This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Discard'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed ?? false) {
                    final timerState = context.read<TimerState>();
                    await timerState.stopTimer();
                    await workoutState.discardWorkout();
                  }
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                  size: 18,
                ),
                tooltip: 'Discard workout',
              ),
              const SizedBox(width: space4),
              // End button
              IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('End Workout?'),
                      content: const Text(
                        'Are you sure you want to end this workout session?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('End'),
                        ),
                      ],
                    ),
                  );

                  if ((confirmed ?? false) && context.mounted) {
                    final timerState = context.read<TimerState>();
                    await timerState.stopTimer();

                    // Prompt for selfie
                    String? selfiePath;
                    if (context.mounted) {
                      selfiePath = await showSelfieCaptureDialog(context);
                    }

                    // Stop workout with optional selfie
                    if (context.mounted) {
                      await workoutState.stopWorkout(
                          selfieImagePath: selfiePath,);
                    }
                  }
                },
                icon: Icon(
                  Icons.stop,
                  color: colorScheme.error,
                  size: 18,
                ),
                tooltip: 'End workout',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
