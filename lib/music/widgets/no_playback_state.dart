import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/tokens.dart';

/// Widget displayed when user is authenticated but no Spotify playback is active.
/// Shows placeholder UI with disabled controls and an "Open Spotify" button.
class NoPlaybackState extends StatefulWidget {

  const NoPlaybackState({
    super.key,
    this.onRefresh,
  });
  /// Callback triggered when playback state should be refreshed
  final VoidCallback? onRefresh;

  @override
  State<NoPlaybackState> createState() => _NoPlaybackStateState();
}

class _NoPlaybackStateState extends State<NoPlaybackState> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 2 seconds to detect when playback starts
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => widget.onRefresh?.call(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _openSpotify() async {
    // Try to launch Spotify app directly (Android package name)
    final spotifyUri = Uri.parse('spotify://');
    final playStoreUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.spotify.music',
    );

    try {
      // Try to open Spotify app
      final canLaunch = await canLaunchUrl(spotifyUri);
      if (canLaunch) {
        await launchUrl(spotifyUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Play Store if Spotify not installed
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Spotify')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(space16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: space32),

          // Placeholder album art
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: brSm,
            ),
            child: Icon(
              Icons.music_note_rounded,
              size: 120,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),

          const SizedBox(height: space32),

          // Track title
          Text(
            'No track playing',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: space8),

          // Artist/instruction text
          Text(
            'Open Spotify and start playing',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: space32),

          // Disabled seek bar
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: 0,
                  onChanged: null, // Disabled
                  activeColor:
                      colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                  inactiveColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: space24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0:00',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      '0:00',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: space24),

          // Disabled playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Shuffle button (disabled)
              IconButton(
                icon: const Icon(Icons.shuffle_rounded),
                iconSize: 28,
                onPressed: null,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),

              // Previous button (disabled)
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 40,
                onPressed: null,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),

              // Play/Pause button (disabled)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 40,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),

              // Next button (disabled)
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 40,
                onPressed: null,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),

              // Repeat button (disabled)
              IconButton(
                icon: const Icon(Icons.repeat_rounded),
                iconSize: 28,
                onPressed: null,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ],
          ),

          const SizedBox(height: space32),

          // "Open Spotify" button
          FilledButton.icon(
            onPressed: _openSpotify,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open Spotify'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: space32, vertical: space16),
            ),
          ),

          const SizedBox(height: space16),

          // Helpful hint
          Text(
            'Playback state will update automatically',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: bottomBarClearance(context)),
        ],
      ),
    );
  }
}
