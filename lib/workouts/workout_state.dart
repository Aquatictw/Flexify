import 'package:drift/drift.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WorkoutState extends ChangeNotifier {
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

  WorkoutState() {
    _loadActiveWorkout();
  }

  Future<void> _loadActiveWorkout() async {
    // Find workout that has no endTime (still ongoing)
    final workout = await (db.workouts.select()
          ..where((w) => w.endTime.isNull())
          ..orderBy([
            (w) => OrderingTerm(expression: w.startTime, mode: OrderingMode.desc)
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

    final workoutName =
        plan.title?.isNotEmpty == true ? plan.title! : plan.days.replaceAll(",", ", ");

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

  Future<void> stopWorkout() async {
    if (_activeWorkout == null) return;

    await (db.workouts.update()..where((w) => w.id.equals(_activeWorkout!.id)))
        .write(WorkoutsCompanion(endTime: Value(DateTime.now().toLocal())));

    _activeWorkout = null;
    _activePlan = null;
    notifyListeners();
  }

  Future<void> discardWorkout() async {
    if (_activeWorkout == null) return;

    // Delete all gym sets associated with this workout
    await (db.gymSets.delete()
          ..where((tbl) => tbl.workoutId.equals(_activeWorkout!.id)))
        .go();

    // Delete the workout itself
    await (db.workouts.delete()
          ..where((w) => w.id.equals(_activeWorkout!.id)))
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
}
