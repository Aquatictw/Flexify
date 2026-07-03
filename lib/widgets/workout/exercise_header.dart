import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../bodypart_tag.dart';

class ExerciseHeader extends StatelessWidget {

  const ExerciseHeader({
    required this.exerciseName, required this.isExpanded, required this.allCompleted, required this.completedCount, required this.totalSets, required this.unit, required this.onTap, super.key,
    this.category,
    this.brandName,
    this.exerciseNotes,
    this.totalVolume,
    this.onLongPress,
  });
  final String exerciseName;
  final String? category;
  final String? brandName;
  final String? exerciseNotes;
  final bool isExpanded;
  final bool allCompleted;
  final int completedCount;
  final int totalSets;
  final String unit;
  final String? totalVolume;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: space16, vertical: space12),
        decoration: BoxDecoration(
          gradient: allCompleted
              ? LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.6),
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(space8),
              decoration: BoxDecoration(
                color: allCompleted
                    ? colorScheme.primary
                    : colorScheme.primaryContainer,
                borderRadius: brSm,
              ),
              child: Icon(
                allCompleted ? Icons.check : Icons.fitness_center,
                color:
                    allCompleted ? colorScheme.onPrimary : colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          exerciseName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      if (category != null && category!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        BodypartTag(bodypart: category),
                      ],
                      if (brandName != null && brandName!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            brandName!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Exercise notes preview
                  if (exerciseNotes?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: 12,
                          color: colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            exerciseNotes!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.tertiary,
                                      fontStyle: FontStyle.italic,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$completedCount / $totalSets sets',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (completedCount > 0 && totalVolume != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.fitness_center,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalVolume $unit',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: durFast,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
