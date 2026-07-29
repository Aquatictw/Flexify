import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../coach/coach_sheet.dart';
import '../database/database.dart';
import '../database/query_helpers.dart';
import '../main.dart';
import '../theme/tokens.dart';
import '../widgets/plate_calculator.dart';
import '../widgets/superset/superset_manager_dialog.dart';
import '../widgets/workout/add_exercise_card.dart';
import '../widgets/workout/exercise_picker_modal.dart';
import '../widgets/workout/notes_section.dart';
import '../workouts/workout_state.dart';
import 'exercise_sets_card.dart';
import 'plan_state.dart';

class StartPlanPage extends StatefulWidget {
  const StartPlanPage({required this.plan, super.key});
  final Plan plan;

  @override
  _StartPlanPageState createState() => _StartPlanPageState();
}

// Represents an exercise item in the workout (either from plan or ad-hoc)
class _ExerciseItem {
  // Preserve sequence number, mutable for reordering

  _ExerciseItem.plan(PlanExercise exercise, {required this.sequence})
      : isPlanExercise = true,
        planExerciseId = exercise.id,
        adHocName = null,
        uniqueId =
            'plan_${exercise.id}_${DateTime.now().microsecondsSinceEpoch}';

  _ExerciseItem.adHoc(String name, {required this.sequence})
      : isPlanExercise = false,
        planExerciseId = null,
        adHocName = name,
        uniqueId = 'adhoc_${name}_${DateTime.now().microsecondsSinceEpoch}';
  final bool isPlanExercise;
  final int? planExerciseId;
  final String? adHocName;
  final String uniqueId;
  int sequence;

  String get key => uniqueId;
}

class _StartPlanPageState extends State<StartPlanPage> {
  int? workoutId;
  late Stream<List<PlanExercise>> stream;
  late String title = widget.plan.days.replaceAll(',', ', ');
  Set<String> expandedExercises = {}; // Now uses string keys
  final TextEditingController _notesController = TextEditingController();
  bool _showNotes = false;
  bool _isReorderMode = false; // Reorder mode toggle
  List<_ExerciseItem> _exerciseOrder = []; // Unified ordered list
  Map<int, PlanExercise> _planExercisesMap = {}; // Cache of plan exercises
  final Map<String, String> _exerciseNotes =
      {}; // Track notes per exercise (key -> notes)
  late WorkoutState _workoutState; // Store reference for dispose()
  int _refreshCounter = 0; // Counter to force ExerciseSetsCard refresh

  @override
  void initState() {
    super.initState();
    title = widget.plan.title?.isNotEmpty ?? false
        ? widget.plan.title!
        : widget.plan.days.replaceAll(',', ', ');

    // Listen for workout state changes to pop when workout ends
    _workoutState = context.read<WorkoutState>();
    _workoutState.addListener(_onWorkoutStateChanged);

    _loadExercises();
  }

  void _onWorkoutStateChanged() {
    // If workout was ended (no active workout), pop this page
    if (!_workoutState.hasActiveWorkout && mounted) {
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
        _notesController.text = workoutState.activeWorkout!.notes ?? '';
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
        _notesController.text = workoutState.activeWorkout!.notes ?? '';
      });
    }

    // Update gym counts with workoutId to show only this workout's progress
    if (!context.mounted) return;
    final planState = context.read<PlanState>();
    await planState.updateGymCounts(widget.plan.id, workoutId);

    // Use optimized query - combines 2 queries into 1
    final workoutData = await QueryHelpers.loadWorkoutResumeData(
      workoutId: workoutId!,
    );

    final existingSets = workoutData.existingSets;
    final removedExercises = workoutData.removedExercises;

    // Load plan exercises (if not freeform)
    List<PlanExercise> planExercises = [];
    if (widget.plan.id != -1) {
      planExercises = await stream.first;
    }

    if (mounted) {
      setState(() {
        _planExercisesMap = {for (final e in planExercises) e.id: e};
        _exerciseOrder = [];

        if (existingSets.isEmpty) {
          // New workout - load plan exercises minus removed ones
          int seq = 0;
          for (final planEx in planExercises) {
            if (!removedExercises.contains(planEx.exercise)) {
              _exerciseOrder.add(_ExerciseItem.plan(planEx, sequence: seq));
              seq++;
            }
          }
        } else {
          // Resuming - rebuild exercise list from sets (preserves order)
          // Group sets by exercise, but detect sequence gaps to identify separate instances
          final List<({String name, int minSeq, int maxSeq})> exerciseGroups =
              [];

          String? currentExercise;
          int? currentMinSeq;
          int? currentMaxSeq;

          for (final set in existingSets) {
            if (currentExercise == null ||
                set.name != currentExercise ||
                (currentMaxSeq != null && set.sequence != currentMaxSeq)) {
              // New exercise or sequence change detected - save previous group
              if (currentExercise != null) {
                exerciseGroups.add(
                  (
                    name: currentExercise,
                    minSeq: currentMinSeq!,
                    maxSeq: currentMaxSeq!,
                  ),
                );
              }
              // Start new group
              currentExercise = set.name;
              currentMinSeq = set.sequence;
              currentMaxSeq = set.sequence;
            } else {
              // Continue current group - sets must have same sequence
              currentMaxSeq = set.sequence;
            }
          }

          // Add last group
          if (currentExercise != null) {
            exerciseGroups.add(
              (
                name: currentExercise,
                minSeq: currentMinSeq!,
                maxSeq: currentMaxSeq!,
              ),
            );
          }

          // Create exercise items for each group
          for (final group in exerciseGroups) {
            final planExercise = planExercises
                .where((e) => e.exercise == group.name)
                .firstOrNull;
            if (planExercise != null) {
              _exerciseOrder.add(
                _ExerciseItem.plan(planExercise, sequence: group.minSeq),
              );
            } else {
              _exerciseOrder
                  .add(_ExerciseItem.adHoc(group.name, sequence: group.minSeq));
            }

            // Restore notes from first set of this group
            final setWithNotes = existingSets
                .where(
                  (s) =>
                      s.name == group.name &&
                      s.sequence >= group.minSeq &&
                      s.sequence <= group.maxSeq &&
                      (s.notes?.isNotEmpty ?? false),
                )
                .firstOrNull;

            if (setWithNotes != null) {
              _exerciseNotes[_exerciseOrder.last.key] = setWithNotes.notes!;
            }
          }
        }

        // Expand all exercises by default
        for (final item in _exerciseOrder) {
          expandedExercises.add(item.key);
        }
      });
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    setState(() {
      final item = _exerciseOrder.removeAt(oldIndex);
      _exerciseOrder.insert(newIndex, item);
    });

    HapticFeedback.mediumImpact();

    // Update sequence numbers in the database and in-memory items to match the new visual order
    if (workoutId != null) {
      // We need to update all exercises' sequence numbers to match their new positions
      for (int i = 0; i < _exerciseOrder.length; i++) {
        final item = _exerciseOrder[i];

        // Get exercise name based on whether it's a plan exercise or ad-hoc
        final String exerciseName;
        if (item.isPlanExercise) {
          final exercise = _planExercisesMap[item.planExerciseId];
          if (exercise == null) continue;
          exerciseName = exercise.exercise;
        } else {
          exerciseName = item.adHocName!;
        }

        // Update all sets for this specific exercise instance to have the new sequence number
        // Match on old sequence (item.sequence) and update to new sequence (i)
        // Update both completed (hidden=0) and uncompleted (hidden=1) sets, but not tombstones (sequence=-1)
        final oldSequence = item.sequence;
        await db.customUpdate(
          'UPDATE gym_sets SET sequence = ? WHERE workout_id = ? AND name = ? AND sequence = ?',
          updates: {db.gymSets},
          variables: [
            Variable.withInt(i),
            Variable.withInt(workoutId!),
            Variable.withString(exerciseName),
            Variable.withInt(oldSequence),
          ],
        );

        // Update the in-memory sequence number after database update
        item.sequence = i;
      }
    }
  }

  Future<void> _saveNotes() async {
    if (workoutId == null) return;
    await (db.workouts.update()..where((w) => w.id.equals(workoutId!)))
        .write(WorkoutsCompanion(notes: Value(_notesController.text)));
  }

  /// Checks if an exercise being deleted is part of a superset, and if so,
  /// automatically unmarks the remaining exercise if only one remains in the superset.
  Future<void> _checkAndUnmarkSingleSuperset(String supersetId) async {
    if (workoutId == null) return;

    // Count how many distinct exercises (by sequence) remain in this superset
    final remainingExercises = await (db.gymSets.selectOnly(distinct: true)
          ..addColumns([db.gymSets.sequence])
          ..where(
            db.gymSets.workoutId.equals(workoutId!) &
                db.gymSets.supersetId.equals(supersetId),
          ))
        .get();

    // If only one exercise remains, unmark it
    if (remainingExercises.length == 1) {
      await db.customUpdate(
        'UPDATE gym_sets SET superset_id = NULL, superset_position = NULL WHERE workout_id = ? AND superset_id = ?',
        updates: {db.gymSets},
        variables: [
          Variable.withInt(workoutId!),
          Variable.withString(supersetId),
        ],
      );
    }
  }

  Future<void> _editWorkoutTitle() async {
    final titleController = TextEditingController(text: title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Workout Title'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
            hintText: 'Enter workout title...',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, titleController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && mounted) {
      setState(() {
        title = newTitle;
      });
      // Update workout name in database
      if (workoutId != null) {
        await (db.workouts.update()..where((w) => w.id.equals(workoutId!)))
            .write(WorkoutsCompanion(name: Value(newTitle)));
        // Refresh workout state
        final workoutState = context.read<WorkoutState>();
        await workoutState.refresh();
      }
    }
    // Don't dispose controller - Flutter manages the dialog lifecycle
  }

  void _showSupersetManager() {
    if (workoutId == null || _exerciseOrder.length < 2) return;

    final exercises = _exerciseOrder.map((item) {
      final name = item.isPlanExercise
          ? _planExercisesMap[item.planExerciseId]?.exercise ?? 'Unknown'
          : item.adHocName!;
      return (name: name, sequence: item.sequence);
    }).toList();

    showDialog(
      context: context,
      builder: (context) => SupersetManagerDialog(
        exercises: exercises,
        workoutId: workoutId!,
        onSupersetCreated: () {
          // Increment refresh counter to force ExerciseSetsCard widgets to reload
          setState(() {
            _refreshCounter++;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _saveNotes();
    _notesController.dispose();
    _workoutState.removeListener(_onWorkoutStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        // Update plan exercises map with latest data
        _planExercisesMap = {for (final e in exercises) e.id: e};

        return Scaffold(
          appBar: AppBar(
            title: _isReorderMode
                ? const Text('Reorder Exercises')
                : GestureDetector(
                    onTap: _editWorkoutTitle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
            leading: IconButton(
              icon: Icon(_isReorderMode ? Icons.close : Icons.arrow_back),
              onPressed: () {
                if (_isReorderMode) {
                  setState(() => _isReorderMode = false);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            actions: [
              if (_isReorderMode)
                TextButton.icon(
                  onPressed: () => setState(() => _isReorderMode = false),
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.psychology_rounded),
                  tooltip: 'Coach',
                  onPressed: workoutId == null
                      ? null
                      : () => showCoachSheet(
                            context,
                            workoutId: workoutId!,
                            onSessionChanged: () {
                              if (mounted) {
                                setState(() => _refreshCounter++);
                              }
                            },
                          ),
                ),
                IconButton(
                  icon: const Icon(Icons.calculate_outlined),
                  tooltip: 'Plate calculator',
                  onPressed: () => showPlateCalculator(context),
                ),
                IconButton(
                  icon: const Icon(Icons.link),
                  tooltip: 'Create superset',
                  onPressed:
                      _exerciseOrder.length >= 2 ? _showSupersetManager : null,
                ),
                IconButton(
                  icon: const Icon(Icons.swap_vert),
                  tooltip: 'Reorder exercises',
                  onPressed: _exerciseOrder.length > 1
                      ? () => setState(() => _isReorderMode = true)
                      : null,
                ),
                IconButton(
                  icon: Icon(
                    _showNotes ? Icons.note : Icons.note_outlined,
                    color: _showNotes ? colorScheme.primary : null,
                  ),
                  tooltip: 'Workout notes',
                  onPressed: () {
                    setState(() {
                      _showNotes = !_showNotes;
                    });
                  },
                ),
              ],
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Notes section
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: NotesSection(
                      controller: _notesController,
                      onChanged: _saveNotes,
                    ),
                    crossFadeState: _showNotes
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: durMed,
                  ),
                  // Exercises list
                  Expanded(
                    child: _isReorderMode
                        ? _buildReorderableList(colorScheme)
                        : _buildExerciseList(colorScheme),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: space8, bottom: 200),
      itemCount: _exerciseOrder.length + 1,
      itemBuilder: (context, index) {
        if (index >= _exerciseOrder.length) {
          return AddExerciseCard(
            key: const ValueKey('add_exercise'),
            onTap: () => _showAddExerciseModal(context),
          );
        }

        final item = _exerciseOrder[index];

        if (item.isPlanExercise) {
          final exercise = _planExercisesMap[item.planExerciseId];
          if (exercise == null) return const SizedBox.shrink();

          return ExerciseSetsCard(
            key: ValueKey(item.key),
            refreshToken: _refreshCounter,
            exercise: exercise,
            planId: widget.plan.id,
            workoutId: workoutId,
            isExpanded: expandedExercises.contains(item.key),
            exerciseNotes: _exerciseNotes[item.key],
            sequence: item.sequence, // Use preserved sequence number
            onNotesChanged: (notes) {
              setState(() {
                if (notes.isEmpty) {
                  _exerciseNotes.remove(item.key);
                } else {
                  _exerciseNotes[item.key] = notes;
                }
              });
            },
            onToggleExpand: () {
              setState(() {
                if (expandedExercises.contains(item.key)) {
                  expandedExercises.remove(item.key);
                } else {
                  expandedExercises.add(item.key);
                }
              });
            },
            onSetCompleted: () {},
            onDeleteExercise: () async {
              final exerciseName = exercise.exercise;
              final removedSequence = item.sequence;

              // Check if this exercise is part of a superset before deleting
              String? supersetId;
              if (workoutId != null) {
                final firstSet = await (db.gymSets.select()
                      ..where(
                        (s) =>
                            s.workoutId.equals(workoutId!) &
                            s.name.equals(exerciseName) &
                            s.sequence.equals(item.sequence),
                      )
                      ..limit(1))
                    .getSingleOrNull();
                supersetId = firstSet?.supersetId;
              }

              // Delete all sets for this specific exercise instance from the database
              await (db.gymSets.delete()
                    ..where(
                      (s) =>
                          s.workoutId.equals(workoutId!) &
                          s.name.equals(exerciseName) &
                          s.sequence.equals(item.sequence),
                    ))
                  .go();

              // Insert a tombstone marker to remember this exercise was removed
              // This persists the removal even when no other sets exist
              await db.gymSets.insertOne(
                GymSetsCompanion.insert(
                  name: exerciseName,
                  reps: -1, // Special marker value
                  weight: 0,
                  unit: 'kg',
                  created: DateTime.now(),
                  workoutId: Value(workoutId),
                  hidden: const Value(true), // Hide from history
                  sequence: const Value(-1), // Special sequence for tombstones
                ),
              );

              // Update sequence numbers for all exercises after the removed one
              // This ensures the sequence numbers match the new visual order
              await db.customUpdate(
                'UPDATE gym_sets SET sequence = sequence - 1 WHERE workout_id = ? AND sequence > ?',
                updates: {db.gymSets},
                variables: [
                  Variable.withInt(workoutId!),
                  Variable.withInt(removedSequence),
                ],
              );

              // If exercise was in a superset, check if only one remains and unmark it
              if (supersetId != null) {
                await _checkAndUnmarkSingleSuperset(supersetId);
              }

              setState(() {
                _exerciseOrder.removeAt(index);
                _exerciseNotes.remove(item.key);

                // Synchronize in-memory sequence values with database
                // After decrementing sequences in DB, update in-memory items to match
                for (int i = index; i < _exerciseOrder.length; i++) {
                  _exerciseOrder[i].sequence = i;
                }

                // Only force sibling cards to reload when a superset was
                // affected (badge needs refresh). A plain delete doesn't.
                if (supersetId != null) _refreshCounter++;
              });
            },
          );
        } else {
          // Create a temporary PlanExercise for ad-hoc exercises
          final tempExercise = PlanExercise(
            id: -1,
            planId: -1,
            exercise: item.adHocName!,
            enabled: true,
            timers: true,
            sequence: item.sequence,
          );

          return ExerciseSetsCard(
            key: ValueKey(item.key),
            refreshToken: _refreshCounter,
            exercise: tempExercise,
            planId: -1, // Ad-hoc exercises don't have a real plan
            workoutId: workoutId,
            isExpanded: expandedExercises.contains(item.key),
            exerciseNotes: _exerciseNotes[item.key],
            sequence: item.sequence, // Use preserved sequence number
            onNotesChanged: (notes) {
              setState(() {
                if (notes.isEmpty) {
                  _exerciseNotes.remove(item.key);
                } else {
                  _exerciseNotes[item.key] = notes;
                }
              });
            },
            onToggleExpand: () {
              setState(() {
                if (expandedExercises.contains(item.key)) {
                  expandedExercises.remove(item.key);
                } else {
                  expandedExercises.add(item.key);
                }
              });
            },
            onSetCompleted:
                () {}, // No special action needed for ad-hoc exercises
            onDeleteExercise: () async {
              final exerciseName = item.adHocName!;
              final removedSequence = item.sequence;

              // Check if this exercise is part of a superset before deleting
              String? supersetId;
              if (workoutId != null) {
                final firstSet = await (db.gymSets.select()
                      ..where(
                        (s) =>
                            s.workoutId.equals(workoutId!) &
                            s.name.equals(exerciseName) &
                            s.sequence.equals(item.sequence),
                      )
                      ..limit(1))
                    .getSingleOrNull();
                supersetId = firstSet?.supersetId;
              }

              // Delete all sets for this specific exercise instance from the database
              await (db.gymSets.delete()
                    ..where(
                      (s) =>
                          s.workoutId.equals(workoutId!) &
                          s.name.equals(exerciseName) &
                          s.sequence.equals(item.sequence),
                    ))
                  .go();

              // Insert a tombstone marker to remember this exercise was removed
              await db.gymSets.insertOne(
                GymSetsCompanion.insert(
                  name: exerciseName,
                  reps: -1, // Special marker value
                  weight: 0,
                  unit: 'kg',
                  created: DateTime.now(),
                  workoutId: Value(workoutId),
                  hidden: const Value(true), // Hide from history
                  sequence: const Value(-1), // Special sequence for tombstones
                ),
              );

              // Update sequence numbers for all exercises after the removed one
              // This ensures the sequence numbers match the new visual order
              await db.customUpdate(
                'UPDATE gym_sets SET sequence = sequence - 1 WHERE workout_id = ? AND sequence > ?',
                updates: {db.gymSets},
                variables: [
                  Variable.withInt(workoutId!),
                  Variable.withInt(removedSequence),
                ],
              );

              // If exercise was in a superset, check if only one remains and unmark it
              if (supersetId != null) {
                await _checkAndUnmarkSingleSuperset(supersetId);
              }

              setState(() {
                _exerciseOrder.removeAt(index);
                _exerciseNotes.remove(item.key);

                // Synchronize in-memory sequence values with database
                // After decrementing sequences in DB, update in-memory items to match
                for (int i = index; i < _exerciseOrder.length; i++) {
                  _exerciseOrder[i].sequence = i;
                }

                // Only force sibling cards to reload when a superset was
                // affected (badge needs refresh). A plain delete doesn't.
                if (supersetId != null) _refreshCounter++;
              });
            },
          );
        }
      },
    );
  }

  Widget _buildReorderableList(ColorScheme colorScheme) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: space8, bottom: 100),
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(
            elevation: 8,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
            borderRadius: brMd,
            child: child,
          ),
          child: child,
        );
      },
      itemCount: _exerciseOrder.length,
      itemBuilder: (context, index) {
        final item = _exerciseOrder[index];
        final exerciseName = item.isPlanExercise
            ? _planExercisesMap[item.planExerciseId]?.exercise ?? 'Unknown'
            : item.adHocName ?? 'Unknown';

        return _ReorderableExerciseTile(
          key: ValueKey(item.key),
          index: index,
          exerciseName: exerciseName,
          isAdHoc: !item.isPlanExercise,
          colorScheme: colorScheme,
        );
      },
    );
  }

  Future<void> _showAddExerciseModal(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => const ExercisePickerModal(),
    );

    if (result != null && mounted) {
      final nextSequence = _exerciseOrder.isEmpty
          ? 0
          : _exerciseOrder
                  .map((e) => e.sequence)
                  .reduce((a, b) => a > b ? a : b) +
              1;
      final newItem = _ExerciseItem.adHoc(result, sequence: nextSequence);
      setState(() {
        _exerciseOrder.add(newItem);
        expandedExercises.add(newItem.key);
      });
    }
  }
}

// Clean reorderable tile for exercise reorder mode
class _ReorderableExerciseTile extends StatelessWidget {
  const _ReorderableExerciseTile({
    required this.index,
    required this.exerciseName,
    required this.isAdHoc,
    required this.colorScheme,
    super.key,
  });
  final int index;
  final String exerciseName;
  final bool isAdHoc;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: space12, vertical: space4),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: brSm,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ),
        title: Text(
          exerciseName,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: isAdHoc
            ? Text(
                'Added exercise',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.tertiary,
                    ),
              )
            : null,
        trailing: ReorderableDragStartListener(
          index: index,
          child: Container(
            padding: const EdgeInsets.all(space8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: brSm,
            ),
            child: Icon(
              Icons.drag_handle,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
