import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

class NotesSection extends StatelessWidget {

  const NotesSection({
    required this.controller, required this.onChanged, super.key,
  });
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bodyStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: colorScheme.onSurface);
    return Container(
      margin: const EdgeInsets.fromLTRB(space12, 0, space12, space8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: brMd,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(space16, space12, space16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: space8),
                Text(
                  'Workout Notes',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(space12, space4, space12, space12),
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 2,
              style: bodyStyle,
              decoration: InputDecoration(
                hintText: 'Add notes about your workout...',
                hintStyle: bodyStyle?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: space8,
                  vertical: space8,
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
