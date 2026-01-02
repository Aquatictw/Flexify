import 'package:drift/drift.dart' hide Column;
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flutter/material.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;
  final int colorIndex;

  const NoteEditorPage({
    super.key,
    this.note,
    required this.colorIndex,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late int _selectedColorIndex;

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

  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedColorIndex = widget.colorIndex;

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isModified = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note is empty')),
      );
      return;
    }

    final now = DateTime.now();

    if (widget.note == null) {
      // Create new note
      final companion = NotesCompanion.insert(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        created: now,
        updated: now,
        color: Value(_selectedColorIndex),
      );
      final id = await db.notes.insertOne(companion);
      final note = await (db.notes.select()..where((n) => n.id.equals(id))).getSingle();
      if (mounted) {
        Navigator.pop(context, note);
      }
    } else {
      // Update existing note
      final companion = NotesCompanion(
        id: Value(widget.note!.id),
        title: Value(title.isEmpty ? 'Untitled' : title),
        content: Value(content),
        updated: Value(now),
        color: Value(_selectedColorIndex),
      );
      await db.notes.update().replace(companion);
      final note = await (db.notes.select()..where((n) => n.id.equals(widget.note!.id))).getSingle();
      if (mounted) {
        Navigator.pop(context, note);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isModified) {
      return true;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save changes?'),
        content: const Text('You have unsaved changes. Do you want to save them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      await _saveNote();
      return false;
    }

    return shouldSave == false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _noteColors[_selectedColorIndex],
        appBar: AppBar(
          backgroundColor: _noteColors[_selectedColorIndex],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.black87),
              onPressed: _saveNote,
              tooltip: 'Save',
            ),
          ],
        ),
        body: Column(
          children: [
            // Color picker
            Container(
              color: _noteColors[_selectedColorIndex],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Color: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _noteColors.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedColorIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedColorIndex = index;
                                  _isModified = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _noteColors[index],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.black87 : Colors.black26,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.black87,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Note content
            Expanded(
              child: Container(
                color: _noteColors[_selectedColorIndex],
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                      ),
                      maxLines: 2,
                    ),
                    const Divider(color: Colors.black26),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Start writing...',
                          hintStyle: TextStyle(
                            color: Colors.black38,
                          ),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
