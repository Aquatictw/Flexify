import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../theme/tokens.dart';
import 'block_creation_dialog.dart';
import 'block_summary_page.dart';
import 'fivethreeone_state.dart';
import 'schemes.dart';

/// Full-page block overview with vertical timeline and week advancement
class BlockOverviewPage extends StatelessWidget {
  const BlockOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FiveThreeOneState>();
    final block = state.activeBlock;

    return Scaffold(
      appBar: AppBar(
        title: Text(block == null ? '5/3/1 Block' : state.positionLabel),
      ),
      body: block == null
          ? _buildNoBlock(context, state)
          : _buildTimeline(context, state, block),
    );
  }

  Widget _buildNoBlock(BuildContext context, FiveThreeOneState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(space16),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            'No active block',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const BlockCreationDialog(),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Start Block'),
          ),
          const SizedBox(height: 32),
          _CompletedBlockHistory(state: state),
        ],
      ),
    );
  }

  Widget _buildTimeline(
      BuildContext context, FiveThreeOneState state, FiveThreeOneBlock block) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(space16),
      child: Column(
        children: [
          _TmCard(block: block),
          const SizedBox(height: 20),
          for (int i = 0; i < cycleNames.length; i++)
            _CycleEntry(
              cycleIndex: i,
              currentCycle: block.currentCycle,
              currentWeek: block.currentWeek,
              block: block,
            ),
          const SizedBox(height: 8),
          _CompleteWeekButton(block: block),
          const SizedBox(height: 32),
          _CompletedBlockHistory(state: state),
        ],
      ),
    );
  }
}

class _CycleEntry extends StatelessWidget {
  const _CycleEntry({
    required this.cycleIndex,
    required this.currentCycle,
    required this.currentWeek,
    required this.block,
  });

  final int cycleIndex;
  final int currentCycle;
  final int currentWeek;
  final FiveThreeOneBlock block;

  @override
  Widget build(BuildContext context) {
    final isCompleted = cycleIndex < currentCycle;
    final isCurrent = cycleIndex == currentCycle;
    final colorScheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: vertical line + circle indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (cycleIndex > 0)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted || isCurrent
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? colorScheme.primary
                        : isCurrent
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerLow,
                    border: isCurrent
                        ? Border.all(color: colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check,
                          size: 14, color: colorScheme.onPrimary)
                      : null,
                ),
                if (cycleIndex < cycleNames.length - 1)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Right: cycle card
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: space12),
              elevation: isCurrent ? 2 : 0,
              color: isCurrent
                  ? colorScheme.primaryContainer
                  : isCompleted
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: brMd,
                side: isCurrent
                    ? BorderSide(color: colorScheme.primary, width: 1.5)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CycleBadge(
                          cycleIndex: cycleIndex,
                          isCurrent: isCurrent,
                          isCompleted: isCompleted,
                        ),
                        const SizedBox(width: space8),
                        Expanded(
                          child: Text(
                            cycleNames[cycleIndex],
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isCurrent || isCompleted
                                      ? null
                                      : colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      getMainSchemeName(cycleIndex),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (isCurrent) ..._buildWeekIndicators(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeekIndicators(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxWeeks = cycleWeeks[cycleIndex];
    final widgets = <Widget>[const SizedBox(height: 8)];

    for (int w = 1; w <= maxWeeks; w++) {
      final isWeekCompleted = w < currentWeek;
      final isWeekCurrent = w == currentWeek;

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWeekCompleted
                      ? colorScheme.primary
                      : isWeekCurrent
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Week $w',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isWeekCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isWeekCompleted
                          ? colorScheme.primary
                          : isWeekCurrent
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }
}

/// Small colored pill showing the cycle's short badge (L1, L2, D, A, T).
class _CycleBadge extends StatelessWidget {
  const _CycleBadge({
    required this.cycleIndex,
    required this.isCurrent,
    required this.isCompleted,
  });

  final int cycleIndex;
  final bool isCurrent;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    if (isCurrent) {
      bg = colorScheme.primary;
      fg = colorScheme.onPrimary;
    } else if (isCompleted) {
      bg = colorScheme.primary.withValues(alpha: 0.18);
      fg = colorScheme.primary;
    } else {
      bg = colorScheme.surfaceContainerHighest;
      fg = colorScheme.onSurfaceVariant;
    }

    return Container(
      width: 28,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: brSm),
      child: Text(
        getCycleBadge(cycleIndex),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _TmCard extends StatefulWidget {
  const _TmCard({required this.block});

  final FiveThreeOneBlock block;

  @override
  State<_TmCard> createState() => _TmCardState();
}

class _TmCardState extends State<_TmCard> {
  late TextEditingController _squatController;
  late TextEditingController _benchController;
  late TextEditingController _deadliftController;
  late TextEditingController _pressController;

  late FocusNode _squatFocus;
  late FocusNode _benchFocus;
  late FocusNode _deadliftFocus;
  late FocusNode _pressFocus;

  @override
  void initState() {
    super.initState();
    _squatController =
        TextEditingController(text: _formatTm(widget.block.squatTm));
    _benchController =
        TextEditingController(text: _formatTm(widget.block.benchTm));
    _deadliftController =
        TextEditingController(text: _formatTm(widget.block.deadliftTm));
    _pressController =
        TextEditingController(text: _formatTm(widget.block.pressTm));

    _squatFocus = FocusNode()
      ..addListener(() => _onFocusLost(_squatFocus, 'squat', _squatController));
    _benchFocus = FocusNode()
      ..addListener(() => _onFocusLost(_benchFocus, 'bench', _benchController));
    _deadliftFocus = FocusNode()
      ..addListener(
          () => _onFocusLost(_deadliftFocus, 'deadlift', _deadliftController));
    _pressFocus = FocusNode()
      ..addListener(() => _onFocusLost(_pressFocus, 'press', _pressController));
  }

  @override
  void didUpdateWidget(covariant _TmCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if block values changed externally (e.g. after TM bump)
    if (!_squatFocus.hasFocus)
      _squatController.text = _formatTm(widget.block.squatTm);
    if (!_benchFocus.hasFocus)
      _benchController.text = _formatTm(widget.block.benchTm);
    if (!_deadliftFocus.hasFocus)
      _deadliftController.text = _formatTm(widget.block.deadliftTm);
    if (!_pressFocus.hasFocus)
      _pressController.text = _formatTm(widget.block.pressTm);
  }

  String _formatTm(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  void _onFocusLost(
      FocusNode node, String exercise, TextEditingController controller) {
    if (!node.hasFocus) {
      _saveTm(exercise, controller);
    }
  }

  void _saveTm(String exercise, TextEditingController controller) {
    final value = double.tryParse(controller.text);
    if (value != null && value > 0) {
      context
          .read<FiveThreeOneState>()
          .updateTm(exercise: exercise, value: value);
    }
  }

  @override
  void dispose() {
    _squatController.dispose();
    _benchController.dispose();
    _deadliftController.dispose();
    _pressController.dispose();
    _squatFocus.dispose();
    _benchFocus.dispose();
    _deadliftFocus.dispose();
    _pressFocus.dispose();
    super.dispose();
  }

  Widget _buildTmField({
    required String label,
    required String exerciseKey,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelText: label,
        suffixText: widget.block.unit,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => _saveTm(exerciseKey, controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(borderRadius: brMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight_outlined,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Training Max',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: brSm,
                  ),
                  child: Text(
                    widget.block.unit,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTmField(
                    label: 'Squat',
                    exerciseKey: 'squat',
                    controller: _squatController,
                    focusNode: _squatFocus,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTmField(
                    label: 'Bench',
                    exerciseKey: 'bench',
                    controller: _benchController,
                    focusNode: _benchFocus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTmField(
                    label: 'Deadlift',
                    exerciseKey: 'deadlift',
                    controller: _deadliftController,
                    focusNode: _deadliftFocus,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTmField(
                    label: 'OHP',
                    exerciseKey: 'press',
                    controller: _pressController,
                    focusNode: _pressFocus,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteWeekButton extends StatelessWidget {
  const _CompleteWeekButton({required this.block});

  final FiveThreeOneBlock block;

  Widget _buildCompleteButton(BuildContext context, FiveThreeOneState state,
      bool isComplete, String label,
      {bool fullWidth = false}) {
    return FilledButton.icon(
      onPressed: () async {
        // Confirmation dialog before advancing
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(label),
            content: Text(isComplete
                ? 'Are you sure you want to complete this block?'
                : 'Are you sure you want to complete this week?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
        if (!context.mounted) return;

        final state = context.read<FiveThreeOneState>();
        if (state.needsTmBump) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Bump Training Max?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Squat: ${block.squatTm} \u2192 ${(block.squatTm + 4.5).toStringAsFixed(1)} ${block.unit}'),
                  Text(
                      'Bench: ${block.benchTm} \u2192 ${(block.benchTm + 2.2).toStringAsFixed(1)} ${block.unit}'),
                  Text(
                      'Deadlift: ${block.deadliftTm} \u2192 ${(block.deadliftTm + 4.5).toStringAsFixed(1)} ${block.unit}'),
                  Text(
                      'OHP: ${block.pressTm} \u2192 ${(block.pressTm + 2.2).toStringAsFixed(1)} ${block.unit}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Skip'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Bump TMs'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await state.bumpTms();
          }
        }

        if (isComplete) {
          // Capture block reference before advancing (which deactivates it)
          final completedBlock = state.activeBlock!;
          await state.advanceWeek();
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => BlockSummaryPage(block: completedBlock),
              ),
            );
          }
        } else {
          await state.advanceWeek();
        }
      },
      icon: Icon(isComplete ? Icons.check : Icons.arrow_forward),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: fullWidth ? const Size.fromHeight(48) : const Size(0, 48),
      ),
    );
  }

  Widget _buildGoBackButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Go Back'),
            content: const Text('Go back to the previous week?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await context.read<FiveThreeOneState>().goBackWeek();
        }
      },
      icon: const Icon(Icons.undo),
      label: const Text('Back', maxLines: 1, softWrap: false),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FiveThreeOneState>();
    final isComplete = state.isBlockComplete;
    final label = isComplete ? 'Complete Block' : 'Complete Week';

    if (state.canGoBack) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildGoBackButton(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildCompleteButton(context, state, isComplete, label),
          ),
        ],
      );
    }

    return _buildCompleteButton(context, state, isComplete, label,
        fullWidth: true);
  }
}

class _CompletedBlockHistory extends StatelessWidget {
  const _CompletedBlockHistory({required this.state});

  final FiveThreeOneState state;

  String _formatTm(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FiveThreeOneBlock>>(
      future: state.getCompletedBlocks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final blocks = snapshot.data!;
        final colorScheme = Theme.of(context).colorScheme;
        final dateFormat = DateFormat('MMM d, y');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completed Blocks',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            for (final block in blocks)
              Card(
                color: colorScheme.surfaceContainerLow,
                child: InkWell(
                  borderRadius: brMd,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlockSummaryPage(block: block),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(space12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dateFormat.format(block.created)}'
                                '${block.completed != null ? ' \u2013 ${dateFormat.format(block.completed!)}' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Training Max',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  for (final entry in [
                                    ('Squat', _formatTm(block.squatTm)),
                                    ('Bench', _formatTm(block.benchTm)),
                                    ('Deadlift', _formatTm(block.deadliftTm)),
                                    ('OHP', _formatTm(block.pressTm)),
                                  ])
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.$1,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          Text(
                                            '${entry.$2} ${block.unit}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
