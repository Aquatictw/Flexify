import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flexify/constants.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/database/gym_sets.dart';
import 'package:flexify/graph/edit_graph_page.dart';
import 'package:flexify/graph/graph_history_page.dart';
import 'package:flexify/graph/strength_data.dart';
import 'package:flexify/main.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/workouts/workout_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StrengthPage extends StatefulWidget {
  final String name;
  final String unit;
  final List<StrengthData> data;
  final TabController tabCtrl;

  const StrengthPage({
    super.key,
    required this.name,
    required this.unit,
    required this.data,
    required this.tabCtrl,
  });

  @override
  createState() => _StrengthPageState();
}

class _StrengthPageState extends State<StrengthPage> {
  late List<StrengthData> data = widget.data;
  late String target = widget.unit;
  late String name = widget.name;

  StrengthMetric metric = StrengthMetric.bestWeight;
  Period period = Period.months3;
  int? selectedIndex;

  // Records data
  ExerciseRecords? records;
  List<RepRecord> repRecords = [];

  @override
  void initState() {
    super.initState();
    widget.tabCtrl.addListener(_onTabChanged);
    setData();
    _loadRecords();
  }

  @override
  void dispose() {
    widget.tabCtrl.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    final settings = context.read<SettingsState>().value;
    if (widget.tabCtrl.index == settings.tabs.indexOf('GraphsPage')) {
      setData();
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    final exerciseRecords = await getExerciseRecords(
      name: widget.name,
      targetUnit: target,
    );
    final reps = await getRepRecords(
      name: widget.name,
      targetUnit: target,
    );
    if (mounted) {
      setState(() {
        records = exerciseRecords;
        repRecords = reps;
      });
    }
  }

  String _getPeriodLabel(Period p) {
    switch (p) {
      case Period.days30:
        return '30D';
      case Period.months3:
        return '3M';
      case Period.months6:
        return '6M';
      case Period.year:
        return '1Y';
      case Period.allTime:
        return 'All';
    }
  }

  String _getMetricLabel(StrengthMetric m) {
    switch (m) {
      case StrengthMetric.bestWeight:
        return 'Best Weight';
      case StrengthMetric.bestVolume:
        return 'Best Volume';
      case StrengthMetric.oneRepMax:
        return '1RM';
      case StrengthMetric.relativeStrength:
        return 'Relative';
      case StrengthMetric.volume:
        return 'Volume';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>().value;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            onPressed: () async {
              final gymSets = await (db.gymSets.select()
                    ..orderBy([
                      (u) => drift.OrderingTerm(
                            expression: u.created,
                            mode: drift.OrderingMode.desc,
                          ),
                    ])
                    ..where((tbl) => tbl.name.equals(name))
                    ..where((tbl) => tbl.hidden.equals(false))
                    ..limit(20))
                  .get();
              if (!context.mounted) return;

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GraphHistoryPage(
                    name: name,
                    gymSets: gymSets,
                  ),
                ),
              );
              Timer(kThemeAnimationDuration, () {
                setData();
                _loadRecords();
              });
            },
            icon: const Icon(Icons.history),
            tooltip: "History",
          ),
          IconButton(
            onPressed: () async {
              String? newName = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditGraphPage(name: name),
                ),
              );
              if (mounted && newName != null) {
                setState(() => name = newName);
              }
            },
            icon: const Icon(Icons.edit),
            tooltip: "Edit",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: Period.values.map((p) {
                  final isSelected = period == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        _getPeriodLabel(p),
                        style: const TextStyle(fontSize: 12),
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            period = p;
                            selectedIndex = null;
                          });
                          setData();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Metric selector chips
            if (name != 'Weight')
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    StrengthMetric.bestWeight,
                    StrengthMetric.bestVolume,
                    StrengthMetric.oneRepMax,
                    if (settings.showBodyWeight)
                      StrengthMetric.relativeStrength,
                  ].map((m) {
                    final isSelected = metric == m;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          _getMetricLabel(m),
                          style: const TextStyle(fontSize: 12),
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              metric = m;
                              selectedIndex = null;
                            });
                            setData();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 12),

            // Chart with overlay label
            SizedBox(
              height: 250,
              child: data.isEmpty
                  ? Center(
                      child: Text(
                        'No data for this period',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : Stack(
                      children: [
                        _buildChart(settings, colorScheme),
                        // Selected value overlay (top left, clickable)
                        if (selectedIndex != null &&
                            selectedIndex! < data.length)
                          Positioned(
                            top: 8,
                            left: 40,
                            child: GestureDetector(
                              onTap: () => _editSet(selectedIndex!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatValue(data[selectedIndex!]),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    if (metric == StrengthMetric.oneRepMax ||
                                        metric == StrengthMetric.bestVolume)
                                      Text(
                                        _formatSetInfo(data[selectedIndex!]),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: colorScheme.onPrimaryContainer
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                    Text(
                                      DateFormat(settings.shortDateFormat)
                                          .format(data[selectedIndex!].created),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onPrimaryContainer
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Records section
            if (records != null && name != 'Weight')
              _buildRecordsSection(colorScheme),

            const SizedBox(height: 24),

            // Rep Records section
            if (repRecords.isNotEmpty && name != 'Weight')
              _buildRepRecordsSection(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsSection(ColorScheme colorScheme) {
    final formatter = NumberFormat("#,###.##");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Personal Records',
              style: TextStyle(
                fontSize: 16,
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
              child: _buildRecordCard(
                colorScheme: colorScheme,
                icon: Icons.fitness_center,
                label: 'Best Weight',
                value: '${formatter.format(records!.bestWeight)} $target',
                date: records!.bestWeightDate,
                color: colorScheme.primary,
                workoutId: records!.bestWeightWorkoutId,
                subtitle: records!.bestWeightReps != null
                    ? '${records!.bestWeightReps!.toInt()} reps'
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRecordCard(
                colorScheme: colorScheme,
                icon: Icons.trending_up,
                label: '1RM',
                value: '${formatter.format(records!.best1RM)} $target',
                date: records!.best1RMDate,
                color: colorScheme.tertiary,
                workoutId: records!.best1RMWorkoutId,
                subtitle: records!.best1RMReps != null
                    ? '${records!.best1RMReps!.toInt()} reps'
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRecordCard(
                colorScheme: colorScheme,
                icon: Icons.bar_chart,
                label: 'Best Volume',
                value: formatter.format(records!.bestVolume),
                date: records!.bestVolumeDate,
                color: colorScheme.secondary,
                workoutId: records!.bestVolumeWorkoutId,
                subtitle: records!.bestVolumeReps != null &&
                        records!.bestVolumeWeight != null
                    ? '${records!.bestVolumeReps!.toInt()} × ${formatter.format(records!.bestVolumeWeight!)} $target'
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordCard({
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
    required DateTime? date,
    required Color color,
    int? workoutId,
    String? subtitle,
  }) {
    return InkWell(
      onTap: workoutId != null
          ? () async {
              final workout = await (db.workouts.select()
                    ..where((w) => w.id.equals(workoutId)))
                  .getSingleOrNull();

              if (workout != null && mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailPage(workout: workout),
                  ),
                );
                Timer(kThemeAnimationDuration, () {
                  setData();
                  _loadRecords();
                });
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
            if (date != null) ...[
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM d, yyyy').format(date),
                style: TextStyle(
                  fontSize: 9,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRepRecordsSection(ColorScheme colorScheme) {
    final formatter = NumberFormat("#,###.##");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.format_list_numbered,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Rep Records',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Reps',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Weight',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Rep rows
              ...List.generate(15, (index) {
                final repCount = index + 1;
                final record =
                    repRecords.where((r) => r.reps == repCount).firstOrNull;

                final isEven = index % 2 == 0;
                final hasRecord = record != null;

                return InkWell(
                  onTap: hasRecord && record.workoutId != null
                      ? () async {
                          final workout = await (db.workouts.select()
                                ..where((w) => w.id.equals(record.workoutId!)))
                              .getSingleOrNull();

                          if (workout != null && mounted) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WorkoutDetailPage(workout: workout),
                              ),
                            );
                          }
                        }
                      : null,
                  borderRadius: index == 14
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        )
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isEven
                          ? Colors.transparent
                          : colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                      borderRadius: index == 14
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: hasRecord
                                  ? colorScheme.primary.withOpacity(0.15)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$repCount',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: hasRecord
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            hasRecord
                                ? '${formatter.format(record.weight)} $target'
                                : '-',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasRecord
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: hasRecord
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _formatValue(StrengthData row) {
    final formatter = NumberFormat("#,###.##");
    switch (metric) {
      case StrengthMetric.bestVolume:
        return '${formatter.format(row.value)} vol';
      case StrengthMetric.relativeStrength:
        return '${row.value.toStringAsFixed(2)}x';
      case StrengthMetric.oneRepMax:
      case StrengthMetric.volume:
        return '${formatter.format(row.value)} $target';
      case StrengthMetric.bestWeight:
        return '${row.reps.toInt()}x${formatter.format(row.value)} $target';
    }
  }

  String _formatSetInfo(StrengthData row) {
    final formatter = NumberFormat("#,###.##");
    return '${row.reps.toInt()} × ${formatter.format(row.weight)} $target';
  }

  Widget _buildChart(Setting settings, ColorScheme colorScheme) {
    List<FlSpot> spots = [];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].value));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range > 0 ? range / 4 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox();
                }
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
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: _getBottomInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();

                // Show 4-5 labels spread across the chart
                final totalLabels = 5;
                final step = (data.length / totalLabels).ceil();
                if (index % step != 0 && index != data.length - 1) {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('M/d').format(data[index].created),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            getTooltipItems: (_) => [],
          ),
          touchCallback: (event, response) {
            if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              final spot = response.lineBarSpots!.first;
              setState(() => selectedIndex = spot.spotIndex);
            }
          },
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: colorScheme.primary,
                  strokeWidth: 2,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: colorScheme.primary,
                      strokeWidth: 2,
                      strokeColor: colorScheme.surface,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final isSelected = index == selectedIndex;
                return FlDotCirclePainter(
                  radius: isSelected ? 5 : 3,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.primary.withOpacity(0.7),
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withOpacity(0.3),
                  colorScheme.primary.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getBottomInterval() {
    if (data.length <= 5) return 1;
    return (data.length / 5).ceilToDouble();
  }

  Future<void> _editSet(int index) async {
    if (index >= data.length) return;
    final row = data[index];

    // Use the workout ID directly from the StrengthData
    if (row.workoutId == null) return;

    final workout = await (db.workouts.select()
          ..where((w) => w.id.equals(row.workoutId!)))
        .getSingleOrNull();

    if (!mounted || workout == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailPage(workout: workout),
      ),
    );
    Timer(kThemeAnimationDuration, () {
      setData();
      _loadRecords();
    });
  }

  Future<void> setData() async {
    if (!mounted) return;
    final strengthData = await getStrengthData(
      target: target,
      name: widget.name,
      metric: metric,
      period: period,
    );
    setState(() {
      data = strengthData;
      selectedIndex = null;
    });
  }
}
