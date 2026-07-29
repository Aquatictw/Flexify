import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../spotify/spotify_state.dart';
import '../../theme/tokens.dart';

/// Shows the Spotify playback queue in a bottom sheet
/// Displays upcoming tracks with album art, title, and artist
void showQueueBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const QueueBottomSheet(),
  );
}

class QueueBottomSheet extends StatelessWidget {
  const QueueBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spotifyState = Provider.of<SpotifyState>(context);
    final queue = spotifyState.queue;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.7,
      expand: false,
      snap: true,
      snapSizes: const [0.7],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusLg)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(space16, space4, space16, space8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(space8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: brSm,
                      ),
                      child: Icon(
                        Icons.queue_music,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: space8),
                    Text(
                      'Queue',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Queue list or empty state
              Expanded(
                child: queue.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.queue_music,
                              size: 48,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: space12),
                            Text(
                              'Queue is empty',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: space4),
                            Text(
                              'Add songs to your queue in Spotify',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: space16),
                        itemCount: queue.length,
                        itemBuilder: (context, index) {
                          final track = queue[index];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: space16,
                              vertical: space4,
                            ),
                            onTap: track.uri != null
                                ? () async {
                                    try {
                                      await spotifyState.playTrack(track.uri!);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Failed to play track: $e',),),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: brSm,
                                color: colorScheme.surfaceContainerHighest,
                              ),
                              child: track.artworkUrl != null
                                  ? ClipRRect(
                                      borderRadius: brSm,
                                      child: Image.network(
                                        track.artworkUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(
                                            Icons.music_note,
                                            color: colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.music_note,
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                            ),
                            title: Text(
                              track.title,
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              track.artist,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
