import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../theme/tokens.dart';

/// Heatmap + streak header for the redesigned History page.
///
/// Self-loading, one-shot on mount. Renders a rounded ember-tinted card with a
/// current-streak counter and a GitHub-style 14-week volume heatmap.
class HistoryHeatmapHeader extends StatefulWidget {
  const HistoryHeatmapHeader({super.key});

  @override
  State<HistoryHeatmapHeader> createState() => _HistoryHeatmapHeaderState();
}

// Grid geometry — 14 weekly columns of 7 day-cells (Sunday-first rows).
const _weeks = 14;
const _cellSize = 14.0;
const _cellGap = 4.0;

class _HistoryHeatmapHeaderState extends State<HistoryHeatmapHeader> {
  // date-only -> summed lifting volume (weight*reps, cardio excluded)
  Map<DateTime, double> _dailyVolume = {};
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    // Window start: Monday of the week 13 weeks before this week.
    final mondayThisWeek = today.subtract(Duration(days: today.weekday - 1));
    final windowStart = mondayThisWeek.subtract(const Duration(days: 13 * 7));
    final startEpoch = windowStart.millisecondsSinceEpoch ~/ 1000;

    // Daily lifting volume across the window.
    final volumeRows = await db.customSelect(
      """
      SELECT DATE(w.start_time, 'unixepoch') AS d,
             SUM(gs.weight * gs.reps) AS vol
      FROM workouts w
      INNER JOIN gym_sets gs ON w.id = gs.workout_id
      WHERE w.start_time >= ?
        AND gs.hidden = 0
        AND gs.cardio = 0
      GROUP BY d
      """,
      variables: [drift.Variable.withInt(startEpoch)],
    ).get();

    final daily = <DateTime, double>{};
    for (final row in volumeRows) {
      final date = DateTime.parse(row.read<String>('d'));
      final vol = row.readNullable<double>('vol') ?? 0;
      daily[DateTime(date.year, date.month, date.day)] = vol;
    }

    final streak = await _calculateStreak();

    if (!mounted) return;
    setState(() {
      _dailyVolume = daily;
      _streak = streak;
      _loading = false;
    });
  }

  // Consecutive days back from today with at least one workout.
  Future<int> _calculateStreak() async {
    final today = DateTime.now();
    var checkDate = DateTime(today.year, today.month, today.day);
    var streak = 0;
    while (true) {
      final row = await db.customSelect(
        'SELECT COUNT(*) AS c FROM workouts '
        "WHERE DATE(start_time, 'unixepoch') = ?",
        variables: [
          drift.Variable.withString(DateFormat('yyyy-MM-dd').format(checkDate)),
        ],
      ).getSingle();
      if (row.read<int>('c') > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // Ember ramp: empty -> surfaceContainerHighest; then primary at escalating
  // alpha by daily lifting volume. Mirrors overview_page _getHeatmapColor.
  Color _rampColor(ColorScheme cs, double volume) {
    if (volume <= 0) return cs.surfaceContainerHighest;
    if (volume < 2000) return cs.primary.withValues(alpha: 0.2);
    if (volume < 5000) return cs.primary.withValues(alpha: 0.4);
    if (volume < 9000) return cs.primary.withValues(alpha: 0.6);
    return cs.primary.withValues(alpha: 0.8);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(space16, 0, space16, 0),
      decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: brMd),
      child: ClipRRect(
        borderRadius: brMd,
        child: Stack(
          children: [
            // Faint ember radial glow in the top-right corner.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [
                      cs.primary.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.55],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHead(cs, text),
                  const SizedBox(height: space12),
                  _buildGrid(cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHead(ColorScheme cs, TextTheme text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Streak block.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_streak',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 0.9,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: space8),
            Padding(
              padding: const EdgeInsets.only(top: space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'day streak',
                    style: text.labelMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'keep it burning',
                    style: text.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Legend: Less [ramp] More.
        Row(
          children: [
            Text(
              'Less',
              style: text.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: space4),
            for (final v in const [0.0, 1000.0, 3000.0, 7000.0, 12000.0])
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: _rampColor(cs, v),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            const SizedBox(width: space4),
            Text(
              'More',
              style: text.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrid(ColorScheme cs) {
    final today = DateUtils.dateOnly(DateTime.now());
    // Sunday-first row index of today (Sun=0 .. Sat=6).
    final todayRow = today.weekday % 7;
    const labels = ['', 'M', '', 'W', '', 'F', ''];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekday label column (M/W/F), aligned to cell rows.
        Column(
          children: [
            for (var d = 0; d < 7; d++)
              Container(
                width: 12,
                height: _cellSize,
                margin: EdgeInsets.only(bottom: d == 6 ? 0 : _cellGap),
                alignment: Alignment.centerLeft,
                child: Text(
                  labels[d],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: space8),
        // Weekly columns.
        for (var w = 0; w < _weeks; w++)
          Padding(
            padding: EdgeInsets.only(right: w == _weeks - 1 ? 0 : _cellGap),
            child: Column(
              children: [
                for (var d = 0; d < 7; d++)
                  _buildCell(cs, w, d, todayRow, today),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCell(
    ColorScheme cs,
    int w,
    int d,
    int todayRow,
    DateTime today,
  ) {
    // Today sits at the bottom-right; daysAgo 0 there. Future cells are blank.
    final daysAgo = (_weeks - 1 - w) * 7 + (todayRow - d);
    final margin = EdgeInsets.only(bottom: d == 6 ? 0 : _cellGap);

    if (daysAgo < 0) {
      return Container(
        width: _cellSize,
        height: _cellSize,
        margin: margin,
      );
    }

    final date = today.subtract(Duration(days: daysAgo));
    final volume = _loading ? 0.0 : (_dailyVolume[date] ?? 0);
    final isToday = daysAgo == 0;

    return Container(
      width: _cellSize,
      height: _cellSize,
      margin: margin,
      decoration: BoxDecoration(
        color: _rampColor(cs, volume),
        borderRadius: BorderRadius.circular(3),
        border: isToday ? Border.all(color: cs.onSurface, width: 2) : null,
      ),
    );
  }

}
