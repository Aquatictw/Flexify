import 'dart:math';

import 'package:flexify/records/records_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a celebratory notification when a new record is achieved
void showRecordNotification(
  BuildContext context, {
  required List<RecordAchievement> achievements,
  required String exerciseName,
}) {
  if (achievements.isEmpty) return;

  // Heavy haptic feedback for record achievement
  HapticFeedback.heavyImpact();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _RecordNotificationDialog(
        achievements: achievements,
        exerciseName: exerciseName,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      );
      return ScaleTransition(
        scale: curvedAnimation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );

  // Auto-dismiss after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
  });
}

class _RecordNotificationDialog extends StatefulWidget {
  final List<RecordAchievement> achievements;
  final String exerciseName;

  const _RecordNotificationDialog({
    required this.achievements,
    required this.exerciseName,
  });

  @override
  State<_RecordNotificationDialog> createState() =>
      _RecordNotificationDialogState();
}

class _RecordNotificationDialogState extends State<_RecordNotificationDialog>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _confettiController;
  late List<_ConfettiParticle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();

    // Create confetti particles
    _particles = List.generate(30, (index) => _ConfettiParticle(_random));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRecord = widget.achievements.first;

    return Stack(
      children: [
        // Confetti overlay
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                    colorScheme.tertiary,
                    Colors.amber,
                    Colors.orange,
                  ],
                ),
              );
            },
          ),
        ),
        // Main dialog
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withValues(alpha: 0.9),
                      colorScheme.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Crown header with shimmer
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Shimmer background
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return Container(
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(22),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment(-2 + 4 * _shimmerController.value, 0),
                                  end: Alignment(-1 + 4 * _shimmerController.value, 0),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Crown icon
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.5, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.amber.shade300,
                                  Colors.amber.shade600,
                                  Colors.orange.shade700,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        children: [
                          // Title
                          Text(
                            'NEW RECORD!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [
                                    Colors.amber.shade400,
                                    Colors.orange.shade600,
                                  ],
                                ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 30),
                                ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Exercise name
                          Text(
                            widget.exerciseName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          // Record achievements
                          ...widget.achievements.map(
                            (achievement) => _RecordBadge(achievement: achievement),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordBadge extends StatelessWidget {
  final RecordAchievement achievement;

  const _RecordBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji
            Text(
              achievement.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            // Record type and value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatValue(achievement),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Improvement badge
            if (achievement.previousValue != null && achievement.improvement > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      size: 14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+${achievement.improvement.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatValue(RecordAchievement achievement) {
    final value = achievement.newValue;
    switch (achievement.type) {
      case RecordType.best1RM:
        return '${value.toStringAsFixed(1)} ${achievement.unit}';
      case RecordType.bestWeight:
        return '${_formatWeight(value)} ${achievement.unit}';
      case RecordType.bestVolume:
        if (value >= 1000) {
          return '${(value / 1000).toStringAsFixed(1)}k ${achievement.unit}';
        }
        return '${value.toStringAsFixed(0)} ${achievement.unit}';
    }
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _ConfettiParticle {
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double size;
  final int colorIndex;
  final double rotation;
  final double rotationSpeed;

  _ConfettiParticle(Random random)
      : startX = random.nextDouble(),
        startY = random.nextDouble() * 0.3,
        velocityX = (random.nextDouble() - 0.5) * 0.3,
        velocityY = 0.5 + random.nextDouble() * 0.5,
        size = 6 + random.nextDouble() * 8,
        colorIndex = random.nextInt(5),
        rotation = random.nextDouble() * 2 * pi,
        rotationSpeed = (random.nextDouble() - 0.5) * 10;
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final List<Color> colors;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = (particle.startX + particle.velocityX * progress) * size.width;
      final y = (particle.startY + particle.velocityY * progress) * size.height;

      if (y > size.height) continue;

      final opacity = 1.0 - progress;
      final color = colors[particle.colorIndex].withValues(alpha: opacity);
      final paint = Paint()..color = color;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + particle.rotationSpeed * progress);

      // Draw confetti shape (small rectangle)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// A small crown icon widget for indicating record sets
class RecordCrown extends StatelessWidget {
  final Set<RecordType> records;
  final double size;
  final bool showTooltip;

  const RecordCrown({
    super.key,
    required this.records,
    this.size = 16,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    // Choose color based on record types
    Color crownColor;
    if (records.contains(RecordType.bestWeight)) {
      crownColor = Colors.amber;
    } else if (records.contains(RecordType.best1RM)) {
      crownColor = Colors.orange;
    } else {
      crownColor = Colors.deepOrange;
    }

    final tooltip = records.map((r) {
      switch (r) {
        case RecordType.best1RM:
          return '1RM';
        case RecordType.bestVolume:
          return 'Volume';
        case RecordType.bestWeight:
          return 'Weight';
      }
    }).join(', ');

    final crown = Container(
      padding: EdgeInsets.all(size * 0.15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            crownColor.withValues(alpha: 0.9),
            crownColor.withValues(alpha: 0.7),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: crownColor.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Icon(
        Icons.emoji_events,
        size: size * 0.7,
        color: Colors.white,
      ),
    );

    if (!showTooltip) return crown;

    return Tooltip(
      message: 'PR: $tooltip',
      child: crown,
    );
  }
}

/// A compact record indicator showing just the icon
class RecordIndicator extends StatelessWidget {
  final Set<RecordType> records;

  const RecordIndicator({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (records.contains(RecordType.bestWeight))
          _buildMiniIcon(Icons.emoji_events, Colors.amber),
        if (records.contains(RecordType.best1RM))
          _buildMiniIcon(Icons.fitness_center, Colors.orange),
        if (records.contains(RecordType.bestVolume))
          _buildMiniIcon(Icons.local_fire_department, Colors.deepOrange),
      ],
    );
  }

  Widget _buildMiniIcon(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Icon(
        icon,
        size: 12,
        color: color,
      ),
    );
  }
}
