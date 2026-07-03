import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../theme/tokens.dart';

/// Summary page shown after block completion or when viewing completed blocks
class BlockSummaryPage extends StatelessWidget {
  const BlockSummaryPage({super.key, required this.block});

  final FiveThreeOneBlock block;

  String _formatTm(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  String _formatDelta(double delta) {
    final formatted = _formatTm(delta.abs());
    if (delta > 0) return '+$formatted';
    if (delta < 0) return '-$formatted';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, y');

    final exercises = [
      (
        name: 'Squat',
        startTm: block.startSquatTm ?? block.squatTm,
        endTm: block.squatTm,
      ),
      (
        name: 'Bench',
        startTm: block.startBenchTm ?? block.benchTm,
        endTm: block.benchTm,
      ),
      (
        name: 'Deadlift',
        startTm: block.startDeadliftTm ?? block.deadliftTm,
        endTm: block.deadliftTm,
      ),
      (
        name: 'OHP',
        startTm: block.startPressTm ?? block.pressTm,
        endTm: block.pressTm,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Block Complete')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: block dates
                  Card(
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(space16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 20, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${dateFormat.format(block.created)}'
                              '${block.completed != null ? '  \u2192  ${dateFormat.format(block.completed!)}' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lift progression cards
                  for (final ex in exercises) ...[
                    _LiftCard(
                      name: ex.name,
                      startTm: ex.startTm,
                      endTm: ex.endTm,
                      unit: block.unit,
                      formatTm: _formatTm,
                      formatDelta: _formatDelta,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),

          // Done button at bottom
          Padding(
            padding: const EdgeInsets.all(space16),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiftCard extends StatelessWidget {
  const _LiftCard({
    required this.name,
    required this.startTm,
    required this.endTm,
    required this.unit,
    required this.formatTm,
    required this.formatDelta,
  });

  final String name;
  final double startTm;
  final double endTm;
  final String unit;
  final String Function(double) formatTm;
  final String Function(double) formatDelta;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final delta = endTm - startTm;
    final isPositive = delta > 0;
    final isNeutral = delta == 0;
    final badgeColor = isPositive
        ? context.jl.success
        : isNeutral
            ? colorScheme.outline
            : context.jl.danger;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(space16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatTm(startTm)} \u2192 ${formatTm(endTm)} $unit',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: brMd,
              ),
              child: Text(
                '${formatDelta(delta)} $unit',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: badgeColor,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
