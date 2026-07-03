import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';

/// A timeline-style tile widget for displaying individual bodyweight entries.
///
/// Shows the entry date, weight with unit, and optional notes.
/// Includes a timeline visual (circle indicator with connecting line)
/// and supports edit/delete actions via swipe-to-dismiss.
class BodyweightEntryTile extends StatelessWidget {

  const BodyweightEntryTile({
    required this.entry, required this.isLast, required this.onEdit, required this.onDelete, super.key,
  });
  final BodyweightEntry entry;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsState>().value;
    final unit = settings.strengthUnit;

    return Dismissible(
      key: Key('entry-${entry.id}'),
      background: Container(
        color: context.jl.danger.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(horizontal: space16),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete, color: context.jl.danger),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Entry'),
              content: const Text(
                'Are you sure you want to delete this bodyweight entry?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onEdit,
        borderRadius: brSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: space4),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline indicator
                SizedBox(
                  width: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Connecting line (hidden for last item)
                      if (!isLast)
                        Positioned(
                          top: 20,
                          bottom: 0,
                          child: Container(
                            width: 2,
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      // Circle indicator
                      Positioned(
                        top: 14,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Entry content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(space8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: brSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date
                        Text(
                          DateFormat('MMM d, yyyy').format(entry.date),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: space4),
                        // Weight
                        Row(
                          children: [
                            Icon(
                              Icons.monitor_weight_outlined,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: space4),
                            Text(
                              '${entry.weight.toStringAsFixed(1)} $unit',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        // Notes (if present)
                        if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                          const SizedBox(height: space4),
                          Text(
                            entry.notes!,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Edit button
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        iconSize: 18,
                        onPressed: onEdit,
                        tooltip: 'Edit entry',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
