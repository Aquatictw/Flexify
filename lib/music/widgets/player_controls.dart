import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify_sdk/models/player_options.dart' as player_options;

import '../../spotify/spotify_service.dart';
import '../../spotify/spotify_state.dart';
import '../../theme/tokens.dart';
import '../../utils.dart';

/// Player controls widget for Spotify playback
/// Displays primary control buttons: shuffle, previous, play/pause, next, repeat
/// Follows Material Design 3 patterns matching app theme
class PlayerControls extends StatefulWidget {
  const PlayerControls({super.key});

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  final SpotifyService _service = SpotifyService();

  // Debouncing mechanism - tracks last action time for each button
  DateTime? _lastPlayPauseAction;
  DateTime? _lastSkipNextAction;
  DateTime? _lastSkipPreviousAction;
  DateTime? _lastShuffleAction;
  DateTime? _lastRepeatAction;

  // Debounce duration: 300ms prevents race conditions
  static const _debounceDuration = Duration(milliseconds: 300);

  /// Check if enough time has passed since last action
  bool _canPerformAction(DateTime? lastAction) {
    if (lastAction == null) return true;
    return DateTime.now().difference(lastAction) >= _debounceDuration;
  }

  /// Handle play/pause toggle with debouncing
  Future<void> _handlePlayPause() async {
    if (!_canPerformAction(_lastPlayPauseAction)) return;

    setState(() {
      _lastPlayPauseAction = DateTime.now();
    });

    try {
      await _service.togglePlayPause();
      // State will update via polling in SpotifyState
    } catch (e) {
      if (!mounted) return;
      toast('Failed to toggle playback');
    }
  }

  /// Handle skip to next track with debouncing
  Future<void> _handleSkipNext() async {
    if (!_canPerformAction(_lastSkipNextAction)) return;

    setState(() {
      _lastSkipNextAction = DateTime.now();
    });

    try {
      await _service.skipNext();
      // State will update via polling
    } catch (e) {
      if (!mounted) return;
      toast('Failed to skip to next track');
    }
  }

  /// Handle skip to previous track with debouncing
  Future<void> _handleSkipPrevious() async {
    if (!_canPerformAction(_lastSkipPreviousAction)) return;

    setState(() {
      _lastSkipPreviousAction = DateTime.now();
    });

    try {
      await _service.skipPrevious();
      // State will update via polling
    } catch (e) {
      if (!mounted) return;
      toast('Failed to skip to previous track');
    }
  }

  /// Handle shuffle toggle with debouncing
  Future<void> _handleToggleShuffle() async {
    if (!_canPerformAction(_lastShuffleAction)) return;

    setState(() {
      _lastShuffleAction = DateTime.now();
    });

    try {
      await _service.toggleShuffle();
      // State will update via polling
    } catch (e) {
      if (!mounted) return;
      toast('Failed to toggle shuffle');
    }
  }

  /// Handle repeat mode toggle with debouncing
  /// Cycles: off → context → track → off
  Future<void> _handleToggleRepeat() async {
    if (!_canPerformAction(_lastRepeatAction)) return;

    setState(() {
      _lastRepeatAction = DateTime.now();
    });

    try {
      await _service.toggleRepeat();
      // State will update via polling
    } catch (e) {
      if (!mounted) return;
      toast('Failed to toggle repeat mode');
    }
  }

  /// Get appropriate icon for repeat mode
  IconData _getRepeatIcon(player_options.RepeatMode mode) {
    switch (mode) {
      case player_options.RepeatMode.off:
        return Icons.repeat_rounded;
      case player_options.RepeatMode.context:
        return Icons.repeat_rounded;
      case player_options.RepeatMode.track:
        return Icons.repeat_one_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotifyState = context.watch<SpotifyState>();
    final colorScheme = Theme.of(context).colorScheme;

    // Determine if controls should be enabled
    final hasActivePlayback = spotifyState.currentPlayerState != null;
    final isConnected =
        spotifyState.connectionStatus == ConnectionStatus.connected;
    final controlsEnabled = hasActivePlayback && isConnected;

    final isPaused = spotifyState.isPaused;
    final isShuffling = spotifyState.isShuffling;
    final repeatMode = spotifyState.repeatMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: space16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle button
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            iconSize: 28,
            color: controlsEnabled
                ? (isShuffling
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant)
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            onPressed: controlsEnabled ? _handleToggleShuffle : null,
            tooltip: 'Shuffle',
            padding: const EdgeInsets.all(space12),
            constraints: const BoxConstraints(
              minWidth: 56,
              minHeight: 56,
            ),
          ),

          // Previous track button
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded),
            iconSize: 36,
            color: controlsEnabled
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            onPressed: controlsEnabled ? _handleSkipPrevious : null,
            tooltip: 'Previous',
            padding: const EdgeInsets.all(space12),
            constraints: const BoxConstraints(
              minWidth: 56,
              minHeight: 56,
            ),
          ),

          // Play/Pause button (large circular)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: controlsEnabled
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
            ),
            child: IconButton(
              icon: Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              ),
              iconSize: 36,
              color: controlsEnabled
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
              onPressed: controlsEnabled ? _handlePlayPause : null,
              tooltip: isPaused ? 'Play' : 'Pause',
            ),
          ),

          // Next track button
          IconButton(
            icon: const Icon(Icons.skip_next_rounded),
            iconSize: 36,
            color: controlsEnabled
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            onPressed: controlsEnabled ? _handleSkipNext : null,
            tooltip: 'Next',
            padding: const EdgeInsets.all(space12),
            constraints: const BoxConstraints(
              minWidth: 56,
              minHeight: 56,
            ),
          ),

          // Repeat mode button
          IconButton(
            icon: Icon(_getRepeatIcon(repeatMode)),
            iconSize: 28,
            color: controlsEnabled
                ? (repeatMode != player_options.RepeatMode.off
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant)
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            onPressed: controlsEnabled ? _handleToggleRepeat : null,
            tooltip: 'Repeat',
            padding: const EdgeInsets.all(space12),
            constraints: const BoxConstraints(
              minWidth: 56,
              minHeight: 56,
            ),
          ),
        ],
      ),
    );
  }
}
