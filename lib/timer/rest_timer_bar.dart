import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import 'timer_state.dart';

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TimerState notifies on start/stop/adjust/native tick. Remaining time is
    // derived from the wall clock, so we only need to poll while a timer is
    // actually counting down — an idle bar does no periodic work at all.
    _syncUpdateTimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Run the 100 ms poll only while there is time left on the clock.
  void _syncUpdateTimer() {
    final timerState = context.read<TimerState>();
    final running = timerState.timer.getDuration() != Duration.zero &&
        timerState.timer.getRemaining().inMilliseconds > 0;

    if (running == (_updateTimer != null)) return;
    if (!running) {
      _updateTimer?.cancel();
      _updateTimer = null;
      return;
    }
    _updateTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final timerState = context.read<TimerState>();
    final newRemaining = timerState.timer.getRemaining();
    final newTotal = timerState.timer.getDuration();

    if (_remaining == newRemaining && _total == newTotal) return;

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

    // Countdown finished (or was cleared): stop polling until the next start.
    // Rescheduled rather than cancelled inline so the timer callback isn't
    // cancelling the timer it is running inside.
    if (newTotal == Duration.zero || newRemaining.inMilliseconds <= 0) {
      scheduleMicrotask(_syncUpdateTimer);
    }
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

        return Align(
          alignment: Alignment.centerLeft,
          child: Transform.scale(
            scale: pulseValue,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isExpanded = !_isExpanded);
              },
              child: AnimatedContainer(
                duration: durMed,
                curve: curveStandard,
                margin: const EdgeInsets.only(left: space16, top: space4),
                padding: EdgeInsets.symmetric(
                  horizontal: space12,
                  vertical: _isExpanded ? space12 : space8,
                ),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? colorScheme.errorContainer
                      : colorScheme.tertiaryContainer,
                  borderRadius: brMd,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isUrgent ? colorScheme.error : colorScheme.tertiary)
                              .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circular mini progress
                        _MiniCircularProgress(
                          progress: progress,
                          isUrgent: isUrgent,
                        ),
                        const SizedBox(width: space8),
                        // Timer display
                        Text(
                          _formatDuration(remaining),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontSize: 22,
                            color: isUrgent
                                ? colorScheme.onErrorContainer
                                : colorScheme.onTertiaryContainer,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: space8),
                        // Time adjustment buttons
                        _TimeAdjustButton(
                          label: '-15',
                          onPressed: () => _adjustTime(-15),
                          isUrgent: isUrgent,
                        ),
                        const SizedBox(width: space4),
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
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: space8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _CompactActionButton(
                              icon: Icons.remove,
                              label: '30s',
                              onPressed: () => _adjustTime(-30),
                              isUrgent: isUrgent,
                            ),
                            const SizedBox(width: space4),
                            _CompactActionButton(
                              icon: Icons.add,
                              label: '1m',
                              onPressed: () => _adjustTime(60),
                              isUrgent: isUrgent,
                            ),
                            const SizedBox(width: space4),
                            _CompactActionButton(
                              icon: Icons.close,
                              label: 'Skip',
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                await timerState.stopTimer();
                              },
                              isDestructive: true,
                              isUrgent: isUrgent,
                            ),
                          ],
                        ),
                      ),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: durFast,
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
  const _MiniCircularProgress({
    required this.progress,
    required this.isUrgent,
  });
  final double progress;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 3,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                (isUrgent ? colorScheme.error : colorScheme.tertiary)
                    .withValues(alpha: 0.2),
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 36,
            height: 36,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: progress, end: progress),
              duration: const Duration(milliseconds: 100),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    isUrgent ? colorScheme.error : colorScheme.tertiary,
                  ),
                );
              },
            ),
          ),
          // Timer icon instead of percentage
          Icon(
            Icons.timer,
            size: 16,
            color: isUrgent
                ? colorScheme.onErrorContainer
                : colorScheme.onTertiaryContainer,
          ),
        ],
      ),
    );
  }
}

class _TimeAdjustButton extends StatelessWidget {
  const _TimeAdjustButton({
    required this.label,
    required this.onPressed,
    required this.isUrgent,
    this.isAdd = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool isUrgent;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: brSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: space8,
            vertical: space4,
          ),
          decoration: BoxDecoration(
            color: (isUrgent ? colorScheme.error : colorScheme.tertiary)
                .withValues(alpha: 0.15),
            borderRadius: brSm,
            border: Border.all(
              color: (isUrgent ? colorScheme.error : colorScheme.tertiary)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  color: isUrgent
                      ? colorScheme.onErrorContainer
                      : colorScheme.onTertiaryContainer,
                ),
          ),
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isUrgent,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isUrgent;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = isDestructive
        ? colorScheme.error.withValues(alpha: 0.2)
        : (isUrgent ? colorScheme.error : colorScheme.tertiary)
            .withValues(alpha: 0.15);

    final fgColor = isDestructive
        ? colorScheme.error
        : (isUrgent
            ? colorScheme.onErrorContainer
            : colorScheme.onTertiaryContainer);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: brSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: space8,
            vertical: space4,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: brSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fgColor),
              const SizedBox(width: space4),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: fgColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
