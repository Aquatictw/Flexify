import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../main.dart';
import '../records/records_service.dart';
import '../theme/tokens.dart';
import '../widgets/history_heatmap_header.dart';
import 'workout_detail_page.dart';

class WorkoutWithSets {
  WorkoutWithSets({
    required this.workout,
    required this.setCount,
    required this.exerciseCount,
    required this.exerciseNames,
    this.totalVolume = 0,
    this.recordCount = 0,
    this.muscleGroups = const [],
    this.dominantGroup = MuscleGroup.other,
    this.prTypesByExercise = const {},
  });
  final Workout workout;
  final int setCount;
  final int exerciseCount;
  final List<String> exerciseNames;
  final double totalVolume;
  final int recordCount;

  /// Distinct Push/Pull/Legs groups trained, in display order.
  final List<MuscleGroup> muscleGroups;

  /// Group with the most sets — tints the card's left rail.
  final MuscleGroup dominantGroup;

  /// Exercise name -> record types it achieved in this workout.
  final Map<String, Set<RecordType>> prTypesByExercise;
}

class WorkoutsList extends StatefulWidget {
  const WorkoutsList({
    required this.scroll,
    required this.onNext,
    required this.search,
    required this.limit,
    required this.selected,
    required this.onSelect,
    super.key,
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

        // Distinct Push/Pull/Legs groups, ordered Push → Pull → Legs → Other.
        // Tally distinct exercises per group (not sets) to pick the dominant
        // category — 3 leg exercises should beat 2 pull exercises regardless of
        // how many sets each had.
        final groupExercises = <MuscleGroup, Set<String>>{};
        for (final s in sets) {
          final g = muscleGroupOf(s.category, s.name);
          (groupExercises[g] ??= <String>{}).add(s.name);
        }
        final groupCounts = {
          for (final e in groupExercises.entries) e.key: e.value.length,
        };
        final muscleGroups = [
          for (final g in MuscleGroup.values)
            if (groupCounts.containsKey(g)) g,
        ];
        // Most sets wins; enum order (Push→Pull→Legs→Other) breaks ties.
        final dominantGroup = muscleGroups.isEmpty
            ? MuscleGroup.other
            : muscleGroups.reduce(
                (a, b) => groupCounts[b]! > groupCounts[a]! ? b : a,
              );

        // Which exercises hit a PR, and of what type(s): map record set-ids
        // back to names, unioning record types per exercise.
        final recordCount = recordCounts[workout.id] ?? 0;
        final prTypes = <String, Set<RecordType>>{};
        if (recordCount > 0) {
          final records = await getWorkoutRecords(workout.id);
          final byId = {for (final s in sets) s.id: s.name};
          for (final entry in records.entries) {
            final name = byId[entry.key];
            if (name == null) continue;
            (prTypes[name] ??= <RecordType>{}).addAll(entry.value);
          }
        }

        result.add(
          WorkoutWithSets(
            workout: workout,
            setCount: sets.length,
            exerciseCount: exerciseNames.length,
            exerciseNames: exerciseNames,
            totalVolume: totalVolume,
            recordCount: recordCount,
            muscleGroups: muscleGroups,
            dominantGroup: dominantGroup,
            prTypesByExercise: prTypes,
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
        final selecting = widget.selected.isNotEmpty;
        // Header only shows on the unfiltered feed, not while searching/selecting.
        final showHeader = widget.search.isEmpty &&
            widget.startDate == null &&
            widget.endDate == null &&
            !selecting;

        if (workouts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(space16),
              child: Text('No workouts found'),
            ),
          );
        }

        // Flatten into a list of "rows": optional header, week dividers, cards.
        final rows = <Widget>[];
        if (showHeader) rows.add(const HistoryHeatmapHeader());

        String? lastBucket;
        for (final w in workouts) {
          final bucket = _weekBucket(w.workout.startTime);
          if (bucket != lastBucket) {
            rows.add(_Divider(label: bucket));
            lastBucket = bucket;
          }
          rows.add(
            _WorkoutCard(
              workoutWithSets: w,
              selected: widget.selected,
              onSelect: widget.onSelect,
            ),
          );
        }

        return ListView.builder(
          controller: widget.scroll,
          padding: EdgeInsets.only(
            bottom: bottomBarClearance(context),
            top: space8,
          ),
          itemCount: rows.length,
          itemBuilder: (context, index) => rows[index],
        );
      },
    );
  }

  /// Coarse recency bucket used as a section divider label.
  String _weekBucket(DateTime when) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final day = DateUtils.dateOnly(when);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
    if (!day.isBefore(startOfWeek)) return 'This week';
    if (!day.isBefore(startOfLastWeek)) return 'Last week';
    if (day.year == today.year) return DateFormat('MMMM').format(day);
    return DateFormat('MMMM yyyy').format(day);
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(space24, space8, space24, space8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
      ),
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
    final textTheme = Theme.of(context).textTheme;
    final isSelected = selected.contains(workout.id);

    final duration = workout.endTime?.difference(workout.startTime);
    final hasNotes = workout.notes?.isNotEmpty ?? false;

    // Day's dominant group (most sets) tints the left rail + corner glow.
    final groups = workoutWithSets.muscleGroups;
    final accent = groups.isEmpty
        ? colorScheme.outline
        : context.jl.muscleColor(workoutWithSets.dominantGroup);

    return Padding(
      padding: const EdgeInsets.fromLTRB(space16, 0, space16, space12),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: .08)
            : colorScheme.surfaceContainer,
        borderRadius: brMd,
        clipBehavior: Clip.antiAlias,
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
          onLongPress: () => onSelect(workout.id),
          child: Stack(
            children: [
              // Left accent rail tinted by the dominant muscle group.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: accent.withValues(alpha: 0.7),
                ),
              ),
              // Faint corner glow of the dominant group.
              Positioned(
                right: -40,
                top: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.07),
                          accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  space16 + space4,
                  space16,
                  space16,
                  space12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: selection checkbox OR date, plus duration.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selected.isNotEmpty) ...[
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (_) => onSelect(workout.id),
                            ),
                          ),
                          const SizedBox(width: space12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dateLabel(workout.startTime),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _dateSub(workout.startTime, workout.name),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (duration != null) _DurationPill(duration: duration),
                      ],
                    ),
                    // Muscle-group pills — the headline identity.
                    if (groups.isNotEmpty) ...[
                      const SizedBox(height: space12),
                      Wrap(
                        spacing: space8,
                        runSpacing: space8,
                        children: [
                          for (final g in groups)
                            _MusclePill(
                              label: muscleLabel(g),
                              color: context.jl.muscleColor(g),
                            ),
                        ],
                      ),
                    ],
                    // Exercise list — prominent, scannable, PR-starred.
                    if (workoutWithSets.exerciseNames.isNotEmpty) ...[
                      const SizedBox(height: space12),
                      for (final name in workoutWithSets.exerciseNames)
                        _ExerciseRow(
                          name: name,
                          accent: accent,
                          prTypes: workoutWithSets.prTypesByExercise[name],
                        ),
                    ],
                    // Stat strip.
                    const SizedBox(height: space12),
                    _StatStrip(data: workoutWithSets),
                    // Note.
                    if (hasNotes) ...[
                      const SizedBox(height: space12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(space8 + space4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: brSm,
                        ),
                        child: Text(
                          workout.notes!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime when) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(when);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(when); // Monday…
    return DateFormat('EEE, MMM d').format(when); // Thu, Jun 26
  }

  String _dateSub(DateTime when, String? name) {
    final time = DateFormat('h:mm a').format(when);
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = today.difference(DateUtils.dateOnly(when)).inDays;
    final ago = diff >= 7 ? '$diff days ago · ' : '';
    final title = (name?.isNotEmpty ?? false) ? ' · $name' : '';
    return '$ago$time$title';
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({required this.duration});
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: space12, vertical: space4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: space4),
          Text(
            _format(duration),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  String _format(Duration d) =>
      d.inHours > 0 ? '${d.inHours}h ${d.inMinutes % 60}m' : '${d.inMinutes}m';
}

class _MusclePill extends StatelessWidget {
  const _MusclePill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: space12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: brPill,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: space8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.name,
    required this.accent,
    this.prTypes,
  });
  final String name;
  final Color accent;
  final Set<RecordType>? prTypes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPr = prTypes?.isNotEmpty ?? false;
    // Show record types in a stable order: 1RM → Vol → Wt.
    final badges = [
      for (final t in RecordType.values)
        if (prTypes?.contains(t) ?? false) t,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: space8 + 1),
          Expanded(
            child: Text(
              name,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: isPr ? FontWeight.w700 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          for (final t in badges) ...[
            const SizedBox(width: space4 + 2),
            _PrBadge(type: t),
          ],
        ],
      ),
    );
  }
}

/// Small "1RM PR" / "Vol PR" / "Wt PR" pill next to a record-setting exercise.
class _PrBadge extends StatelessWidget {
  const _PrBadge({required this.type});
  final RecordType type;

  @override
  Widget build(BuildContext context) {
    final pr = context.jl.pr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: pr.withValues(alpha: 0.15),
        borderRadius: brSm,
      ),
      child: Text(
        '${recordShortLabel(type)} PR',
        style: TextStyle(
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: pr,
        ),
      ),
    );
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.data});
  final WorkoutWithSets data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(top: space12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _stat(context, _formatVolume(data.totalVolume), 'Volume'),
          _sep(context),
          _stat(context, '${data.setCount}', 'Sets'),
          _sep(context),
          _stat(context, '${data.exerciseCount}', 'Exercises'),
          _sep(context),
          _stat(
            context,
            data.recordCount > 0 ? '${data.recordCount}' : '—',
            'PRs',
            highlight: data.recordCount > 0,
            icon: data.recordCount > 0 ? Icons.emoji_events : null,
          ),
        ],
      ),
    );
  }

  Widget _sep(BuildContext context) => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: space12),
        color:
            Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
      );

  Widget _stat(
    BuildContext context,
    String value,
    String label, {
    bool highlight = false,
    IconData? icon,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: context.jl.pr),
                const SizedBox(width: 3),
              ],
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: highlight ? context.jl.pr : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // FittedBox keeps the longest label ("EXERCISES") on one line by
          // scaling it down within its equal-width column instead of wrapping.
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: highlight
                      ? context.jl.pr
                      : colorScheme.onSurfaceVariant,
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
                  fontSize: highlight ? 12 : null,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(1)}k';
    return volume.toStringAsFixed(0);
  }
}
