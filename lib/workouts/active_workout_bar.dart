import 'dart:async';

import 'package:flexify/database/database.dart';
import 'package:flexify/plan/start_plan_page.dart';
import 'package:flexify/timer/timer_state.dart';
import 'package:flexify/workouts/workout_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      if (mounted) {
        setState(() {
          final workoutState = context.read<WorkoutState>();
          if (workoutState.activeWorkout != null) {
            _elapsed = DateTime.now()
                .difference(workoutState.activeWorkout!.startTime);
          }
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

  void _navigateToWorkout(GlobalKey<NavigatorState>? navKey, Plan plan) {
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

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (plan != null) {
              final navKey = workoutState.plansNavigatorKey;
              final tabController = workoutState.tabController;
              final plansIndex = workoutState.plansTabIndex;

              // First, switch to Plans tab if not already there
              if (tabController != null && plansIndex >= 0) {
                if (tabController.index != plansIndex) {
                  tabController.animateTo(plansIndex);
                  // Wait for tab switch animation, then navigate
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _navigateToWorkout(navKey, plan);
                  });
                  return;
                }
              }

              // Already on Plans tab, navigate directly
              _navigateToWorkout(navKey, plan);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        workout.name ?? 'Workout',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(_elapsed),
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.7),
                          fontSize: 12,
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
                      useRootNavigator: true,
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
                    if (confirmed == true) {
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
                const SizedBox(width: 4),
                // End button
                IconButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      useRootNavigator: true,
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
                    if (confirmed == true) {
                      final timerState = context.read<TimerState>();
                      await timerState.stopTimer();
                      await workoutState.stopWorkout();
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
      ),
    );
  }
}
