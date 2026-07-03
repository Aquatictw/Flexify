import 'package:flutter/material.dart';
import '../../models/set_data.dart';
import '../../records/records_service.dart';
import '../../theme/tokens.dart';
import 'complete_button.dart';
import 'reps_input.dart';
import 'weight_input.dart';

class SetRow extends StatelessWidget {

  const SetRow({
    required this.index, required this.setData, required this.unit, required this.records, required this.onWeightChanged, required this.onRepsChanged, required this.onToggle, required this.onDelete, super.key,
    this.onTypeChanged,
  });
  final int index;
  final SetData setData;
  final String unit;
  final Set<RecordType> records;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Function(bool isWarmup, bool isDropSet)? onTypeChanged;

  Future<void> _showSetTypeMenu(
    BuildContext context,
    ColorScheme colorScheme,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: space12, bottom: space8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: brPill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: space16, vertical: space8),
              child: Text(
                'Change Set Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.fitness_center, color: colorScheme.primary),
              title: const Text('Working Set'),
              subtitle: const Text('Regular set'),
              selected: !setData.isWarmup && !setData.isDropSet,
              onTap: () => Navigator.pop(context, 'working'),
            ),
            ListTile(
              leading: Icon(Icons.whatshot, color: context.jl.warmup),
              title: const Text('Warmup Set'),
              subtitle: const Text('Lighter weight, prepare muscles'),
              selected: setData.isWarmup,
              onTap: () => Navigator.pop(context, 'warmup'),
            ),
            ListTile(
              leading: Icon(Icons.trending_down, color: context.jl.dropSet),
              title: const Text('Drop Set'),
              subtitle: const Text('Reduced weight, push to failure'),
              selected: setData.isDropSet,
              onTap: () => Navigator.pop(context, 'drop'),
            ),
            const SizedBox(height: space8),
          ],
        ),
      ),
    );

    if (result != null && onTypeChanged != null) {
      switch (result) {
        case 'working':
          onTypeChanged!(false, false);
          break;
        case 'warmup':
          onTypeChanged!(true, false);
          break;
        case 'drop':
          onTypeChanged!(false, true);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final jl = context.jl;
    final completed = setData.completed;
    final isWarmup = setData.isWarmup;
    final isDropSet = setData.isDropSet;

    // Choose colors based on warmup/drop set/completed state
    final Color bgColor;
    final Color borderColor;
    final Color accentColor;
    final IconData setTypeIcon;

    if (isWarmup) {
      if (completed) {
        bgColor = jl.warmup.withValues(alpha: 0.2);
        borderColor = jl.warmup.withValues(alpha: 0.5);
        accentColor = jl.warmup;
      } else {
        bgColor = jl.warmup.withValues(alpha: 0.1);
        borderColor = jl.warmup.withValues(alpha: 0.3);
        accentColor = jl.warmup;
      }
      setTypeIcon = Icons.whatshot;
    } else if (isDropSet) {
      if (completed) {
        bgColor = jl.dropSet.withValues(alpha: 0.2);
        borderColor = jl.dropSet.withValues(alpha: 0.5);
        accentColor = jl.dropSet;
      } else {
        bgColor = jl.dropSet.withValues(alpha: 0.1);
        borderColor = jl.dropSet.withValues(alpha: 0.3);
        accentColor = jl.dropSet;
      }
      setTypeIcon = Icons.trending_down;
    } else {
      if (completed) {
        bgColor = colorScheme.primaryContainer.withValues(alpha: 0.4);
        borderColor = colorScheme.primary.withValues(alpha: 0.5);
        accentColor = colorScheme.primary;
      } else {
        bgColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
        borderColor = colorScheme.outlineVariant.withValues(alpha: 0.5);
        accentColor = colorScheme.primary;
      }
      setTypeIcon = Icons.fitness_center;
    }

    return Dismissible(
      key: Key('dismissible_set_${isWarmup ? "w" : ""}$index'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onDelete();
        return false; // We handle deletion ourselves
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: space12, vertical: space4),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: brMd,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: space24),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.error,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: space12, vertical: space4),
        padding: const EdgeInsets.symmetric(horizontal: space12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: brMd,
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            // Set number badge with warmup/drop set indicator (clickable)
            GestureDetector(
              onTap: onTypeChanged != null
                  ? () => _showSetTypeMenu(context, colorScheme)
                  : null,
              child: Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: space8),
                decoration: BoxDecoration(
                  color: completed
                      ? accentColor.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: brSm,
                  border: onTypeChanged != null
                      ? Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isWarmup || isDropSet)
                      Icon(
                        setTypeIcon,
                        size: 12,
                        color: accentColor,
                      ),
                    Text(
                      isWarmup
                          ? 'W$index'
                          : isDropSet
                              ? 'D$index'
                              : '$index',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: completed
                                ? accentColor
                                : colorScheme.onSurfaceVariant,
                            fontSize: (isWarmup || isDropSet) ? 11 : 14,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Weight input - always editable
            Expanded(
              flex: 3,
              child: WeightInput(
                value: setData.weight,
                unit: unit,
                completed: completed,
                accentColor: accentColor,
                onChanged: onWeightChanged,
              ),
            ),
            const SizedBox(width: space8),
            // Reps input with +/- buttons - always editable
            Expanded(
              flex: 4,
              child: RepsInput(
                value: setData.reps,
                completed: completed,
                accentColor: accentColor,
                onChanged: onRepsChanged,
              ),
            ),
            const SizedBox(width: space8),
            // Complete/Toggle button with integrated PR crown
            CompleteButton(
              completed: completed,
              isWarmup: isWarmup,
              isDropSet: isDropSet,
              records: completed ? records : {},
              onPressed: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}
