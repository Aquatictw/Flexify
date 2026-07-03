import 'package:flutter/material.dart';
import '../../spotify/spotify_state.dart';
import '../../theme/tokens.dart';

/// Horizontal scrollable section showing recently played tracks
class RecentlyPlayedSection extends StatelessWidget {

  const RecentlyPlayedSection({
    required this.recentlyPlayed, super.key,
  });
  final List<Track> recentlyPlayed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (recentlyPlayed.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space8,
          ),
          child: Text(
            'Recently Played',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: space16),
            itemCount: recentlyPlayed.length,
            itemBuilder: (context, index) {
              final track = recentlyPlayed[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: space8),
                child: SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      // Album art
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: brSm,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: brSm,
                          child: track.artworkUrl != null
                              ? Image.network(
                                  track.artworkUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return ColoredBox(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.music_note,
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    );
                                  },
                                )
                              : ColoredBox(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.music_note,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
