import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:spotify_sdk/models/player_options.dart' as player_options;
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

import 'spotify_config.dart';

/// Singleton service wrapping Spotify SDK
/// Manages connection lifecycle and playback controls
class SpotifyService {
  factory SpotifyService() => _instance;
  SpotifyService._internal();
  static final SpotifyService _instance = SpotifyService._internal();

  static const String clientId = SpotifyConfig.clientId;
  static const String redirectUrl = SpotifyConfig.redirectUrl;
  static const List<String> scopes = SpotifyConfig.scopes;

  bool _isConnected = false;

  /// OAuth access token for Spotify Web API calls.
  /// Captured during connection and expires after 1 hour.
  String? _accessToken;

  /// Expiration timestamp for the access token.
  /// Set to 1 hour after token acquisition.
  DateTime? _tokenExpiry;

  bool get isConnected => _isConnected;

  /// Get the current access token if available.
  /// Returns null if not connected or token not yet acquired.
  /// Check [hasValidToken] to verify token is still valid.
  String? get accessToken => _accessToken;

  /// Get the token expiry time if available.
  /// Returns null if no token has been acquired.
  DateTime? get tokenExpiry => _tokenExpiry;

  /// Check if a valid, non-expired access token is available.
  /// Returns true only if token exists and hasn't expired.
  bool get hasValidToken =>
      _accessToken != null &&
      _tokenExpiry != null &&
      DateTime.now().isBefore(_tokenExpiry!);

  /// Restore tokens from previously saved values (e.g., from database)
  /// This allows reusing tokens without reconnecting
  void restoreTokens({
    required String? accessToken,
    required DateTime? tokenExpiry,
  }) {
    _accessToken = accessToken;
    _tokenExpiry = tokenExpiry;

    // ponytail: don't log the token itself (even a preview lands in logcat).
    if (accessToken != null &&
        tokenExpiry != null &&
        DateTime.now().isAfter(tokenExpiry)) {
      debugPrint('🎵 Warning: Restored token is already expired');
    }
  }

  Future<bool> connect() async {
    try {
      // ponytail: never log clientId — it's a secret in a public repo's logs.
      debugPrint('🎵 Starting Spotify connection...');
      try {
        _accessToken = await SpotifySdk.getAccessToken(
          clientId: clientId,
          redirectUrl: redirectUrl,
          scope: scopes.join(' '),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('🎵 Access token request timed out');
            throw TimeoutException('Authentication timed out.');
          },
        );
        // Token expires in 1 hour
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
        debugPrint('🎵 Access token received');
      } catch (e) {
        print('🎵 Access token error: $e');
        _accessToken = null;
        _tokenExpiry = null;
        // Continue anyway - some SDK versions don't need this step
      }

      print('🎵 Step 2: Connecting to Spotify Remote...');
      final result = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('🎵 Remote connection timed out after 30 seconds');
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );

      print('🎵 Connection result: $result');
      _isConnected = result;
      return result;
    } catch (e) {
      print('🎵 Connection error: $e');
      print('🎵 Error type: ${e.runtimeType}');
      _isConnected = false;
      rethrow;
    }
  }

  /// Disconnect from Spotify and clean up connection
  Future<void> disconnect() async {
    try {
      await SpotifySdk.disconnect();
      _isConnected = false;
      _accessToken = null;
      _tokenExpiry = null;
    } catch (e) {
      // Ignore disconnect errors
      _isConnected = false;
      _accessToken = null;
      _tokenExpiry = null;
    }
  }

  /// Toggle play/pause based on current playback state
  Future<void> togglePlayPause() async {
    try {
      final state = await SpotifySdk.getPlayerState();
      if (state?.isPaused ?? true) {
        await SpotifySdk.resume();
      } else {
        await SpotifySdk.pause();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Skip to next track
  Future<void> skipNext() async {
    try {
      await SpotifySdk.skipNext();
    } catch (e) {
      rethrow;
    }
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    try {
      await SpotifySdk.skipPrevious();
    } catch (e) {
      rethrow;
    }
  }

  /// Seek to specific position in current track
  Future<void> seekTo(int positionMs) async {
    try {
      await SpotifySdk.seekTo(positionedMilliseconds: positionMs);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle shuffle on/off
  Future<void> toggleShuffle() async {
    try {
      final state = await SpotifySdk.getPlayerState();
      final currentShuffle = state?.playbackOptions.isShuffling ?? false;
      await SpotifySdk.setShuffle(shuffle: !currentShuffle);
    } catch (e) {
      rethrow;
    }
  }

  /// Cycle through repeat modes: off → context → track → off
  Future<void> toggleRepeat() async {
    try {
      final state = await SpotifySdk.getPlayerState();
      final currentRepeat =
          state?.playbackOptions.repeatMode ?? player_options.RepeatMode.off;

      final player_options.RepeatMode nextMode;
      switch (currentRepeat) {
        case player_options.RepeatMode.off:
          nextMode = player_options.RepeatMode.context;
          break;
        case player_options.RepeatMode.context:
          nextMode = player_options.RepeatMode.track;
          break;
        case player_options.RepeatMode.track:
          nextMode = player_options.RepeatMode.off;
          break;
      }

      // Convert to SDK's RepeatMode enum for the API call
      final sdkRepeatMode = _convertToSdkRepeatMode(nextMode);
      await SpotifySdk.setRepeatMode(repeatMode: sdkRepeatMode);
    } catch (e) {
      rethrow;
    }
  }

  /// Convert player_options.RepeatMode to SDK's RepeatMode enum
  RepeatMode _convertToSdkRepeatMode(player_options.RepeatMode mode) {
    switch (mode) {
      case player_options.RepeatMode.off:
        return RepeatMode.off;
      case player_options.RepeatMode.track:
        return RepeatMode.track;
      case player_options.RepeatMode.context:
        return RepeatMode.context;
    }
  }

  /// Get current player state from Spotify
  /// Returns null if no active playback
  Future<PlayerState?> getPlayerState() async {
    try {
      return await SpotifySdk.getPlayerState();
    } catch (e) {
      return null;
    }
  }

  /// Play a specific track by Spotify URI
  /// Accepts full URI format: "spotify:track:xxxxx"
  Future<void> playTrack(String spotifyUri) async {
    try {
      await SpotifySdk.play(spotifyUri: spotifyUri);
    } catch (e) {
      print('🎵 Play track error: $e');
      rethrow;
    }
  }

  // Note: Queue API is not available in spotify_sdk package
  // Queue functionality has been removed as it's not supported
}
