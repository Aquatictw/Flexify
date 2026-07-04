import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../main.dart';
import '../records/records_service.dart';
import '../theme/tokens.dart';
import '../utils.dart' as utils;
import 'graph_tile.dart';

/// A single "PR achieved" event, ready for display in the ticker.
class _PrEvent {
  const _PrEvent({
    required this.type,
    required this.exerciseName,
    required this.value,
    required this.unit,
    required this.created,
  });
  final RecordType type;
  final String exerciseName;
  final double value;
  final String unit;
  final DateTime created;
}

/// Horizontally-scrolling strip of recent personal records (last 30 days).
///
/// Self-loading, one-shot on mount. Reuses [getSetRecords] from
/// `records_service.dart` for the actual PR math instead of reimplementing it.
class RecentPrTicker extends StatefulWidget {
  const RecentPrTicker({required this.tabCtrl, super.key});
  final TabController tabCtrl;

  @override
  State<RecentPrTicker> createState() => _RecentPrTickerState();
}

const _lookbackDays = 30;
const _maxEvents = 10;

class _RecentPrTickerState extends State<RecentPrTicker> {
  List<_PrEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cutoff = DateTime.now().subtract(const Duration(days: _lookbackDays));

    final recentSets = await (db.gymSets.select()
          ..where(
            (s) =>
                s.created.isBiggerOrEqualValue(cutoff) &
                s.hidden.equals(false) &
                s.warmup.equals(false) &
                s.cardio.equals(false),
          )
          ..orderBy([(s) => OrderingTerm.desc(s.created)]))
        .get();

    final events = <_PrEvent>[];
    for (final set in recentSets) {
      if (events.length >= _maxEvents) break;

      final records = await getSetRecords(
        setId: set.id,
        exerciseName: set.name,
        weight: set.weight,
        reps: set.reps,
      );
      if (records.isEmpty) continue;

      for (final type in records) {
        final value = switch (type) {
          RecordType.bestWeight => set.weight,
          RecordType.best1RM => calculate1RM(set.weight, set.reps),
          RecordType.bestVolume => calculateVolume(set.weight, set.reps),
        };
        events.add(
          _PrEvent(
            type: type,
            exerciseName: set.name,
            value: value,
            unit: set.unit,
            created: set.created,
          ),
        );
      }
    }

    events.sort((a, b) => b.created.compareTo(a.created));
    final capped = events.take(_maxEvents).toList();

    if (!mounted) return;
    setState(() {
      _events = capped;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 76);
    }
    if (_events.isEmpty) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: space16),
          child: Text(
            'Recent PRs',
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: space12),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: space16),
            itemCount: _events.length,
            separatorBuilder: (context, index) => const SizedBox(width: space8),
            itemBuilder: (context, index) => _PrChip(
              event: _events[index],
              cs: cs,
              text: text,
              tabCtrl: widget.tabCtrl,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrChip extends StatelessWidget {
  const _PrChip({
    required this.event,
    required this.cs,
    required this.text,
    required this.tabCtrl,
  });
  final _PrEvent event;
  final ColorScheme cs;
  final TextTheme text;
  final TabController tabCtrl;

  String get _badgeLabel => switch (event.type) {
        RecordType.best1RM => '1RM',
        RecordType.bestVolume => 'VOL',
        RecordType.bestWeight => 'WT',
      };

  @override
  Widget build(BuildContext context) {
    final pr = context.jl.pr;

    return Material(
      color: cs.surfaceContainer,
      borderRadius: brMd,
      child: InkWell(
        borderRadius: brMd,
        onTap: () => openExerciseGraph(
          context,
          name: event.exerciseName,
          unit: event.unit,
          cardio: false,
          tabCtrl: tabCtrl,
        ),
        child: Container(
          padding: const EdgeInsets.all(space12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: pr.withValues(alpha: 0.15),
                  borderRadius: brSm,
                ),
                child: Text(
                  _badgeLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                    color: pr,
                  ),
                ),
              ),
              const SizedBox(width: space8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.exerciseName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${utils.toString(event.value)} ${event.unit} · '
                    '${timeago.format(event.created)}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
