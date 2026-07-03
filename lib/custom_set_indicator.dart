import 'package:flutter/material.dart';

import 'theme/tokens.dart';

class CustomSetIndicator extends StatelessWidget {
  const CustomSetIndicator({
    required this.count, required this.max, super.key,
  });
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    for (int i = 0; i < max; i++) {
      items.add(
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: brPill,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            height: 6,
            child: AnimatedFractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: count > i ? 1 : 0,
              duration: durMed,
              curve: curveStandard,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: brPill,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      );
      if (i < max - 1) {
        items.add(const SizedBox(width: space8));
      }
    }
    return Row(children: items);
  }
}
