import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A small, compact tag widget that displays a bodypart/muscle group
class BodypartTag extends StatelessWidget {

  const BodypartTag({
    required this.bodypart, super.key,
    this.fontSize = 10,
  });
  final String? bodypart;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (bodypart == null || bodypart!.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: brPill,
      ),
      child: Text(
        bodypart!,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}
