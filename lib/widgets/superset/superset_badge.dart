import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'superset_utils.dart';

/// A badge that displays superset label (A1, A2, B1, B2, etc.)
class SupersetBadge extends StatelessWidget { // Compact mode for smaller displays

  const SupersetBadge({
    required this.supersetIndex, required this.position, super.key,
    this.isCompact = false,
  });
  final int supersetIndex; // 0-based (A=0, B=1, etc.)
  final int position; // 0-based position within superset
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final label = getSupersetLabel(supersetIndex, position);
    final backgroundColor = getSupersetColor(context, supersetIndex);
    final textColor = getSupersetTextColor(context, supersetIndex);

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: space4, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: brSm,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
                height: 1.2,
              ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: space8, vertical: space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: brSm,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              height: 1.2,
            ),
      ),
    );
  }
}

/// A horizontal indicator bar showing all exercises in a superset
class SupersetIndicator extends StatelessWidget { // 0-based

  const SupersetIndicator({
    required this.supersetIndex, required this.totalExercises, required this.currentPosition, super.key,
  });
  final int supersetIndex;
  final int totalExercises;
  final int currentPosition;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = getSupersetColor(context, supersetIndex);
    final textColor = getSupersetTextColor(context, supersetIndex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: space12, vertical: space8),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.15),
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.3),
        ),
        borderRadius: brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Superset ${getSupersetLabel(supersetIndex, 0)[0]}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(width: space8),
          ...List.generate(totalExercises, (index) {
            final isActive = index == currentPosition;
            return Padding(
              padding: const EdgeInsets.only(right: space4),
              child: Container(
                width: isActive ? 8 : 6,
                height: isActive ? 8 : 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? backgroundColor
                      : backgroundColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
