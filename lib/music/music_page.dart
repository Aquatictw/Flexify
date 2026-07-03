import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../spotify/spotify_state.dart';
import '../theme/tokens.dart';
import 'widgets/animated_equalizer.dart';
import 'widgets/auth_prompt.dart';
import 'widgets/no_playback_state.dart';
import 'widgets/player_controls.dart';
import 'widgets/queue_bottom_sheet.dart';
import 'widgets/recently_played_bottom_sheet.dart';
import 'widgets/seek_bar.dart';

/// Main UI widget for the Music tab
/// Provides Spotify remote control interface during workouts
class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  @override
  void initState() {
    super.initState();
    // Start polling when page initializes if already connected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final spotifyState = context.read<SpotifyState>();
      if (spotifyState.connectionStatus == ConnectionStatus.connected) {
        spotifyState.startPolling();
      }
    });
  }

  @override
  void dispose() {
    // Stop polling when page is disposed
    context.read<SpotifyState>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spotifyState = context.watch<SpotifyState>();
    final theme = Theme.of(context);

    // Determine which UI to render based on connection status
    if (spotifyState.connectionStatus == ConnectionStatus.disconnected ||
        spotifyState.connectionStatus == ConnectionStatus.connecting) {
      return const AuthPrompt();
    }

    // Connected but no active playback
    if (spotifyState.currentPlayerState == null ||
        spotifyState.currentTrack.artworkUrl == null) {
      return const NoPlaybackState();
    }

    // Active playback - render full player UI
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              spotifyState.currentTrack.dominantColor?.withValues(alpha: 0.3) ??
                  theme.colorScheme.surface,
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: space24,
                    vertical: space16,
                  ),
                  child: Column(
                    children: [
                      // Add top spacing to center content vertically
                      const SizedBox(height: 40),

                      // Large album art
                      _buildAlbumArt(context, spotifyState),
                      const SizedBox(height: space32),

                      // Track name (bold, large text)
                      _buildTrackTitle(theme, spotifyState),
                      const SizedBox(height: 4),

                      // Artist name (medium gray text)
                      _buildArtistName(theme, spotifyState),
                      const SizedBox(height: 6),

                      // Album name with music note icon
                      _buildAlbumName(theme, spotifyState),
                      const SizedBox(height: 4),

                      // Playing from context
                      _buildPlayingFromContext(theme, spotifyState),
                      const SizedBox(height: space24),

                      // Seek bar with position/duration
                      const SeekBar(),
                      const SizedBox(height: 4),

                      // Player controls (shuffle, previous, play/pause, next, repeat)
                      const PlayerControls(),
                      const SizedBox(height: space8),

                      // Action buttons row (Queue and Recently Played)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // View Queue button
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: _buildViewQueueButton(context),
                            ),
                          ),
                          // View Recently Played button
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: _buildRecentlyPlayedButton(context),
                            ),
                          ),
                        ],
                      ),

                      // Clear the floating nav/timer/active-workout bars.
                      SizedBox(height: bottomBarClearance(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build album art widget with fallback placeholder
  Widget _buildAlbumArt(BuildContext context, SpotifyState spotifyState) {
    final screenWidth = MediaQuery.of(context).size.width;
    final artSize = (screenWidth * 0.65).clamp(200.0, 300.0);

    return Container(
      width: artSize,
      height: artSize,
      decoration: BoxDecoration(
        borderRadius: brMd,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: brMd,
        child: spotifyState.currentTrack.artworkUrl != null
            ? Image.network(
                spotifyState.currentTrack.artworkUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderArt(context);
                },
              )
            : _buildPlaceholderArt(context),
      ),
    );
  }

  /// Placeholder album art for when image is unavailable
  Widget _buildPlaceholderArt(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 120,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Build track title with animated equalizer for playback indication
  Widget _buildTrackTitle(ThemeData theme, SpotifyState spotifyState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated equalizer (only when playing)
        if (!spotifyState.isPaused)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedEqualizer(
              color: theme.colorScheme.primary,
              size: 20,
              isPlaying: !spotifyState.isPaused,
            ),
          ),
        // Track title
        Flexible(
          child: Text(
            spotifyState.currentTrack.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build artist name with medium gray styling
  Widget _buildArtistName(ThemeData theme, SpotifyState spotifyState) {
    return Text(
      spotifyState.currentTrack.artist,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build album name with album icon
  Widget _buildAlbumName(ThemeData theme, SpotifyState spotifyState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.album,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            spotifyState.currentTrack.album,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build playing from context (playlist/album name)
  Widget _buildPlayingFromContext(ThemeData theme, SpotifyState spotifyState) {
    if (spotifyState.playingFromName == null) {
      return const SizedBox.shrink();
    }

    final IconData contextIcon;
    switch (spotifyState.playingFromType) {
      case 'playlist':
        contextIcon = Icons.playlist_play;
        break;
      case 'album':
        contextIcon = Icons.album;
        break;
      case 'artist':
        contextIcon = Icons.person;
        break;
      default:
        contextIcon = Icons.music_note;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          contextIcon,
          size: 12,
          color: theme.colorScheme.primary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Playing from ${spotifyState.playingFromName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build "View Queue" button that opens queue bottom sheet
  Widget _buildViewQueueButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          builder: (context) => const QueueBottomSheet(),
        );
      },
      icon: const Icon(Icons.queue_music),
      label: const Text('Queue'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: space16, vertical: space12),
      ),
    );
  }

  /// Build "Recently Played" button that opens recently played bottom sheet
  Widget _buildRecentlyPlayedButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          builder: (context) => const RecentlyPlayedBottomSheet(),
        );
      },
      icon: const Icon(Icons.history),
      label: const Text('Recent'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: space16, vertical: space12),
      ),
    );
  }
}
