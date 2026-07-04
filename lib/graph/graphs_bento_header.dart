import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../main.dart';
import '../records/records_service.dart';
import '../theme/tokens.dart';
import 'graph_tile.dart' show openExerciseGraph;

// Fixed heights so the surrounding list never jumps while data loads.
const _featuredTileHeight = 158.0;
const _gridTileHeight = 152.0;
// Two full-width featured rows + one grid row, with a space12 gap after each
// featured row.
const _placeholderHeight =
    _featuredTileHeight * 2 + space12 * 2 + _gridTileHeight;

// Estimated 1RM (Brzycki), mirrors calculate1RM() in records_service.dart, as
// a SQL expression so per-workout bests can be aggregated in the query. CAST to
// REAL keeps drift from reading an int back for the reps<=0 branch.
const _oneRmSql = 'CAST(CASE '
    'WHEN reps <= 0 THEN 0 '
    'WHEN reps = 1 THEN weight '
    'WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) '
    'ELSE weight * (1.0278 - 0.0278 * reps) END AS REAL)';

/// Bento-grid highlight header for the redesigned Graphs page.
///
/// Self-loading, one-shot on mount (mirrors [HistoryHeatmapHeader]'s
/// pattern): picks the top 4 non-cardio, non-hidden exercises by most
/// sessions trained (not recency). The two highest-session exercises render
/// as full-width featured rows with the ember glow; the other two share a
/// grid row. Headline number is estimated best 1RM. Any exercise with a
/// personal record in the last 7 days gets a gold PR chip in its corner.
class GraphsBentoHeader extends StatefulWidget {
  const GraphsBentoHeader({required this.tabCtrl, super.key});

  final TabController tabCtrl;

  @override
  State<GraphsBentoHeader> createState() => _GraphsBentoHeaderState();
}

class _TileData {
  const _TileData({
    required this.name,
    required this.muscle,
    required this.best1RM,
    required this.unit,
    required this.series,
    required this.sessionCount,
    required this.lastDate,
    this.deltaKg,
    this.prType,
    this.prAt,
  });

  final String name;
  final MuscleGroup muscle;
  final double best1RM;
  final String unit;
  final List<double> series;
  final int sessionCount;
  final DateTime lastDate;
  final double? deltaKg;
  final RecordType? prType;
  final DateTime? prAt;
}

class _GraphsBentoHeaderState extends State<GraphsBentoHeader> {
  List<_TileData> _tiles = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Top 4 non-cardio, non-hidden exercises by total sessions trained.
    final topRows = await db.customSelect(
      '''
      SELECT name, category, COUNT(DISTINCT workout_id) AS session_count
      FROM gym_sets
      WHERE hidden = 0 AND cardio = 0 AND workout_id IS NOT NULL
      GROUP BY name
      ORDER BY session_count DESC
      LIMIT 4
      ''',
    ).get();

    final sevenDaysAgoEpoch = DateTime.now()
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch ~/
        1000;

    final tiles = <_TileData>[];
    for (final row in topRows) {
      final name = row.read<String>('name');
      final category = row.readNullable<String>('category');
      final sessionCount = row.read<int>('session_count');

      // Best estimated 1RM ever for this exercise (and the unit of the set
      // that produced it — unit is per-set, not per-exercise).
      final bestRow = await db.customSelect(
        '''
        SELECT unit, $_oneRmSql AS one_rm FROM gym_sets
        WHERE name = ? AND hidden = 0 AND cardio = 0
        ORDER BY one_rm DESC
        LIMIT 1
        ''',
        variables: [drift.Variable.withString(name)],
      ).getSingleOrNull();
      if (bestRow == null) continue;

      // Per-workout best 1RM over the last ~10 workouts, newest first — used
      // both for the trend delta and (reversed) the sparkline.
      final rawSeriesRows = await db.customSelect(
        '''
        SELECT MAX($_oneRmSql) AS w, MAX(created) AS c
        FROM gym_sets
        WHERE name = ? AND hidden = 0 AND cardio = 0 AND workout_id IS NOT NULL
        GROUP BY workout_id
        ORDER BY c DESC
        LIMIT 10
        ''',
        variables: [drift.Variable.withString(name)],
      ).get();
      if (rawSeriesRows.isEmpty) continue;

      final lastDate = DateTime.fromMillisecondsSinceEpoch(
        rawSeriesRows.first.read<int>('c') * 1000,
      );
      final deltaKg = rawSeriesRows.length >= 2
          ? rawSeriesRows[0].read<double>('w') -
              rawSeriesRows[1].read<double>('w')
          : null;
      final series = rawSeriesRows
          .map((r) => r.read<double>('w'))
          .toList()
          .reversed
          .toList();

      // Fresh-PR detection: walk this exercise's sets from the last 7 days,
      // newest first, and ask records_service whether each one held a
      // record when it was logged. The first hit is the most recent PR.
      RecordType? prType;
      DateTime? prAt;
      final recentSets = await db.customSelect(
        '''
        SELECT id, weight, reps, created FROM gym_sets
        WHERE name = ? AND hidden = 0 AND warmup = 0 AND cardio = 0
          AND created >= ?
        ORDER BY created DESC
        ''',
        variables: [
          drift.Variable.withString(name),
          drift.Variable.withInt(sevenDaysAgoEpoch),
        ],
      ).get();
      for (final setRow in recentSets) {
        final records = await getSetRecords(
          setId: setRow.read<int>('id'),
          exerciseName: name,
          weight: setRow.read<double>('weight'),
          reps: setRow.read<double>('reps'),
        );
        if (records.isNotEmpty) {
          prType = records.contains(RecordType.best1RM)
              ? RecordType.best1RM
              : records.contains(RecordType.bestVolume)
                  ? RecordType.bestVolume
                  : RecordType.bestWeight;
          prAt = DateTime.fromMillisecondsSinceEpoch(
            setRow.read<int>('created') * 1000,
          );
          break;
        }
      }

      tiles.add(
        _TileData(
          name: name,
          muscle: muscleGroupOf(category, name),
          best1RM: bestRow.read<double>('one_rm'),
          unit: bestRow.read<String>('unit'),
          series: series,
          sessionCount: sessionCount,
          lastDate: lastDate,
          deltaKg: deltaKg,
          prType: prType,
          prAt: prAt,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _tiles = tiles;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: _placeholderHeight);
    if (_tiles.length < 2) return const SizedBox.shrink();

    // Already ordered by session count desc from the query — the top 2 are
    // the full-width featured rows, the rest fill the 2-column grid.
    final featured = _tiles.take(2).toList();
    final rest = _tiles.skip(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in featured) ...[
            _BentoTile(data: t, featured: true, tabCtrl: widget.tabCtrl),
            const SizedBox(height: space12),
          ],
          for (var i = 0; i < rest.length; i += 2)
            Padding(
              padding: EdgeInsets.only(
                bottom: i + 2 < rest.length ? space12 : 0,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _BentoTile(
                        data: rest[i],
                        featured: false,
                        tabCtrl: widget.tabCtrl,
                      ),
                    ),
                    const SizedBox(width: space8),
                    Expanded(
                      child: i + 1 < rest.length
                          ? _BentoTile(
                              data: rest[i + 1],
                              featured: false,
                              tabCtrl: widget.tabCtrl,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Color _tintedSurface(ColorScheme cs, Color muscle) =>
    Color.alphaBlend(muscle.withValues(alpha: 0.06), cs.surfaceContainer);

String _formatWeight(double w) {
  if (w == w.roundToDouble()) return w.toInt().toString();
  return w.toStringAsFixed(1);
}

class _MusclePill extends StatelessWidget {
  const _MusclePill({required this.muscle});
  final MuscleGroup muscle;

  @override
  Widget build(BuildContext context) {
    final color = context.jl.muscleColor(muscle);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: brPill,
      ),
      child: Text(
        muscleLabel(muscle).toLowerCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PrChip extends StatelessWidget {
  const _PrChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(radiusMd),
          bottomLeft: Radius.circular(radiusMd),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('★', style: TextStyle(fontSize: 9, color: Colors.black87)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "+5kg  ·  last 2d ago" line under the headline weight. The delta is
/// colored success/danger/neutral; the "last Xd ago" segment is always
/// onSurfaceVariant.
class _DeltaLine extends StatelessWidget {
  const _DeltaLine({required this.data, this.alignEnd = false});
  final _TileData data;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final daysAgo = DateTime.now().difference(data.lastDate).inDays;
    final lastText = daysAgo <= 0 ? 'last today' : 'last ${daysAgo}d ago';

    String? deltaText;
    Color deltaColor = cs.onSurfaceVariant;
    final delta = data.deltaKg;
    if (delta != null) {
      if (delta > 0.05) {
        deltaText = '+${_formatWeight(delta)}${data.unit}';
        deltaColor = context.jl.success;
      } else if (delta < -0.05) {
        deltaText = '-${_formatWeight(delta.abs())}${data.unit}';
        deltaColor = context.jl.danger;
      } else {
        deltaText = 'flat';
      }
    }

    final neutralStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: cs.onSurfaceVariant,
    );

    return Text.rich(
      TextSpan(
        children: [
          if (deltaText != null) ...[
            TextSpan(
              text: deltaText,
              style: neutralStyle.copyWith(color: deltaColor),
            ),
            TextSpan(text: '  ·  ', style: neutralStyle),
          ],
          TextSpan(text: lastText, style: neutralStyle),
        ],
      ),
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.data,
    required this.featured,
    required this.tabCtrl,
  });

  final _TileData data;
  final bool featured;
  final TabController tabCtrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muscleColor = context.jl.muscleColor(data.muscle);

    return Container(
      height: featured ? _featuredTileHeight : _gridTileHeight,
      decoration: BoxDecoration(
        color: _tintedSurface(cs, muscleColor),
        borderRadius: brMd,
      ),
      child: ClipRRect(
        borderRadius: brMd,
        child: Stack(
          children: [
            // Faint ember radial glow, top-right, on the featured rows only —
            // same treatment as HistoryHeatmapHeader's card.
            if (featured)
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openExerciseGraph(
                  context,
                  name: data.name,
                  unit: data.unit,
                  cardio: false,
                  tabCtrl: tabCtrl,
                ),
                child: Padding(
                  padding: EdgeInsets.all(featured ? space16 : space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              data.name,
                              maxLines: featured ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: featured ? 16 : 15,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: space8),
                          _MusclePill(muscle: data.muscle),
                        ],
                      ),
                      SizedBox(height: featured ? space8 : space4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatWeight(data.best1RM),
                            style: (featured
                                    ? text.headlineMedium
                                    : text.headlineSmall)
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: space4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              data.unit,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: space8),
                          // Delta + last-trained sit to the right of the
                          // headline to keep the tile vertically compact.
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: _DeltaLine(data: data, alignEnd: true),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: double.infinity,
                            height: featured ? 42 : 34,
                            child: CustomPaint(
                              painter: _SparklinePainter(
                                series: data.series,
                                color: muscleColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '${data.sessionCount} sessions',
                        style: text.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (data.prType != null)
              Positioned(
                top: 0,
                right: 0,
                child: _PrChip(
                  color: context.jl.pr,
                  label: recordShortLabel(data.prType!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Polyline sparkline with a subtle gradient fill fading toward the bottom.
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.series, required this.color});

  final List<double> series;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2 || size.width <= 0 || size.height <= 0) return;

    final minV = series.reduce(math.min);
    final maxV = series.reduce(math.max);
    final range = maxV - minV;

    final points = <Offset>[
      for (var i = 0; i < series.length; i++)
        Offset(
          size.width * i / (series.length - 1),
          size.height -
              (range == 0 ? 0.5 : (series[i] - minV) / range) * size.height,
        ),
    ];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    final areaPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.color != color;
}
