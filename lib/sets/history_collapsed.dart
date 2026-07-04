import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../utils.dart';
import '../utils/duration_format.dart';
import '../widgets/depth_ember_reveal.dart';
import 'edit_set_page.dart';
import 'history_page.dart';

class HistoryCollapsed extends StatefulWidget {
  const HistoryCollapsed({
    required this.days,
    required this.onSelect,
    required this.selected,
    required this.onNext,
    required this.scroll,
    super.key,
  });
  final List<HistoryDay> days;
  final ScrollController scroll;
  final Function(int) onSelect;
  final Set<int> selected;
  final Function onNext;

  @override
  State<HistoryCollapsed> createState() => _HistoryCollapsedState();
}

class _HistoryCollapsedState extends State<HistoryCollapsed> {
  bool goingNext = false;

  @override
  Widget build(BuildContext context) {
    final showImages = context
        .select<SettingsState, bool>((settings) => settings.value.showImages);

    return ListView.builder(
      itemCount: widget.days.length,
      padding:
          EdgeInsets.only(bottom: bottomBarClearance(context), top: space8),
      controller: widget.scroll,
      itemBuilder: (context, index) {
        final history = widget.days[index];
        final prev = index > 0 ? widget.days[index - 1] : null;

        final bool showDivider =
            prev != null && !isSameDay(history.day, prev.day);

        return RevealBlock(
          index: index,
          child: Column(
            children: historyChildren(
              showDivider,
              prev,
              history,
              context,
              showImages,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    widget.scroll.removeListener(scrollListener);
  }

  List<Widget> historyChildren(
    bool showDivider,
    HistoryDay? prev,
    HistoryDay history,
    BuildContext context,
    bool showImages,
  ) {
    return [
      if (showDivider)
        Row(
          children: [
            const Expanded(child: Divider()),
            const Icon(Icons.today),
            const SizedBox(width: space4),
            Selector<SettingsState, String>(
              selector: (context, settings) => settings.value.shortDateFormat,
              builder: (context, value, child) => Text(
                DateFormat(value).format(prev!.day),
              ),
            ),
            const SizedBox(width: space4),
            const Expanded(child: Divider()),
          ],
        ),
      ExpansionTile(
        title: Text('${history.name} (${history.gymSets.length})'),
        shape: const Border.symmetric(),
        children: history.gymSets.map(
          (gymSet) {
            final duration = formatDurationMinutes(gymSet.duration);
            final distance = toString(gymSet.distance);
            final reps = toString(gymSet.reps);
            final weight = toString(gymSet.weight);
            String incline = '';
            if (gymSet.incline != null && gymSet.incline! > 0)
              incline = '@ ${gymSet.incline}%';

            Widget? leading = SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: widget.selected.contains(gymSet.id),
                onChanged: (value) {
                  widget.onSelect(gymSet.id);
                },
              ),
            );

            if (widget.selected.isEmpty && showImages && gymSet.image != null) {
              leading = GestureDetector(
                onTap: () => widget.onSelect(gymSet.id),
                child: Image.file(
                  File(gymSet.image!),
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              );
            } else if (widget.selected.isEmpty) {
              final colorScheme = Theme.of(context).colorScheme;
              leading = GestureDetector(
                onTap: () => widget.onSelect(gymSet.id),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: brSm,
                  ),
                  child: Center(
                    child: Text(
                      gymSet.name.isNotEmpty
                          ? gymSet.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              );
            }

            leading = AnimatedSwitcher(
              duration: durFast,
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: leading,
            );

            final isWarmup = gymSet.warmup;
            final isDropSet = gymSet.dropSet;
            final colorScheme = Theme.of(context).colorScheme;

            return ListTile(
              leading: leading,
              title: Row(
                children: [
                  if (isWarmup) ...[
                    Container(
                      padding: const EdgeInsets.all(space4),
                      margin: const EdgeInsets.only(right: space8),
                      decoration: BoxDecoration(
                        color: context.jl.warmup.withValues(alpha: 0.2),
                        borderRadius: brSm,
                      ),
                      child: Icon(
                        Icons.whatshot,
                        size: 12,
                        color: context.jl.warmup,
                      ),
                    ),
                  ],
                  if (isDropSet) ...[
                    Container(
                      padding: const EdgeInsets.all(space4),
                      margin: const EdgeInsets.only(right: space8),
                      decoration: BoxDecoration(
                        color: context.jl.dropSet.withValues(alpha: 0.2),
                        borderRadius: brSm,
                      ),
                      child: Icon(
                        Icons.trending_down,
                        size: 12,
                        color: context.jl.dropSet,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      gymSet.cardio
                          ? '$distance ${gymSet.unit} / $duration $incline'
                          : '$weight ${gymSet.unit} x $reps',
                      style: (isWarmup || isDropSet)
                          ? TextStyle(color: colorScheme.onSurfaceVariant)
                          : null,
                    ),
                  ),
                ],
              ),
              selected: widget.selected.contains(gymSet.id),
              subtitle: Selector<SettingsState, String>(
                selector: (context, settings) => settings.value.longDateFormat,
                builder: (context, dateFormat, child) => Text(
                  dateFormat == 'timeago'
                      ? timeago.format(gymSet.created)
                      : DateFormat(dateFormat).format(gymSet.created),
                ),
              ),
              onLongPress: () {
                widget.onSelect(gymSet.id);
              },
              onTap: () {
                if (widget.selected.isNotEmpty)
                  widget.onSelect(gymSet.id);
                else
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditSetPage(gymSet: gymSet),
                    ),
                  );
              },
            );
          },
        ).toList(),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(scrollListener);
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
}
