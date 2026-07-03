import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

class AddExerciseCard extends StatelessWidget {

  const AddExerciseCard({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: space12, vertical: space8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: brMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
                vertical: space16, horizontal: space16,),
            decoration: BoxDecoration(
              borderRadius: brMd,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.2),
                  colorScheme.secondaryContainer.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(space8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: brSm,
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: space12),
                Text(
                  'Add Exercise',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
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
