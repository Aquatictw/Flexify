import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../spotify/spotify_service.dart';
import '../../spotify/spotify_state.dart';
import '../../theme/tokens.dart';

/// Seek bar widget for Spotify playback position control
/// Displays current position, total duration, and interactive slider
class SeekBar extends StatefulWidget {
  const SeekBar({super.key});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  final SpotifyService _service = SpotifyService();

  // Local position tracking for smooth UI during seeking
  int? _localPositionMs;

  @override
  Widget build(BuildContext context) {
    final spotifyState = context.watch<SpotifyState>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use local position if seeking, otherwise use state position
    final positionMs = _localPositionMs ?? spotifyState.positionMs;
    final durationMs = spotifyState.durationMs;

    // Calculate slider value (0.0 to 1.0)
    // Handle edge cases: division by zero, null duration
    final sliderValue =
        durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

    // Format times as M:SS (e.g., "3:45", not "03:45")
    final currentTime = _formatTime(positionMs);
    final totalTime = _formatTime(durationMs);

    // Disable slider if no active playback
    final isEnabled = durationMs > 0 &&
        spotifyState.connectionStatus == ConnectionStatus.connected;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: sliderValue,
            onChanged: isEnabled ? _onSliderChanged : null,
            onChangeStart: isEnabled ? _onSliderChangeStart : null,
            onChangeEnd: isEnabled ? _onSliderChangeEnd : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: space24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentTime,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                totalTime,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Called when user starts dragging the slider
  void _onSliderChangeStart(double value) {
    // Mark that seeking has started (no state needed currently)
  }

  /// Called while user is dragging the slider
  /// Updates local position immediately for smooth UI
  void _onSliderChanged(double value) {
    final spotifyState = context.read<SpotifyState>();
    final durationMs = spotifyState.durationMs;

    setState(() {
      _localPositionMs = (value * durationMs).round();
    });
  }

  /// Called when user finishes dragging the slider
  /// Commits the seek operation to Spotify
  Future<void> _onSliderChangeEnd(double value) async {
    final spotifyState = context.read<SpotifyState>();
    final durationMs = spotifyState.durationMs;
    final targetPositionMs = (value * durationMs).round();

    // Call SpotifyService.seekTo with new position
    try {
      await _service.seekTo(targetPositionMs);
    } catch (e) {
      // Ignore seek errors - polling will sync position
    }

    setState(() {
      _localPositionMs = null;
    });
  }

  /// Format milliseconds as M:SS (e.g., "3:45", not "03:45")
  String _formatTime(int ms) {
    final seconds = (ms / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
