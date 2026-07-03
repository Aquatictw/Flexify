import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../fivethreeone/block_creation_dialog.dart';
import '../fivethreeone/block_overview_page.dart';
import '../fivethreeone/fivethreeone_state.dart';
import '../main.dart';
import '../theme/tokens.dart';
import 'note_editor_page.dart';

/// Notes can have an arbitrary background color (preset or user-picked), so
/// foreground ink must contrast against that color, not the app theme.
Color _inkOn(Color bg) =>
    bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
Color _inkMutedOn(Color bg) =>
    bg.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70;

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Note>? _localNotes;
  bool _isReorderMode = false;

  // Artistic color palette for notes (darker shades)
  final List<Color> _noteColors = [
    const Color(0xFFFFB366), // Peach
    const Color(0xFF7DD3D3), // Mint
    const Color(0xFF6FA8FF), // Sky Blue
    const Color(0xFFFF99FF), // Pink
    const Color(0xFFFF7A7A), // Coral
    const Color(0xFFF9FF66), // Light Yellow
    const Color(0xFF7FD98A), // Mint Green
    const Color(0xFF9D8FFF), // Lavender
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getColorFromValue(int? colorValue) {
    if (colorValue == null) {
      return _noteColors[0];
    }
    // If it's a preset index (0-7), use the preset color
    if (colorValue >= 0 && colorValue < _noteColors.length) {
      return _noteColors[colorValue];
    }
    // Otherwise, treat it as a custom color value
    return Color(colorValue);
  }

  int _getRandomColorIndex() {
    return DateTime.now().millisecondsSinceEpoch % _noteColors.length;
  }

  Future<void> _createNote() async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(
          colorIndex: _getRandomColorIndex(),
        ),
      ),
    );

    if (!mounted) return;
    setState(() { _localNotes = null; });

    if (result != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note created')),
        );
      } on FlutterError catch (_) {
        // Scaffold may be deactivated during frame transition
      }
    }
  }

  Future<void> _editNote(Note note) async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(
          note: note,
          colorIndex: note.color ?? 0,
        ),
      ),
    );

    if (!mounted) return;
    setState(() { _localNotes = null; });

    if (result != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note updated')),
        );
      } on FlutterError catch (_) {
        // Scaffold may be deactivated during frame transition
      }
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await (db.notes.delete()..where((n) => n.id.equals(note.id))).go();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          if (_searchQuery.isEmpty)
            IconButton(
              icon: Icon(_isReorderMode ? Icons.grid_view : Icons.reorder),
              onPressed: () {
                setState(() {
                  _isReorderMode = !_isReorderMode;
                });
              },
              tooltip: _isReorderMode ? 'Grid View' : 'Reorder Notes',
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNote,
            tooltip: 'New Note',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: brSm,
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  _localNotes = null; // Force resync with stream
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Note>>(
        stream: (db.notes.select()
              ..orderBy([
                (n) =>
                    OrderingTerm(expression: n.sequence, mode: OrderingMode.desc),
              ]))
            .watch(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var notes = snapshot.data!;

          // Filter by search query
          if (_searchQuery.isNotEmpty) {
            notes = notes.where((note) {
              return note.title.toLowerCase().contains(_searchQuery) ||
                  note.content.toLowerCase().contains(_searchQuery);
            }).toList();
          }

          if (notes.isEmpty && _searchQuery.isNotEmpty) {
            return Column(
              children: [
                const _TrainingMaxBanner(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_outlined,
                          size: 80,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notes found',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (notes.isEmpty) {
            return Column(
              children: [
                const _TrainingMaxBanner(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add_outlined,
                          size: 80,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notes yet',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _createNote,
                          icon: const Icon(Icons.add),
                          label: const Text('Create your first note'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Sync stream data to _localNotes when it changes
          if (_localNotes == null || _searchQuery.isNotEmpty) {
            _localNotes = List.from(notes);
          }

          final colorScheme = Theme.of(context).colorScheme;

          return Column(
            children: [
              const _TrainingMaxBanner(),
              Expanded(
                child: _isReorderMode && _searchQuery.isEmpty
                    // ReorderableListView when in reorder mode (list layout)
                    ? ReorderableListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          space12,
                          space8,
                          space12,
                          bottomBarClearance(context),
                        ),
                        itemCount: _localNotes!.length,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 8,
                            shadowColor:
                                colorScheme.shadow.withValues(alpha: 0.3),
                            borderRadius: brMd,
                            child: child,
                          );
                        },
                        onReorder: (oldIndex, newIndex) async {
                          if (oldIndex < newIndex) newIndex--;

                          setState(() {
                            final item = _localNotes!.removeAt(oldIndex);
                            _localNotes!.insert(newIndex, item);
                          });

                          // Batch update sequences (highest index = highest sequence = top of list)
                          await db.batch((batch) {
                            for (var i = 0; i < _localNotes!.length; i++) {
                              batch.update(
                                db.notes,
                                NotesCompanion(
                                    sequence:
                                        Value(_localNotes!.length - 1 - i)),
                                where: (n) => n.id.equals(_localNotes![i].id),
                              );
                            }
                          });
                        },
                        itemBuilder: (context, index) {
                          final note = _localNotes![index];
                          final color = _getColorFromValue(note.color);
                          return _NoteCard(
                            key: ValueKey(note.id),
                            note: note,
                            color: color,
                            onTap: () => _editNote(note),
                            onDelete: () => _deleteNote(note),
                            isGridMode: false,
                          );
                        },
                      )
                    // GridView as default with drag-to-reorder support
                    : _ReorderableGridView(
                        notes: _localNotes!,
                        getColorFromValue: _getColorFromValue,
                        onEditNote: _editNote,
                        onDeleteNote: _deleteNote,
                        onReorder: (oldIndex, newIndex) async {
                          setState(() {
                            final item = _localNotes!.removeAt(oldIndex);
                            _localNotes!.insert(newIndex, item);
                          });

                          // Batch update sequences
                          await db.batch((batch) {
                            for (var i = 0; i < _localNotes!.length; i++) {
                              batch.update(
                                db.notes,
                                NotesCompanion(
                                    sequence:
                                        Value(_localNotes!.length - 1 - i)),
                                where: (n) => n.id.equals(_localNotes![i].id),
                              );
                            }
                          });
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrainingMaxBanner extends StatelessWidget {
  const _TrainingMaxBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fiveThreeOneState = context.watch<FiveThreeOneState>();
    final hasBlock = fiveThreeOneState.hasActiveBlock;

    final backgroundColor = hasBlock
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;
    final textColor = hasBlock
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final iconColor = hasBlock
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final label = hasBlock
        ? fiveThreeOneState.positionLabel
        : 'Start a 5/3/1 block \u2192';

    return Container(
      margin: const EdgeInsets.fromLTRB(space12, space8, space12, space4),
      child: Material(
        elevation: 3,
        borderRadius: brMd,
        color: backgroundColor,
        child: InkWell(
          onTap: () {
            if (hasBlock) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BlockOverviewPage(),
                ),
              );
            } else {
              showDialog(
                context: context,
                builder: (_) => const BlockCreationDialog(),
              );
            }
          },
          borderRadius: brMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: space16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: brMd,
              gradient: LinearGradient(
                colors: [
                  backgroundColor,
                  backgroundColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: brSm,
                  ),
                  child: hasBlock
                      ? Text(
                          fiveThreeOneState.cycleBadge,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: iconColor),
                        )
                      : Icon(
                          Icons.fitness_center,
                          size: 24,
                          color: iconColor,
                        ),
                ),
                const SizedBox(width: space16),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: textColor,
                          letterSpacing: 0.2,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: iconColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReorderableGridView extends StatefulWidget {
  const _ReorderableGridView({
    required this.notes,
    required this.getColorFromValue,
    required this.onEditNote,
    required this.onDeleteNote,
    required this.onReorder,
  });

  final List<Note> notes;
  final Color Function(int?) getColorFromValue;
  final void Function(Note) onEditNote;
  final void Function(Note) onDeleteNote;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<_ReorderableGridView> createState() => _ReorderableGridViewState();
}

class _ReorderableGridViewState extends State<_ReorderableGridView> {
  int? _draggedIndex;
  int? _targetIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        space12,
        space8,
        space12,
        bottomBarClearance(context),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: space12,
        mainAxisSpacing: space12,
      ),
      itemCount: widget.notes.length,
      itemBuilder: (context, index) {
        final note = widget.notes[index];
        final color = widget.getColorFromValue(note.color);
        final isDragging = _draggedIndex == index;
        final isTarget = _targetIndex == index && _draggedIndex != index;

        return DragTarget<int>(
          onWillAcceptWithDetails: (details) {
            if (details.data != index) {
              setState(() => _targetIndex = index);
              return true;
            }
            return false;
          },
          onLeave: (_) {
            setState(() => _targetIndex = null);
          },
          onAcceptWithDetails: (details) {
            widget.onReorder(details.data, index);
            setState(() {
              _draggedIndex = null;
              _targetIndex = null;
            });
          },
          builder: (context, candidateData, rejectedData) {
            return LongPressDraggable<int>(
              data: index,
              delay: durFast,
              onDragStarted: () {
                setState(() => _draggedIndex = index);
              },
              onDragEnd: (_) {
                setState(() {
                  _draggedIndex = null;
                  _targetIndex = null;
                });
              },
              feedback: Material(
                elevation: 8,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
                borderRadius: brMd,
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width - 36) / 2,
                  height: ((MediaQuery.of(context).size.width - 36) / 2) / 0.85,
                  child: _NoteCard(
                    note: note,
                    color: color,
                    onTap: () {},
                    onDelete: () {},
                    isGridMode: true,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _NoteCard(
                  note: note,
                  color: color,
                  onTap: () {},
                  onDelete: () {},
                  isGridMode: true,
                ),
              ),
              child: AnimatedContainer(
                duration: durMed,
                curve: curveStandard,
                decoration: isTarget
                    ? BoxDecoration(
                        borderRadius: brMd,
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      )
                    : null,
                child: Opacity(
                  opacity: isDragging ? 0.3 : 1.0,
                  child: _NoteCard(
                    note: note,
                    color: color,
                    onTap: () => widget.onEditNote(note),
                    onDelete: () => widget.onDeleteNote(note),
                    isGridMode: true,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    super.key,
    required this.note,
    required this.color,
    required this.onTap,
    required this.onDelete,
    this.isGridMode = false,
  });
  final Note note;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isGridMode;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');
    final ink = _inkOn(color);
    final inkMuted = _inkMutedOn(color);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      color: color,
      margin:
          isGridMode ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 6),
      shape: const RoundedRectangleBorder(
        borderRadius: brMd,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: brMd,
        child: Padding(
          padding: const EdgeInsets.all(space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: isGridMode ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: textTheme.titleMedium?.copyWith(color: ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: inkMuted,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: space8),
                isGridMode
                    ? Expanded(
                        child: Text(
                          note.content,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: ink, height: 1.4),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : Text(
                        note.content,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: ink, height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
              const SizedBox(height: space12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: inkMuted,
                  ),
                  const SizedBox(width: space4),
                  Flexible(
                    child: Text(
                      '${dateFormat.format(note.updated)} ${timeFormat.format(note.updated)}',
                      style: textTheme.labelSmall?.copyWith(color: inkMuted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
