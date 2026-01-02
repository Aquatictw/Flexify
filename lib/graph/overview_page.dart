import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/workouts/workout_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum OverviewPeriod { week, month, months3, months6, year, allTime }

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  OverviewPeriod period = OverviewPeriod.month;
  Map<String, double> muscleVolumes = {};
  Map<String, int> muscleSetCounts = {};
  Map<DateTime, int> trainingDays = {};
  int totalWorkouts = 0;
  double totalVolume = 0;
  int currentStreak = 0;
  String? mostTrainedMuscle;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final now = DateTime.now();
    DateTime startDate;

    // For All Time, get the earliest workout date
    if (period == OverviewPeriod.allTime) {
      final firstWorkout = await (db.workouts.select()
            ..orderBy([(w) => OrderingTerm(expression: w.startTime, mode: OrderingMode.asc)])
            ..limit(1))
          .getSingleOrNull();

      if (firstWorkout != null) {
        startDate = firstWorkout.startTime;
      } else {
        // No workouts yet, use today
        startDate = now;
      }
    } else {
      startDate = _getStartDate(now);
    }

    // Load muscle volumes
    final volumeQuery = await db.customSelect(
      """
      SELECT
        gs.category as muscle,
        SUM(gs.weight * gs.reps) as total_volume
      FROM gym_sets gs
      WHERE gs.created >= ?
        AND gs.hidden = 0
        AND gs.category IS NOT NULL
        AND gs.cardio = 0
      GROUP BY gs.category
      ORDER BY total_volume DESC
    """,
      variables: [
        drift.Variable.withInt(startDate.millisecondsSinceEpoch ~/ 1000),
      ],
    ).get();

    final volumes = <String, double>{};
    for (final row in volumeQuery) {
      final muscle = row.read<String>('muscle');
      final volume = row.read<double>('total_volume');
      volumes[muscle] = volume;
    }

    // Load muscle set counts
    final setCountQuery = await db.customSelect(
      """
      SELECT
        gs.category as muscle,
        COUNT(*) as total_sets
      FROM gym_sets gs
      WHERE gs.created >= ?
        AND gs.hidden = 0
        AND gs.category IS NOT NULL
        AND gs.cardio = 0
      GROUP BY gs.category
      ORDER BY total_sets DESC
    """,
      variables: [
        drift.Variable.withInt(startDate.millisecondsSinceEpoch ~/ 1000),
      ],
    ).get();

    final setCounts = <String, int>{};
    for (final row in setCountQuery) {
      final muscle = row.read<String>('muscle');
      final count = row.read<int>('total_sets');
      setCounts[muscle] = count;
    }

    // Load training days for heatmap
    final daysQuery = await db.customSelect(
      """
      SELECT DISTINCT
        DATE(w.start_time, 'unixepoch') as workout_date,
        COUNT(DISTINCT gs.id) as set_count
      FROM workouts w
      INNER JOIN gym_sets gs ON w.id = gs.workout_id
      WHERE w.start_time >= ?
        AND gs.hidden = 0
      GROUP BY workout_date
      ORDER BY workout_date DESC
    """,
      variables: [
        drift.Variable.withInt(startDate.millisecondsSinceEpoch ~/ 1000),
      ],
    ).get();

    final days = <DateTime, int>{};
    for (final row in daysQuery) {
      final dateStr = row.read<String>('workout_date');
      final date = DateTime.parse(dateStr);
      final count = row.read<int>('set_count');
      days[DateTime(date.year, date.month, date.day)] = count;
    }

    // Calculate total workouts
    final workoutsQuery = await db.customSelect(
      """
      SELECT COUNT(DISTINCT w.id) as workout_count
      FROM workouts w
      WHERE w.start_time >= ?
    """,
      variables: [
        drift.Variable.withInt(startDate.millisecondsSinceEpoch ~/ 1000),
      ],
    ).getSingle();

    final workoutCount = workoutsQuery.read<int>('workout_count');

    // Calculate total volume
    final totalVol = volumes.values.fold<double>(0, (sum, vol) => sum + vol);

    // Calculate current streak
    final streak = await _calculateStreak();

    // Find most trained muscle
    String? topMuscle;
    if (volumes.isNotEmpty) {
      topMuscle =
          volumes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    if (mounted) {
      setState(() {
        muscleVolumes = volumes;
        muscleSetCounts = setCounts;
        trainingDays = days;
        totalWorkouts = workoutCount;
        totalVolume = totalVol;
        currentStreak = streak;
        mostTrainedMuscle = topMuscle;
        isLoading = false;
      });
    }
  }

  Future<int> _calculateStreak() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime checkDate = todayDate;

    while (true) {
      final hasWorkout = await db.customSelect(
        """
        SELECT COUNT(*) as count
        FROM workouts w
        WHERE DATE(w.start_time, 'unixepoch') = ?
      """,
        variables: [
          drift.Variable.withString(DateFormat('yyyy-MM-dd').format(checkDate)),
        ],
      ).getSingle();

      if (hasWorkout.read<int>('count') > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Future<void> _showDayDetails(DateTime date) async {
    // Fetch workout for this date using SQL query
    final workoutQuery = await db.customSelect(
      """
      SELECT *
      FROM workouts
      WHERE DATE(start_time, 'unixepoch') = ?
      LIMIT 1
    """,
      variables: [
        drift.Variable.withString(DateFormat('yyyy-MM-dd').format(date)),
      ],
      readsFrom: {db.workouts},
    ).getSingleOrNull();

    if (workoutQuery == null || !mounted) return;

    final workoutId = workoutQuery.read<int>('id');
    final workoutName = workoutQuery.readNullable<String>('name');
    final startTime = DateTime.fromMillisecondsSinceEpoch(
      workoutQuery.read<int>('start_time') * 1000,
    );

    final dayData = await db.customSelect(
      """
      SELECT
        gs.name as exercise_name,
        gs.category,
        COUNT(*) as set_count,
        SUM(gs.weight * gs.reps) as volume
      FROM gym_sets gs
      WHERE gs.workout_id = ?
        AND gs.hidden = 0
      GROUP BY gs.name
      ORDER BY gs.created
    """,
      variables: [
        drift.Variable.withInt(workoutId),
      ],
    ).get();

    if (!mounted) return;

    if (dayData.isEmpty) {
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // Create a Workout object for navigation
                        final workout = Workout(
                          id: workoutId,
                          startTime: startTime,
                          name: workoutName,
                        );
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutDetailPage(workout: workout),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workoutName ?? 'Workout',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${dayData.length} exercises',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
            // Exercise list
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: dayData.length,
                itemBuilder: (context, index) {
                  final exercise = dayData[index];
                  final exerciseName = exercise.read<String>('exercise_name');
                  final category = exercise.readNullable<String>('category');
                  final setCount = exercise.read<int>('set_count');
                  final volume = exercise.read<double>('volume');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exerciseName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (category != null)
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$setCount sets',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              '${NumberFormat("#,###").format(volume.round())} kg',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getStartDate(DateTime now) {
    switch (period) {
      case OverviewPeriod.week:
        return now.subtract(const Duration(days: 7));
      case OverviewPeriod.month:
        return DateTime(now.year, now.month - 1, now.day);
      case OverviewPeriod.months3:
        return DateTime(now.year, now.month - 3, now.day);
      case OverviewPeriod.months6:
        return DateTime(now.year, now.month - 6, now.day);
      case OverviewPeriod.year:
        return DateTime(now.year - 1, now.month, now.day);
      case OverviewPeriod.allTime:
        return DateTime(1970, 1, 1); // Beginning of time
    }
  }

  String _getPeriodLabel(OverviewPeriod p) {
    switch (p) {
      case OverviewPeriod.week:
        return '7D';
      case OverviewPeriod.month:
        return '1M';
      case OverviewPeriod.months3:
        return '3M';
      case OverviewPeriod.months6:
        return '6M';
      case OverviewPeriod.year:
        return '1Y';
      case OverviewPeriod.allTime:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Overview'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: OverviewPeriod.values.map((p) {
                        final isSelected = period == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_getPeriodLabel(p)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => period = p);
                                _loadData();
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats cards
                  _buildStatsCards(colorScheme),

                  const SizedBox(height: 24),

                  // Heatmap calendar
                  _buildHeatmapSection(colorScheme),

                  const SizedBox(height: 24),

                  // Muscle volume chart
                  if (muscleVolumes.isNotEmpty)
                    _buildMuscleVolumeChart(colorScheme),

                  // Muscle set count chart
                  if (muscleSetCounts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildMuscleSetCountChart(colorScheme),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCards(ColorScheme colorScheme) {
    final formatter = NumberFormat("#,###");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                colorScheme: colorScheme,
                icon: Icons.fitness_center,
                label: 'Workouts',
                value: '$totalWorkouts',
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                colorScheme: colorScheme,
                icon: Icons.trending_up,
                label: 'Total Volume',
                value: formatter.format(totalVolume.round()),
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                colorScheme: colorScheme,
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '$currentStreak days',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                colorScheme: colorScheme,
                icon: Icons.emoji_events,
                label: 'Top Muscle',
                value: mostTrainedMuscle ?? 'N/A',
                color: colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Training Heatmap',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildHeatmap(colorScheme),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getHeatmapColor(
                      colorScheme,
                      index == 0 ? 0 : index * 5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'More',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeatmap(ColorScheme colorScheme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = _getStartDate(now);

    // Find the Monday of the week containing startDate
    final startWeekday = startDate.weekday; // 1 = Monday, 7 = Sunday
    final mondayOfStartWeek = startDate.subtract(Duration(days: startWeekday - 1));

    // Find the Sunday of the week containing today
    final todayWeekday = today.weekday;
    final sundayOfCurrentWeek = today.add(Duration(days: 7 - todayWeekday));

    // Calculate weeks to display
    final totalDays = sundayOfCurrentWeek.difference(mondayOfStartWeek).inDays + 1;
    final weeks = (totalDays / 7).ceil();

    // Build month labels (latest on left)
    final monthLabels = <int, String>{};
    int lastMonth = -1;
    for (int week = 0; week < weeks; week++) {
      // Start from the most recent week and go backwards
      final date = sundayOfCurrentWeek.subtract(Duration(days: week * 7));
      if (date.month != lastMonth) {
        monthLabels[week] = DateFormat('MMM').format(date);
        lastMonth = date.month;
      }
    }

    // Build grid of days
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed days of week column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Empty space for month labels row
              const SizedBox(height: 25),
              // Day labels
              ...List.generate(7, (dayOfWeek) {
                return SizedBox(
                  width: 30,
                  height: 18,
                  child: Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][dayOfWeek],
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
          // Scrollable heatmap grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month labels
                Row(
                  children: List.generate(weeks, (weekIndex) {
                    final label = monthLabels[weekIndex];
                    return SizedBox(
                      width: 18,
                      child: label != null
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary.withValues(alpha: 0.8),
                                ),
                              ),
                            )
                          : const SizedBox(),
                    );
                  }),
                ),
                // Day rows (Monday=0 to Sunday=6)
                ...List.generate(7, (dayOfWeek) {
                  return Row(
                    children: List.generate(weeks, (weekIndex) {
                      // Calculate date from most recent week backwards
                      final weeksFromNow = weekIndex;
                      final weekStart = sundayOfCurrentWeek.subtract(Duration(days: weeksFromNow * 7 + (6 - dayOfWeek)));
                      final date = DateTime(weekStart.year, weekStart.month, weekStart.day);

                      if (date.isBefore(startDate) || date.isAfter(today)) {
                        return const Padding(
                          padding: EdgeInsets.all(2),
                          child: SizedBox(width: 14, height: 14),
                        );
                      }

                      final count = trainingDays[date] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: InkWell(
                          onTap: count > 0
                              ? () => _showDayDetails(date)
                              : null,
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _getHeatmapColor(colorScheme, count),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: count > 0
                                    ? colorScheme.primary.withValues(alpha: 0.3)
                                    : colorScheme.outline.withValues(alpha: 0.2),
                                width: count > 0 ? 0.8 : 0.5,
                              ),
                              boxShadow: count > 10
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 2,
                                        spreadRadius: 0.5,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHeatmapColor(ColorScheme colorScheme, int count) {
    if (count == 0) {
      return colorScheme.surfaceContainerHighest;
    } else if (count < 5) {
      return colorScheme.primary.withValues(alpha: 0.2);
    } else if (count < 10) {
      return colorScheme.primary.withValues(alpha: 0.4);
    } else if (count < 15) {
      return colorScheme.primary.withValues(alpha: 0.6);
    } else {
      return colorScheme.primary.withValues(alpha: 0.8);
    }
  }

  Widget _buildMuscleVolumeChart(ColorScheme colorScheme) {
    final sortedMuscles = muscleVolumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 10 muscles
    final topMuscles = sortedMuscles.take(10).toList();

    final maxVolume = topMuscles.isEmpty
        ? 0.0
        : topMuscles.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Muscle Group Volume',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVolume * 1.1,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.surface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final muscle = topMuscles[group.x.toInt()].key;
                    final volume = topMuscles[group.x.toInt()].value;
                    return BarTooltipItem(
                      '$muscle\n${NumberFormat("#,###").format(volume)} kg',
                      TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= topMuscles.length) {
                        return const SizedBox();
                      }
                      final muscle = topMuscles[value.toInt()].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            muscle,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxVolume / 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                topMuscles.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: topMuscles[index].value,
                      color: colorScheme.primary,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleSetCountChart(ColorScheme colorScheme) {
    final sortedMuscles = muscleSetCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 10 muscles
    final topMuscles = sortedMuscles.take(10).toList();

    final maxSets = topMuscles.isEmpty
        ? 0
        : topMuscles.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_list_numbered, color: colorScheme.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Muscle Group Set Count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxSets * 1.1).toDouble(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.surface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final muscle = topMuscles[group.x.toInt()].key;
                    final sets = topMuscles[group.x.toInt()].value;
                    return BarTooltipItem(
                      '$muscle\n$sets sets',
                      TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= topMuscles.length) {
                        return const SizedBox();
                      }
                      final muscle = topMuscles[value.toInt()].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(
                            muscle,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxSets / 5).ceilToDouble(),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                topMuscles.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: topMuscles[index].value.toDouble(),
                      color: colorScheme.secondary,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
