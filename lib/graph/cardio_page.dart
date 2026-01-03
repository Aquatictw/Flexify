import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flexify/constants.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/database/gym_sets.dart';
import 'package:flexify/graph/cardio_data.dart';
import 'package:flexify/graph/edit_graph_page.dart';
import 'package:flexify/graph/graph_history_page.dart';
import 'package:flexify/main.dart';
import 'package:flexify/workouts/workout_detail_page.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CardioPage extends StatefulWidget {
  final String name;
  final String unit;
  final List<CardioData> data;
  final TabController? tabCtrl;

  const CardioPage({
    super.key,
    required this.name,
    required this.unit,
    required this.data,
    this.tabCtrl,
  });

  @override
  createState() => _CardioPageState();
}

class _CardioPageState extends State<CardioPage> {
  late List<CardioData> data = widget.data;
  late String target = widget.unit;

  CardioMetric metric = CardioMetric.pace;
  Period period = Period.months3;
  DateTime lastTap = DateTime(0);
  int? selectedIndex;
  String? brandName;

  @override
  void initState() {
    super.initState();
    widget.tabCtrl?.addListener(_onTabChanged);
    setData();
    _loadBrandName();
  }

  @override
  void dispose() {
    widget.tabCtrl?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (widget.tabCtrl == null) return;
    final settings = context.read<SettingsState>().value;
    if (widget.tabCtrl!.index == settings.tabs.indexOf('GraphsPage')) {
      setData();
    }
  }

  Future<void> _loadBrandName() async {
    final result = await (db.gymSets.select()
          ..where((tbl) => tbl.name.equals(widget.name))
          ..orderBy([
            (u) => drift.OrderingTerm(expression: u.created, mode: drift.OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (mounted) {
      setState(() {
        brandName = result?.brandName;
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

  String _getMetricLabel(CardioMetric m) {
    switch (m) {
      case CardioMetric.pace:
        return 'Pace';
      case CardioMetric.distance:
        return 'Distance';
      case CardioMetric.duration:
        return 'Duration';
      case CardioMetric.incline:
        return 'Incline';
      case CardioMetric.inclineAdjustedPace:
        return 'Adj. Pace';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>().value;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(widget.name),
            ),
            if (brandName != null && brandName!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  brandName!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
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
                    ..where((tbl) => tbl.name.equals(widget.name))
                    ..where((tbl) => tbl.hidden.equals(false))
                    ..limit(20))
                  .get();
              if (!context.mounted) return;

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GraphHistoryPage(
                    name: widget.name,
                    gymSets: gymSets,
                  ),
                ),
              );
              Timer(kThemeAnimationDuration, setData);
            },
            icon: const Icon(Icons.history),
            tooltip: "History",
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditGraphPage(name: widget.name),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            tooltip: "Edit",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getPeriodLabel(p)),
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
            const SizedBox(height: 12),

            // Metric selector chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CardioMetric.values.map((m) {
                  final isSelected = metric == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getMetricLabel(m)),
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

            const SizedBox(height: 16),

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
                        // Selected value overlay (top left, ignores pointer)
                        if (selectedIndex != null && selectedIndex! < data.length)
                          Positioned(
                            top: 8,
                            left: 56,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
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
                                    Text(
                                      DateFormat(settings.shortDateFormat)
                                          .format(data[selectedIndex!].created),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
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
          ],
        ),
      ),
    );
  }

  String _formatValue(CardioData row) {
    switch (metric) {
      case CardioMetric.pace:
        return '${row.value.toStringAsFixed(2)} ${row.unit}/min';
      case CardioMetric.duration:
        final minutes = row.value.floor();
        final seconds = ((row.value * 60) % 60).floor().toString().padLeft(2, '0');
        return '$minutes:$seconds';
      case CardioMetric.distance:
        return '${row.value.toStringAsFixed(2)} ${row.unit}';
      case CardioMetric.incline:
        return '${row.value.toStringAsFixed(1)}%';
      case CardioMetric.inclineAdjustedPace:
        return '${row.value.toStringAsFixed(2)} adj';
    }
  }

  Widget _buildChart(Setting settings, ColorScheme colorScheme) {
    List<FlSpot> spots = [];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].value));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range > 0 ? range * 0.1 : 1;

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range > 0 ? range / 4 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox();
                }
                return Text(
                  NumberFormat.compact().format(value),
                  style: TextStyle(
                    fontSize: 11,
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

              // Handle double tap to edit
              if (event is FlTapUpEvent) {
                if (DateTime.now().difference(lastTap) <
                    const Duration(milliseconds: 300)) {
                  _editSet(spot.spotIndex);
                }
                lastTap = DateTime.now();
              }
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
                  color: isSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.7),
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
                  colorScheme.primary.withValues(alpha: 0.3),
                  colorScheme.primary.withValues(alpha: 0.05),
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

    GymSet? gymSet = await (db.gymSets.select()
          ..where(
            (tbl) =>
                tbl.created.equals(row.created) & tbl.name.equals(widget.name),
          )
          ..limit(1))
        .getSingleOrNull();

    if (!mounted || gymSet == null || gymSet.workoutId == null) return;

    final workout = await (db.workouts.select()
          ..where((w) => w.id.equals(gymSet!.workoutId!)))
        .getSingleOrNull();

    if (!mounted || workout == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailPage(workout: workout),
      ),
    );
    Timer(kThemeAnimationDuration, setData);
  }

  void setData() async {
    final cardio = await getCardioData(
      period: period,
      metric: metric,
      name: widget.name,
      target: target,
    );

    if (!mounted) return;
    setState(() {
      data = cardio;
      selectedIndex = null;
    });
  }
}
