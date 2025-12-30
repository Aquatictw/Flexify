import 'dart:async';
import 'dart:ui';

import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/timer/timer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class RestTimerBar extends StatefulWidget {
  const RestTimerBar({super.key});

  @override
  State<RestTimerBar> createState() => _RestTimerBarState();
}

class _RestTimerBarState extends State<RestTimerBar>
    with SingleTickerProviderStateMixin {
  Timer? _updateTimer;
  Duration _remaining = Duration.zero;
  Duration _total = Duration.zero;
  late AnimationController _pulseController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        final timerState = context.read<TimerState>();
        final newRemaining = timerState.timer.getRemaining();
        final newTotal = timerState.timer.getDuration();

        if (_remaining != newRemaining || _total != newTotal) {
          setState(() {
            _remaining = newRemaining;
            _total = newTotal;
          });

          // Pulse animation when timer is about to end
          if (newRemaining.inSeconds <= 5 &&
              newRemaining.inSeconds > 0 &&
              !_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          } else if (newRemaining.inSeconds > 5) {
            _pulseController.stop();
            _pulseController.reset();
          }
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _adjustTime(int seconds) async {
    HapticFeedback.selectionClick();
    final timerState = context.read<TimerState>();
    final settings = context.read<SettingsState>().value;

    if (seconds > 0) {
      // Adding time
      await timerState.addSeconds(
        seconds,
        settings.alarmSound,
        settings.vibrate,
      );
    } else {
      // Subtracting time
      await timerState.subtractSeconds(
        -seconds,
        settings.alarmSound,
        settings.vibrate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = context.watch<TimerState>();
    final remaining = timerState.timer.getRemaining();
    final total = timerState.timer.getDuration();

    if (total == Duration.zero || remaining.inSeconds <= 0) {
      _pulseController.stop();
      _pulseController.reset();
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final progress = remaining.inMilliseconds / total.inMilliseconds;
    final isUrgent = remaining.inSeconds <= 10;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = isUrgent && remaining.inSeconds <= 5
            ? 1.0 + (_pulseController.value * 0.05)
            : 1.0;

        return Transform.scale(
          scale: pulseValue,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isExpanded = !_isExpanded);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUrgent
                      ? [
                          colorScheme.errorContainer,
                          colorScheme.errorContainer.withValues(alpha: 0.8),
                        ]
                      : [
                          colorScheme.tertiaryContainer,
                          colorScheme.tertiaryContainer.withValues(alpha: 0.8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isUrgent
                            ? colorScheme.error
                            : colorScheme.tertiary)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background progress indicator
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (isUrgent
                                      ? colorScheme.error
                                      : colorScheme.tertiary)
                                  .withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            stops: [progress, progress],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: _isExpanded ? 16 : 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              // Circular mini progress
                              _MiniCircularProgress(
                                progress: progress,
                                isUrgent: isUrgent,
                              ),
                              const SizedBox(width: 14),
                              // Timer display
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 16,
                                          color: isUrgent
                                              ? colorScheme.onErrorContainer
                                              : colorScheme.onTertiaryContainer,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Rest Timer',
                                          style: TextStyle(
                                            color: isUrgent
                                                ? colorScheme.onErrorContainer
                                                    .withValues(alpha: 0.7)
                                                : colorScheme.onTertiaryContainer
                                                    .withValues(alpha: 0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDuration(remaining),
                                      style: TextStyle(
                                        color: isUrgent
                                            ? colorScheme.onErrorContainer
                                            : colorScheme.onTertiaryContainer,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Time adjustment buttons (always visible)
                              _TimeAdjustButton(
                                label: '-15',
                                onPressed: () => _adjustTime(-15),
                                isUrgent: isUrgent,
                              ),
                              const SizedBox(width: 8),
                              _TimeAdjustButton(
                                label: '+15',
                                onPressed: () => _adjustTime(15),
                                isUrgent: isUrgent,
                                isAdd: true,
                              ),
                            ],
                          ),
                          // Expanded content with stop button
                          AnimatedCrossFade(
                            firstChild: const SizedBox(width: double.infinity),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.remove_circle_outline,
                                      label: '-30s',
                                      onPressed: () => _adjustTime(-30),
                                      isUrgent: isUrgent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.add_circle_outline,
                                      label: '+1min',
                                      onPressed: () => _adjustTime(60),
                                      isUrgent: isUrgent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.stop_rounded,
                                      label: 'Skip',
                                      onPressed: () async {
                                        HapticFeedback.mediumImpact();
                                        await timerState.stopTimer();
                                      },
                                      isDestructive: true,
                                      isUrgent: isUrgent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            crossFadeState: _isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniCircularProgress extends StatelessWidget {
  final double progress;
  final bool isUrgent;

  const _MiniCircularProgress({
    required this.progress,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 4,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                (isUrgent ? colorScheme.error : colorScheme.tertiary)
                    .withValues(alpha: 0.2),
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 48,
            height: 48,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: progress, end: progress),
              duration: const Duration(milliseconds: 100),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    isUrgent ? colorScheme.error : colorScheme.tertiary,
                  ),
                );
              },
            ),
          ),
          // Percentage text
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isUrgent
                  ? colorScheme.onErrorContainer
                  : colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeAdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isUrgent;
  final bool isAdd;

  const _TimeAdjustButton({
    required this.label,
    required this.onPressed,
    required this.isUrgent,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (isUrgent ? colorScheme.error : colorScheme.tertiary)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isUrgent ? colorScheme.error : colorScheme.tertiary)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isUrgent
                  ? colorScheme.onErrorContainer
                  : colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isUrgent;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isUrgent,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = isDestructive
        ? colorScheme.error.withValues(alpha: 0.15)
        : (isUrgent ? colorScheme.error : colorScheme.tertiary)
            .withValues(alpha: 0.1);

    final fgColor = isDestructive
        ? colorScheme.error
        : (isUrgent
            ? colorScheme.onErrorContainer
            : colorScheme.onTertiaryContainer);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
