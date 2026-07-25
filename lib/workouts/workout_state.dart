import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../database/database.dart';
import '../main.dart';

class WorkoutState extends ChangeNotifier {
  WorkoutState() {
    // Initialize asynchronously with error handling
    _loadActiveWorkout().catchError((error) {
      print('⚠️ Error loading active workout: $error');
      // Don't crash, just continue with no active workout
    });
  }
  Workout? _activeWorkout;
  Plan? _activePlan;
  GlobalKey<NavigatorState>? _plansNavigatorKey;
  TabController? _tabController;
  int _plansTabIndex = 0;

  Workout? get activeWorkout => _activeWorkout;
  Plan? get activePlan => _activePlan;
  bool get hasActiveWorkout => _activeWorkout != null;
  GlobalKey<NavigatorState>? get plansNavigatorKey => _plansNavigatorKey;
  TabController? get tabController => _tabController;
  int get plansTabIndex => _plansTabIndex;

  void setPlansNavigatorKey(GlobalKey<NavigatorState> key) {
    _plansNavigatorKey = key;
  }

  void setTabController(TabController controller, int plansIndex) {
    _tabController = controller;
    _plansTabIndex = plansIndex;
  }

  /// Switch to the Plans tab and wait for its nested navigator to be mounted.
  ///
  /// Plans is created on first visit, so the key can still be null (or its
  /// state not yet attached) when a caller wants to push onto it — poll rather
  /// than capture it up front.
  Future<NavigatorState?> openPlansNavigator() async {
    final controller = _tabController;
    if (controller != null &&
        _plansTabIndex >= 0 &&
        controller.index != _plansTabIndex) {
      controller.animateTo(_plansTabIndex);
    }
    for (var attempts = 0; attempts < 20; attempts++) {
      final state = _plansNavigatorKey?.currentState;
      if (state != null) return state;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return _plansNavigatorKey?.currentState;
  }

  Future<void> _loadActiveWorkout() async {
    // Find workout that has no endTime (still ongoing)
    final workout = await (db.workouts.select()
          ..where((w) => w.endTime.isNull())
          ..orderBy([
            (w) =>
                OrderingTerm(expression: w.startTime, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (workout != null) {
      _activeWorkout = workout;
      if (workout.planId != null) {
        _activePlan = await (db.plans.select()
              ..where((p) => p.id.equals(workout.planId!)))
            .getSingleOrNull();
      } else {
        // Freeform workout - create temporary plan so overlay click works
        _activePlan = Plan(
          id: -1,
          days: workout.name ?? 'Workout',
          sequence: 0,
          title: workout.name ?? 'Workout',
        );
      }
      notifyListeners();
    }
  }

  Future<Workout?> startWorkout(Plan plan) async {
    if (_activeWorkout != null) {
      return null; // Cannot start a new workout while one is active
    }

    final workoutName = plan.title?.isNotEmpty ?? false
        ? plan.title!
        : plan.days.replaceAll(',', ', ');

    final workout = await db.into(db.workouts).insertReturning(
          WorkoutsCompanion.insert(
            startTime: DateTime.now().toLocal(),
            planId: Value(plan.id),
            name: Value(workoutName),
          ),
        );

    _activeWorkout = workout;
    _activePlan = plan;
    notifyListeners();
    return workout;
  }

  Future<void> stopWorkout({String? selfieImagePath}) async {
    if (_activeWorkout == null) return;

    await (db.workouts.update()..where((w) => w.id.equals(_activeWorkout!.id)))
        .write(
      WorkoutsCompanion(
        endTime: Value(DateTime.now().toLocal()),
        selfieImagePath: Value(selfieImagePath),
      ),
    );

    _activeWorkout = null;
    _activePlan = null;
    notifyListeners();
  }

  Future<void> discardWorkout() async {
    if (_activeWorkout == null) return;

    // Delete selfie file if it exists
    if (_activeWorkout!.selfieImagePath != null) {
      try {
        final file = File(_activeWorkout!.selfieImagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore file deletion errors
      }
    }

    // Delete all gym sets associated with this workout
    await (db.gymSets.delete()
          ..where((tbl) => tbl.workoutId.equals(_activeWorkout!.id)))
        .go();

    // Delete the workout itself
    await (db.workouts.delete()..where((w) => w.id.equals(_activeWorkout!.id)))
        .go();

    _activeWorkout = null;
    _activePlan = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadActiveWorkout();
  }

  void clearActiveWorkout() {
    _activeWorkout = null;
    _activePlan = null;
    notifyListeners();
  }

  void setActiveWorkout(Workout workout, Plan? plan) {
    _activeWorkout = workout;
    _activePlan = plan;
    notifyListeners();
  }

  Future<Plan?> resumeWorkout(Workout workout) async {
    if (_activeWorkout != null && _activeWorkout!.id != workout.id) {
      return null; // Cannot resume a different workout while one is active
    }

    // Calculate the original workout duration
    final originalDuration = workout.endTime != null
        ? workout.endTime!.difference(workout.startTime)
        : Duration.zero;

    // Adjust startTime so the timer continues from where it left off
    final newStartTime = DateTime.now().toLocal().subtract(originalDuration);

    // Update the workout with new startTime and cleared endTime
    await (db.workouts.update()..where((w) => w.id.equals(workout.id))).write(
      WorkoutsCompanion(
        startTime: Value(newStartTime),
        endTime: const Value(null),
      ),
    );

    // Load the updated workout
    final updatedWorkout = await (db.workouts.select()
          ..where((w) => w.id.equals(workout.id)))
        .getSingleOrNull();

    // Return null if workout was deleted
    if (updatedWorkout == null) {
      print('⚠️ Workout not found after resume update');
      return null;
    }

    // Load the associated plan
    Plan? plan;
    if (updatedWorkout.planId != null) {
      plan = await (db.plans.select()
            ..where((p) => p.id.equals(updatedWorkout.planId!)))
          .getSingleOrNull();
    } else {
      // Freeform workout - create temporary plan
      plan = Plan(
        id: -1,
        days: updatedWorkout.name ?? 'Workout',
        sequence: 0,
        title: updatedWorkout.name ?? 'Workout',
      );
    }

    _activeWorkout = updatedWorkout;
    _activePlan = plan;
    notifyListeners();
    return plan;
  }
}
