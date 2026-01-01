import 'dart:io';

import 'package:flexify/constants.dart';
import 'package:flexify/database/gym_sets.dart';
import 'package:flexify/graph/cardio_page.dart';
import 'package:flexify/graph/strength_page.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class GraphTile extends StatelessWidget {
  final GraphExercise exercise;
  final Set<String> selected;
  final Function(String) onSelect;
  final TabController tabCtrl;

  const GraphTile({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.exercise,
    required this.tabCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showImages = context
        .select<SettingsState, bool>((settings) => settings.value.showImages);

    Widget? leading;

    // Show checkbox when selected, otherwise show image if available
    if (selected.contains(exercise.name)) {
      leading = SizedBox(
        height: 40,
        width: 40,
        child: Checkbox(
          value: true,
          onChanged: (value) {
            onSelect(exercise.name);
          },
        ),
      );
    } else if (showImages && exercise.image?.isNotEmpty == true) {
      leading = GestureDetector(
        onTap: () => onSelect(exercise.name),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(exercise.image!),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.fitness_center,
                  size: 20, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    // Only wrap in AnimatedSwitcher if leading is not null
    if (leading != null) {
      leading = AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: leading,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: selected.contains(exercise.name)
            ? colorScheme.primary.withValues(alpha: .08)
            : Colors.transparent,
        border: Border.all(
          color: selected.contains(exercise.name)
              ? colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: leading,
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Selector<SettingsState, String>(
          selector: (context, settings) => settings.value.longDateFormat,
          builder: (context, dateFormat, child) => Text(
            dateFormat == 'timeago'
                ? timeago.format(exercise.created)
                : 'Last: ${timeago.format(exercise.created)}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                '${exercise.workoutCount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        onTap: () async {
          if (selected.isNotEmpty) {
            onSelect(exercise.name);
            return;
          }

          if (exercise.cardio) {
            final data = await getCardioData(
              target: exercise.unit,
              name: exercise.name,
              metric: CardioMetric.pace,
              period: Period.months3,
            );
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardioPage(
                  tabCtrl: tabCtrl,
                  name: exercise.name,
                  unit: exercise.unit,
                  data: data,
                ),
              ),
            );
            return;
          }

          final data = await getStrengthData(
            target: exercise.unit,
            name: exercise.name,
            metric: StrengthMetric.bestWeight,
            period: Period.months3,
          );
          if (!context.mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StrengthPage(
                name: exercise.name,
                unit: exercise.unit,
                data: data,
                tabCtrl: tabCtrl,
              ),
            ),
          );
        },
        onLongPress: () {
          onSelect(exercise.name);
        },
      ),
    );
  }
}
