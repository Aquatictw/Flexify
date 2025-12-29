import 'package:drift/drift.dart' hide Column;
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/plan/exercise_sets_card.dart';
import 'package:flexify/plan/plan_state.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/workouts/workout_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StartPlanPage extends StatefulWidget {
  final Plan plan;

  const StartPlanPage({super.key, required this.plan});

  @override
  createState() => _StartPlanPageState();
}

class _StartPlanPageState extends State<StartPlanPage> {
  int? workoutId;
  late Stream<List<PlanExercise>> stream;
  late String title = widget.plan.days.replaceAll(",", ", ");
  Set<int> expandedExercises = {};

  @override
  void initState() {
    super.initState();
    title = widget.plan.title?.isNotEmpty == true
        ? widget.plan.title!
        : widget.plan.days.replaceAll(",", ", ");

    // Listen for workout state changes to pop when workout ends
    final workoutState = context.read<WorkoutState>();
    workoutState.addListener(_onWorkoutStateChanged);

    _loadExercises();
  }

  void _onWorkoutStateChanged() {
    final workoutState = context.read<WorkoutState>();
    // If workout was ended (no active workout), pop this page
    if (!workoutState.hasActiveWorkout && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadExercises() async {
    setState(() {
      stream = (db.planExercises.select()
            ..where(
              (pe) => pe.planId.equals(widget.plan.id) & pe.enabled,
            )
            ..orderBy(
              [
                (u) => OrderingTerm(
                      expression: u.sequence,
                      mode: OrderingMode.asc,
                    ),
              ],
            ))
          .watch();
    });

    // Use WorkoutState to get or create workout session
    final workoutState = context.read<WorkoutState>();
    if (workoutState.activeWorkout != null &&
        workoutState.activePlan?.id == widget.plan.id) {
      // Resume existing workout
      setState(() {
        workoutId = workoutState.activeWorkout!.id;
      });
    } else if (workoutState.activeWorkout == null) {
      // Create a new workout session
      final workout = await workoutState.startWorkout(widget.plan);
      if (workout != null) {
        setState(() {
          workoutId = workout.id;
        });
      }
    } else {
      // There's an active workout for a different plan - use its ID
      setState(() {
        workoutId = workoutState.activeWorkout!.id;
      });
    }

    // Update gym counts with workoutId to show only this workout's progress
    final planState = context.read<PlanState>();
    await planState.updateGymCounts(widget.plan.id, workoutId);

    // Expand first exercise by default
    final exercises = await stream.first;
    if (exercises.isNotEmpty && mounted) {
      setState(() {
        expandedExercises.add(0);
      });
    }
  }

  @override
  void dispose() {
    final workoutState = context.read<WorkoutState>();
    workoutState.removeListener(_onWorkoutStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plan.title?.isNotEmpty == true) title = widget.plan.title!;

    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final exercises = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 160),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return ExerciseSetsCard(
                key: ValueKey(exercise.id),
                exercise: exercise,
                planId: widget.plan.id,
                workoutId: workoutId,
                isExpanded: expandedExercises.contains(index),
                onToggleExpand: () {
                  setState(() {
                    if (expandedExercises.contains(index)) {
                      expandedExercises.remove(index);
                    } else {
                      expandedExercises.add(index);
                    }
                  });
                },
                onSetCompleted: () {
                  // Optionally auto-expand next exercise when current is complete
                  _checkAutoExpandNext(exercises, index);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _checkAutoExpandNext(List<PlanExercise> exercises, int currentIndex) {
    // This is called after a set is completed
    // We could add logic here to auto-expand the next exercise
    // when the current one is fully complete
  }
}
