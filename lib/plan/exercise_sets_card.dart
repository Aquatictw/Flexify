import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../database/database.dart';
import '../database/gym_sets.dart';
import '../database/query_helpers.dart';
import '../graph/cardio_page.dart';
import '../graph/strength_page.dart';
import '../main.dart';
import '../models/set_data.dart';
import '../records/record_notification.dart';
import '../records/records_service.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../timer/timer_state.dart';
import '../widgets/bodypart_tag.dart';
import '../widgets/five_three_one_calculator.dart';
import '../widgets/sets/set_row.dart';
import '../widgets/superset/superset_badge.dart';
import 'plan_state.dart';

class ExerciseSetsCard extends StatefulWidget { // Exercise order within workout

  const ExerciseSetsCard({
    required this.exercise, required this.planId, required this.workoutId, required this.isExpanded, required this.onToggleExpand, required this.onSetCompleted, super.key,
    this.onDeleteExercise,
    this.exerciseNotes,
    this.sequence = 0,
    this.onNotesChanged,
  });
  final PlanExercise exercise;
  final int planId;
  final int? workoutId;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onSetCompleted;
  final VoidCallback? onDeleteExercise;
  final String? exerciseNotes;
  final ValueChanged<String>? onNotesChanged;
  final int sequence;

  @override
  State<ExerciseSetsCard> createState() => _ExerciseSetsCardState();
}

class _ExerciseSetsCardState extends State<ExerciseSetsCard> {
  List<SetData> sets = [];
  bool _initialized = false;
  String unit = 'kg';
  double _defaultWeight = 0;
  int _defaultReps = 8;
  String? _brandName;
  String? _exerciseType;
  String? _category;
  int? _restMs; // Custom rest time for this exercise

  // Store previous sets by type for smarter set creation
  List<GymSet> _previousWarmups = [];
  List<GymSet> _previousDropSets = [];
  List<GymSet> _previousWorkingSets = [];

  // Superset information
  String? _supersetId;
  int? _supersetPosition;
  int? _supersetIndex; // Global index (A=0, B=1, etc.) for color/labeling

  @override
  void initState() {
    super.initState();
    _loadSetsData();
  }

  @override
  void didUpdateWidget(ExerciseSetsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workoutId != widget.workoutId) {
      _loadSetsData();
    }
  }

  Future<void> _loadSetsData() async {
    final settings = context.read<SettingsState>().value;
    final maxSets = widget.exercise.maxSets ?? settings.maxSets;

    // Use optimized query helper - replaces 3-5 separate queries with 1-2 queries
    final exerciseData = await QueryHelpers.loadExerciseData(
      exerciseName: widget.exercise.exercise,
      sequence: widget.sequence,
      workoutId: widget.workoutId,
    );

    // Separate previous sets by type for smart set creation
    _previousWarmups =
        exerciseData.previousSets.where((s) => s.warmup).toList();
    _previousDropSets =
        exerciseData.previousSets.where((s) => s.dropSet).toList();
    _previousWorkingSets = exerciseData.previousSets
        .where((s) => !s.warmup && !s.dropSet)
        .toList();

    // Get default values from first working set, or first set, or fallback
    GymSet? referenceSet = _previousWorkingSets.firstOrNull ??
        exerciseData.previousSets.firstOrNull;

    // If no previous completed sets, check for any set (including hidden) for metadata
    referenceSet ??= await (db.gymSets.select()
          ..where((tbl) => tbl.name.equals(widget.exercise.exercise))
          ..orderBy([
            (u) => OrderingTerm(expression: u.created, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();

    _defaultWeight = referenceSet?.weight ?? 0.0;
    _defaultReps = referenceSet?.reps.toInt() ?? 8;
    final defaultUnit = referenceSet?.unit ?? settings.strengthUnit;
    _brandName = referenceSet?.brandName;
    _exerciseType = referenceSet?.exerciseType;
    _category = referenceSet?.category;
    _restMs = referenceSet?.restMs;

    // Use existing sets from helper
    final existingSets = exerciseData.existingSets;

    // Load superset information from helper
    _supersetId = exerciseData.supersetId;
    _supersetPosition = exerciseData.supersetPosition;
    _supersetIndex = exerciseData.supersetIndex;

    if (!mounted) return;

    if (existingSets.isNotEmpty) {
      // Batch-load all records at once instead of per-set queries
      final allRecords = await QueryHelpers.batchLoadSetRecords(
        exerciseName: widget.exercise.exercise,
        sets: existingSets,
      );

      // Load existing sets from database (resuming workout)
      final loadedSets = <SetData>[];
      for (final set in existingSets) {
        loadedSets.add(SetData(
          weight: set.weight,
          reps: set.reps.toInt(),
          completed: !set.hidden, // hidden=false means completed
          savedSetId: set.id,
          isWarmup: set.warmup,
          isDropSet: set.dropSet,
          records: allRecords[set.id] ?? {},
        ),);
      }

      setState(() {
        unit = defaultUnit;
        sets = loadedSets;
        _initialized = true;
      });
    } else {
      // No existing sets - create new sets based on previous workout
      if (widget.workoutId != null) {
        final newSets = <SetData>[];

        // Count existing sets for this exercise instance to calculate starting setOrder
        final existingSetCount = await (db.gymSets.selectOnly()
              ..addColumns([db.gymSets.id.count()])
              ..where(db.gymSets.workoutId.equals(widget.workoutId!) &
                  db.gymSets.name.equals(widget.exercise.exercise) &
                  db.gymSets.sequence.equals(widget.sequence),))
            .getSingleOrNull();

        final startingSetOrder =
            existingSetCount?.read(db.gymSets.id.count()) ?? 0;

        // Create working sets based on previous working sets
        for (int i = 0; i < maxSets; i++) {
          double weight;
          int reps;

          if (i < _previousWorkingSets.length) {
            // Use the value from the corresponding previous working set
            weight = _previousWorkingSets[i].weight;
            reps = _previousWorkingSets[i].reps.toInt();
          } else if (_previousWorkingSets.isNotEmpty) {
            // Use the last previous working set value
            weight = _previousWorkingSets.last.weight;
            reps = _previousWorkingSets.last.reps.toInt();
          } else {
            // Fallback to defaults
            weight = _defaultWeight;
            reps = _defaultReps;
          }

          final gymSet = await db.into(db.gymSets).insertReturning(
                GymSetsCompanion.insert(
                  name: widget.exercise.exercise,
                  reps: reps.toDouble(),
                  weight: weight,
                  unit: defaultUnit,
                  created: DateTime.now().toLocal(),
                  planId: Value(widget.planId),
                  workoutId: Value(widget.workoutId),
                  sequence: Value(widget.sequence),
                  setOrder: Value(
                      startingSetOrder + i,), // Set position within exercise
                  hidden: const Value(true), // Uncompleted
                  brandName: Value(_brandName),
                  exerciseType: Value(_exerciseType),
                  category: Value(_category),
                  supersetId: Value(_supersetId),
                  supersetPosition: Value(_supersetPosition),
                ),
              );

          newSets.add(
            SetData(
              weight: weight,
              reps: reps,
              savedSetId: gymSet.id,
            ),
          );
        }
        if (mounted) {
          setState(() {
            unit = defaultUnit;
            sets = newSets;
            _initialized = true;
          });
        }
      } else {
        // No workout ID - memory only (shouldn't happen normally)
        setState(() {
          unit = defaultUnit;
          sets = List.generate(maxSets, (i) {
            if (i < _previousWorkingSets.length) {
              return SetData(
                weight: _previousWorkingSets[i].weight,
                reps: _previousWorkingSets[i].reps.toInt(),
              );
            } else if (_previousWorkingSets.isNotEmpty) {
              return SetData(
                weight: _previousWorkingSets.last.weight,
                reps: _previousWorkingSets.last.reps.toInt(),
              );
            } else {
              return SetData(
                weight: _defaultWeight,
                reps: _defaultReps,
              );
            }
          });
          _initialized = true;
        });
      }
    }
  }

  int get completedCount => sets.where((s) => s.completed).length;

  bool get _isMainPowerliftingExercise {
    final name = widget.exercise.exercise.toLowerCase();
    return name.contains('squat') ||
        name.contains('bench') ||
        name.contains('deadlift') ||
        name.contains('press');
  }

  Future<void> _showExerciseMenu(BuildContext parentContext) async {
    final colorScheme = Theme.of(parentContext).colorScheme;

    await showModalBottomSheet(
      context: parentContext,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Note: bottomSheetTheme.showDragHandle already draws the grabber.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: space16,
                vertical: space8,
              ),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, color: colorScheme.primary),
                  const SizedBox(width: space12),
                  Expanded(
                    child: Text(
                      widget.exercise.exercise,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (_isMainPowerliftingExercise)
              ListTile(
                leading:
                    Icon(Icons.calculate_outlined, color: colorScheme.primary),
                title: const Text('5/3/1 Calculator'),
                subtitle: const Text('Calculate weights for 5/3/1 program'),
                onTap: () {
                  Navigator.pop(context);
                  _show531Calculator(parentContext);
                },
              ),
            ListTile(
              leading:
                  Icon(Icons.note_add_outlined, color: colorScheme.primary),
              title: const Text('Add Notes'),
              subtitle: widget.exerciseNotes?.isNotEmpty ?? false
                  ? Text(
                      widget.exerciseNotes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _showNotesDialog(parentContext);
              },
            ),
            ListTile(
              leading: Icon(Icons.show_chart, color: colorScheme.primary),
              title: const Text('View Graph'),
              subtitle: const Text('Jump to graph page for this exercise'),
              onTap: () async {
                Navigator.pop(context);
                await _jumpToGraph(parentContext);
              },
            ),
            ListTile(
              leading: Icon(Icons.remove_circle_outline,
                  color: context.jl.danger,),
              title: Text(
                'Remove Exercise',
                style: TextStyle(color: context.jl.danger),
              ),
              subtitle: const Text('Remove this exercise from workout'),
              onTap: () {
                Navigator.pop(context);
                widget.onDeleteExercise?.call();
              },
            ),
            const SizedBox(height: space8),
          ],
        ),
      ),
    );
  }

  Future<void> _show531Calculator(BuildContext parentContext) async {
    await showDialog(
      context: parentContext,
      builder: (context) => FiveThreeOneCalculator(
        exerciseName: widget.exercise.exercise,
      ),
    );
  }

  Future<void> _showNotesDialog(BuildContext parentContext) async {
    final controller = TextEditingController(text: widget.exerciseNotes ?? '');
    final result = await showDialog<String>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Notes for ${widget.exercise.exercise}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Add notes for this exercise...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Don't dispose controller here - let the dialog handle its own lifecycle
    if (result != null && widget.onNotesChanged != null) {
      widget.onNotesChanged!(result);
    }
  }

  Future<void> _jumpToGraph(BuildContext parentContext) async {
    // Get the exercise data to determine if it's cardio or strength
    final exerciseData = await (db.gymSets.select()
          ..where((tbl) => tbl.name.equals(widget.exercise.exercise))
          ..orderBy([
            (u) => OrderingTerm(expression: u.created, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (exerciseData == null || !parentContext.mounted) return;

    if (exerciseData.cardio) {
      final data = await getCardioData(
        target: exerciseData.unit,
        name: widget.exercise.exercise,
        period: Period.months3,
      );
      if (!parentContext.mounted) return;
      Navigator.push(
        parentContext,
        MaterialPageRoute(
          builder: (context) => CardioPage(
            name: widget.exercise.exercise,
            unit: exerciseData.unit,
            data: data,
          ),
        ),
      );
    } else {
      final data = await getStrengthData(
        target: exerciseData.unit,
        name: widget.exercise.exercise,
        metric: StrengthMetric.bestWeight,
        period: Period.months3,
      );
      if (!parentContext.mounted) return;
      Navigator.push(
        parentContext,
        MaterialPageRoute(
          builder: (context) => StrengthPage(
            name: widget.exercise.exercise,
            unit: exerciseData.unit,
            data: data,
          ),
        ),
      );
    }
  }

  Future<void> _toggleSet(int index) async {
    if (sets[index].completed) {
      await _uncompleteSet(index);
    } else {
      await _completeSet(index);
    }
  }

  Future<void> _completeSet(int index) async {
    if (sets[index].completed) return;

    final settings = context.read<SettingsState>().value;
    final setData = sets[index];

    HapticFeedback.mediumImpact();

    if (sets[index].savedSetId != null) {
      // Update existing record - just change hidden to false
      await (db.gymSets.update()
            ..where((tbl) => tbl.id.equals(sets[index].savedSetId!)))
          .write(
        const GymSetsCompanion(
          hidden: Value(false),
        ),
      );

      // Clear PR cache since a set was completed
      clearPRCache();

      setState(() {
        sets[index].completed = true;
      });
    } else {
      // Fallback: Insert new record (shouldn't happen with auto-save)
      // Calculate setOrder based on the current index in the sets array
      final setOrderValue = index;

      final gymSet = await db.into(db.gymSets).insertReturning(
            GymSetsCompanion.insert(
              name: widget.exercise.exercise,
              reps: setData.reps.toDouble(),
              weight: setData.weight,
              unit: unit,
              created: DateTime.now().toLocal(),
              planId: Value(widget.planId),
              workoutId: Value(widget.workoutId),
              sequence: Value(widget.sequence),
              setOrder: Value(setOrderValue), // Use index as setOrder
              notes: Value(widget.exerciseNotes ?? ''),
              hidden: const Value(false),
              warmup: Value(setData.isWarmup),
              dropSet: Value(setData.isDropSet),
              brandName: Value(_brandName),
              exerciseType: Value(_exerciseType),
              category: Value(_category),
              supersetId: Value(_supersetId),
              supersetPosition: Value(_supersetPosition),
            ),
          );

      // Clear PR cache since a set was completed
      clearPRCache();

      setState(() {
        sets[index].completed = true;
        sets[index].savedSetId = gymSet.id;
      });
    }

    // Check for records (only for non-warmup, non-cardio sets)
    if (!setData.isWarmup && setData.weight > 0 && setData.reps > 0) {
      final achievements = await checkForRecords(
        exerciseName: widget.exercise.exercise,
        weight: setData.weight,
        reps: setData.reps.toDouble(),
        unit: unit,
        excludeSetId: sets[index]
            .savedSetId, // Exclude this set to compare against previous bests
      );

      if (achievements.isNotEmpty) {
        // Update the set's records
        setState(() {
          sets[index].records = achievements.map((a) => a.type).toSet();
        });

        // Show the celebration notification
        if (mounted) {
          showRecordNotification(
            context,
            achievements: achievements,
            exerciseName: widget.exercise.exercise,
          );
        }
      }
    }

    // Start rest timer
    if (settings.restTimers) {
      final timerState = context.read<TimerState>();
      // Use custom rest time if set, otherwise use global default
      final restMs = _restMs ?? settings.timerDuration;
      timerState.startTimer(
        '${widget.exercise.exercise} ($completedCount)',
        Duration(milliseconds: restMs),
        settings.alarmSound,
        settings.vibrate,
      );
    }

    // Update plan state
    final planState = context.read<PlanState>();
    await planState.updateGymCounts(widget.planId, widget.workoutId);

    widget.onSetCompleted();
  }

  Future<void> _uncompleteSet(int index) async {
    if (!sets[index].completed || sets[index].savedSetId == null) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Update record to mark as uncompleted (hidden=true) instead of deleting
    await (db.gymSets.update()
          ..where((tbl) => tbl.id.equals(sets[index].savedSetId!)))
        .write(
      const GymSetsCompanion(
        hidden: Value(true),
      ),
    );

    setState(() {
      sets[index].completed = false;
    });

    // Update plan state
    final planState = context.read<PlanState>();
    await planState.updateGymCounts(widget.planId, widget.workoutId);
  }

  Future<void> _addSet({bool isWarmup = false, bool isDropSet = false}) async {
    HapticFeedback.selectionClick();

    int insertIndex;
    if (isWarmup) {
      // Warmup sets go at the front
      insertIndex = sets.where((s) => s.isWarmup).length;
    } else if (isDropSet) {
      // Drop sets go at the very end
      insertIndex = sets.length;
    } else {
      // Working sets go after warmup but before drop sets
      insertIndex = sets.length - sets.where((s) => s.isDropSet).length;
    }

    // Determine weight and reps based on set type and previous sets
    double weight;
    int reps;

    if (isWarmup) {
      // Use previous warmup sets
      final currentWarmupCount = sets.where((s) => s.isWarmup).length;
      if (currentWarmupCount < _previousWarmups.length) {
        // Use the corresponding previous warmup set
        weight = _previousWarmups[currentWarmupCount].weight;
        reps = _previousWarmups[currentWarmupCount].reps.toInt();
      } else if (_previousWarmups.isNotEmpty) {
        // Use the last previous warmup set
        weight = _previousWarmups.last.weight;
        reps = _previousWarmups.last.reps.toInt();
      } else {
        // Fallback: 50% of base weight
        final baseWeight =
            _previousWorkingSets.firstOrNull?.weight ?? _defaultWeight;
        weight = (baseWeight * 0.5).roundToDouble();
        reps = _defaultReps;
      }
    } else if (isDropSet) {
      // Use previous drop sets
      final currentDropCount = sets.where((s) => s.isDropSet).length;
      if (currentDropCount < _previousDropSets.length) {
        // Use the corresponding previous drop set
        weight = _previousDropSets[currentDropCount].weight;
        reps = _previousDropSets[currentDropCount].reps.toInt();
      } else if (_previousDropSets.isNotEmpty) {
        // Use the last previous drop set
        weight = _previousDropSets.last.weight;
        reps = _previousDropSets.last.reps.toInt();
      } else {
        // Fallback: 75% of last working set weight
        final baseWeight =
            _previousWorkingSets.lastOrNull?.weight ?? _defaultWeight;
        weight = (baseWeight * 0.75).roundToDouble();
        reps = _defaultReps;
      }
    } else {
      // Working set - use previous working sets
      final currentWorkingCount =
          sets.where((s) => !s.isWarmup && !s.isDropSet).length;
      if (currentWorkingCount < _previousWorkingSets.length) {
        // Use the corresponding previous working set
        weight = _previousWorkingSets[currentWorkingCount].weight;
        reps = _previousWorkingSets[currentWorkingCount].reps.toInt();
      } else if (_previousWorkingSets.isNotEmpty) {
        // Use the last previous working set
        weight = _previousWorkingSets.last.weight;
        reps = _previousWorkingSets.last.reps.toInt();
      } else {
        // Fallback to defaults
        weight = _defaultWeight;
        reps = _defaultReps;
      }
    }

    if (widget.workoutId != null) {
      final gymSet = await db.into(db.gymSets).insertReturning(
            GymSetsCompanion.insert(
              name: widget.exercise.exercise,
              reps: reps.toDouble(),
              weight: weight,
              unit: unit,
              created: DateTime.now().toLocal(),
              planId: Value(widget.planId),
              workoutId: Value(widget.workoutId),
              sequence: Value(widget.sequence),
              setOrder: Value(insertIndex), // Set position within exercise
              notes: Value(widget.exerciseNotes ?? ''),
              hidden: const Value(true),
              warmup: Value(isWarmup),
              dropSet: Value(isDropSet),
              brandName: Value(_brandName),
              exerciseType: Value(_exerciseType),
              category: Value(_category),
              supersetId: Value(_supersetId),
              supersetPosition: Value(_supersetPosition),
            ),
          );

      setState(() {
        sets.insert(
          insertIndex,
          SetData(
            weight: weight,
            reps: reps,
            isWarmup: isWarmup,
            isDropSet: isDropSet,
            savedSetId: gymSet.id,
          ),
        );
      });

      // Update setOrder for all sets to match their new array positions
      for (int i = 0; i < sets.length; i++) {
        if (sets[i].savedSetId != null) {
          await (db.gymSets.update()
                ..where((tbl) => tbl.id.equals(sets[i].savedSetId!)))
              .write(
            GymSetsCompanion(
              setOrder: Value(i),
            ),
          );
        }
      }
    } else {
      setState(() {
        sets.insert(
          insertIndex,
          SetData(
            weight: weight,
            reps: reps,
            isWarmup: isWarmup,
            isDropSet: isDropSet,
          ),
        );
      });
    }
  }

  Future<void> _updateSet(int index) async {
    final setData = sets[index];
    if (setData.savedSetId == null) return;

    // Update the set in database
    await (db.gymSets.update()
          ..where((tbl) => tbl.id.equals(setData.savedSetId!)))
        .write(
      GymSetsCompanion(
        weight: Value(setData.weight),
        reps: Value(setData.reps.toDouble()),
      ),
    );

    // Update plan state only if completed (for gym counts)
    if (setData.completed) {
      final planState = context.read<PlanState>();
      await planState.updateGymCounts(widget.planId, widget.workoutId);
    }
  }

  Future<void> _deleteSet(int index) async {
    HapticFeedback.mediumImpact();

    // Delete from database if it has been saved
    if (sets[index].savedSetId != null) {
      await (db.gymSets.delete()
            ..where((tbl) => tbl.id.equals(sets[index].savedSetId!)))
          .go();

      // Update plan state
      final planState = context.read<PlanState>();
      await planState.updateGymCounts(widget.planId, widget.workoutId);
    }

    setState(() {
      sets.removeAt(index);
    });
  }

  Future<void> _changeSetType(int index, bool isWarmup, bool isDropSet) async {
    HapticFeedback.lightImpact();

    setState(() {
      sets[index].isWarmup = isWarmup;
      sets[index].isDropSet = isDropSet;
    });

    // Update database if the set has been saved
    if (sets[index].savedSetId != null) {
      await (db.gymSets.update()
            ..where((tbl) => tbl.id.equals(sets[index].savedSetId!)))
          .write(
        GymSetsCompanion(
          warmup: Value(isWarmup),
          dropSet: Value(isDropSet),
        ),
      );
    }
  }

  Future<void> _reorderSets(int oldIndex, int newIndex) async {
    HapticFeedback.mediumImpact();

    // Adjust newIndex if moving down
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = sets.removeAt(oldIndex);
      sets.insert(newIndex, item);
    });

    // Update setOrder (NOT sequence!) in database for all sets
    if (widget.workoutId != null) {
      for (int i = 0; i < sets.length; i++) {
        if (sets[i].savedSetId != null) {
          await (db.gymSets.update()
                ..where((tbl) => tbl.id.equals(sets[i].savedSetId!)))
              .write(
            GymSetsCompanion(
              setOrder: Value(i), // CHANGE: Update setOrder instead of sequence
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allCompleted = sets.isNotEmpty && sets.every((s) => s.completed);

    // Determine superset color if in a superset
    Color? supersetColor;
    if (_supersetId != null && _supersetIndex != null) {
      final colors = [
        colorScheme.primaryContainer,
        colorScheme.tertiaryContainer,
        colorScheme.secondaryContainer,
        colorScheme.errorContainer,
      ];
      supersetColor = colors[_supersetIndex! % colors.length];
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: space12, vertical: space8 - 2),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
      color: supersetColor?.withValues(
          alpha: 0.08,), // Subtle background tint for superset exercises
      shape: supersetColor != null
          ? RoundedRectangleBorder(
              borderRadius: brMd,
              side: BorderSide(
                color: supersetColor.withValues(alpha: 0.3),
                width: 2,
              ),
            )
          : null,
      child: Column(
        children: [
          // Exercise Header
          InkWell(
            onTap: widget.onToggleExpand,
            onLongPress: () => _showExerciseMenu(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: space16,
                vertical: space12 + 2,
              ),
              decoration: BoxDecoration(
                gradient: allCompleted
                    ? LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withValues(alpha: 0.6),
                          colorScheme.primaryContainer.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(space8),
                    decoration: BoxDecoration(
                      color: allCompleted
                          ? colorScheme.primary
                          : colorScheme.primaryContainer,
                      borderRadius: brSm,
                    ),
                    child: Icon(
                      allCompleted ? Icons.check : Icons.fitness_center,
                      color: allCompleted
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: space12 + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.exercise.exercise,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (_supersetId != null &&
                                _supersetPosition != null &&
                                _supersetIndex != null) ...[
                              const SizedBox(width: space8),
                              SupersetBadge(
                                supersetIndex: _supersetIndex!,
                                position: _supersetPosition!,
                                isCompact: true,
                              ),
                            ],
                            if (_category != null && _category!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              BodypartTag(bodypart: _category),
                            ],
                            if (_brandName != null &&
                                _brandName!.isNotEmpty) ...[
                              const SizedBox(width: space4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: space4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer
                                      .withValues(alpha: 0.7),
                                  borderRadius: brSm,
                                ),
                                child: Text(
                                  _brandName!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: colorScheme.onSecondaryContainer,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Exercise notes preview
                        if (widget.exerciseNotes?.isNotEmpty ?? false) ...[
                          const SizedBox(height: space4),
                          Row(
                            children: [
                              Icon(
                                Icons.sticky_note_2_outlined,
                                size: 12,
                                color: colorScheme.tertiary,
                              ),
                              const SizedBox(width: space4),
                              Expanded(
                                child: Text(
                                  widget.exerciseNotes!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.tertiary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 2),
                        if (_initialized)
                          Row(
                            children: [
                              Icon(
                                Icons.repeat,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$completedCount / ${sets.length} sets',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              if (_brandName != null &&
                                  _brandName!.isNotEmpty) ...[
                                const SizedBox(width: space8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: space4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer
                                        .withValues(alpha: 0.7),
                                    borderRadius: brSm,
                                  ),
                                  child: Text(
                                    // Explicit tiny size: no textTheme role
                                    // this small for a dense inline badge.
                                    _brandName!,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                              if (completedCount > 0) ...[
                                const SizedBox(width: space12),
                                Icon(
                                  Icons.fitness_center,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: space4),
                                Text(
                                  '${_getTotalVolume()} $unit',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: widget.isExpanded ? 0.5 : 0,
                    duration: durMed,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Progress bar
          if (_initialized)
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: sets.isEmpty ? 0 : completedCount / sets.length,
              ),
              duration: durSlow,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  allCompleted ? colorScheme.primary : colorScheme.tertiary,
                ),
                minHeight: 4,
              ),
            ),
          // Set rows (when expanded)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _initialized
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: space8),
                    child: Column(
                      children: [
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sets.length,
                          onReorder: _reorderSets,
                          proxyDecorator: (child, index, animation) {
                            return Material(
                              elevation: 6,
                              shadowColor: colorScheme.shadow,
                              borderRadius: brMd,
                              child: child,
                            );
                          },
                          itemBuilder: (context, index) {
                            // Calculate display index (exclude warmups and drop sets from numbering)
                            final warmupCount = sets
                                .take(index)
                                .where((s) => s.isWarmup)
                                .length;
                            final dropSetCount = sets
                                .take(index)
                                .where((s) => s.isDropSet)
                                .length;
                            final displayIndex = sets[index].isWarmup
                                ? index + 1 - dropSetCount
                                : sets[index].isDropSet
                                    ? index + 1 - warmupCount
                                    : index - warmupCount - dropSetCount + 1;

                            return SetRow(
                              key: ValueKey(
                                'set_${sets[index].savedSetId ?? index}',
                              ),
                              index: displayIndex,
                              setData: sets[index],
                              unit: unit,
                              records: sets[index].records,
                              onWeightChanged: (value) {
                                setState(() => sets[index].weight = value);
                                if (sets[index].savedSetId != null) {
                                  _updateSet(index);
                                }
                              },
                              onRepsChanged: (value) {
                                setState(() => sets[index].reps = value);
                                if (sets[index].savedSetId != null) {
                                  _updateSet(index);
                                }
                              },
                              onToggle: () {
                                // Unfocus to close keyboard when completing a set
                                if (!sets[index].completed) {
                                  FocusScope.of(context).unfocus();
                                }
                                _toggleSet(index);
                              },
                              onDelete: () => _deleteSet(index),
                              onTypeChanged: (isWarmup, isDropSet) =>
                                  _changeSetType(index, isWarmup, isDropSet),
                            );
                          },
                        ),
                        // Add set buttons row
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: space12,
                            vertical: space4,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Add Warmup button
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _addSet(isWarmup: true),
                                      borderRadius: brMd,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: space8 + 2,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: context.jl.warmup
                                                .withValues(alpha: 0.5),
                                          ),
                                          borderRadius: brMd,
                                          color: context.jl.warmup
                                              .withValues(alpha: 0.15),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.whatshot_outlined,
                                              size: 16,
                                              color: context.jl.warmup,
                                            ),
                                            const SizedBox(width: space4 + 2),
                                            Text(
                                              'Warmup',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color: context.jl.warmup,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: space4 + 2),
                                  // Add Drop Set button
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _addSet(isDropSet: true),
                                      borderRadius: brMd,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: space8 + 2,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: context.jl.dropSet
                                                .withValues(alpha: 0.5),
                                          ),
                                          borderRadius: brMd,
                                          color: context.jl.dropSet
                                              .withValues(alpha: 0.15),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.trending_down,
                                              size: 16,
                                              color: context.jl.dropSet,
                                            ),
                                            const SizedBox(width: space4 + 2),
                                            Text(
                                              'Drop',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color: context.jl.dropSet,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: space4 + 2),
                                  // Add Working Set button
                                  Expanded(
                                    child: InkWell(
                                      onTap: _addSet,
                                      borderRadius: brMd,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: space8 + 2,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: context.jl.working
                                                .withValues(alpha: 0.5),
                                          ),
                                          borderRadius: brMd,
                                          color: context.jl.working
                                              .withValues(alpha: 0.15),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add,
                                              size: 16,
                                              color: context.jl.working,
                                            ),
                                            const SizedBox(width: space4 + 2),
                                            Text(
                                              'Working',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color: context.jl.working,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
            crossFadeState: widget.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: durMed,
          ),
        ],
      ),
    );
  }

  String _getTotalVolume() {
    final total = sets
        .where((s) => s.completed)
        .fold<double>(0, (sum, s) => sum + (s.weight * s.reps));
    if (total >= 1000) {
      return '${(total / 1000).toStringAsFixed(1)}k';
    }
    return total.toStringAsFixed(0);
  }
}
