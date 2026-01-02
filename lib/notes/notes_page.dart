import 'package:drift/drift.dart' hide Column;
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/notes/note_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Artistic color palette for notes
  final List<Color> _noteColors = [
    const Color(0xFFFFD6A5), // Peach
    const Color(0xFFCAFAFA), // Mint
    const Color(0xFFA0C4FF), // Sky Blue
    const Color(0xFFFFC6FF), // Pink
    const Color(0xFFFFADAD), // Coral
    const Color(0xFFFDFFB6), // Light Yellow
    const Color(0xFFB9FBC0), // Mint Green
    const Color(0xFFBDB2FF), // Lavender
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getColorFromValue(int? colorValue) {
    if (colorValue == null || colorValue < 0 || colorValue >= _noteColors.length) {
      return _noteColors[0];
    }
    return _noteColors[colorValue];
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

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note created')),
      );
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

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note updated')),
      );
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

    if (confirm == true) {
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
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNote,
            tooltip: 'New Note',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Note>>(
        stream: (db.notes.select()
              ..orderBy([
                (n) => OrderingTerm(expression: n.updated, mode: OrderingMode.desc)
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

          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? 'No notes yet' : 'No notes found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_searchQuery.isEmpty)
                    TextButton.icon(
                      onPressed: _createNote,
                      icon: const Icon(Icons.add),
                      label: const Text('Create your first note'),
                    ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final color = _getColorFromValue(note.color);

              return _NoteCard(
                note: note,
                color: color,
                onTap: () => _editNote(note),
                onDelete: () => _deleteNote(note),
              );
            },
          );
        },
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      elevation: 2,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.black54,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  note.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(note.updated)} ${timeFormat.format(note.updated)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
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
