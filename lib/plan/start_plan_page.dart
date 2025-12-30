import 'package:drift/drift.dart' hide Column;
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/plan/exercise_sets_card.dart';
import 'package:flexify/plan/plan_state.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/workouts/workout_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class StartPlanPage extends StatefulWidget {
  final Plan plan;

  const StartPlanPage({super.key, required this.plan});

  @override
  createState() => _StartPlanPageState();
}

// Represents an exercise item in the workout (either from plan or ad-hoc)
class _ExerciseItem {
  final bool isPlanExercise;
  final int? planExerciseId;
  final String? adHocName;

  _ExerciseItem.plan(PlanExercise exercise)
      : isPlanExercise = true,
        planExerciseId = exercise.id,
        adHocName = null;

  _ExerciseItem.adHoc(String name)
      : isPlanExercise = false,
        planExerciseId = null,
        adHocName = name;

  String get key => isPlanExercise ? 'plan_$planExerciseId' : 'adhoc_$adHocName';
}

class _StartPlanPageState extends State<StartPlanPage> {
  int? workoutId;
  late Stream<List<PlanExercise>> stream;
  late String title = widget.plan.days.replaceAll(",", ", ");
  Set<String> expandedExercises = {}; // Now uses string keys
  final TextEditingController _notesController = TextEditingController();
  bool _showNotes = false;
  bool _isReorderMode = false; // Reorder mode toggle
  List<_ExerciseItem> _exerciseOrder = []; // Unified ordered list
  Map<int, PlanExercise> _planExercisesMap = {}; // Cache of plan exercises
  Map<String, String> _exerciseNotes = {}; // Track notes per exercise (key -> notes)

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
    final planState = context.read<PlanState>();
    await planState.updateGymCounts(widget.plan.id, workoutId);

    // Query all sets for this workout to understand its current state
    final existingSets = await (db.gymSets.select()
          ..where((s) => s.workoutId.equals(workoutId!))
          ..orderBy([
            (s) => OrderingTerm(expression: s.sequence, mode: OrderingMode.asc)
          ]))
        .get();

    // Get unique exercise names from existing sets
    final exercisesWithSets = existingSets.map((s) => s.name).toSet();

    // Load plan exercises (if not freeform)
    List<PlanExercise> planExercises = [];
    if (widget.plan.id != -1) {
      planExercises = await stream.first;
    }

    // Identify removed exercises (those with only tombstone markers)
    final removedExercises = <String>{};
    final exerciseSets = <String, List<GymSet>>{};

    for (final set in existingSets) {
      exerciseSets.putIfAbsent(set.name, () => []).add(set);
    }

    for (final entry in exerciseSets.entries) {
      // If all sets are tombstones (sequence=-1), this exercise was removed
      if (entry.value.every((s) => s.sequence == -1)) {
        removedExercises.add(entry.key);
      }
    }

    // Insert placeholders for new plan exercises (before setState)
    if (existingSets.isEmpty || existingSets.every((s) => s.sequence == -1)) {
      for (final planEx in planExercises) {
        if (!removedExercises.contains(planEx.exercise)) {
          await _ensureExercisePlaceholder(planEx.exercise, workoutId!);
        }
      }
    }

    if (mounted) {
      setState(() {
        // Build map from plan exercises
        _planExercisesMap = {for (var e in planExercises) e.id: e};

        // Build exercise order list
        _exerciseOrder = [];

        if (existingSets.isEmpty || existingSets.every((s) => s.sequence == -1)) {
          // Brand new workout OR only tombstones - load plan exercises minus removed ones
          for (final planEx in planExercises) {
            if (!removedExercises.contains(planEx.exercise)) {
              _exerciseOrder.add(_ExerciseItem.plan(planEx));
            }
          }
        } else {
          // Resuming - rebuild exercise list from sets (preserves order and removals)
          final seenExercises = <String>{};
          final orderedExercises = <String>[];

          // Only process sets that aren't tombstones (includes placeholders with sequence=-2)
          for (final set in existingSets.where((s) => s.sequence != -1)) {
            if (!seenExercises.contains(set.name)) {
              seenExercises.add(set.name);
              orderedExercises.add(set.name);
            }
          }

          // Add exercises in the order they appear in sets
          for (final name in orderedExercises) {
            final planExercise = planExercises.where((e) => e.exercise == name).firstOrNull;
            if (planExercise != null) {
              _exerciseOrder.add(_ExerciseItem.plan(planExercise));
            } else {
              // Custom/freeform exercise
              _exerciseOrder.add(_ExerciseItem.adHoc(name));
            }
          }

          // Restore notes from first non-tombstone, non-placeholder set
          for (final name in orderedExercises) {
            final realSet = existingSets.where(
              (s) => s.name == name && s.sequence >= 0, // Real sets have sequence >= 0
            ).firstOrNull;

            if (realSet?.notes?.isNotEmpty == true) {
              final item = _exerciseOrder.firstWhere((item) =>
                item.isPlanExercise
                  ? _planExercisesMap[item.planExerciseId]?.exercise == name
                  : item.adHocName == name);
              _exerciseNotes[item.key] = realSet!.notes!;
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

  void _onReorder(int oldIndex, int newIndex) {
    // Adjust newIndex if moving down the list
    if (newIndex > oldIndex) newIndex--;

    setState(() {
      final item = _exerciseOrder.removeAt(oldIndex);
      _exerciseOrder.insert(newIndex, item);
    });

    HapticFeedback.mediumImpact();
  }

  /// Ensures an exercise has a placeholder marker in the database so it persists
  /// even without completed sets. Placeholder has sequence=-2 and hidden=true.
  Future<void> _ensureExercisePlaceholder(String exerciseName, int workoutId) async {
    // Check if exercise already has any sets (including placeholders)
    final existingCount = await (db.gymSets.select()
          ..where((s) =>
            s.workoutId.equals(workoutId) &
            s.name.equals(exerciseName)))
        .get()
        .then((sets) => sets.length);

    // Only insert placeholder if exercise has no sets at all
    if (existingCount == 0) {
      await db.gymSets.insertOne(
        GymSetsCompanion.insert(
          name: exerciseName,
          reps: 0,
          weight: 0,
          unit: 'kg',
          created: DateTime.now(),
          workoutId: Value(workoutId),
          hidden: const Value(true), // Hide from history
          sequence: const Value(-2), // Placeholder marker (different from tombstone -1)
        ),
      );
    }
  }

  Future<void> _saveNotes() async {
    if (workoutId == null) return;
    await (db.workouts.update()..where((w) => w.id.equals(workoutId!)))
        .write(WorkoutsCompanion(notes: Value(_notesController.text)));
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
    titleController.dispose();
  }

  @override
  void dispose() {
    _saveNotes();
    _notesController.dispose();
    final workoutState = context.read<WorkoutState>();
    workoutState.removeListener(_onWorkoutStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plan.title?.isNotEmpty == true) title = widget.plan.title!;
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
        _planExercisesMap = {for (var e in exercises) e.id: e};

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
          body: Column(
            children: [
              // Notes section
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: _NotesSection(
                  controller: _notesController,
                  onChanged: _saveNotes,
                ),
                crossFadeState: _showNotes
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
              // Exercises list
              Expanded(
                child: _isReorderMode
                    ? _buildReorderableList(colorScheme)
                    : _buildExerciseList(colorScheme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 200),
      itemCount: _exerciseOrder.length + 1,
      itemBuilder: (context, index) {
        if (index >= _exerciseOrder.length) {
          return _AddExerciseCard(
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
            exercise: exercise,
            planId: widget.plan.id,
            workoutId: workoutId,
            isExpanded: expandedExercises.contains(item.key),
            exerciseNotes: _exerciseNotes[item.key],
            sequence: index, // Pass the visual order
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
              // Delete all sets for this exercise from the database
              await (db.gymSets.delete()
                    ..where((s) =>
                      s.workoutId.equals(workoutId!) &
                      s.name.equals(exerciseName)))
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
                  workoutId: Value(workoutId!),
                  hidden: const Value(true), // Hide from history
                  sequence: const Value(-1), // Special sequence for tombstones
                ),
              );

              setState(() {
                _exerciseOrder.removeAt(index);
                _exerciseNotes.remove(item.key);
              });
            },
          );
        } else {
          return _AdHocExerciseCard(
            key: ValueKey(item.key),
            exerciseName: item.adHocName!,
            workoutId: workoutId,
            isExpanded: expandedExercises.contains(item.key),
            exerciseNotes: _exerciseNotes[item.key],
            sequence: index, // Pass the visual order
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
            onRemove: () async {
              final exerciseName = item.adHocName!;
              // Delete all sets for this exercise from the database
              await (db.gymSets.delete()
                    ..where((s) =>
                      s.workoutId.equals(workoutId!) &
                      s.name.equals(exerciseName)))
                  .go();

              // Insert a tombstone marker to remember this exercise was removed
              await db.gymSets.insertOne(
                GymSetsCompanion.insert(
                  name: exerciseName,
                  reps: -1, // Special marker value
                  weight: 0,
                  unit: 'kg',
                  created: DateTime.now(),
                  workoutId: Value(workoutId!),
                  hidden: const Value(true), // Hide from history
                  sequence: const Value(-1), // Special sequence for tombstones
                ),
              );

              setState(() {
                _exerciseOrder.removeAt(index);
                _exerciseNotes.remove(item.key);
              });
            },
          );
        }
      },
    );
  }

  Widget _buildReorderableList(ColorScheme colorScheme) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(
            elevation: 8,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
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
    final existingAdHocNames = _exerciseOrder
        .where((item) => !item.isPlanExercise)
        .map((item) => item.adHocName!)
        .toList();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => _ExercisePickerModal(
        existingExercises: existingAdHocNames,
      ),
    );

    if (result != null && mounted) {
      final newItem = _ExerciseItem.adHoc(result);
      setState(() {
        _exerciseOrder.add(newItem);
        expandedExercises.add(newItem.key);
      });
    }
  }
}

// Clean reorderable tile for exercise reorder mode
class _ReorderableExerciseTile extends StatelessWidget {
  final int index;
  final String exerciseName;
  final bool isAdHoc;
  final ColorScheme colorScheme;

  const _ReorderableExerciseTile({
    super.key,
    required this.index,
    required this.exerciseName,
    required this.isAdHoc,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        title: Text(
          exerciseName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: isAdHoc
            ? Text(
                'Added exercise',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.tertiary,
                ),
              )
            : null,
        trailing: ReorderableDragStartListener(
          index: index,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.drag_handle,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _NotesSection({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Workout Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 2,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Add notes about your workout...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddExerciseCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.2),
                  colorScheme.secondaryContainer.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Add Exercise',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExercisePickerModal extends StatefulWidget {
  final List<String> existingExercises;

  const _ExercisePickerModal({required this.existingExercises});

  @override
  State<_ExercisePickerModal> createState() => _ExercisePickerModalState();
}

class _ExercisePickerModalState extends State<_ExercisePickerModal> {
  String _search = '';
  List<String> _allExercises = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    // Get distinct exercise names from gym_sets
    final sets = await db.gymSets.select().get();
    final exerciseNames = sets.map((s) => s.name).toSet().toList();
    exerciseNames.sort();

    if (mounted) {
      setState(() {
        _allExercises = exerciseNames;
        _loading = false;
      });
    }
  }

  List<String> get _filteredExercises {
    if (_search.isEmpty) return _allExercises;
    return _allExercises
        .where((e) => e.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add Exercise',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          // Exercise list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No exercises found',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (_search.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              FilledButton.tonal(
                                onPressed: () =>
                                    Navigator.pop(context, _search),
                                child: Text('Create "$_search"'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
                          final alreadyAdded =
                              widget.existingExercises.contains(exercise);

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: alreadyAdded
                                    ? colorScheme.surfaceContainerHighest
                                    : colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                size: 20,
                                color: alreadyAdded
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              exercise,
                              style: TextStyle(
                                color: alreadyAdded
                                    ? colorScheme.onSurfaceVariant
                                    : null,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: alreadyAdded
                                ? Icon(
                                    Icons.check_circle,
                                    color: colorScheme.primary,
                                  )
                                : Icon(
                                    Icons.add_circle_outline,
                                    color: colorScheme.primary,
                                  ),
                            enabled: !alreadyAdded,
                            onTap: alreadyAdded
                                ? null
                                : () => Navigator.pop(context, exercise),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _AdHocExerciseCard extends StatefulWidget {
  final String exerciseName;
  final int? workoutId;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onRemove;
  final String? exerciseNotes;
  final ValueChanged<String>? onNotesChanged;
  final int sequence; // Exercise order within workout

  const _AdHocExerciseCard({
    super.key,
    required this.exerciseName,
    required this.workoutId,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onRemove,
    this.exerciseNotes,
    this.onNotesChanged,
    this.sequence = 0,
  });

  @override
  State<_AdHocExerciseCard> createState() => _AdHocExerciseCardState();
}

class _AdHocExerciseCardState extends State<_AdHocExerciseCard> {
  List<SetData> sets = [];
  bool _initialized = false;
  String unit = 'kg';
  double _defaultWeight = 0.0;
  int _defaultReps = 8;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final settings = context.read<SettingsState>().value;

    // Get the last set for this exercise to get default weight
    final lastSet = await (db.gymSets.select()
          ..where((tbl) => tbl.name.equals(widget.exerciseName))
          ..orderBy([
            (u) => OrderingTerm(expression: u.created, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();

    _defaultWeight = lastSet?.weight ?? 0.0;
    _defaultReps = lastSet?.reps.toInt() ?? 8;
    final defaultUnit = lastSet?.unit ?? settings.strengthUnit;

    // Get ALL sets (including uncompleted/hidden ones) in this workout for this exercise
    List<GymSet> existingSets = [];
    if (widget.workoutId != null) {
      existingSets = await (db.gymSets.select()
            ..where((tbl) =>
                tbl.name.equals(widget.exerciseName) &
                tbl.workoutId.equals(widget.workoutId!) &
                tbl.sequence.isBiggerOrEqualValue(0)) // Exclude tombstones and placeholders
            ..orderBy([
              (u) => OrderingTerm(expression: u.created, mode: OrderingMode.asc),
            ]))
          .get();
    }

    if (!mounted) return;

    setState(() {
      unit = defaultUnit;

      if (existingSets.isNotEmpty) {
        // Load existing sets from database
        sets = existingSets.map((set) {
          return SetData(
            weight: set.weight,
            reps: set.reps.toInt(),
            completed: !set.hidden, // hidden=false means completed
            savedSetId: set.id,
          );
        }).toList();
      } else {
        // Start with 3 empty sets
        sets = List.generate(3, (_) => SetData(
          weight: _defaultWeight,
          reps: _defaultReps,
          completed: false,
        ));
      }
      _initialized = true;
    });
  }

  int get completedCount => sets.where((s) => s.completed).length;

  Future<void> _showExerciseMenu(BuildContext parentContext) async {
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
                borderRadius: BorderRadius.circular(2),
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
                      widget.exerciseName,
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
              leading: Icon(Icons.note_add_outlined, color: colorScheme.primary),
              title: const Text('Add Notes'),
              subtitle: widget.exerciseNotes?.isNotEmpty == true
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
              leading: Icon(Icons.remove_circle_outline, color: colorScheme.error),
              title: Text('Remove Exercise', style: TextStyle(color: colorScheme.error)),
              subtitle: const Text('Remove this exercise from workout'),
              onTap: () {
                Navigator.pop(context);
                widget.onRemove();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showNotesDialog(BuildContext parentContext) async {
    final controller = TextEditingController(text: widget.exerciseNotes ?? '');
    final result = await showDialog<String>(
      context: parentContext,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text('Notes for ${widget.exerciseName}'),
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

  String _getTotalVolume() {
    final total = sets
        .where((s) => s.completed)
        .fold<double>(0, (sum, s) => sum + (s.weight * s.reps));
    if (total >= 1000) {
      return '${(total / 1000).toStringAsFixed(1)}k';
    }
    return total.toStringAsFixed(0);
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

    if (sets[index].savedSetId != null) {
      // Update existing record - just change hidden to false
      await (db.gymSets.update()
            ..where((tbl) => tbl.id.equals(sets[index].savedSetId!)))
          .write(const GymSetsCompanion(
            hidden: Value(false),
          ));

      setState(() {
        sets[index].completed = true;
      });
    } else {
      // Fallback: Insert new record (shouldn't happen with auto-save)
      final settings = context.read<SettingsState>().value;
      final setData = sets[index];

      double? bodyWeight;
      if (settings.showBodyWeight) {
        final weightSet = await (db.gymSets.select()
              ..where((tbl) => tbl.name.equals('Weight'))
              ..orderBy([
                (u) =>
                    OrderingTerm(expression: u.created, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();
        bodyWeight = weightSet?.weight;
      }

      final gymSet = await db.into(db.gymSets).insertReturning(
            GymSetsCompanion.insert(
              name: widget.exerciseName,
              reps: setData.reps.toDouble(),
              weight: setData.weight,
              unit: unit,
              created: DateTime.now().toLocal(),
              workoutId: Value(widget.workoutId),
              bodyWeight: Value.absentIfNull(bodyWeight),
              sequence: Value(widget.sequence),
              notes: Value(widget.exerciseNotes ?? ''),
              hidden: const Value(false),
            ),
          );

      setState(() {
        sets[index].completed = true;
        sets[index].savedSetId = gymSet.id;
      });
    }
  }

  Future<void> _uncompleteSet(int index) async {
    if (!sets[index].completed || sets[index].savedSetId == null) return;

    // Update record to mark as uncompleted (hidden=true) instead of deleting
    await (db.gymSets.update()
          ..where((tbl) => tbl.id.equals(sets[index].savedSetId!)))
        .write(const GymSetsCompanion(
          hidden: Value(true),
        ));

    setState(() {
      sets[index].completed = false;
    });
  }

  Future<void> _addSet({bool isWarmup = false}) async {
    int insertIndex;
    if (isWarmup) {
      insertIndex = sets.where((s) => s.isWarmup).length;
    } else {
      insertIndex = sets.length;
    }

    final baseWeight = sets.isNotEmpty ? sets.last.weight : _defaultWeight;
    final weight = isWarmup ? (baseWeight * 0.5).roundToDouble() : baseWeight;
    final reps = sets.isNotEmpty ? sets.last.reps : _defaultReps;

    // Insert to database immediately with hidden=true
    if (widget.workoutId != null) {
      final settings = context.read<SettingsState>().value;
      double? bodyWeight;
      if (settings.showBodyWeight) {
        final weightSet = await (db.gymSets.select()
              ..where((tbl) => tbl.name.equals('Weight'))
              ..orderBy([
                (u) => OrderingTerm(expression: u.created, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();
        bodyWeight = weightSet?.weight;
      }

      final gymSet = await db.into(db.gymSets).insertReturning(
        GymSetsCompanion.insert(
          name: widget.exerciseName,
          reps: reps.toDouble(),
          weight: weight,
          unit: unit,
          created: DateTime.now().toLocal(),
          workoutId: Value(widget.workoutId),
          bodyWeight: Value.absentIfNull(bodyWeight),
          sequence: Value(widget.sequence),
          notes: Value(widget.exerciseNotes ?? ''),
          hidden: const Value(true), // Uncompleted by default
        ),
      );

      setState(() {
        sets.insert(insertIndex, SetData(
          weight: weight,
          reps: reps,
          completed: false,
          isWarmup: isWarmup,
          savedSetId: gymSet.id, // Save the ID
        ));
      });
    } else {
      // No workout ID - fallback to in-memory only
      setState(() {
        sets.insert(insertIndex, SetData(
          weight: weight,
          reps: reps,
          completed: false,
          isWarmup: isWarmup,
        ));
      });
    }
  }

  Future<void> _deleteSet(int index) async {
    // Delete from database if it has been saved
    if (sets[index].savedSetId != null) {
      await (db.gymSets.delete()
            ..where((tbl) => tbl.id.equals(sets[index].savedSetId!)))
          .go();
    }
    setState(() => sets.removeAt(index));
  }

  Future<void> _updateSet(int index) async {
    final setData = sets[index];
    if (setData.savedSetId == null) return;

    await (db.gymSets.update()
          ..where((tbl) => tbl.id.equals(setData.savedSetId!)))
        .write(GymSetsCompanion(
          weight: Value(setData.weight),
          reps: Value(setData.reps.toDouble()),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allCompleted = sets.isNotEmpty && sets.every((s) => s.completed);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
      child: Column(
        children: [
          // Exercise Header - same styling as ExerciseSetsCard
          InkWell(
            onTap: widget.onToggleExpand,
            onLongPress: () => _showExerciseMenu(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: allCompleted
                          ? colorScheme.primary
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      allCompleted ? Icons.check : Icons.fitness_center,
                      color: allCompleted
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exerciseName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        // Exercise notes preview
                        if (widget.exerciseNotes?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.sticky_note_2_outlined,
                                size: 12,
                                color: colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.exerciseNotes!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              if (completedCount > 0) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.fitness_center,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_getTotalVolume()} $unit',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Progress bar - same styling as ExerciseSetsCard
          if (_initialized)
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: sets.isEmpty ? 0 : completedCount / sets.length,
              ),
              duration: const Duration(milliseconds: 300),
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
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Column(
                      children: [
                        ...List.generate(sets.length, (index) {
                          final warmupCount = sets.take(index).where((s) => s.isWarmup).length;
                          final displayIndex = sets[index].isWarmup
                              ? index + 1
                              : index - warmupCount + 1;

                          return _AdHocSetRow(
                            key: ValueKey('adhoc_set_$index'),
                            index: displayIndex,
                            setData: sets[index],
                            unit: unit,
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
                            onToggle: () => _toggleSet(index),
                            onDelete: () => _deleteSet(index),
                          );
                        }),
                        // Add set buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _addSet(isWarmup: true),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: colorScheme.tertiary.withValues(alpha: 0.5),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: colorScheme.tertiaryContainer.withValues(alpha: 0.2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.whatshot_outlined,
                                            size: 18, color: colorScheme.tertiary),
                                        const SizedBox(width: 6),
                                        Text('Warmup',
                                            style: TextStyle(
                                              color: colorScheme.tertiary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _addSet(isWarmup: false),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: colorScheme.primary.withValues(alpha: 0.5),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add,
                                            size: 18, color: colorScheme.primary),
                                        const SizedBox(width: 6),
                                        Text('Working Set',
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
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
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// Simplified set row for ad-hoc exercises
class _AdHocSetRow extends StatelessWidget {
  final int index;
  final SetData setData;
  final String unit;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AdHocSetRow({
    super.key,
    required this.index,
    required this.setData,
    required this.unit,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = setData.completed;
    final isWarmup = setData.isWarmup;

    final Color bgColor;
    final Color borderColor;
    final Color accentColor;

    if (isWarmup) {
      bgColor = completed
          ? colorScheme.tertiaryContainer.withValues(alpha: 0.4)
          : colorScheme.tertiaryContainer.withValues(alpha: 0.2);
      borderColor = colorScheme.tertiary.withValues(alpha: completed ? 0.5 : 0.3);
      accentColor = colorScheme.tertiary;
    } else {
      bgColor = completed
          ? colorScheme.primaryContainer.withValues(alpha: 0.4)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      borderColor = completed
          ? colorScheme.primary.withValues(alpha: 0.5)
          : colorScheme.outlineVariant.withValues(alpha: 0.5);
      accentColor = colorScheme.primary;
    }

    return Dismissible(
      key: Key('dismissible_adhoc_set_$index'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onDelete();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: colorScheme.error),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            // Set number badge
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: completed
                    ? accentColor.withValues(alpha: 0.2)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isWarmup)
                    Icon(Icons.whatshot, size: 12, color: accentColor),
                  Text(
                    isWarmup ? 'W$index' : '$index',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: completed
                          ? accentColor
                          : colorScheme.onSurfaceVariant,
                      fontSize: isWarmup ? 11 : 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Weight input
            Expanded(
              flex: 3,
              child: _SimpleWeightInput(
                value: setData.weight,
                unit: unit,
                completed: completed,
                accentColor: accentColor,
                onChanged: onWeightChanged,
              ),
            ),
            const SizedBox(width: 8),
            // Reps input
            Expanded(
              flex: 4,
              child: _SimpleRepsInput(
                value: setData.reps,
                completed: completed,
                accentColor: accentColor,
                onChanged: onRepsChanged,
              ),
            ),
            const SizedBox(width: 8),
            // Complete button
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: onToggle,
                style: IconButton.styleFrom(
                  backgroundColor: completed
                      ? accentColor
                      : colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.check,
                  color: completed
                      ? (isWarmup
                          ? colorScheme.onTertiary
                          : colorScheme.onPrimary)
                      : colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleWeightInput extends StatelessWidget {
  final double value;
  final String unit;
  final bool completed;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _SimpleWeightInput({
    required this.value,
    required this.unit,
    required this.completed,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: TextEditingController(
        text: value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toStringAsFixed(1),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: completed ? accentColor : colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        suffixText: unit,
        suffixStyle: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: completed
              ? BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: completed
              ? BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        filled: true,
        fillColor: completed
            ? accentColor.withValues(alpha: 0.1)
            : colorScheme.surface,
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}

class _SimpleRepsInput extends StatefulWidget {
  final int value;
  final bool completed;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const _SimpleRepsInput({
    required this.value,
    required this.completed,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<_SimpleRepsInput> createState() => _SimpleRepsInputState();
}

class _SimpleRepsInputState extends State<_SimpleRepsInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(_SimpleRepsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_hasFocus) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: widget.completed
            ? widget.accentColor.withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: widget.completed
            ? Border.all(color: widget.accentColor.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              onPressed: widget.value > 1
                  ? () {
                      HapticFeedback.selectionClick();
                      widget.onChanged(widget.value - 1);
                    }
                  : null,
              icon: Icon(
                Icons.remove,
                color: widget.value > 1
                    ? widget.accentColor
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.completed ? widget.accentColor : colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 10,
                ),
                border: InputBorder.none,
                hintText: 'reps',
                hintStyle: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              onChanged: (text) {
                final parsed = int.tryParse(text);
                if (parsed != null && parsed > 0 && parsed < 100) {
                  widget.onChanged(parsed);
                }
              },
              onTap: () {
                _controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controller.text.length,
                );
              },
            ),
          ),
          SizedBox(
            width: 32,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              onPressed: widget.value < 99
                  ? () {
                      HapticFeedback.selectionClick();
                      widget.onChanged(widget.value + 1);
                    }
                  : null,
              icon: Icon(
                Icons.add,
                color: widget.value < 99
                    ? widget.accentColor
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
