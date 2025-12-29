import 'package:drift/drift.dart' hide Column;
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/workouts/workout_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class WorkoutWithSets {
  final Workout workout;
  final int setCount;
  final int exerciseCount;
  final List<String> exerciseNames;

  WorkoutWithSets({
    required this.workout,
    required this.setCount,
    required this.exerciseCount,
    required this.exerciseNames,
  });
}

class WorkoutsList extends StatefulWidget {
  final ScrollController scroll;
  final Function onNext;
  final String search;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;

  const WorkoutsList({
    super.key,
    required this.scroll,
    required this.onNext,
    required this.search,
    this.startDate,
    this.endDate,
    required this.limit,
  });

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
        (w) => OrderingTerm(expression: w.startTime, mode: OrderingMode.desc)
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
              ..where((s) => s.workoutId.equals(workout.id)))
            .get();

        final exerciseNames = sets.map((s) => s.name).toSet().toList();

        result.add(WorkoutWithSets(
          workout: workout,
          setCount: sets.length,
          exerciseCount: exerciseNames.length,
          exerciseNames: exerciseNames,
        ));
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
          padding: const EdgeInsets.only(bottom: 96, top: 8),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workoutWithSets = workouts[index];
            return _WorkoutCard(workoutWithSets: workoutWithSets);
          },
        );
      },
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutWithSets workoutWithSets;

  const _WorkoutCard({required this.workoutWithSets});

  @override
  Widget build(BuildContext context) {
    final workout = workoutWithSets.workout;
    final dateFormat = context.select<SettingsState, String>(
      (settings) => settings.value.longDateFormat,
    );

    final duration = workout.endTime != null
        ? workout.endTime!.difference(workout.startTime)
        : null;

    final formattedDate = dateFormat == 'timeago'
        ? timeago.format(workout.startTime)
        : DateFormat(dateFormat).format(workout.startTime);

    final exercisePreview = workoutWithSets.exerciseNames.take(3).join(', ');
    final moreCount = workoutWithSets.exerciseNames.length - 3;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutDetailPage(workout: workout),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workout.name ?? 'Workout',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                moreCount > 0
                    ? '$exercisePreview +$moreCount more'
                    : exercisePreview,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip(
                    context,
                    Icons.fitness_center,
                    '${workoutWithSets.exerciseCount} exercises',
                  ),
                  const SizedBox(width: 16),
                  _buildChip(
                    context,
                    Icons.repeat,
                    '${workoutWithSets.setCount} sets',
                  ),
                  if (duration != null) ...[
                    const SizedBox(width: 16),
                    _buildChip(
                      context,
                      Icons.timer,
                      _formatDuration(duration),
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

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}
