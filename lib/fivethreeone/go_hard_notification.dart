import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Guards against stacking. Starting a plan loads several exercise cards at
/// once, so two main lifts would otherwise each push their own dialog and the
/// auto-dismiss would pop the wrong route.
bool _visible = false;

/// Shows a short "Go Hard!" prompt when a 5/3/1 main lift is auto-filled from
/// the active block. A smaller, calmer sibling of the record notification —
/// same entrance, no confetti, and it clears itself after two seconds.
void showGoHardNotification(
  BuildContext context, {
  required String exerciseName,
  required String schemeLabel,
}) {
  if (_visible) return;
  _visible = true;

  HapticFeedback.mediumImpact();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black45,
    transitionDuration: durMed,
    pageBuilder: (context, animation, secondaryAnimation) => _GoHardDialog(
      exerciseName: exerciseName,
      schemeLabel: schemeLabel,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  ).whenComplete(() => _visible = false);

  Future.delayed(const Duration(seconds: 2), () {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
  });
}

class _GoHardDialog extends StatelessWidget {
  const _GoHardDialog({
    required this.exerciseName,
    required this.schemeLabel,
  });

  final String exerciseName;
  final String schemeLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(space32),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(
              horizontal: space24,
              vertical: space16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.surface,
                ],
              ),
              borderRadius: brMd,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: durSlow,
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Container(
                    padding: const EdgeInsets.all(space12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      size: 28,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: space12),
                Text(
                  'GO HARD!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: colorScheme.primary,
                      ),
                ),
                const SizedBox(height: space4),
                Text(
                  exerciseName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  schemeLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
