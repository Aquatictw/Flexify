import 'package:drift/drift.dart' hide Column;
import 'package:flexify/constants.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/database/gym_sets.dart';
import 'package:flexify/graph/cardio_page.dart';
import 'package:flexify/graph/strength_page.dart';
import 'package:flexify/main.dart';
import 'package:flexify/plan/plan_state.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/timer/timer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SetData {
  double weight;
  int reps;
  bool completed;
  int? savedSetId;
  bool isWarmup;

  SetData({
    required this.weight,
    required this.reps,
    this.completed = false,
    this.savedSetId,
    this.isWarmup = false,
  });
}

class ExerciseSetsCard extends StatefulWidget {
  final PlanExercise exercise;
  final int planId;
  final int? workoutId;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onSetCompleted;
  final VoidCallback? onDeleteExercise;
  final String? exerciseNotes;
  final ValueChanged<String>? onNotesChanged;
  final int sequence; // Exercise order within workout

  const ExerciseSetsCard({
    super.key,
    required this.exercise,
    required this.planId,
    required this.workoutId,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onSetCompleted,
    this.onDeleteExercise,
    this.exerciseNotes,
    this.sequence = 0,
    this.onNotesChanged,
  });

  @override
  State<ExerciseSetsCard> createState() => _ExerciseSetsCardState();
}

class _ExerciseSetsCardState extends State<ExerciseSetsCard> {
  List<SetData> sets = [];
  bool _initialized = false;
  String unit = 'kg';
  double _defaultWeight = 0.0;
  int _defaultReps = 8;
  String? _brandName;
  String? _exerciseType;
  int? _restMs; // Custom rest time for this exercise

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

    // Get the last set for this exercise to get default weight
    final lastSet = await (db.gymSets.select()
          ..where((tbl) => tbl.name.equals(widget.exercise.exercise))
          ..orderBy([
            (u) => OrderingTerm(expression: u.created, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();

    _defaultWeight = lastSet?.weight ?? 0.0;
    _defaultReps = lastSet?.reps.toInt() ?? 8;
    final defaultUnit = lastSet?.unit ?? settings.strengthUnit;
    _brandName = lastSet?.brandName;
    _exerciseType = lastSet?.exerciseType;
    _restMs = lastSet?.restMs; // Load custom rest time

    // Get ALL sets (including uncompleted/hidden ones) in this workout for this specific exercise instance
    List<GymSet> existingSets = [];
    if (widget.workoutId != null) {
      existingSets = await (db.gymSets.select()
            ..where((tbl) =>
                tbl.name.equals(widget.exercise.exercise) &
                tbl.workoutId.equals(widget.workoutId!) &
                tbl.sequence.equals(widget.sequence)) // Filter by sequence to get only this instance
            ..orderBy([
              (u) => OrderingTerm(expression: u.created, mode: OrderingMode.asc),
            ]))
          .get();
    }

    if (!mounted) return;

    if (existingSets.isNotEmpty) {
      // Load existing sets from database
      final loadedSets = existingSets.map((set) {
        return SetData(
          weight: set.weight,
          reps: set.reps.toInt(),
          completed: !set.hidden, // hidden=false means completed
          savedSetId: set.id,
          isWarmup: set.warmup,
        );
      }).toList();

      setState(() {
        unit = defaultUnit;
        sets = loadedSets;
        _initialized = true;
      });
    } else {
      // No existing sets - create and persist them immediately
      if (widget.workoutId != null) {
        final newSets = <SetData>[];
        for (int i = 0; i < maxSets; i++) {
          final gymSet = await db.into(db.gymSets).insertReturning(
            GymSetsCompanion.insert(
              name: widget.exercise.exercise,
              reps: _defaultReps.toDouble(),
              weight: _defaultWeight,
              unit: defaultUnit,
              created: DateTime.now().toLocal(),
              planId: Value(widget.planId),
              workoutId: Value(widget.workoutId),
              sequence: Value(widget.sequence),
              hidden: const Value(true), // Uncompleted
              brandName: Value(_brandName),
              exerciseType: Value(_exerciseType),
            ),
          );
          newSets.add(SetData(
            weight: _defaultWeight,
            reps: _defaultReps,
            completed: false,
            savedSetId: gymSet.id,
          ));
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
          sets = List.generate(maxSets, (_) => SetData(
            weight: _defaultWeight,
            reps: _defaultReps,
            completed: false,
          ));
          _initialized = true;
        });
      }
    }
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
                      widget.exercise.exercise,
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
              leading: Icon(Icons.show_chart, color: colorScheme.primary),
              title: const Text('View Graph'),
              subtitle: const Text('Jump to graph page for this exercise'),
              onTap: () async {
                Navigator.pop(context);
                await _jumpToGraph(parentContext);
              },
            ),
            ListTile(
              leading: Icon(Icons.remove_circle_outline, color: colorScheme.error),
              title: Text(
                'Remove Exercise',
                style: TextStyle(color: colorScheme.error),
              ),
              subtitle: const Text('Remove this exercise from workout'),
              onTap: () {
                Navigator.pop(context);
                widget.onDeleteExercise?.call();
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
        metric: CardioMetric.pace,
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

    HapticFeedback.mediumImpact();

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
      final setData = sets[index];

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
              notes: Value(widget.exerciseNotes ?? ''),
              hidden: const Value(false),
              warmup: Value(setData.isWarmup),
              brandName: Value(_brandName),
              exerciseType: Value(_exerciseType),
            ),
          );

      setState(() {
        sets[index].completed = true;
        sets[index].savedSetId = gymSet.id;
      });
    }

    // Start rest timer
    if (settings.restTimers) {
      final timerState = context.read<TimerState>();
      // Use custom rest time if set, otherwise use global default
      final restMs = _restMs ?? settings.timerDuration;
      timerState.startTimer(
        "${widget.exercise.exercise} (${completedCount})",
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
        .write(const GymSetsCompanion(
          hidden: Value(true),
        ));

    setState(() {
      sets[index].completed = false;
    });

    // Update plan state
    final planState = context.read<PlanState>();
    await planState.updateGymCounts(widget.planId, widget.workoutId);
  }

  Future<void> _addSet({bool isWarmup = false}) async {
    HapticFeedback.selectionClick();

    int insertIndex;
    if (isWarmup) {
      insertIndex = sets.where((s) => s.isWarmup).length;
    } else {
      insertIndex = sets.length;
    }

    final baseWeight = sets.isNotEmpty ? sets.last.weight : _defaultWeight;
    final weight = isWarmup ? (baseWeight * 0.5).roundToDouble() : baseWeight;
    final reps = sets.isNotEmpty ? sets.last.reps : _defaultReps;

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
          notes: Value(widget.exerciseNotes ?? ''),
          hidden: const Value(true),
          warmup: Value(isWarmup),
          brandName: Value(_brandName),
          exerciseType: Value(_exerciseType),
        ),
      );

      setState(() {
        sets.insert(insertIndex, SetData(
          weight: weight,
          reps: reps,
          completed: false,
          isWarmup: isWarmup,
          savedSetId: gymSet.id,
        ));
      });
    } else {
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

  Future<void> _updateSet(int index) async {
    final setData = sets[index];
    if (setData.savedSetId == null) return;

    // Update the set in database
    await (db.gymSets.update()
          ..where((tbl) => tbl.id.equals(setData.savedSetId!)))
        .write(GymSetsCompanion(
          weight: Value(setData.weight),
          reps: Value(setData.reps.toDouble()),
        ));

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
          // Exercise Header
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.exercise.exercise,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            if (_brandName != null && _brandName!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _brandName!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                              if (_brandName != null && _brandName!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
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
          // Progress bar
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
                          // Calculate display index (exclude warmups from numbering)
                          final warmupCount = sets.take(index).where((s) => s.isWarmup).length;
                          final displayIndex = sets[index].isWarmup
                              ? index + 1
                              : index - warmupCount + 1;

                          return _SetRow(
                            key: ValueKey('set_${sets[index].isWarmup ? "w" : ""}$index'),
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
                        // Add set buttons row
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              // Add Warmup button
                              Expanded(
                                child: InkWell(
                                  onTap: () => _addSet(isWarmup: true),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: colorScheme.tertiary.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: colorScheme.tertiaryContainer.withValues(alpha: 0.2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.whatshot_outlined,
                                          size: 18,
                                          color: colorScheme.tertiary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Warmup',
                                          style: TextStyle(
                                            color: colorScheme.tertiary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Add Working Set button
                              Expanded(
                                child: InkWell(
                                  onTap: () => _addSet(isWarmup: false),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: colorScheme.primary.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 18,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Working Set',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
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

class _SetRow extends StatelessWidget {
  final int index;
  final SetData setData;
  final String unit;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SetRow({
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

    // Choose colors based on warmup/completed state
    final Color bgColor;
    final Color borderColor;
    final Color accentColor;

    if (isWarmup) {
      if (completed) {
        bgColor = colorScheme.tertiaryContainer.withValues(alpha: 0.4);
        borderColor = colorScheme.tertiary.withValues(alpha: 0.5);
        accentColor = colorScheme.tertiary;
      } else {
        bgColor = colorScheme.tertiaryContainer.withValues(alpha: 0.2);
        borderColor = colorScheme.tertiary.withValues(alpha: 0.3);
        accentColor = colorScheme.tertiary;
      }
    } else {
      if (completed) {
        bgColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
        borderColor = colorScheme.primary.withValues(alpha: 0.5);
        accentColor = colorScheme.primary;
      } else {
        bgColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
        borderColor = colorScheme.outlineVariant.withValues(alpha: 0.5);
        accentColor = colorScheme.primary;
      }
    }

    return Dismissible(
      key: Key('dismissible_set_${isWarmup ? "w" : ""}$index'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onDelete();
        return false; // We handle deletion ourselves
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.error,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Set number badge with warmup indicator
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
                    Icon(
                      Icons.whatshot,
                      size: 12,
                      color: accentColor,
                    ),
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
            // Weight input - always editable
            Expanded(
              flex: 3,
              child: _WeightInput(
                value: setData.weight,
                unit: unit,
                enabled: true,
                completed: completed,
                accentColor: accentColor,
                onChanged: onWeightChanged,
              ),
            ),
            const SizedBox(width: 8),
            // Reps input with +/- buttons - always editable
            Expanded(
              flex: 4,
              child: _RepsInput(
                value: setData.reps,
                enabled: true,
                completed: completed,
                accentColor: accentColor,
                onChanged: onRepsChanged,
              ),
            ),
            const SizedBox(width: 8),
            // Complete/Toggle button
            _CompleteButton(
              completed: completed,
              isWarmup: isWarmup,
              onPressed: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightInput extends StatefulWidget {
  final double value;
  final String unit;
  final bool enabled;
  final bool completed;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _WeightInput({
    required this.value,
    required this.unit,
    required this.enabled,
    required this.completed,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<_WeightInput> createState() => _WeightInputState();
}

class _WeightInputState extends State<_WeightInput> {
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatWeight(widget.value));
  }

  @override
  void didUpdateWidget(_WeightInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_hasFocus) {
      _controller.text = _formatWeight(widget.value);
    }
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      onFocusChange: (hasFocus) => _hasFocus = hasFocus,
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: widget.completed ? widget.accentColor : colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          suffixText: widget.unit,
          suffixStyle: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: widget.completed
                ? BorderSide(color: widget.accentColor.withValues(alpha: 0.3), width: 1)
                : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: widget.completed
                ? BorderSide(color: widget.accentColor.withValues(alpha: 0.3), width: 1)
                : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: widget.accentColor, width: 2),
          ),
          filled: true,
          fillColor: widget.completed
              ? widget.accentColor.withValues(alpha: 0.1)
              : colorScheme.surface,
        ),
        onChanged: (value) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
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
    );
  }
}

class _RepsInput extends StatefulWidget {
  final int value;
  final bool enabled;
  final bool completed;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const _RepsInput({
    required this.value,
    required this.enabled,
    required this.completed,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<_RepsInput> createState() => _RepsInputState();
}

class _RepsInputState extends State<_RepsInput> {
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
  void didUpdateWidget(_RepsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
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
          _RepsButton(
            icon: Icons.remove,
            accentColor: widget.accentColor,
            onPressed: widget.value > 1
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onChanged(widget.value - 1);
                  }
                : null,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.completed
                    ? widget.accentColor
                    : colorScheme.onSurface,
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
              onChanged: (value) {
                final parsed = int.tryParse(value);
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
          _RepsButton(
            icon: Icons.add,
            accentColor: widget.accentColor,
            onPressed: widget.value < 99
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onChanged(widget.value + 1);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _RepsButton extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _RepsButton({
    required this.icon,
    required this.accentColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 32,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null
              ? accentColor
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  final bool completed;
  final bool isWarmup;
  final VoidCallback onPressed;

  const _CompleteButton({
    required this.completed,
    required this.isWarmup,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = isWarmup ? colorScheme.tertiary : colorScheme.primary;
    final onAccentColor = isWarmup ? colorScheme.onTertiary : colorScheme.onPrimary;

    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: completed
              ? accentColor
              : colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            completed ? Icons.check : Icons.check,
            key: ValueKey(completed),
            color: completed
                ? onAccentColor
                : colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
      ),
    );
  }
}
