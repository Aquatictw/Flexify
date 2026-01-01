import 'package:drift/drift.dart' hide Column;
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/workouts/workout_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class GraphHistoryPage extends StatefulWidget {
  final String name;
  final List<GymSet> gymSets;

  const GraphHistoryPage({
    super.key,
    required this.name,
    required this.gymSets,
  });

  @override
  createState() => _GraphHistoryPageState();
}

class _GraphHistoryPageState extends State<GraphHistoryPage> {
  List<WorkoutSummary> workouts = [];
  int limit = 20;
  final scroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Showing workouts containing ${widget.name}',
            onPressed: () {},
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (workouts.isEmpty)
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No workouts yet",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Start tracking ${widget.name} to see your workout history here",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );

          return ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.all(8),
            itemCount: workouts.length + 1,
            itemBuilder: (context, index) {
              if (index == workouts.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        limit += 10;
                      });
                      loadWorkouts();
                    },
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Load more'),
                  ),
                );
              }

              final workout = workouts[index];
              return _buildWorkoutCard(workout, colorScheme);
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutSummary workout, ColorScheme colorScheme) {
    final settings = context.watch<SettingsState>().value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final workoutData = await (db.workouts.select()
                  ..where((w) => w.id.equals(workout.workoutId)))
                .getSingleOrNull();

            if (workoutData != null && mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutDetailPage(workout: workoutData),
                ),
              );
              loadWorkouts();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.workoutName ?? 'Workout',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            settings.longDateFormat == 'timeago'
                                ? timeago.format(workout.created)
                                : DateFormat(settings.longDateFormat)
                                    .format(workout.created),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatChip(
                      colorScheme,
                      Icons.fitness_center,
                      '${workout.sets} sets',
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      colorScheme,
                      Icons.repeat,
                      'Best: ${workout.bestReps.toInt()}x${_formatWeight(workout.bestWeight)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(ColorScheme colorScheme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeight(double weight) {
    if (weight % 1 == 0) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1);
  }

  @override
  void initState() {
    super.initState();
    loadWorkouts();
  }

  void loadWorkouts() async {
    // Get all workouts containing this exercise
    final result = await db.customSelect("""
      SELECT
        w.id as workout_id,
        w.name as workout_name,
        w.start_time as created,
        COUNT(DISTINCT gs.id) as sets,
        (SELECT gs2.weight FROM gym_sets gs2
         WHERE gs2.workout_id = w.id
           AND gs2.name = ?
           AND gs2.hidden = 0
         ORDER BY gs2.weight DESC
         LIMIT 1) as best_weight,
        (SELECT gs2.reps FROM gym_sets gs2
         WHERE gs2.workout_id = w.id
           AND gs2.name = ?
           AND gs2.hidden = 0
         ORDER BY gs2.weight DESC
         LIMIT 1) as best_reps
      FROM workouts w
      INNER JOIN gym_sets gs ON w.id = gs.workout_id
      WHERE gs.name = ?
        AND gs.hidden = 0
      GROUP BY w.id
      ORDER BY w.start_time DESC
      LIMIT ?
    """, variables: [
      Variable.withString(widget.name),
      Variable.withString(widget.name),
      Variable.withString(widget.name),
      Variable.withInt(limit),
    ]).get();

    setState(() {
      workouts = result.map((row) {
        return WorkoutSummary(
          workoutId: row.read<int>('workout_id'),
          workoutName: row.read<String?>('workout_name'),
          created: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('created') * 1000,
          ),
          sets: row.read<int>('sets'),
          bestWeight: row.read<double>('best_weight'),
          bestReps: row.read<double>('best_reps'),
        );
      }).toList();
    });
  }
}

class WorkoutSummary {
  final int workoutId;
  final String? workoutName;
  final DateTime created;
  final int sets;
  final double bestWeight;
  final double bestReps;

  WorkoutSummary({
    required this.workoutId,
    required this.workoutName,
    required this.created,
    required this.sets,
    required this.bestWeight,
    required this.bestReps,
  });
}
