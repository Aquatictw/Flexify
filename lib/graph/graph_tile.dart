import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../constants.dart';
import '../database/gym_sets.dart';
import '../main.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import 'cardio_page.dart';
import 'strength_page.dart';

// Trend: 1 = improving, 0 = flat, -1 = declining, null = no signal (cardio or
// not enough history). Cached per exercise name so re-renders (e.g. selection
// toggles) don't re-query the db.
final Map<String, Future<int?>> _trendCache = {};

Future<int?> _trendFor(GraphExercise exercise) {
  if (exercise.cardio) return Future.value();
  return _trendCache.putIfAbsent(
    exercise.name,
    () => _computeTrend(exercise.name),
  );
}

// Estimated 1RM (Brzycki), mirrors calculate1RM() in records_service.dart, as
// a SQL expression so the per-workout best can be aggregated. CAST to REAL so
// drift doesn't read an int back for the reps<=0 branch.
const _oneRmSql = 'CAST(CASE '
    'WHEN reps <= 0 THEN 0 '
    'WHEN reps = 1 THEN weight '
    'WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) '
    'ELSE weight * (1.0278 - 0.0278 * reps) END AS REAL)';

Future<int?> _computeTrend(String name) async {
  final rows = await db.customSelect(
    'SELECT MAX($_oneRmSql) AS max_1rm '
    'FROM gym_sets '
    'WHERE name = ? AND cardio = 0 AND hidden = 0 AND workout_id IS NOT NULL '
    'GROUP BY workout_id '
    'ORDER BY MAX(created) DESC '
    'LIMIT 2',
    variables: [drift.Variable.withString(name)],
  ).get();
  if (rows.length < 2) return null;

  final latest = rows[0].read<double>('max_1rm');
  final previous = rows[1].read<double>('max_1rm');
  final diff = latest - previous;
  if (diff > 0.5) return 1;
  if (diff < -0.5) return -1;
  return 0;
}

/// Opens the exercise's graph page (cardio or strength) — the same navigation
/// as tapping its row in the Graphs list. Shared by GraphTile, the bento
/// header, and the PR ticker.
Future<void> openExerciseGraph(
  BuildContext context, {
  required String name,
  required String unit,
  required bool cardio,
  required TabController tabCtrl,
}) async {
  if (cardio) {
    final data = await getCardioData(
      target: unit,
      name: name,
      period: Period.months3,
    );
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardioPage(
          tabCtrl: tabCtrl,
          name: name,
          unit: unit,
          data: data,
        ),
      ),
    );
    return;
  }

  final data = await getStrengthData(
    target: unit,
    name: name,
    metric: StrengthMetric.bestWeight,
    period: Period.months3,
  );
  if (!context.mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => StrengthPage(
        name: name,
        unit: unit,
        data: data,
        tabCtrl: tabCtrl,
      ),
    ),
  );
}

class GraphTile extends StatelessWidget {
  const GraphTile({
    required this.selected,
    required this.onSelect,
    required this.exercise,
    required this.tabCtrl,
    super.key,
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
    final isSelected = selected.contains(exercise.name);
    final muscleGroup = muscleGroupOf(exercise.category, exercise.name);
    final muscleColor = context.jl.muscleColor(muscleGroup);

    Widget? leading;

    // Show checkbox when selected, otherwise show image if available
    if (isSelected) {
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
      margin: const EdgeInsets.symmetric(horizontal: space16, vertical: 3),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: brMd,
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: .5)
            : colorScheme.surfaceContainer,
        border: Border.all(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: muscleColor),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: ListTile(
              leading: leading,
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      exercise.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: muscleColor.withValues(alpha: 0.15),
                      borderRadius: brPill,
                    ),
                    child: Text(
                      muscleLabel(muscleGroup),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: muscleColor,
                      ),
                    ),
                  ),
                  if (exercise.brandName != null &&
                      exercise.brandName!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer
                            .withValues(alpha: 0.7),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: brPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${exercise.workoutCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 16,
                    child: FutureBuilder<int?>(
                      future: _trendFor(exercise),
                      builder: (context, snapshot) {
                        final trend = snapshot.data;
                        if (trend == null) return const SizedBox.shrink();
                        final (glyph, color) = switch (trend) {
                          > 0 => ('↑', context.jl.success),
                          < 0 => ('↓', context.jl.danger),
                          _ => ('→', colorScheme.onSurfaceVariant),
                        };
                        return Text(
                          glyph,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              onTap: () {
                if (selected.isNotEmpty) {
                  onSelect(exercise.name);
                  return;
                }
                openExerciseGraph(
                  context,
                  name: exercise.name,
                  unit: exercise.unit,
                  cardio: exercise.cardio,
                  tabCtrl: tabCtrl,
                );
              },
              onLongPress: () {
                onSelect(exercise.name);
              },
            ),
          ),
        ],
      ),
    );
  }
}
