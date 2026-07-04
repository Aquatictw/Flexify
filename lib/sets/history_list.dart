import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../database/database.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../utils.dart';
import '../utils/duration_format.dart';
import '../widgets/depth_ember_reveal.dart';
import 'edit_set_page.dart';

class HistoryList extends StatefulWidget {
  const HistoryList({
    required this.sets,
    required this.onSelect,
    required this.selected,
    required this.onNext,
    required this.scroll,
    super.key,
  });
  final List<GymSet> sets;
  final ScrollController scroll;
  final Function(int) onSelect;
  final Set<int> selected;
  final Function onNext;

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  bool goingNext = false;
  final GlobalKey<AnimatedListState> _key = GlobalKey<AnimatedListState>();
  List<GymSet> _current = [];

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(scrollListener);
    _current = List.from(widget.sets);
  }

  @override
  void didUpdateWidget(HistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final toRemove = _current
        .where(
          (oldSet) => !widget.sets.contains(oldSet),
        )
        .toList();

    for (final setToRemove in toRemove) {
      final index = _current.indexOf(setToRemove);
      if (index != -1) {
        final removedSet = _current.removeAt(index);
        _key.currentState?.removeItem(
          index,
          (context, animation) => _buildItem(
            removedSet,
            animation,
            index,
            context.read<SettingsState>().value.showImages,
          ),
        );
      }
    }

    final toAdd = widget.sets
        .where(
          (newSet) => !_current.contains(newSet),
        )
        .toList();

    for (final setToAdd in toAdd) {
      final insertIndex = widget.sets.indexOf(setToAdd);
      if (insertIndex >= 0 && insertIndex <= _current.length) {
        _current.insert(insertIndex, setToAdd);
        _key.currentState?.insertItem(insertIndex, duration: Duration.zero);
      }
    }
  }

  Widget _buildItem(
    GymSet gymSet,
    Animation<double> animation,
    int index,
    bool showImages,
  ) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).chain(CurveTween(curve: curveStandard)).animate(animation);

    final sizeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).chain(CurveTween(curve: curveStandard)).animate(animation);

    return SizeTransition(
      sizeFactor: sizeAnimation,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: offsetAnimation,
          child: _buildListItem(gymSet, index, showImages),
        ),
      ),
    );
  }

  Widget _buildListItem(GymSet gymSet, int index, bool showImages) {
    final previousGymSet =
        index > 0 ? _current.elementAtOrNull(index - 1) : null;
    final bool showDivider = previousGymSet != null &&
        !isSameDay(gymSet.created, previousGymSet.created);

    final duration = formatDurationMinutes(gymSet.duration);
    final distance = toString(gymSet.distance);
    final reps = toString(gymSet.reps);
    final weight = toString(gymSet.weight);
    String incline = '';
    if (gymSet.incline != null && gymSet.incline! > 0) {
      incline = '@ ${gymSet.incline}%';
    }

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
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
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
              gymSet.name.isNotEmpty ? gymSet.name[0].toUpperCase() : '?',
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

    String trailing = '$weight ${gymSet.unit} x $reps';
    if (gymSet.cardio &&
        (gymSet.unit == 'kg' || gymSet.unit == 'lb' || gymSet.unit == 'stone'))
      trailing = '$weight ${gymSet.unit} / $duration $incline';
    else if (gymSet.cardio &&
        (gymSet.unit == 'km' || gymSet.unit == 'mi' || gymSet.unit == 'kcal'))
      trailing = '$distance ${gymSet.unit} / $duration $incline';

    return RevealBlock(
      index: index,
      child: Column(
        children: [
          if (showDivider)
            Row(
              children: [
                const Expanded(child: Divider()),
                const Icon(Icons.today),
                const SizedBox(width: space4),
                Selector<SettingsState, String>(
                  selector: (context, settings) =>
                      settings.value.shortDateFormat,
                  builder: (context, value, child) => Text(
                    DateFormat(value).format(previousGymSet.created),
                  ),
                ),
                const SizedBox(width: space4),
                const Expanded(child: Divider()),
              ],
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: space8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: brSm,
              color: widget.selected.contains(gymSet.id)
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: .08)
                  : Colors.transparent,
              border: Border.all(
                color: widget.selected.contains(gymSet.id)
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: ListTile(
              leading: leading,
              title: Row(
                children: [
                  Text(gymSet.name),
                  if (gymSet.warmup) ...[
                    const SizedBox(width: space8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: space8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.jl.warmup.withValues(alpha: 0.16),
                        borderRadius: brSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.whatshot_outlined,
                            size: 10,
                            color: context.jl.warmup,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Warmup',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: context.jl.warmup,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (gymSet.dropSet) ...[
                    const SizedBox(width: space8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: space8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.jl.dropSet.withValues(alpha: 0.16),
                        borderRadius: brSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_down,
                            size: 10,
                            color: context.jl.dropSet,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Drop',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: context.jl.dropSet,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (gymSet.brandName != null &&
                      gymSet.brandName!.isNotEmpty) ...[
                    const SizedBox(width: space8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: space8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.7),
                        borderRadius: brSm,
                      ),
                      child: Text(
                        gymSet.brandName!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Selector<SettingsState, String>(
                selector: (context, settings) => settings.value.longDateFormat,
                builder: (context, dateFormat, child) => Text(
                  dateFormat == 'timeago'
                      ? timeago.format(gymSet.created)
                      : DateFormat(dateFormat).format(gymSet.created),
                ),
              ),
              trailing: Text(
                trailing,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontSize: 16),
              ),
              onLongPress: () => widget.onSelect(gymSet.id),
              onTap: () {
                if (widget.selected.isNotEmpty) {
                  widget.onSelect(gymSet.id);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditSetPage(gymSet: gymSet),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showImages = context
        .select<SettingsState, bool>((settings) => settings.value.showImages);

    return AnimatedList(
      key: _key,
      initialItemCount: _current.length,
      padding:
          EdgeInsets.only(bottom: bottomBarClearance(context), top: space8),
      controller: widget.scroll,
      itemBuilder: (context, index, animation) {
        return _buildItem(_current[index], animation, index, showImages);
      },
    );
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

  @override
  void dispose() {
    widget.scroll.removeListener(scrollListener);
    super.dispose();
  }
}
