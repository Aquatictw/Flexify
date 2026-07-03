import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../main.dart';
import '../settings/settings_state.dart';
import '../theme/components.dart';
import '../theme/tokens.dart';
import '../utils/bodyweight_calculations.dart';
import '../widgets/bodyweight_entry_dialog.dart';
import '../widgets/bodyweight_entry_tile.dart';

enum BodyweightPeriod { week, month, months3, months6, year, allTime }

class BodyweightOverviewPage extends StatefulWidget {
  const BodyweightOverviewPage({super.key});

  @override
  _BodyweightOverviewPageState createState() => _BodyweightOverviewPageState();
}

class _BodyweightOverviewPageState extends State<BodyweightOverviewPage> {
  BodyweightPeriod period = BodyweightPeriod.month;
  bool show14DayMA = false;
  bool show7DayMA = false;
  bool show3DayMA = false;

  List<BodyweightEntry> periodEntries = [];
  bool isLoading = true;

  // Calculated stats
  double? currentWeight;
  double? averageWeight;
  double? minWeight;
  double? maxWeight;
  double? periodChange;
  int entryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final now = DateTime.now();
    final startDate = _getStartDate(now);

    // Load entries for period
    final entries = await (db.bodyweightEntries.select()
          ..where((e) => e.date.isBiggerOrEqualValue(startDate))
          ..orderBy([
            (e) => drift.OrderingTerm(
                  expression: e.date,
                ),
          ]))
        .get();

    // Calculate stats
    final current = entries.isNotEmpty ? entries.last.weight : null;
    final average = calculateAverageWeight(entries);
    final min = calculateMinWeight(entries);
    final max = calculateMaxWeight(entries);
    final change = calculateWeightChange(entries);
    final count = entries.length;

    if (mounted) {
      setState(() {
        periodEntries = entries;
        currentWeight = current;
        averageWeight = average;
        minWeight = min;
        maxWeight = max;
        periodChange = change;
        entryCount = count;
        isLoading = false;
      });
    }
  }

  DateTime _getStartDate(DateTime now) {
    switch (period) {
      case BodyweightPeriod.week:
        return now.subtract(const Duration(days: 7));
      case BodyweightPeriod.month:
        return DateTime(now.year, now.month - 1, now.day);
      case BodyweightPeriod.months3:
        return DateTime(now.year, now.month - 3, now.day);
      case BodyweightPeriod.months6:
        return DateTime(now.year, now.month - 6, now.day);
      case BodyweightPeriod.year:
        return DateTime(now.year - 1, now.month, now.day);
      case BodyweightPeriod.allTime:
        return DateTime(1970);
    }
  }

  String _getPeriodLabel(BodyweightPeriod p) {
    switch (p) {
      case BodyweightPeriod.week:
        return '7D';
      case BodyweightPeriod.month:
        return '1M';
      case BodyweightPeriod.months3:
        return '3M';
      case BodyweightPeriod.months6:
        return '6M';
      case BodyweightPeriod.year:
        return '1Y';
      case BodyweightPeriod.allTime:
        return 'All';
    }
  }

  Future<void> _addEntry() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const BodyweightEntryDialog(),
    );
    if (result ?? false) {
      _loadData();
    }
  }

  Future<void> _editEntry(BodyweightEntry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BodyweightEntryDialog(entry: entry),
    );
    if (result ?? false) {
      _loadData();
    }
  }

  Future<void> _deleteEntry(BodyweightEntry entry) async {
    await db.bodyweightEntries.deleteWhere((tbl) => tbl.id.equals(entry.id));
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bodyweight Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Moving Averages',
            onPressed: () => _showInfoDialog(colorScheme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('Log Weight'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                space16,
                space16,
                space16,
                space32 * 3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  _buildPeriodSelector(),
                  const SizedBox(height: space24),

                  // Stats cards grid
                  _buildStatsGrid(colorScheme),
                  const SizedBox(height: space24),

                  // Main chart with bodyweight + moving averages
                  _buildBodyweightChart(colorScheme),

                  // Chart legend (directly under chart)
                  if (periodEntries.isNotEmpty) const SizedBox(height: space12),
                  if (periodEntries.isNotEmpty) _buildChartLegend(colorScheme),
                  const SizedBox(height: space16),

                  // Moving average toggles (compact)
                  if (periodEntries.isNotEmpty)
                    _buildMovingAverageToggles(colorScheme),
                  if (periodEntries.isNotEmpty) const SizedBox(height: space24),

                  // Entry history list (period-filtered)
                  _buildEntryHistorySection(colorScheme),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: BodyweightPeriod.values.map((p) {
          final isSelected = period == p;
          return Padding(
            padding: const EdgeInsets.only(right: space8),
            child: FilterPill(
              label: _getPeriodLabel(p),
              selected: isSelected,
              onTap: () {
                setState(() => period = p);
                _loadData();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid(ColorScheme colorScheme) {
    final settings = context.watch<SettingsState>().value;
    final unit = settings.strengthUnit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: colorScheme.primary, size: 20),
            const SizedBox(width: space8),
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: space12),

        // Row 1: Current + Average
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                colorScheme: colorScheme,
                icon: Icons.monitor_weight_outlined,
                label: 'Current',
                value: currentWeight != null
                    ? '${currentWeight!.toStringAsFixed(1)} $unit'
                    : 'N/A',
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: space12),
            Expanded(
              child: _buildStatCard(
                colorScheme: colorScheme,
                icon: Icons.equalizer,
                label: 'Average',
                value: averageWeight != null
                    ? '${averageWeight!.toStringAsFixed(1)} $unit'
                    : 'N/A',
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: space12),

        // Row 2: Change + Entry Count
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                colorScheme: colorScheme,
                icon: _getChangeIcon(periodChange),
                label: 'Change',
                value: _formatChange(periodChange, unit),
                color: _getChangeColor(periodChange, colorScheme),
              ),
            ),
            const SizedBox(width: space12),
            Expanded(
              child: _buildStatCard(
                colorScheme: colorScheme,
                icon: Icons.format_list_numbered,
                label: 'Entries',
                value: '$entryCount',
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
      padding: const EdgeInsets.all(space16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: brMd,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: space8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: space8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getChangeIcon(double? change) {
    if (change == null) return Icons.trending_flat;
    if (change > 0.1) return Icons.trending_up;
    if (change < -0.1) return Icons.trending_down;
    return Icons.trending_flat;
  }

  Color _getChangeColor(double? change, ColorScheme colorScheme) {
    if (change == null) return colorScheme.onSurfaceVariant;
    if (change > 0.1) return context.jl.success;
    if (change < -0.1) return context.jl.danger;
    return colorScheme.onSurfaceVariant;
  }

  String _formatChange(double? change, String unit) {
    if (change == null) return 'No change';
    if (change > 0.1) return '+${change.toStringAsFixed(1)} $unit';
    if (change < -0.1) return '${change.toStringAsFixed(1)} $unit';
    return 'No change';
  }

  Widget _buildBodyweightChart(ColorScheme colorScheme) {
    final settings = context.watch<SettingsState>().value;
    final unit = settings.strengthUnit;

    if (periodEntries.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow.withValues(alpha: 0.3),
          borderRadius: brMd,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: space16),
            Text(
              'No bodyweight data for this period',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: space8),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add),
              label: const Text('Log Your First Entry'),
              onPressed: _addEntry,
            ),
          ],
        ),
      );
    }

    // Prepare main bodyweight line
    final mainSpots = periodEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    // Calculate Y-axis range
    final weights = periodEntries.map((e) => e.weight).toList();
    final minY = weights.reduce((a, b) => a < b ? a : b);
    final maxY = weights.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final yMin = range > 0 ? (minY - range * 0.1).floorToDouble() : minY - 1;
    final yMax = range > 0 ? (maxY + range * 0.1).ceilToDouble() : maxY + 1;

    // Build line bars data
    final List<LineChartBarData> lineBars = [
      // Main bodyweight line
      LineChartBarData(
        spots: mainSpots,
        isCurved: true,
        color: colorScheme.primary,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: colorScheme.primary,
              strokeWidth: 2,
              strokeColor: colorScheme.surface,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
    ];

    // Add moving averages if toggled
    if (show14DayMA) {
      final ma14 = calculateMovingAverage(periodEntries, 14);
      if (ma14.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: ma14,
            isCurved: true,
            color: colorScheme.secondary,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(),
          ),
        );
      }
    }

    if (show7DayMA) {
      final ma7 = calculateMovingAverage(periodEntries, 7);
      if (ma7.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: ma7,
            isCurved: true,
            color: colorScheme.tertiary,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(),
          ),
        );
      }
    }

    if (show3DayMA) {
      final ma3 = calculateMovingAverage(periodEntries, 3);
      if (ma3.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: ma3,
            isCurved: true,
            color: context.jl.pr,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.show_chart, color: colorScheme.primary, size: 20),
            const SizedBox(width: space8),
            Text(
              'Bodyweight Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: space16),
        Container(
          padding: const EdgeInsets.all(space16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: brMd,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minY: yMin,
                maxY: yMax,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: range > 10 ? 5 : (range > 5 ? 2 : 1),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: range > 10 ? 5 : (range > 5 ? 2 : 1),
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${value.toStringAsFixed(0)} $unit',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (periodEntries.length / 5).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= periodEntries.length) {
                          return const SizedBox.shrink();
                        }
                        final date = periodEntries[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('MMM d').format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (periodEntries.length - 1).toDouble(),
                lineBarsData: lineBars,
                lineTouchData: LineTouchData(
                  touchSpotThreshold: 30,
                  getTouchedSpotIndicator:
                      (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: colorScheme.primary,
                              strokeWidth: 3,
                              strokeColor: colorScheme.surface,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        colorScheme.surfaceContainerHighest,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= periodEntries.length) {
                          return null;
                        }
                        final entry = periodEntries[index];
                        return LineTooltipItem(
                          '${entry.weight.toStringAsFixed(1)} $unit\n${DateFormat('MMM d, yyyy').format(entry.date)}',
                          TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              duration: durMed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMovingAverageToggles(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune, color: colorScheme.primary, size: 16),
            const SizedBox(width: 6),
            Text(
              'Moving Averages',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 14-day MA toggle
        _buildToggleTile(
          colorScheme: colorScheme,
          label: '14-Day',
          color: colorScheme.secondary,
          value: show14DayMA,
          onChanged: (val) => setState(() => show14DayMA = val),
          enabled: periodEntries.isNotEmpty,
          daysNeeded: 14,
        ),

        // 7-day MA toggle
        _buildToggleTile(
          colorScheme: colorScheme,
          label: '7-Day',
          color: colorScheme.tertiary,
          value: show7DayMA,
          onChanged: (val) => setState(() => show7DayMA = val),
          enabled: periodEntries.isNotEmpty,
          daysNeeded: 7,
        ),

        // 3-day MA toggle
        _buildToggleTile(
          colorScheme: colorScheme,
          label: '3-Day',
          color: context.jl.pr,
          value: show3DayMA,
          onChanged: (val) => setState(() => show3DayMA = val),
          enabled: periodEntries.isNotEmpty,
          daysNeeded: 3,
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required ColorScheme colorScheme,
    required String label,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool enabled,
    required int daysNeeded,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: brPill,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (!enabled)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '(No data)',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(ColorScheme colorScheme) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem('Bodyweight', colorScheme.primary, solid: true),
        if (show14DayMA) _buildLegendItem('14-Day MA', colorScheme.secondary),
        if (show7DayMA) _buildLegendItem('7-Day MA', colorScheme.tertiary),
        if (show3DayMA) _buildLegendItem('3-Day MA', context.jl.pr),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool solid = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: brPill,
          ),
          child: solid
              ? null
              : CustomPaint(
                  painter: _DashedLinePainter(color: color),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildEntryHistorySection(ColorScheme colorScheme) {
    if (periodEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Entry History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Timeline list (period-filtered, reversed for newest first)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: periodEntries.length,
          itemBuilder: (context, index) {
            // Reverse the order to show newest first
            final reversedIndex = periodEntries.length - 1 - index;
            final entry = periodEntries[reversedIndex];
            return BodyweightEntryTile(
              entry: entry,
              isLast: index == periodEntries.length - 1,
              onEdit: () => _editEntry(entry),
              onDelete: () => _deleteEntry(entry),
            );
          },
        ),
      ],
    );
  }

  void _showInfoDialog(ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Moving Averages'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moving averages help smooth out daily fluctuations in your bodyweight to reveal overall trends.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '• 3-Day Average: Shows short-term trends',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                '• 7-Day Average: Best for weekly patterns',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                '• 14-Day Average: Reveals long-term direction',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                'Tip: Use moving averages to track progress without worrying about daily weight fluctuations from water retention, food intake, or time of day.',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for drawing dashed lines in the legend
class _DashedLinePainter extends CustomPainter {

  _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const dashWidth = 3;
    const dashSpace = 2;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
