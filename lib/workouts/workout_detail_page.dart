import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flexify/constants.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/database/gym_sets.dart';
import 'package:flexify/graph/cardio_page.dart';
import 'package:flexify/graph/strength_page.dart';
import 'package:flexify/main.dart';
import 'package:flexify/records/record_notification.dart';
import 'package:flexify/records/records_service.dart';
import 'package:flexify/sets/edit_set_page.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/utils.dart';
import 'package:flexify/widgets/bodypart_tag.dart';
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
  Map<int, Set<RecordType>> _recordsMap = {};

  @override
  void initState() {
    super.initState();
    setsStream = (db.gymSets.select()
          ..where((s) =>
              s.workoutId.equals(widget.workout.id) &
              s.hidden.equals(false) &
              s.sequence.isBiggerOrEqualValue(0))
          ..orderBy([
            (s) => OrderingTerm(expression: s.created, mode: OrderingMode.asc)
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

          // Group sets by exercise, detecting sequence gaps for multiple instances
          final List<({String name, List<GymSet> sets, int minSeq, int maxSeq})> exerciseGroups = [];

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
                  (currentMaxSeq != null && set.sequence > currentMaxSeq + 1)) {
                // New exercise or gap detected - save previous group
                if (currentExercise != null && currentSets.isNotEmpty) {
                  exerciseGroups.add((
                    name: currentExercise,
                    sets: currentSets,
                    minSeq: currentMinSeq!,
                    maxSeq: currentMaxSeq!,
                  ));
                }
                // Start new group
                currentExercise = set.name;
                currentSets = [set];
                currentMinSeq = set.sequence;
                currentMaxSeq = set.sequence;
              } else {
                // Continue current group
                currentSets.add(set);
                currentMaxSeq = set.sequence;
              }
            }

            // Add last group
            if (currentExercise != null && currentSets.isNotEmpty) {
              exerciseGroups.add((
                name: currentExercise,
                sets: currentSets,
                minSeq: currentMinSeq!,
                maxSeq: currentMaxSeq!,
              ));
            }
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
                child: _buildStatsSection(sets, totalVolume, uniqueExerciseNames, _recordsMap.length),
              ),
              // Notes section
              if (widget.workout.notes?.isNotEmpty == true)
                SliverToBoxAdapter(
                  child: _buildNotesSection(),
                ),
              // Empty state
              if (exerciseGroups.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No exercises in this workout'),
                  ),
                ),
              // Exercise groups (each instance displayed separately)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final group = exerciseGroups[index];
                    return _buildExerciseGroup(
                      group.name,
                      group.sets,
                      showImages,
                      _recordsMap,
                    );
                  },
                  childCount: exerciseGroups.length,
                ),
              ),
              // Bottom padding for navigation bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
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

  Widget _buildStatsSection(List<GymSet> sets, double totalVolume, int exerciseCount, int recordCount) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = widget.workout.endTime != null
        ? widget.workout.endTime!.difference(widget.workout.startTime)
        : DateTime.now().difference(widget.workout.startTime);

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

  Widget _buildStatItem(IconData icon, String value, String label, {bool isHighlighted = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlighted ? Colors.amber : colorScheme.primary,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? Colors.amber.shade700 : null,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isHighlighted ? Colors.amber.shade600 : colorScheme.onSurfaceVariant,
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
    List<GymSet> unsortedSets,
    bool showImages,
    Map<int, Set<RecordType>> recordsMap,
  ) {
    // Sort sets: warmups first, then by creation time
    final sets = List<GymSet>.from(unsortedSets)
      ..sort((a, b) {
        // Warmups come first
        if (a.warmup && !b.warmup) return -1;
        if (!a.warmup && b.warmup) return 1;
        // Then by creation time
        return a.created.compareTo(b.created);
      });

    final firstSet = unsortedSets.first; // Use original first for metadata
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
      ...(() {
        int workingSetNumber = 0;
        int dropSetNumber = 0;
        return sets.map((set) {
          final setRecords = recordsMap[set.id] ?? {};
          if (set.dropSet) {
            dropSetNumber++;
            return _buildSetTile(set, dropSetNumber, isDropSet: true, records: setRecords);
          } else if (!set.warmup) {
            workingSetNumber++;
            return _buildSetTile(set, workingSetNumber, records: setRecords);
          } else {
            return _buildSetTile(set, 0, records: setRecords);
          }
        }).toList();
      })(),
    ];

    return InkWell(
      onLongPress: () => _showExerciseMenu(context, exerciseName),
      child: ExpansionTile(
        leading: leading,
        title: Row(
          children: [
            Flexible(
              child: Text(exerciseName),
            ),
            if (category != null && category.isNotEmpty) ...[
              const SizedBox(width: 6),
              BodypartTag(bodypart: category),
            ],
            if (brandName != null && brandName.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.7),
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
                color: Colors.amber.shade600,
              ),
            ],
          ],
        ),
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
      ),
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

  Widget _buildSetTile(GymSet set, int setNumber, {bool isDropSet = false, Set<RecordType> records = const {}}) {
    final reps = toString(set.reps);
    final weight = toString(set.weight);
    final minutes = set.duration.floor();
    final seconds =
        ((set.duration * 60) % 60).floor().toString().padLeft(2, '0');
    final distance = toString(set.distance);
    final colorScheme = Theme.of(context).colorScheme;
    final isWarmup = set.warmup;
    final hasRecords = records.isNotEmpty;

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
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isWarmup
              ? colorScheme.tertiaryContainer
              : isDropSet
                  ? colorScheme.secondaryContainer
                  : hasRecords
                      ? Colors.amber.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: hasRecords
              ? Border.all(color: Colors.amber.shade400, width: 1.5)
              : null,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: hasRecords ? Colors.amber.shade700 : colorScheme.onSurface,
                        fontWeight: hasRecords ? FontWeight.bold : null,
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
                          ? TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)
                          : null,
                ),
              ),
              if (hasRecords)
                RecordCrown(records: records, size: 18),
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
                      color = Colors.orange;
                      break;
                    case RecordType.bestVolume:
                      label = 'Volume Record';
                      color = Colors.deepOrange;
                      break;
                    case RecordType.bestWeight:
                      label = 'Weight Record';
                      color = Colors.amber;
                      break;
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: color.withValues(alpha: 0.4),
                        width: 1,
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

  Future<void> _showExerciseMenu(BuildContext parentContext, String exerciseName) async {
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

  Future<void> _jumpToGraph(BuildContext parentContext, String exerciseName) async {
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
        metric: CardioMetric.pace,
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
