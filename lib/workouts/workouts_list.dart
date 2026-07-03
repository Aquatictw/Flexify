import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../main.dart';
import '../records/records_service.dart';
import '../theme/tokens.dart';
import 'workout_detail_page.dart';

class WorkoutWithSets {

  WorkoutWithSets({
    required this.workout,
    required this.setCount,
    required this.exerciseCount,
    required this.exerciseNames,
    this.totalVolume = 0,
    this.recordCount = 0,
  });
  final Workout workout;
  final int setCount;
  final int exerciseCount;
  final List<String> exerciseNames;
  final double totalVolume;
  final int recordCount;
}

class WorkoutsList extends StatefulWidget {

  const WorkoutsList({
    required this.scroll, required this.onNext, required this.search, required this.limit, required this.selected, required this.onSelect, super.key,
    this.startDate,
    this.endDate,
  });
  final ScrollController scroll;
  final Function onNext;
  final String search;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final Set<int> selected;
  final Function(int) onSelect;

  @override
  State<WorkoutsList> createState() => _WorkoutsListState();
}

class _WorkoutsListState extends State<WorkoutsList> {
  bool goingNext = false;

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(scrollListener);
  }

  @override
  void dispose() {
    widget.scroll.removeListener(scrollListener);
    super.dispose();
  }

  void scrollListener() {
    if (widget.scroll.position.pixels <
            widget.scroll.position.maxScrollExtent - 200 ||
        goingNext) return;
    setState(() {
      goingNext = true;
    });
    try {
      widget.onNext();
    } finally {
      setState(() {
        goingNext = false;
      });
    }
  }

  Stream<List<WorkoutWithSets>> _getWorkoutsStream() {
    var query = db.workouts.select()
      ..orderBy([
        (w) => OrderingTerm(expression: w.startTime, mode: OrderingMode.desc),
      ])
      ..limit(widget.limit);

    if (widget.startDate != null) {
      query = query
        ..where((w) => w.startTime.isBiggerOrEqualValue(widget.startDate!));
    }
    if (widget.endDate != null) {
      query = query
        ..where((w) => w.startTime.isSmallerOrEqualValue(widget.endDate!));
    }

    return query.watch().asyncMap((workouts) async {
      final List<WorkoutWithSets> result = [];

      // Get all workout IDs first
      final workoutIds = workouts.map((w) => w.id).toList();

      // Batch query for record counts
      final recordCounts = await getBatchWorkoutRecordCounts(workoutIds);

      for (final workout in workouts) {
        // Filter by search term if provided
        if (widget.search.isNotEmpty) {
          final searchLower = widget.search.toLowerCase();
          final nameMatches =
              workout.name?.toLowerCase().contains(searchLower) ?? false;

          // Check if any exercise in this workout matches
          final exercises = await (db.gymSets.selectOnly()
                ..addColumns([db.gymSets.name])
                ..where(db.gymSets.workoutId.equals(workout.id))
                ..groupBy([db.gymSets.name]))
              .map((row) => row.read(db.gymSets.name)!)
              .get();

          final exerciseMatches = exercises.any(
            (name) => name.toLowerCase().contains(searchLower),
          );

          if (!nameMatches && !exerciseMatches) continue;
        }

        final sets = await (db.gymSets.select()
              ..where(
                (s) =>
                    s.workoutId.equals(workout.id) &
                    s.hidden.equals(false) &
                    s.sequence.isBiggerOrEqualValue(0),
              ))
            .get();

        final exerciseNames = sets.map((s) => s.name).toSet().toList();
        final totalVolume = sets.fold<double>(
          0,
          (sum, s) => sum + (s.weight * s.reps),
        );

        // Get record count from batch query
        final recordCount = recordCounts[workout.id] ?? 0;

        result.add(
          WorkoutWithSets(
            workout: workout,
            setCount: sets.length,
            exerciseCount: exerciseNames.length,
            exerciseNames: exerciseNames,
            totalVolume: totalVolume,
            recordCount: recordCount,
          ),
        );
      }

      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkoutWithSets>>(
      stream: _getWorkoutsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final workouts = snapshot.data!;

        if (workouts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No workouts found'),
            ),
          );
        }

        return ListView.builder(
          controller: widget.scroll,
          padding: EdgeInsets.only(
              bottom: bottomBarClearance(context), top: space8,),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workoutWithSets = workouts[index];
            return _WorkoutCard(
              workoutWithSets: workoutWithSets,
              selected: widget.selected,
              onSelect: widget.onSelect,
            );
          },
        );
      },
    );
  }
}

class _WorkoutCard extends StatelessWidget {

  const _WorkoutCard({
    required this.workoutWithSets,
    required this.selected,
    required this.onSelect,
  });
  final WorkoutWithSets workoutWithSets;
  final Set<int> selected;
  final Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    final workout = workoutWithSets.workout;
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selected.contains(workout.id);

    final duration = workout.endTime?.difference(workout.startTime);

    final exercisePreview = workoutWithSets.exerciseNames.take(3).join(', ');
    final moreCount = workoutWithSets.exerciseNames.length - 3;
    final hasNotes = workout.notes?.isNotEmpty ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      color: isSelected ? colorScheme.primary.withValues(alpha: .08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: brSm,
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (selected.isNotEmpty) {
            onSelect(workout.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailPage(workout: workout),
              ),
            );
          }
        },
        onLongPress: () {
          onSelect(workout.id);
        },
        borderRadius: brSm,
        child: Padding(
          padding: const EdgeInsets.all(space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date badge and workout name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection indicator or Date badge
                  if (selected.isNotEmpty)
                    AnimatedSwitcher(
                      duration: durFast,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            onSelect(workout.id);
                          },
                        ),
                      ),
                    )
                  else
                    // Date badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('d').format(workout.startTime),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                              height: 1,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(workout.startTime),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selected.isEmpty) const SizedBox(width: 12),
                  if (selected.isNotEmpty) const SizedBox(width: 16),
                  // Title and year
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                workout.name ?? 'Workout',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            if (workoutWithSets.recordCount > 0) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.emoji_events,
                                size: 18,
                                color: context.jl.pr,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('yyyy').format(workout.startTime),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Duration badge
                  if (duration != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Exercise preview
              Text(
                moreCount > 0
                    ? '$exercisePreview +$moreCount more'
                    : exercisePreview,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Notes preview
              if (hasNotes) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notes,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          workout.notes!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontStyle: FontStyle.italic,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Stats row
              Row(
                children: [
                  _buildChip(
                    context,
                    Icons.fitness_center,
                    '${workoutWithSets.exerciseCount} exercises',
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    context,
                    Icons.repeat,
                    '${workoutWithSets.setCount} sets',
                  ),
                  if (workoutWithSets.totalVolume > 0) ...[
                    const SizedBox(width: 8),
                    _buildChip(
                      context,
                      Icons.show_chart,
                      _formatVolume(workoutWithSets.totalVolume),
                    ),
                  ],
                  if (workoutWithSets.recordCount > 0) ...[
                    const SizedBox(width: 8),
                    _buildRecordChip(
                      context,
                      workoutWithSets.recordCount,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildRecordChip(BuildContext context, int count) {
    final pr = context.jl.pr;
    final onPr = ThemeData.estimateBrightnessForColor(pr) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            pr,
            pr.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: brSm,
        boxShadow: [
          BoxShadow(
            color: pr.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            size: 12,
            color: onPr,
          ),
          const SizedBox(width: space4),
          Text(
            '$count PR${count > 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: onPr,
                ),
          ),
        ],
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
      return '${(volume / 1000).toStringAsFixed(1)}k vol';
    }
    return '${volume.toStringAsFixed(0)} vol';
  }
}
