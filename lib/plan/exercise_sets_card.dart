import 'package:drift/drift.dart' hide Column;
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/plan/plan_state.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/timer/timer_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SetData {
  double weight;
  int reps;
  bool completed;
  int? savedSetId;

  SetData({
    required this.weight,
    required this.reps,
    this.completed = false,
    this.savedSetId,
  });
}

class ExerciseSetsCard extends StatefulWidget {
  final PlanExercise exercise;
  final int planId;
  final int? workoutId;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onSetCompleted;

  const ExerciseSetsCard({
    super.key,
    required this.exercise,
    required this.planId,
    required this.workoutId,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onSetCompleted,
  });

  @override
  State<ExerciseSetsCard> createState() => _ExerciseSetsCardState();
}

class _ExerciseSetsCardState extends State<ExerciseSetsCard> {
  List<SetData> sets = [];
  bool _initialized = false;
  String unit = 'kg';

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

    final defaultWeight = lastSet?.weight ?? 0.0;
    final defaultUnit = lastSet?.unit ?? settings.strengthUnit;

    // Get sets already completed in this workout
    List<GymSet> completedSets = [];
    if (widget.workoutId != null) {
      completedSets = await (db.gymSets.select()
            ..where((tbl) =>
                tbl.name.equals(widget.exercise.exercise) &
                tbl.workoutId.equals(widget.workoutId!) &
                tbl.hidden.equals(false))
            ..orderBy([
              (u) => OrderingTerm(expression: u.created, mode: OrderingMode.asc),
            ]))
          .get();
    }

    if (!mounted) return;

    setState(() {
      unit = defaultUnit;
      sets = List.generate(maxSets, (index) {
        if (index < completedSets.length) {
          final set = completedSets[index];
          return SetData(
            weight: set.weight,
            reps: set.reps.toInt(),
            completed: true,
            savedSetId: set.id,
          );
        }
        return SetData(
          weight: defaultWeight,
          reps: 8,
          completed: false,
        );
      });
      _initialized = true;
    });
  }

  int get completedCount => sets.where((s) => s.completed).length;

  Future<void> _completeSet(int index) async {
    if (sets[index].completed) return;

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
            name: widget.exercise.exercise,
            reps: setData.reps.toDouble(),
            weight: setData.weight,
            unit: unit,
            created: DateTime.now().toLocal(),
            planId: Value(widget.planId),
            workoutId: Value(widget.workoutId),
            bodyWeight: Value.absentIfNull(bodyWeight),
          ),
        );

    setState(() {
      sets[index].completed = true;
      sets[index].savedSetId = gymSet.id;
    });

    // Start rest timer if not last set
    final isLastSet = completedCount == sets.length;
    if (!isLastSet && settings.restTimers) {
      final timerState = context.read<TimerState>();
      final restMs = settings.timerDuration;
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allCompleted = sets.isNotEmpty && sets.every((s) => s.completed);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Exercise Header
          InkWell(
            onTap: widget.onToggleExpand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: allCompleted
                    ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : null,
              ),
              child: Row(
                children: [
                  if (allCompleted)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 24,
                    )
                  else
                    Icon(
                      Icons.fitness_center,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.exercise,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (_initialized)
                          Text(
                            '$completedCount / ${sets.length} sets',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    widget.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // Progress bar
          if (_initialized)
            LinearProgressIndicator(
              value: sets.isEmpty ? 0 : completedCount / sets.length,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              minHeight: 3,
            ),
          // Set rows (when expanded)
          if (widget.isExpanded && _initialized)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: List.generate(sets.length, (index) {
                  return _SetRow(
                    index: index,
                    setData: sets[index],
                    unit: unit,
                    onWeightChanged: (value) {
                      setState(() {
                        sets[index].weight = value;
                      });
                    },
                    onRepsChanged: (value) {
                      setState(() {
                        sets[index].reps = value;
                      });
                    },
                    onComplete: () => _completeSet(index),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int index;
  final SetData setData;
  final String unit;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onComplete;

  const _SetRow({
    required this.index,
    required this.setData,
    required this.unit,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = setData.completed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: completed
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Set number
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Set ${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: completed
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Weight input
          Expanded(
            flex: 3,
            child: _WeightInput(
              value: setData.weight,
              unit: unit,
              enabled: !completed,
              onChanged: onWeightChanged,
            ),
          ),
          const SizedBox(width: 8),
          // Reps input with +/- buttons
          Expanded(
            flex: 3,
            child: _RepsInput(
              value: setData.reps,
              enabled: !completed,
              onChanged: onRepsChanged,
            ),
          ),
          const SizedBox(width: 8),
          // Complete button
          _CompleteButton(
            completed: completed,
            onPressed: completed ? null : onComplete,
          ),
        ],
      ),
    );
  }
}

class _WeightInput extends StatefulWidget {
  final double value;
  final String unit;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _WeightInput({
    required this.value,
    required this.unit,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_WeightInput> createState() => _WeightInputState();
}

class _WeightInputState extends State<_WeightInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatWeight(widget.value));
  }

  @override
  void didUpdateWidget(_WeightInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_controller.text.contains('.')) {
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

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: widget.enabled ? null : colorScheme.primary,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        suffixText: widget.unit,
        suffixStyle: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: widget.enabled
            ? colorScheme.surface
            : Colors.transparent,
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
    );
  }
}

class _RepsInput extends StatelessWidget {
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _RepsInput({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: enabled ? colorScheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (enabled)
            _RepsButton(
              icon: Icons.remove,
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
            ),
          Expanded(
            child: Text(
              '$value reps',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: enabled ? null : colorScheme.primary,
              ),
            ),
          ),
          if (enabled)
            _RepsButton(
              icon: Icons.add,
              onPressed: value < 99 ? () => onChanged(value + 1) : null,
            ),
        ],
      ),
    );
  }
}

class _RepsButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _RepsButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  final bool completed;
  final VoidCallback? onPressed;

  const _CompleteButton({
    required this.completed,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: completed
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(
          Icons.check,
          color: completed
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}
