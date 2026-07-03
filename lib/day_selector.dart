import 'package:flutter/material.dart';

import 'constants.dart';
import 'theme/tokens.dart';

class DaySelector extends StatefulWidget {
  const DaySelector({required this.daySwitches, super.key});
  final List<bool> daySwitches;

  @override
  State<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<DaySelector> {
  void _toggleDay(int index) {
    setState(() {
      widget.daySwitches[index] = !widget.daySwitches[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(weekdays.length, (index) {
        final isSelected = widget.daySwitches[index];
        final dayLabel = weekdays[index].length < 3
            ? weekdays[index]
            : weekdays[index].substring(0, 3);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: space4 / 2),
            child: AnimatedContainer(
              duration: durMed,
              curve: curveStandard,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: brSm,
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary.withAlpha(
                          (colorScheme.primary.a * 0.7 * 255.0).round() & 0xff,
                        )
                      : colorScheme.outline.withAlpha(
                          (colorScheme.outline.a * 0.3 * 255.0).round() & 0xff,
                        ),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: brSm,
                  onTap: () => _toggleDay(index),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: durMed,
                      style: (isSelected
                              ? Theme.of(context).textTheme.labelLarge
                              : Theme.of(context).textTheme.labelMedium)
                          ?.copyWith(color: colorScheme.onSurface) ??
                          const TextStyle(),
                      child: Text(dayLabel),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
