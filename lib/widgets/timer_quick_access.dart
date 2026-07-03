import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../timer/timer_state.dart';

/// Quick access timer dialog that can be opened from anywhere
class TimerQuickAccessDialog extends StatefulWidget {
  const TimerQuickAccessDialog({super.key});

  @override
  State<TimerQuickAccessDialog> createState() => _TimerQuickAccessDialogState();
}

class _TimerQuickAccessDialogState extends State<TimerQuickAccessDialog> {
  Duration _selectedDuration = const Duration(minutes: 1);
  late final bool _wasTimerRunningOnOpen;

  // Preset durations
  static const List<Duration> presets = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 3),
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];

  @override
  void initState() {
    super.initState();
    _wasTimerRunningOnOpen =
        context.read<TimerState>().timer.getDuration() != Duration.zero;
  }

  void _startTimer() {
    final settings = context.read<SettingsState>().value;
    final timerState = context.read<TimerState>();

    // Close the dialog first, then start the timer
    Navigator.of(context).pop();

    // Start timer after dialog is closed
    timerState.startTimer(
      'Quick Timer',
      _selectedDuration,
      settings.alarmSound,
      settings.vibrate,
    );
  }

  Future<void> _stopTimer() async {
    final timerState = context.read<TimerState>();
    await timerState.stopTimer();

    // Close dialog after stopping timer
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timerState = context.watch<TimerState>();
    final isTimerRunning = timerState.timer.getDuration() != Duration.zero;

    // Only show running state if timer was already running when dialog opened
    final showRunningState = _wasTimerRunningOnOpen && isTimerRunning;

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: brLg,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(space12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: brSm,
                  ),
                  child: Icon(
                    Icons.timer,
                    color: colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: space16),
                Expanded(
                  child: Text(
                    showRunningState ? 'Timer Running' : 'Start Timer',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: space24),

            if (showRunningState) ...[
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filled(
                    onPressed: () {
                      final settings = context.read<SettingsState>().value;
                      timerState.subtractSeconds(
                          30, settings.alarmSound, settings.vibrate,);
                    },
                    icon: const Icon(Icons.remove),
                    tooltip: '-30s',
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      final settings = context.read<SettingsState>().value;
                      timerState.addOneMinute(
                          settings.alarmSound, settings.vibrate,);
                    },
                    child: const Text('+1 min'),
                  ),
                  IconButton.filled(
                    onPressed: _stopTimer,
                    icon: const Icon(Icons.stop),
                    tooltip: 'Stop',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Duration presets
              Wrap(
                alignment: WrapAlignment.center,
                spacing: space8,
                runSpacing: space8,
                children: presets.map((duration) {
                  final isSelected = _selectedDuration == duration;
                  return ChoiceChip(
                    label: Text(_formatDuration(duration)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDuration = duration;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: space24),

              // Start button
              FilledButton.icon(
                onPressed: _startTimer,
                icon: const Icon(Icons.play_arrow),
                label:
                    Text('Start ${_formatDuration(_selectedDuration)} Timer'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: space24, vertical: space16,),
                ),
              ),
            ],

            const SizedBox(height: space16),

            // Close button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Function to show the timer quick access dialog
Future<void> showTimerQuickAccess(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) => const TimerQuickAccessDialog(),
  );
}
