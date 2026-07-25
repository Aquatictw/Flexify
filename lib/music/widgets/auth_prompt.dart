import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../spotify/spotify_state.dart';
import '../../theme/tokens.dart';
import '../../utils.dart';

/// Auth prompt widget for first-time Spotify connection
/// Displays centered card with Spotify logo, explanation, and connect button
class AuthPrompt extends StatefulWidget {
  const AuthPrompt({super.key});

  @override
  State<AuthPrompt> createState() => _AuthPromptState();
}

class _AuthPromptState extends State<AuthPrompt> {
  bool _isConnecting = false;

  Future<void> _handleConnect() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final spotifyState = context.read<SpotifyState>();
      final success = await spotifyState.connect();

      if (!mounted) return;

      if (success) {
        // Connection successful - SpotifyState will update and UI will rebuild.
        // MusicPage starts polling off the status change.
        toast('Connected to Spotify successfully');
      } else {
        // Connection failed but no exception - show generic error
        toast('Failed to connect to Spotify. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;

      // Handle specific error cases
      String errorMessage = 'Failed to connect to Spotify';

      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('not installed') ||
          errorStr.contains('spotify app')) {
        errorMessage =
            'Spotify app not installed. Please install it from the Play Store.';
      } else if (errorStr.contains('timeout') ||
          errorStr.contains('timed out')) {
        errorMessage = 'Connection timed out. Please try again.';
      } else if (errorStr.contains('network') ||
          errorStr.contains('internet')) {
        errorMessage = 'Check your internet connection and try again.';
      } else if (errorStr.contains('premium')) {
        errorMessage = 'Spotify Premium required for remote control.';
      }

      toast(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotifyState = context.watch<SpotifyState>();
    final isConnecting = _isConnecting ||
        spotifyState.connectionStatus == ConnectionStatus.connecting;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          space24,
          space24,
          space24,
          bottomBarClearance(context),
        ),
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: brLg,
            side: BorderSide(
              color: colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(space32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Spotify logo placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: brMd,
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),

                const SizedBox(height: space24),

                // Heading
                Text(
                  'Connect to Spotify',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: space12),

                // Explanation
                Text(
                  'Control your Spotify playback during workouts',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: space32),

                // Connect button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isConnecting ? null : _handleConnect,
                    icon: isConnecting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.link_rounded),
                    label: Text(
                      isConnecting ? 'Connecting...' : 'Connect with Spotify',
                      style: textTheme.labelLarge,
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: space16,
                        horizontal: space24,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: space16),

                // Info text
                Text(
                  "You'll be redirected to authorize JackedLog",
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
