import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/sets/edit_set_page.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WorkoutDetailPage extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late Stream<List<GymSet>> setsStream;

  @override
  void initState() {
    super.initState();
    setsStream = (db.gymSets.select()
          ..where((s) => s.workoutId.equals(widget.workout.id))
          ..orderBy([
            (s) => OrderingTerm(expression: s.created, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = context.select<SettingsState, String>(
      (settings) => settings.value.longDateFormat,
    );
    final showImages = context.select<SettingsState, bool>(
      (settings) => settings.value.showImages,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name ?? 'Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteWorkout(context),
          ),
        ],
      ),
      body: StreamBuilder<List<GymSet>>(
        stream: setsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sets = snapshot.data!;
          if (sets.isEmpty) {
            return const Center(
              child: Text('No exercises in this workout'),
            );
          }

          // Group sets by exercise name
          final exerciseGroups = <String, List<GymSet>>{};
          for (final set in sets) {
            exerciseGroups.putIfAbsent(set.name, () => []).add(set);
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _buildWorkoutHeader(dateFormat, sets),
              const Divider(),
              ...exerciseGroups.entries.map(
                (entry) => _buildExerciseGroup(
                  entry.key,
                  entry.value,
                  showImages,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkoutHeader(String dateFormat, List<GymSet> sets) {
    final duration = widget.workout.endTime != null
        ? widget.workout.endTime!.difference(widget.workout.startTime)
        : DateTime.now().difference(widget.workout.startTime);

    final formattedDate = dateFormat == 'timeago'
        ? DateFormat('MMM d, yyyy h:mm a').format(widget.workout.startTime)
        : DateFormat(dateFormat).format(widget.workout.startTime);

    final exerciseCount =
        sets.map((s) => s.name).toSet().length;
    final totalSets = sets.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip(
                Icons.fitness_center,
                '$exerciseCount exercises',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                Icons.repeat,
                '$totalSets sets',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                Icons.timer,
                _formatDuration(duration),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  Widget _buildExerciseGroup(
    String exerciseName,
    List<GymSet> sets,
    bool showImages,
  ) {
    final firstSet = sets.first;

    Widget? leading;
    if (showImages && firstSet.image != null) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(firstSet.image!),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialBadge(exerciseName),
        ),
      );
    } else {
      leading = _buildInitialBadge(exerciseName);
    }

    return ExpansionTile(
      leading: leading,
      title: Text(exerciseName),
      subtitle: Text('${sets.length} sets'),
      initiallyExpanded: true,
      children: sets.asMap().entries.map((entry) {
        final index = entry.key;
        final set = entry.value;
        return _buildSetTile(set, index + 1);
      }).toList(),
    );
  }

  Widget _buildInitialBadge(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSetTile(GymSet set, int setNumber) {
    final reps = toString(set.reps);
    final weight = toString(set.weight);
    final minutes = set.duration.floor();
    final seconds =
        ((set.duration * 60) % 60).floor().toString().padLeft(2, '0');
    final distance = toString(set.distance);

    String subtitle;
    if (set.cardio) {
      String incline = '';
      if (set.incline != null && set.incline! > 0) {
        incline = ' @ ${set.incline}%';
      }
      subtitle = '$distance ${set.unit} / $minutes:$seconds$incline';
    } else {
      subtitle = '$reps x $weight ${set.unit}';
    }

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          '$setNumber',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      title: Text(subtitle),
      subtitle: set.notes?.isNotEmpty == true ? Text(set.notes!) : null,
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

    if (confirmed == true && context.mounted) {
      // Delete all sets in this workout
      await (db.gymSets.delete()
            ..where((s) => s.workoutId.equals(widget.workout.id)))
          .go();
      // Delete the workout
      await (db.workouts.delete()
            ..where((w) => w.id.equals(widget.workout.id)))
          .go();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}
