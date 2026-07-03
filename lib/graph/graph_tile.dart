import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../constants.dart';
import '../database/gym_sets.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../widgets/bodypart_tag.dart';
import 'cardio_page.dart';
import 'strength_page.dart';

class GraphTile extends StatelessWidget {

  const GraphTile({
    required this.selected, required this.onSelect, required this.exercise, required this.tabCtrl, super.key,
  });
  final GraphExercise exercise;
  final Set<String> selected;
  final Function(String) onSelect;
  final TabController tabCtrl;

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
    } else if (showImages && (exercise.image?.isNotEmpty ?? false)) {
      leading = GestureDetector(
        onTap: () => onSelect(exercise.name),
        child: ClipRRect(
          borderRadius: brSm,
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
                borderRadius: brSm,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    // Only wrap in AnimatedSwitcher if leading is not null
    if (leading != null) {
      leading = AnimatedSwitcher(
        duration: durFast,
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: leading,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: space8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: brMd,
        color: selected.contains(exercise.name)
            ? colorScheme.primaryContainer.withValues(alpha: .5)
            : Colors.transparent,
        border: Border.all(
          color: selected.contains(exercise.name)
              ? colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        leading: leading,
        title: Row(
          children: [
            Flexible(
              child: Text(
                exercise.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (exercise.category != null && exercise.category!.isNotEmpty) ...[
              const SizedBox(width: 6),
              BodypartTag(bodypart: exercise.category),
            ],
            if (exercise.brandName != null &&
                exercise.brandName!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
                  borderRadius: brSm,
                ),
                child: Text(
                  exercise.brandName!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSecondaryContainer,
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
            borderRadius: brMd,
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
