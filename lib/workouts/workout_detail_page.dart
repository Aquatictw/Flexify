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
    final showImages = context.select<SettingsState, bool>(
      (settings) => settings.value.showImages,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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

          // Group sets by exercise name
          final exerciseGroups = <String, List<GymSet>>{};
          for (final set in sets) {
            exerciseGroups.putIfAbsent(set.name, () => []).add(set);
          }

          // Sort exercise groups by stored sequence (from first set of each exercise)
          final sortedExerciseNames = exerciseGroups.keys.toList()
            ..sort((a, b) {
              // Use the sequence stored in each set (from the first set of each exercise)
              final seqA = exerciseGroups[a]!.first.sequence;
              final seqB = exerciseGroups[b]!.first.sequence;

              // If sequences are different, use them
              if (seqA != seqB) return seqA.compareTo(seqB);

              // If sequences are the same (both 0 for old data), fall back to creation time
              final timeA = exerciseGroups[a]!.first.created;
              final timeB = exerciseGroups[b]!.first.created;
              return timeA.compareTo(timeB);
            });

          final totalVolume = sets.fold<double>(
            0,
            (sum, s) => sum + (s.weight * s.reps),
          );

          return CustomScrollView(
            slivers: [
              // Stylish App Bar Header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteWorkout(context),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
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
                            // Date badge
                            _buildDateBadge(),
                            const SizedBox(height: 12),
                            // Workout title
                            Text(
                              widget.workout.name ?? 'Workout',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Time (24h format)
                            Text(
                              DateFormat('HH:mm').format(widget.workout.startTime),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Stats section
              SliverToBoxAdapter(
                child: _buildStatsSection(sets, totalVolume),
              ),
              // Notes section
              if (widget.workout.notes?.isNotEmpty == true)
                SliverToBoxAdapter(
                  child: _buildNotesSection(),
                ),
              // Empty state
              if (sets.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No exercises in this workout'),
                  ),
                ),
              // Exercise groups (sorted by plan sequence)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final exerciseName = sortedExerciseNames[index];
                    return _buildExerciseGroup(
                      exerciseName,
                      exerciseGroups[exerciseName]!,
                      showImages,
                    );
                  },
                  childCount: sortedExerciseNames.length,
                ),
              ),
              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateBadge() {
    final colorScheme = Theme.of(context).colorScheme;
    final workout = widget.workout;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('yyyy MMMM d').format(workout.startTime),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(List<GymSet> sets, double totalVolume) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = widget.workout.endTime != null
        ? widget.workout.endTime!.difference(widget.workout.startTime)
        : DateTime.now().difference(widget.workout.startTime);

    final exerciseCount = sets.map((s) => s.name).toSet().length;
    final totalSets = sets.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
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
          borderRadius: BorderRadius.circular(16),
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

  Widget _buildExerciseGroup(
    String exerciseName,
    List<GymSet> sets,
    bool showImages,
  ) {
    final firstSet = sets.first;
    final exerciseNotes = firstSet.notes;

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

    final children = <Widget>[
      // Show exercise notes if present
      if (exerciseNotes?.isNotEmpty == true)
        Container(
          margin: const EdgeInsets.fromLTRB(72, 0, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
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
      ...sets.asMap().entries.map((entry) {
        final index = entry.key;
        final set = entry.value;
        return _buildSetTile(set, index + 1);
      }),
    ];

    return ExpansionTile(
      leading: leading,
      title: Text(exerciseName),
      subtitle: exerciseNotes?.isNotEmpty == true
          ? Row(
              children: [
                Icon(Icons.note, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text('${sets.length} sets'),
              ],
            )
          : Text('${sets.length} sets'),
      initiallyExpanded: true,
      children: children,
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
