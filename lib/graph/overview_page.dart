import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flexify/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum OverviewPeriod { week, month, months3, months6, year }

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  OverviewPeriod period = OverviewPeriod.month;
  Map<String, double> muscleVolumes = {};
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
    final startDate = _getStartDate(now);

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
    final startDate = _getStartDate(now);

    // Calculate weeks to display
    final days = now.difference(startDate).inDays;
    final weeks = (days / 7).ceil();

    // Build grid of days
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(7, (dayOfWeek) {
            return Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][dayOfWeek],
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...List.generate(weeks, (week) {
                  final date = startDate.add(
                    Duration(
                      days: week * 7 + dayOfWeek,
                    ),
                  );

                  if (date.isAfter(now)) {
                    return const Padding(
                      padding: EdgeInsets.all(2),
                      child: SizedBox(width: 14, height: 14),
                    );
                  }

                  final normalizedDate =
                      DateTime(date.year, date.month, date.day);
                  final count = trainingDays[normalizedDate] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.all(2),
                    child: Tooltip(
                      message: '${DateFormat('MMM d').format(date)}\n$count sets',
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _getHeatmapColor(colorScheme, count),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ),
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
}
