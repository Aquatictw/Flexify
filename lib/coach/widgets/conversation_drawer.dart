import 'package:flutter/material.dart';

import '../../database/database.dart';

/// The Coach tab's conversation sidebar.
///
/// Lists ad-hoc threads newest-activity first and lets you start, switch to, or
/// delete one. Workout threads are deliberately absent: their write tools
/// target the *live* session, so reopening one from the tab would put it in a
/// context it was never written in.
class ConversationDrawer extends StatelessWidget {
  const ConversationDrawer({
    required this.threads,
    required this.currentThreadId,
    required this.runningThreadIds,
    required this.onNewThread,
    required this.onOpenThread,
    required this.onDeleteThread,
    required this.bottomPadding,
    super.key,
  });

  /// Clearance for the home Stack's pill nav, which is painted *above* this
  /// drawer — without it the last conversation in the list sits under the nav.
  final double bottomPadding;

  final List<ChatThread> threads;

  /// Null while the open conversation is still unsaved, in which case "New
  /// conversation" is the selected row.
  final int? currentThreadId;

  /// Threads whose reply is still generating. A turn keeps running in the
  /// conversation it was sent from, so one you have switched away from can still
  /// be working — the row says so instead of looking finished.
  final Set<int> runningThreadIds;

  final VoidCallback onNewThread;
  final ValueChanged<int> onOpenThread;
  final ValueChanged<ChatThread> onDeleteThread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Conversations',
                style: theme.textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New conversation'),
              selected: currentThreadId == null,
              onTap: () {
                Navigator.pop(context);
                onNewThread();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: threads.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Past conversations show up here.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: bottomPadding),
                      itemCount: threads.length,
                      itemBuilder: (context, index) {
                        final thread = threads[index];
                        final running = runningThreadIds.contains(thread.id);
                        return ListTile(
                          key: ValueKey('coach-thread-${thread.id}'),
                          title: Text(
                            thread.title ?? 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            running ? 'Replying…' : _relativeDay(thread.updated),
                          ),
                          selected: thread.id == currentThreadId,
                          onTap: () {
                            Navigator.pop(context);
                            onOpenThread(thread.id);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete conversation',
                            onPressed: () => onDeleteThread(thread),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeDay(DateTime when) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(when.year, when.month, when.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  return '${when.year}-${_two(when.month)}-${_two(when.day)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
