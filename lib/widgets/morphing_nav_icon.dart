import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Animated navigation icon: scales up and settles when selected.
class MorphingNavIcon extends StatelessWidget {
  const MorphingNavIcon({
    required this.icon,
    required this.isSelected,
    required this.color,
    super.key,
    this.size = 24.0,
  });

  final IconData icon;
  final bool isSelected;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: durMed,
      curve: curveStandard,
      child: AnimatedRotation(
        turns: isSelected ? 0.02 : 0.0,
        duration: durMed,
        curve: curveStandard,
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
