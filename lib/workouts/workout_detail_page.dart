import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../database/database.dart';
import '../database/gym_sets.dart';
import '../utils/cardio_format.dart';
import '../graph/cardio_page.dart';
import '../graph/strength_page.dart';
import '../main.dart';
import '../models/set_data.dart';
import '../plan/start_plan_page.dart';
import '../records/record_notification.dart';
import '../records/records_service.dart';
import '../sets/edit_set_page.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../utils.dart';
import '../widgets/bodypart_tag.dart';
import '../widgets/sets/cardio_bout.dart';
import '../widgets/sets/set_row.dart';
import '../widgets/workout/exercise_picker_modal.dart';
import 'workout_state.dart';

class WorkoutDetailPage extends StatefulWidget {
  const WorkoutDetailPage({required this.workout, super.key});
  final Workout workout;

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late Stream<List<GymSet>> setsStream;
  Map<int, Set<RecordType>> _recordsMap = {};
  Workout? _currentWorkout;

  // Edit mode state
  bool _isEditMode = false;
  bool _isReorderMode = false;
  bool _hasUnsavedChanges = false;
  List<
      ({
        String name,
        int sequence,
        List<SetData> editableSets,
        String unit,
        bool cardio,
      })> _exerciseGroups = [];

  Workout get currentWorkout => _currentWorkout ?? widget.workout;

  @override
  void initState() {
    super.initState();
    _currentWorkout = widget.workout;
    setsStream = (db.gymSets.select()
          ..where(
            (s) =>
                s.workoutId.equals(widget.workout.id) &
                s.hidden.equals(false) &
                s.sequence.isBiggerOrEqualValue(0),
          )
          ..orderBy([
            // Order by sequence first (exercise position)
            (s) => OrderingTerm(expression: s.sequence),
            // Then by setOrder if available, fallback to created timestamp
            (s) => OrderingTerm(
                  expression: const CustomExpression<int>(
                    'COALESCE(set_order, CAST((julianday(created) - 2440587.5) * 86400000 AS INTEGER))',
                  ),
                ),
          ]))
        .watch();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await getWorkoutRecords(widget.workout.id);
    if (mounted) {
      setState(() {
        _recordsMap = records;
      });
    }
  }

  // Edit mode methods
  void _enterEditMode(
      List<({String name, int sequence, List<GymSet> sets})> groups) {
    setState(() {
      _isEditMode = true;
      _hasUnsavedChanges = false;
      _exerciseGroups = groups
          .map((g) => (
                name: g.name,
                sequence: g.sequence,
                unit: g.sets.firstOrNull?.unit ?? 'kg',
                cardio: g.sets.firstOrNull?.cardio ?? false,
                editableSets: g.sets
                    .map((s) => SetData(
                          weight: s.weight,
                          reps: s.reps.toInt(),
                          duration: s.duration,
                          distance: s.distance,
                          incline: s.incline,
                          cardioMetric: s.cardioMetric,
                          completed: !s.hidden,
                          savedSetId: s.id,
                          isWarmup: s.warmup,
                          isDropSet: s.dropSet,
                          records: _recordsMap[s.id] ?? {},
                        ))
                    .toList(),
              ))
          .toList();
    });
  }

  Future<void> _exitEditMode({bool save = false}) async {
    if (!save && _hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardDialog();
      if (!shouldDiscard) return;
    }

    setState(() {
      _isEditMode = false;
      _isReorderMode = false;
      _hasUnsavedChanges = false;
      _exerciseGroups = [];
    });
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _editWorkoutName() async {
    final nameController =
        TextEditingController(text: currentWorkout.name ?? 'Workout');
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Workout Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
            hintText: 'Enter workout name...',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      await (db.workouts.update()..where((w) => w.id.equals(widget.workout.id)))
          .write(WorkoutsCompanion(name: Value(newName)));
      await _reloadWorkout();
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _addExercise() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => const ExercisePickerModal(),
    );

    if (result != null && mounted) {
      final nextSequence = _exerciseGroups.isEmpty
          ? 0
          : _exerciseGroups
                  .map((e) => e.sequence)
                  .reduce((a, b) => a > b ? a : b) +
              1;

      // Insert a placeholder set to database
      final newSet = await db.gymSets.insertReturning(
        GymSetsCompanion.insert(
          name: result,
          reps: 0,
          weight: 0,
          unit: 'kg',
          created: DateTime.now(),
          workoutId: Value(widget.workout.id),
          hidden: const Value(false),
          sequence: Value(nextSequence),
          setOrder: const Value(0),
        ),
      );

      setState(() {
        _exerciseGroups.add((
          name: result,
          sequence: nextSequence,
          unit: newSet.unit,
          cardio: newSet.cardio,
          editableSets: [
            SetData(
              weight: newSet.weight,
              reps: newSet.reps.toInt(),
              completed: !newSet.hidden,
              savedSetId: newSet.id,
              isWarmup: newSet.warmup,
              isDropSet: newSet.dropSet,
            )
          ],
        ));
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _removeExercise(int index) async {
    final group = _exerciseGroups[index];
    final exerciseName = group.name;
    final sequence = group.sequence;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exercise?'),
        content: Text('Remove $exerciseName and all its sets?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Check if this exercise is part of a superset before deleting
    String? supersetId;
    final firstSetId = group.editableSets.firstOrNull?.savedSetId;
    if (firstSetId != null) {
      final firstSet = await (db.gymSets.select()
            ..where((s) => s.id.equals(firstSetId)))
          .getSingleOrNull();
      supersetId = firstSet?.supersetId;
    }

    // Delete all sets for this exercise
    await (db.gymSets.delete()
          ..where((s) =>
              s.workoutId.equals(widget.workout.id) &
              s.name.equals(exerciseName) &
              s.sequence.equals(sequence)))
        .go();

    // Update sequence numbers for exercises after removed one
    await db.customUpdate(
      'UPDATE gym_sets SET sequence = sequence - 1 WHERE workout_id = ? AND sequence > ?',
      updates: {db.gymSets},
      variables: [
        Variable.withInt(widget.workout.id),
        Variable.withInt(sequence),
      ],
    );

    // If exercise was in a superset, check if only one remains and unmark it
    if (supersetId != null) {
      await _checkAndUnmarkSingleSuperset(supersetId);
    }

    // Clear PR cache
    clearPRCache();

    setState(() {
      _exerciseGroups.removeAt(index);
      // Update sequence numbers in local list
      for (int i = index; i < _exerciseGroups.length; i++) {
        final old = _exerciseGroups[i];
        _exerciseGroups[i] = (
          name: old.name,
          sequence: i,
          unit: old.unit,
          cardio: old.cardio,
          editableSets: old.editableSets,
        );
      }
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _checkAndUnmarkSingleSuperset(String supersetId) async {
    // Count how many distinct exercises (by sequence) remain in this superset
    final remainingExercises = await (db.gymSets.selectOnly(distinct: true)
          ..addColumns([db.gymSets.sequence])
          ..where(
            db.gymSets.workoutId.equals(widget.workout.id) &
                db.gymSets.supersetId.equals(supersetId),
          ))
        .get();

    // If only one exercise remains, unmark it
    if (remainingExercises.length == 1) {
      await db.customUpdate(
        'UPDATE gym_sets SET superset_id = NULL, superset_position = NULL WHERE workout_id = ? AND superset_id = ?',
        updates: {db.gymSets},
        variables: [
          Variable.withInt(widget.workout.id),
          Variable.withString(supersetId),
        ],
      );
    }
  }

  Future<void> _reorderExercises(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;

    final item = _exerciseGroups.removeAt(oldIndex);
    _exerciseGroups.insert(newIndex, item);

    HapticFeedback.mediumImpact();

    // Update sequence numbers in database for all exercises
    for (int i = 0; i < _exerciseGroups.length; i++) {
      final group = _exerciseGroups[i];
      final oldSequence = group.sequence;

      await db.customUpdate(
        'UPDATE gym_sets SET sequence = ? WHERE workout_id = ? AND name = ? AND sequence = ?',
        updates: {db.gymSets},
        variables: [
          Variable.withInt(i),
          Variable.withInt(widget.workout.id),
          Variable.withString(group.name),
          Variable.withInt(oldSequence),
        ],
      );

      // Update local sequence
      _exerciseGroups[i] = (
        name: group.name,
        sequence: i,
        unit: group.unit,
        cardio: group.cardio,
        editableSets: group.editableSets,
      );
    }

    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  // Set editing methods
  Future<void> _updateSetWeight(
      int exerciseIndex, int setIndex, double value) async {
    final sets = _exerciseGroups[exerciseIndex].editableSets;
    sets[setIndex].weight = value;

    if (sets[setIndex].savedSetId != null) {
      await (db.gymSets.update()
            ..where((tbl) => tbl.id.equals(sets[setIndex].savedSetId!)))
          .write(GymSetsCompanion(weight: Value(value)));
      clearPRCache();
    }

    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _updateSetReps(
      int exerciseIndex, int setIndex, int value) async {
    final sets = _exerciseGroups[exerciseIndex].editableSets;
    sets[setIndex].reps = value;

    if (sets[setIndex].savedSetId != null) {
      await (db.gymSets.update()
            ..where((tbl) => tbl.id.equals(sets[setIndex].savedSetId!)))
          .write(GymSetsCompanion(reps: Value(value.toDouble())));
      clearPRCache();
    }

    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _updateCardioSet(int exerciseIndex, int setIndex) async {
    final sets = _exerciseGroups[exerciseIndex].editableSets;
    final set = sets[setIndex];

    if (set.savedSetId != null) {
      await (db.gymSets.update()
            ..where((tbl) => tbl.id.equals(set.savedSetId!)))
          .write(
        GymSetsCompanion(
          duration: Value(set.duration),
          distance: Value(set.distance),
          incline: Value(set.incline),
        ),
      );
      clearPRCache();
    }

    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _addSetToExercise(int exerciseIndex,
      {bool isWarmup = false, bool isDropSet = false}) async {
    HapticFeedback.selectionClick();

    final group = _exerciseGroups[exerciseIndex];
    final sets = group.editableSets;

    if (group.cardio) {
      final previous = sets.lastOrNull;
      final gymSet = await db.into(db.gymSets).insertReturning(
            GymSetsCompanion.insert(
              name: group.name,
              reps: 0,
              weight: 0,
              unit: group.unit,
              created: DateTime.now().toLocal(),
              workoutId: Value(widget.workout.id),
              sequence: Value(group.sequence),
              setOrder: Value(sets.length),
              hidden: const Value(false),
              cardio: const Value(true),
              duration: Value(previous?.duration ?? 0),
              distance: Value(previous?.distance ?? 0),
              incline: Value(previous?.incline),
              cardioMetric: Value(previous?.cardioMetric),
            ),
          );

      setState(() {
        sets.add(
          SetData(
            weight: 0,
            reps: 0,
            duration: gymSet.duration,
            distance: gymSet.distance,
            incline: gymSet.incline,
            cardioMetric: gymSet.cardioMetric,
            completed: true,
            savedSetId: gymSet.id,
          ),
        );
        _hasUnsavedChanges = true;
      });
      clearPRCache();
      return;
    }

    // Determine insert position
    int insertIndex;
    if (isWarmup) {
      insertIndex = sets.where((s) => s.isWarmup).length;
    } else if (isDropSet) {
      insertIndex = sets.length;
    } else {
      insertIndex = sets.length - sets.where((s) => s.isDropSet).length;
    }

    // Get default weight/reps from last set of same type or defaults
    double weight = 0;
    int reps = 8;

    if (isWarmup && sets.any((s) => s.isWarmup)) {
      final lastWarmup = sets.lastWhere((s) => s.isWarmup);
      weight = lastWarmup.weight;
      reps = lastWarmup.reps;
    } else if (isDropSet && sets.any((s) => s.isDropSet)) {
      final lastDrop = sets.lastWhere((s) => s.isDropSet);
      weight = lastDrop.weight;
      reps = lastDrop.reps;
    } else if (!isWarmup &&
        !isDropSet &&
        sets.any((s) => !s.isWarmup && !s.isDropSet)) {
      final lastWorking = sets.lastWhere((s) => !s.isWarmup && !s.isDropSet);
      weight = lastWorking.weight;
      reps = lastWorking.reps;
    } else if (sets.isNotEmpty) {
      weight = sets.last.weight;
      reps = sets.last.reps;
    }

    // Insert to database
    final gymSet = await db.into(db.gymSets).insertReturning(
          GymSetsCompanion.insert(
            name: group.name,
            reps: reps.toDouble(),
            weight: weight,
            unit: group.unit,
            created: DateTime.now().toLocal(),
            workoutId: Value(widget.workout.id),
            sequence: Value(group.sequence),
            setOrder: Value(insertIndex),
            hidden: const Value(false),
            warmup: Value(isWarmup),
            dropSet: Value(isDropSet),
          ),
        );

    // Add to local list
    sets.insert(
        insertIndex,
        SetData(
          weight: weight,
          reps: reps,
          completed: true,
          savedSetId: gymSet.id,
          isWarmup: isWarmup,
          isDropSet: isDropSet,
        ));

    // Update setOrder for all sets
    for (int i = 0; i < sets.length; i++) {
      if (sets[i].savedSetId != null) {
        await (db.gymSets.update()
              ..where((tbl) => tbl.id.equals(sets[i].savedSetId!)))
            .write(GymSetsCompanion(setOrder: Value(i)));
      }
    }

    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _deleteSetFromExercise(int exerciseIndex, int setIndex) async {
    HapticFeedback.mediumImpact();

    final sets = _exerciseGroups[exerciseIndex].editableSets;
    final set = sets[setIndex];

    if (set.savedSetId != null) {
      await (db.gymSets.delete()
            ..where((tbl) => tbl.id.equals(set.savedSetId!)))
          .go();
      clearPRCache();
    }

    sets.removeAt(setIndex);

    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _changeSetType(
      int exerciseIndex, int setIndex, bool isWarmup, bool isDropSet) async {
    HapticFeedback.lightImpact();

    final sets = _exerciseGroups[exerciseIndex].editableSets;
    sets[setIndex].isWarmup = isWarmup;
    sets[setIndex].isDropSet = isDropSet;

    if (sets[setIndex].savedSetId != null) {
      await (db.gymSets.update()
            ..where((tbl) => tbl.id.equals(sets[setIndex].savedSetId!)))
          .write(GymSetsCompanion(
        warmup: Value(isWarmup),
        dropSet: Value(isDropSet),
      ));
    }

    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _showExerciseMenu(
      int exerciseIndex, ColorScheme colorScheme) async {
    final group = _exerciseGroups[exerciseIndex];
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: brPill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading:
                  Icon(Icons.remove_circle_outline, color: colorScheme.error),
              title: Text(
                'Remove Exercise',
                style: TextStyle(color: colorScheme.error),
              ),
              subtitle: const Text('Remove this exercise and all its sets'),
              onTap: () {
                Navigator.pop(context);
                _removeExercise(exerciseIndex);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showImages = context.select<SettingsState, bool>(
      (settings) => settings.value.showImages,
    );
    final colorScheme = Theme.of(context).colorScheme;

    final workoutEnded = widget.workout.endTime != null;

    return PopScope(
      canPop: !_isEditMode || !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_isEditMode && _hasUnsavedChanges) {
          final shouldDiscard = await _showDiscardDialog();
          if (shouldDiscard && mounted) {
            setState(() {
              _isEditMode = false;
              _hasUnsavedChanges = false;
            });
            if (mounted) Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: StreamBuilder<List<GymSet>>(
          stream: setsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Scaffold(
                appBar: AppBar(title: Text(widget.workout.name ?? 'Workout')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final sets = snapshot.data!;

            // Group sets by exercise, detecting sequence gaps for multiple instances
            final List<
                    ({String name, List<GymSet> sets, int minSeq, int maxSeq})>
                exerciseGroups = [];

            if (sets.isNotEmpty) {
              // Sort by sequence first to ensure proper grouping
              final sortedSets = List<GymSet>.from(sets)
                ..sort((a, b) => a.sequence.compareTo(b.sequence));

              String? currentExercise;
              List<GymSet> currentSets = [];
              int? currentMinSeq;
              int? currentMaxSeq;

              for (final set in sortedSets) {
                if (currentExercise == null ||
                    set.name != currentExercise ||
                    (currentMaxSeq != null && set.sequence != currentMaxSeq)) {
                  // New exercise or sequence change detected - save previous group
                  if (currentExercise != null && currentSets.isNotEmpty) {
                    exerciseGroups.add(
                      (
                        name: currentExercise,
                        sets: currentSets,
                        minSeq: currentMinSeq!,
                        maxSeq: currentMaxSeq!,
                      ),
                    );
                  }
                  // Start new group
                  currentExercise = set.name;
                  currentSets = [set];
                  currentMinSeq = set.sequence;
                  currentMaxSeq = set.sequence;
                } else {
                  // Continue current group - sets must have same sequence
                  currentSets.add(set);
                  currentMaxSeq = set.sequence;
                }
              }

              // Add last group
              if (currentExercise != null && currentSets.isNotEmpty) {
                exerciseGroups.add(
                  (
                    name: currentExercise,
                    sets: currentSets,
                    minSeq: currentMinSeq!,
                    maxSeq: currentMaxSeq!,
                  ),
                );
              }
            }

            // Group exercises into supersets
            // First, collect all unique superset IDs in order
            final supersetIds = <String>[];
            for (final group in exerciseGroups) {
              final supersetId = group.sets.firstOrNull?.supersetId;
              if (supersetId != null && !supersetIds.contains(supersetId)) {
                supersetIds.add(supersetId);
              }
            }

            // Create display items - render each exercise individually, even in supersets
            final displayItems = <Map<String, dynamic>>[];
            int i = 0;
            while (i < exerciseGroups.length) {
              final group = exerciseGroups[i];
              final supersetId = group.sets.firstOrNull?.supersetId;
              final supersetPosition = group.sets.firstOrNull?.supersetPosition;

              if (supersetId != null && supersetPosition != null) {
                // This exercise is part of a superset - render individually with metadata
                final supersetIndex = supersetIds.indexOf(supersetId);

                // Determine if this is the first or last exercise in the superset
                final isFirstInSuperset = i == 0 ||
                    exerciseGroups[i - 1].sets.firstOrNull?.supersetId !=
                        supersetId;
                final isLastInSuperset = i == exerciseGroups.length - 1 ||
                    exerciseGroups[i + 1].sets.firstOrNull?.supersetId !=
                        supersetId;

                displayItems.add({
                  'type': 'exercise',
                  'name': group.name,
                  'sets': group.sets,
                  'supersetIndex': supersetIndex,
                  'supersetPosition': supersetPosition,
                  'isFirstInSuperset': isFirstInSuperset,
                  'isLastInSuperset': isLastInSuperset,
                });
              } else {
                // Regular exercise (not in a superset)
                displayItems.add({
                  'type': 'exercise',
                  'name': group.name,
                  'sets': group.sets,
                });
              }
              i++;
            }

            final totalVolume = sets.fold<double>(
              0,
              (sum, s) => sum + (s.weight * s.reps),
            );

            // Count unique exercise names (not instances)
            final uniqueExerciseNames = sets.map((s) => s.name).toSet().length;

            return CustomScrollView(
              slivers: [
                // Stylish App Bar Header
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor:
                      _isEditMode ? colorScheme.tertiaryContainer : null,
                  title:
                      _isReorderMode ? const Text('Reorder Exercises') : null,
                  leading: _isReorderMode
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Cancel reorder',
                          onPressed: () =>
                              setState(() => _isReorderMode = false),
                        )
                      : _isEditMode
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Cancel editing',
                              onPressed: () => _exitEditMode(save: false),
                            )
                          : null,
                  actions: [
                    if (_isReorderMode) ...[
                      // Done button in reorder mode
                      TextButton.icon(
                        onPressed: () => setState(() => _isReorderMode = false),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                      ),
                    ] else if (_isEditMode) ...[
                      // Reorder button in edit mode (only if more than 1 exercise)
                      if (_exerciseGroups.length > 1)
                        IconButton(
                          icon: const Icon(Icons.swap_vert),
                          tooltip: 'Reorder exercises',
                          onPressed: () =>
                              setState(() => _isReorderMode = true),
                        ),
                      // Selfie button in edit mode
                      IconButton(
                        icon: Icon(
                          currentWorkout.selfieImagePath != null
                              ? Icons.camera_alt
                              : Icons.add_a_photo_outlined,
                        ),
                        tooltip: currentWorkout.selfieImagePath != null
                            ? 'Change Selfie'
                            : 'Add Selfie',
                        onPressed: () => _editSelfie(context),
                      ),
                      // Save button in edit mode
                      IconButton(
                        icon: const Icon(Icons.check),
                        tooltip: 'Done editing',
                        onPressed: () => _exitEditMode(save: true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteWorkout(context),
                      ),
                    ] else ...[
                      // Edit button when not in edit mode (only for ended workouts)
                      if (workoutEnded)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit Workout',
                          onPressed: () => _enterEditMode(
                            exerciseGroups
                                .map((g) => (
                                      name: g.name,
                                      sequence: g.minSeq,
                                      sets: g.sets,
                                    ))
                                .toList(),
                          ),
                        ),
                      if (workoutEnded)
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          tooltip: 'Resume Workout',
                          onPressed: () => _resumeWorkout(context),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteWorkout(context),
                      ),
                    ],
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: currentWorkout.selfieImagePath != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              // Selfie image
                              Image.file(
                                File(currentWorkout.selfieImagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultGradientBackground(
                                        colorScheme),
                              ),
                              // Dark gradient overlay for text readability
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.3),
                                      Colors.black.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                              ),
                              // Content on top
                              SafeArea(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 60, 20, 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildDateBadge(),
                                      const SizedBox(height: 12),
                                      _isEditMode
                                          ? GestureDetector(
                                              onTap: _editWorkoutName,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      currentWorkout.name ??
                                                          'Workout',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineSmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    Icons.edit_outlined,
                                                    size: 20,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Text(
                                              currentWorkout.name ?? 'Workout',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('HH:mm')
                                            .format(currentWorkout.startTime),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.9),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _buildDefaultGradientBackground(colorScheme),
                  ),
                ),
                // Stats section
                SliverToBoxAdapter(
                  child: _buildStatsSection(
                    sets,
                    totalVolume,
                    uniqueExerciseNames,
                    _recordsMap.length,
                  ),
                ),
                // Notes section
                if (widget.workout.notes?.isNotEmpty ?? false)
                  SliverToBoxAdapter(
                    child: _buildNotesSection(),
                  ),
                // Empty state (only in view mode)
                if (displayItems.isEmpty && !_isEditMode)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text('No exercises in this workout'),
                    ),
                  ),
                // Edit mode: use reorderable list with add/remove
                if (_isEditMode) ...[
                  if (_isReorderMode)
                    SliverReorderableList(
                      itemCount: _exerciseGroups.length,
                      onReorder: _reorderExercises,
                      itemBuilder: (context, index) {
                        final group = _exerciseGroups[index];
                        return ReorderableDragStartListener(
                          key: ValueKey(
                              'reorder_${group.name}_${group.sequence}'),
                          index: index,
                          child: _buildReorderableExerciseTile(
                            index,
                            colorScheme,
                          ),
                        );
                      },
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildEditableExerciseCard(
                          index,
                          colorScheme,
                        ),
                        childCount: _exerciseGroups.length,
                      ),
                    ),
                  // Add Exercise button at the end
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _addExercise,
                          borderRadius: brSm,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: space16),
                            decoration: BoxDecoration(
                              borderRadius: brSm,
                              border: Border.all(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primaryContainer
                                      .withValues(alpha: 0.3),
                                  colorScheme.secondaryContainer
                                      .withValues(alpha: 0.2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Exercise',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // View mode: display items (exercises with optional superset styling)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = displayItems[index];

                        // All items are exercises now, some with superset metadata
                        return _buildExerciseGroup(
                          item['name'] as String,
                          item['sets'] as List<GymSet>,
                          showImages,
                          _recordsMap,
                          supersetIndex: item['supersetIndex'] as int?,
                          supersetPosition: item['supersetPosition'] as int?,
                          isFirstInSuperset:
                              item['isFirstInSuperset'] as bool? ?? false,
                          isLastInSuperset:
                              item['isLastInSuperset'] as bool? ?? false,
                        );
                      },
                      childCount: displayItems.length,
                    ),
                  ),
                ],
                // Bottom padding for navigation bar + active workout bar + timer
                const SliverPadding(padding: EdgeInsets.only(bottom: 260)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultGradientBackground(ColorScheme colorScheme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isEditMode
              ? [
                  colorScheme.tertiaryContainer,
                  colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                  colorScheme.surface,
                ]
              : [
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withValues(alpha: 0.6),
                  colorScheme.surface,
                ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateBadge(),
              const SizedBox(height: 12),
              _isEditMode
                  ? GestureDetector(
                      onTap: _editWorkoutName,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              currentWorkout.name ?? 'Workout',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      currentWorkout.name ?? 'Workout',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(currentWorkout.startTime),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBadge() {
    final colorScheme = Theme.of(context).colorScheme;
    final workout = currentWorkout;
    final hasSelfie = workout.selfieImagePath != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: hasSelfie
            ? Colors.white.withValues(alpha: 0.2)
            : colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: brSm,
        border: Border.all(
          color: hasSelfie
              ? Colors.white.withValues(alpha: 0.4)
              : colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: hasSelfie ? Colors.white : colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('yyyy MMMM d').format(workout.startTime),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasSelfie ? Colors.white : colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    List<GymSet> sets,
    double totalVolume,
    int exerciseCount,
    int recordCount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = currentWorkout.endTime != null
        ? currentWorkout.endTime!.difference(currentWorkout.startTime)
        : DateTime.now().difference(currentWorkout.startTime);

    final totalSets = sets.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: brMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              Icons.fitness_center,
              '$exerciseCount',
              'exercises',
            ),
            _buildStatDivider(),
            _buildStatItem(
              Icons.repeat,
              '$totalSets',
              'sets',
            ),
            _buildStatDivider(),
            if (_isEditMode && currentWorkout.endTime != null)
              GestureDetector(
                onTap: _editDuration,
                child: _buildStatItem(
                  Icons.timer,
                  _formatDuration(duration),
                  'duration',
                  isHighlighted: true,
                ),
              )
            else
              _buildStatItem(
                Icons.timer,
                _formatDuration(duration),
                'duration',
              ),
            if (totalVolume > 0) ...[
              _buildStatDivider(),
              _buildStatItem(
                Icons.show_chart,
                _formatVolume(totalVolume),
                'volume',
              ),
            ],
            if (recordCount > 0) ...[
              _buildStatDivider(),
              _buildStatItem(
                Icons.emoji_events,
                '$recordCount',
                'PRs',
                isHighlighted: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label, {
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlighted ? context.jl.pr : colorScheme.primary,
        ),
        const SizedBox(height: space4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isHighlighted ? context.jl.pr : null,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isHighlighted
                    ? context.jl.pr
                    : colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  Widget _buildNotesSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: brMd,
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Workout Notes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.workout.notes!,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k';
    }
    return volume.toStringAsFixed(0);
  }

  Widget _buildReorderableExerciseTile(
    int index,
    ColorScheme colorScheme,
  ) {
    final group = _exerciseGroups[index];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: space12, vertical: space4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: brSm,
          ),
          child: Icon(
            Icons.fitness_center,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${group.editableSets.length} set${group.editableSets.length == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.drag_handle,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableExerciseCard(
    int exerciseIndex,
    ColorScheme colorScheme,
  ) {
    final group = _exerciseGroups[exerciseIndex];
    final sets = group.editableSets;
    final exerciseName = group.name;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: space12, vertical: space8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row - long press to show menu
          InkWell(
            onLongPress: () => _showExerciseMenu(exerciseIndex, colorScheme),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              child: Row(
                children: [
                  // Exercise icon badge (like ExerciseSetsCard)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: brSm,
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Exercise name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exerciseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${sets.length} set${sets.length == 1 ? '' : 's'} - Hold for options',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (group.cardio)
            ..._buildEditableCardioBouts(exerciseIndex, colorScheme)
          else ...[
            // Sets list using SetRow
            if (sets.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sets.length,
                itemBuilder: (context, setIndex) {
                  // Calculate display index
                  final warmupCount =
                      sets.take(setIndex).where((s) => s.isWarmup).length;
                  final dropSetCount =
                      sets.take(setIndex).where((s) => s.isDropSet).length;
                  final displayIndex = sets[setIndex].isWarmup
                      ? setIndex + 1 - dropSetCount
                      : sets[setIndex].isDropSet
                          ? setIndex + 1 - warmupCount
                          : setIndex - warmupCount - dropSetCount + 1;

                  return SetRow(
                    key: ValueKey(
                        'edit_set_${sets[setIndex].savedSetId ?? setIndex}'),
                    index: displayIndex,
                    setData: sets[setIndex],
                    unit: group.unit,
                    records: sets[setIndex].records,
                    onWeightChanged: (value) =>
                        _updateSetWeight(exerciseIndex, setIndex, value),
                    onRepsChanged: (value) =>
                        _updateSetReps(exerciseIndex, setIndex, value),
                    onToggle:
                        () {}, // No toggle in edit mode - sets are completed
                    onDelete: () =>
                        _deleteSetFromExercise(exerciseIndex, setIndex),
                    onTypeChanged: (isWarmup, isDropSet) => _changeSetType(
                        exerciseIndex, setIndex, isWarmup, isDropSet),
                  );
                },
              ),
            // Add set buttons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Add Warmup button
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          _addSetToExercise(exerciseIndex, isWarmup: true),
                      borderRadius: brSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.tertiary.withValues(alpha: 0.5),
                          ),
                          borderRadius: brSm,
                          color: colorScheme.tertiaryContainer
                              .withValues(alpha: 0.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.whatshot_outlined,
                              size: 14,
                              color: colorScheme.tertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Warmup',
                              style: TextStyle(
                                color: colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Add Drop Set button
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          _addSetToExercise(exerciseIndex, isDropSet: true),
                      borderRadius: brSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.secondary.withValues(alpha: 0.5),
                          ),
                          borderRadius: brSm,
                          color: colorScheme.secondaryContainer
                              .withValues(alpha: 0.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_down,
                              size: 14,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Drop',
                              style: TextStyle(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Add Working Set button
                  Expanded(
                    child: InkWell(
                      onTap: () => _addSetToExercise(exerciseIndex),
                      borderRadius: brSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          borderRadius: brSm,
                          color: colorScheme.primaryContainer
                              .withValues(alpha: 0.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Working',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildEditableCardioBouts(
    int exerciseIndex,
    ColorScheme colorScheme,
  ) {
    final group = _exerciseGroups[exerciseIndex];
    final sets = group.editableSets;
    return [
      for (int setIndex = 0; setIndex < sets.length; setIndex++)
        CardioBout(
          key: ValueKey('edit_bout_${sets[setIndex].savedSetId ?? setIndex}'),
          index: setIndex + 1,
          setData: sets[setIndex],
          unit: group.unit,
          records: sets[setIndex].records,
          onDurationChanged: (value) {
            setState(() {
              final speed =
                  cardioSpeed(sets[setIndex].distance, sets[setIndex].duration);
              sets[setIndex].duration = value;
              if (speed > 0) sets[setIndex].distance = speed * value / 60;
            });
            _updateCardioSet(exerciseIndex, setIndex);
          },
          onDistanceChanged: (value) {
            setState(() => sets[setIndex].distance = value);
            _updateCardioSet(exerciseIndex, setIndex);
          },
          onSpeedChanged: (value) {
            setState(() {
              sets[setIndex].distance = value * sets[setIndex].duration / 60;
            });
            _updateCardioSet(exerciseIndex, setIndex);
          },
          onInclineChanged: (value) {
            setState(() => sets[setIndex].incline = value);
            _updateCardioSet(exerciseIndex, setIndex);
          },
          onToggle: () {},
          onDelete: () => _deleteSetFromExercise(exerciseIndex, setIndex),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: InkWell(
          onTap: () => _addSetToExercise(exerciseIndex),
          borderRadius: brSm,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
              borderRadius: brSm,
              color:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 14, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Add bout',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildExerciseGroup(
    String exerciseName,
    List<GymSet> sets,
    bool showImages,
    Map<int, Set<RecordType>> recordsMap, {
    int? supersetIndex,
    int? supersetPosition,
    bool isFirstInSuperset = false,
    bool isLastInSuperset = false,
  }) {
    // Sets are already ordered by the database query using setOrder
    // No need to re-sort them here

    final firstSet = sets.first;
    final exerciseNotes = firstSet.notes;
    final brandName = firstSet.brandName;
    final category = firstSet.category;

    // Check if any set in this group has records
    final groupHasRecords = sets.any((s) => recordsMap.containsKey(s.id));

    Widget? leading;
    if (showImages && firstSet.image != null) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(firstSet.image!),
          width: 40,
          height: 40,
          // 2x the box, single dimension so the cover crop keeps its aspect.
          cacheWidth: decodePx(context, 80),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildInitialBadge(exerciseName),
        ),
      );
    } else {
      leading = _buildInitialBadge(exerciseName);
    }

    final children = <Widget>[
      // Show exercise notes if present
      if (exerciseNotes?.isNotEmpty ?? false)
        Container(
          margin: const EdgeInsets.fromLTRB(72, 0, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notes,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exerciseNotes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ),
        ),
      // Show all sets
      ...(() {
        int workingSetNumber = 0;
        int dropSetNumber = 0;
        return sets.map((set) {
          final setRecords = recordsMap[set.id] ?? {};
          if (set.dropSet) {
            dropSetNumber++;
            return _buildSetTile(
              set,
              dropSetNumber,
              isDropSet: true,
              records: setRecords,
            );
          } else if (!set.warmup) {
            workingSetNumber++;
            return _buildSetTile(set, workingSetNumber, records: setRecords);
          } else {
            return _buildSetTile(set, 0, records: setRecords);
          }
        }).toList();
      })(),
    ];

    // Determine superset color and styling
    final colorScheme = Theme.of(context).colorScheme;
    Color? supersetColor;
    String? supersetLabel;
    if (supersetIndex != null && supersetPosition != null) {
      final colors = [
        colorScheme.primaryContainer,
        colorScheme.tertiaryContainer,
        colorScheme.secondaryContainer,
        colorScheme.errorContainer,
      ];
      supersetColor = colors[supersetIndex % colors.length];
      final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
      supersetLabel =
          '${letters[supersetIndex % letters.length]}${supersetPosition + 1}';
    }

    final exerciseWidget = InkWell(
      onLongPress: () => _showViewExerciseMenu(context, exerciseName),
      child: ExpansionTile(
        leading: leading,
        title: Row(
          children: [
            Flexible(
              child: Text(exerciseName),
            ),
            // Superset badge
            if (supersetLabel != null && supersetColor != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      supersetColor,
                      supersetColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: supersetColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  supersetLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
            if (category != null && category.isNotEmpty) ...[
              const SizedBox(width: 6),
              BodypartTag(bodypart: category),
            ],
            if (brandName != null && brandName.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  brandName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
            if (groupHasRecords) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.emoji_events,
                size: 18,
                color: context.jl.pr,
              ),
            ],
          ],
        ),
        subtitle: exerciseNotes?.isNotEmpty ?? false
            ? Row(
                children: [
                  Icon(
                    Icons.note,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text('${sets.length} sets'),
                ],
              )
            : Text('${sets.length} sets'),
        initiallyExpanded: true,
        children: children,
      ),
    );

    // Wrap with artistic superset styling if in a superset
    if (supersetColor != null) {
      return Container(
        margin: EdgeInsets.only(
          left: 8,
          right: 16,
          top: isFirstInSuperset ? 8 : 0,
          bottom: isLastInSuperset ? 12 : 0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft:
                isFirstInSuperset ? const Radius.circular(12) : Radius.zero,
            bottomLeft:
                isLastInSuperset ? const Radius.circular(12) : Radius.zero,
            topRight:
                isFirstInSuperset ? const Radius.circular(12) : Radius.zero,
            bottomRight:
                isLastInSuperset ? const Radius.circular(12) : Radius.zero,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Subtle background tint
              color: supersetColor.withValues(alpha: 0.05),
              // Colored left border with gradient effect
              border: Border(
                left: BorderSide(
                  color: supersetColor.withValues(alpha: 0.6),
                  width: 4,
                ),
                // Add connecting lines for middle exercises
                top: !isFirstInSuperset
                    ? BorderSide(
                        color: supersetColor.withValues(alpha: 0.2),
                      )
                    : BorderSide.none,
              ),
              // Subtle glow effect
              boxShadow: [
                BoxShadow(
                  color: supersetColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: exerciseWidget,
          ),
        ),
      );
    }

    return exerciseWidget;
  }

  Widget _buildInitialBadge(String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(
          Icons.fitness_center,
          color: colorScheme.onPrimary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSetTile(
    GymSet set,
    int setNumber, {
    bool isDropSet = false,
    Set<RecordType> records = const {},
  }) {
    final reps = toString(set.reps);
    final weight = toString(set.weight);
    final colorScheme = Theme.of(context).colorScheme;
    final isWarmup = set.warmup;
    final hasRecords = records.isNotEmpty;

    String subtitle;
    if (set.cardio) {
      final cardioUnit = context.read<SettingsState>().value.cardioUnit;
      subtitle = formatCardioSummary(set, cardioUnit, includeSpeed: true);
    } else {
      subtitle = '$weight ${set.unit} x $reps';
    }

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isWarmup
              ? colorScheme.tertiaryContainer
              : isDropSet
                  ? colorScheme.secondaryContainer
                  : hasRecords
                      ? context.jl.pr.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border:
              hasRecords ? Border.all(color: context.jl.pr, width: 1.5) : null,
        ),
        child: Center(
          child: isWarmup
              ? Icon(
                  Icons.whatshot,
                  size: 14,
                  color: colorScheme.tertiary,
                )
              : isDropSet
                  ? Icon(
                      Icons.trending_down,
                      size: 14,
                      color: colorScheme.secondary,
                    )
                  : Text(
                      '$setNumber',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: hasRecords
                                ? context.jl.pr
                                : colorScheme.onSurface,
                          ),
                    ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: (isWarmup || isDropSet)
                      ? TextStyle(color: colorScheme.onSurfaceVariant)
                      : hasRecords
                          ? TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            )
                          : null,
                ),
              ),
              if (hasRecords) RecordCrown(records: records, size: 18),
            ],
          ),
          if (hasRecords)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: records.map((recordType) {
                  String label;
                  Color color;
                  switch (recordType) {
                    case RecordType.best1RM:
                      label = '1RM Record';
                      color = context.jl.pr;
                      break;
                    case RecordType.bestVolume:
                      label = 'Volume Record';
                      color = colorScheme.tertiary;
                      break;
                    case RecordType.bestWeight:
                      label = 'Weight Record';
                      color = colorScheme.secondary;
                      break;
                    case RecordType.bestDuration:
                      label = 'Time Record';
                      color = colorScheme.primary;
                      break;
                    case RecordType.bestDistance:
                      label = 'Distance Record';
                      color = colorScheme.tertiary;
                      break;
                    case RecordType.bestSpeed:
                      label = 'Speed Record';
                      color = context.jl.pr;
                      break;
                    case RecordType.bestIncline:
                      label = 'Incline Record';
                      color = colorScheme.secondary;
                      break;
                  }
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.9),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditSetPage(gymSet: set),
          ),
        );
      },
    );
  }

  Future<void> _showViewExerciseMenu(
    BuildContext parentContext,
    String exerciseName,
  ) async {
    final colorScheme = Theme.of(parentContext).colorScheme;

    await showModalBottomSheet(
      context: parentContext,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: brPill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exerciseName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.show_chart, color: colorScheme.primary),
              title: const Text('View Graph'),
              subtitle: const Text('Jump to graph page for this exercise'),
              onTap: () async {
                Navigator.pop(context);
                await _jumpToGraph(parentContext, exerciseName);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _jumpToGraph(
    BuildContext parentContext,
    String exerciseName,
  ) async {
    // Get the exercise data to determine if it's cardio or strength
    final exerciseData = await (db.gymSets.select()
          ..where((tbl) => tbl.name.equals(exerciseName))
          ..orderBy([
            (u) => OrderingTerm(expression: u.created, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (exerciseData == null || !parentContext.mounted) return;

    if (exerciseData.cardio) {
      final data = await getCardioData(
        target: exerciseData.unit,
        name: exerciseName,
        period: Period.months3,
      );
      if (!parentContext.mounted) return;
      Navigator.push(
        parentContext,
        MaterialPageRoute(
          builder: (context) => CardioPage(
            name: exerciseName,
            unit: exerciseData.unit,
            data: data,
          ),
        ),
      );
    } else {
      final data = await getStrengthData(
        target: exerciseData.unit,
        name: exerciseName,
        metric: StrengthMetric.bestWeight,
        period: Period.months3,
      );
      if (!parentContext.mounted) return;
      Navigator.push(
        parentContext,
        MaterialPageRoute(
          builder: (context) => StrengthPage(
            name: exerciseName,
            unit: exerciseData.unit,
            data: data,
          ),
        ),
      );
    }
  }

  Future<void> _resumeWorkout(BuildContext context) async {
    final workoutState = context.read<WorkoutState>();

    // Try to resume the workout
    final plan = await workoutState.resumeWorkout(widget.workout);

    if (plan == null && context.mounted) {
      // Failed to resume (another workout is active)
      toast('Finish your current workout first');
      return;
    }

    if (!context.mounted) return;

    // Navigate to the Plans tab and then to the workout page. Plans is created
    // on first visit, so wait for its navigator instead of a fixed delay.
    final plansNavigator = await workoutState.openPlansNavigator();

    if (!context.mounted) return;

    // Push the workout page (keeping Plans page in back stack)
    plansNavigator?.push(
      MaterialPageRoute(
        builder: (context) => StartPlanPage(plan: plan),
        settings: RouteSettings(
          name: 'StartPlanPage_${plan!.id}',
        ),
      ),
    );

    // Pop the detail page
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _editSelfie(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelfie = currentWorkout.selfieImagePath != null;

    // Show action sheet
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: brPill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.camera_alt, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Workout Selfie',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.camera_alt, color: colorScheme.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: colorScheme.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (hasSelfie)
              ListTile(
                leading: Icon(Icons.delete_outline, color: colorScheme.error),
                title: Text(
                  'Remove Selfie',
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null || !context.mounted) return;

    if (action == 'remove') {
      // Remove selfie
      await _removeSelfie();
    } else {
      // Capture new selfie
      final picker = ImagePicker();
      final source =
          action == 'camera' ? ImageSource.camera : ImageSource.gallery;

      final XFile? pickedFile = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
      );

      if (pickedFile != null) {
        await _updateSelfie(pickedFile.path);
      }
    }
  }

  Future<void> _editDuration() async {
    DateTime editStart = currentWorkout.startTime;
    DateTime editEnd = currentWorkout.endTime!;
    final dateFormat = DateFormat('yyyy MMM d');
    final timeFormat = DateFormat('HH:mm');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date'),
                trailing: Text(dateFormat.format(editStart)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: editStart,
                    firstDate: _datePickerFirstDate(editStart),
                    lastDate: _datePickerLastDate(editStart),
                  );
                  if (date != null) {
                    setDialogState(() {
                      editStart = _withDate(editStart, date);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Start Time'),
                trailing: Text(timeFormat.format(editStart)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(editStart),
                  );
                  if (time != null) {
                    setDialogState(() {
                      editStart = _withTime(editStart, time);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('End Date'),
                trailing: Text(dateFormat.format(editEnd)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: editEnd,
                    firstDate: _datePickerFirstDate(editEnd),
                    lastDate: _datePickerLastDate(editEnd),
                  );
                  if (date != null) {
                    setDialogState(() {
                      editEnd = _withDate(editEnd, date);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('End Time'),
                trailing: Text(timeFormat.format(editEnd)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(editEnd),
                  );
                  if (time != null) {
                    setDialogState(() {
                      editEnd = _withTime(editEnd, time);
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (editEnd.isBefore(editStart) ||
                    editEnd.isAtSameMomentAs(editStart)) {
                  toast('End time must be after start time');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved ?? false) {
      await (db.workouts.update()..where((w) => w.id.equals(widget.workout.id)))
          .write(
        WorkoutsCompanion(
          startTime: Value(editStart),
          endTime: Value(editEnd),
        ),
      );
      await _reloadWorkout();
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  DateTime _withDate(DateTime original, DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      original.hour,
      original.minute,
      original.second,
      original.millisecond,
      original.microsecond,
    );
  }

  DateTime _withTime(DateTime original, TimeOfDay time) {
    return DateTime(
      original.year,
      original.month,
      original.day,
      time.hour,
      time.minute,
      original.second,
      original.millisecond,
      original.microsecond,
    );
  }

  DateTime _datePickerFirstDate(DateTime value) {
    return DateTime(value.year - 10);
  }

  DateTime _datePickerLastDate(DateTime value) {
    final today = DateTime.now();
    final year = value.year > today.year ? value.year : today.year;
    return DateTime(year + 1, 12, 31);
  }

  Future<void> _reloadWorkout() async {
    final workout = await (db.workouts.select()
          ..where((w) => w.id.equals(widget.workout.id)))
        .getSingleOrNull();
    if (mounted && workout != null) {
      setState(() {
        _currentWorkout = workout;
      });
    }
  }

  Future<void> _updateSelfie(String imagePath) async {
    await (db.workouts.update()..where((w) => w.id.equals(widget.workout.id)))
        .write(
      WorkoutsCompanion(
        selfieImagePath: Value(imagePath),
      ),
    );

    await _reloadWorkout();
  }

  Future<void> _removeSelfie() async {
    await (db.workouts.update()..where((w) => w.id.equals(widget.workout.id)))
        .write(
      const WorkoutsCompanion(
        selfieImagePath: Value(null),
      ),
    );

    await _reloadWorkout();
  }

  Future<void> _deleteWorkout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: const Text(
          'This will delete the workout and all its sets. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      // Delete selfie file if it exists
      if (currentWorkout.selfieImagePath != null) {
        try {
          final file = File(currentWorkout.selfieImagePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Ignore file deletion errors
        }
      }

      // Delete all sets in this workout
      await (db.gymSets.delete()
            ..where((s) => s.workoutId.equals(widget.workout.id)))
          .go();
      // Delete the workout
      await (db.workouts.delete()..where((w) => w.id.equals(widget.workout.id)))
          .go();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}
