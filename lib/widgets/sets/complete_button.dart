import 'package:flutter/material.dart';
import '../../records/records_service.dart';
import '../../theme/tokens.dart';

class CompleteButton extends StatelessWidget {

  const CompleteButton({
    required this.completed, required this.isWarmup, required this.onPressed, super.key,
    this.isDropSet = false,
    this.records = const {},
  });
  final bool completed;
  final bool isWarmup;
  final bool isDropSet;
  final Set<RecordType> records;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final jl = context.jl;
    final accentColor = isWarmup
        ? jl.warmup
        : isDropSet
            ? jl.dropSet
            : jl.working;
    // jl.warmup/dropSet are custom semantic colors (not ColorScheme roles), so
    // pick a contrasting foreground by brightness rather than relying on an
    // "on*" role that doesn't exist for them.
    final onAccentColor = isWarmup || isDropSet
        ? (colorScheme.brightness == Brightness.dark
            ? Colors.black
            : Colors.white)
        : colorScheme.onPrimary;

    // If completed and has records, show crown instead of checkmark
    final bool hasPR = completed && records.isNotEmpty;

    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor:
              completed ? accentColor : colorScheme.surfaceContainerHighest,
          shape: const RoundedRectangleBorder(
            borderRadius: brSm,
          ),
        ),
        icon: AnimatedSwitcher(
          duration: durFast,
          child: hasPR
              ? Stack(
                  key: ValueKey('crown_$completed'),
                  alignment: Alignment.center,
                  children: [
                    // Golden glow effect
                    Icon(
                      Icons.workspace_premium,
                      color: jl.pr.withValues(alpha: 0.5),
                      size: 28,
                    ),
                    // Main crown icon
                    Icon(
                      Icons.workspace_premium,
                      color: onAccentColor,
                      size: 24,
                    ),
                  ],
                )
              : Icon(
                  completed ? Icons.check : Icons.check,
                  key: ValueKey('check_$completed'),
                  color:
                      completed ? onAccentColor : colorScheme.onSurfaceVariant,
                  size: 22,
                ),
        ),
      ),
    );
  }
}
