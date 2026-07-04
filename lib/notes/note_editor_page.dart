import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../database/database.dart';
import '../main.dart';
import '../theme/tokens.dart';

/// Notes let the user pick an arbitrary background color (like a sticky
/// note), so foreground content must contrast against whatever was chosen —
/// not against the app's light/dark theme. Compute readable ink colors from
/// the note's own background luminance instead of hardcoding black.
Color _inkOn(Color bg) =>
    bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
Color _inkFaintOn(Color bg) =>
    bg.computeLuminance() > 0.5 ? Colors.black38 : Colors.white38;
Color _inkBorderOn(Color bg) =>
    bg.computeLuminance() > 0.5 ? Colors.black26 : Colors.white24;

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    required this.colorIndex,
    super.key,
    this.note,
  });
  final Note? note;
  final int colorIndex;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late int _selectedColorIndex;
  Color? _customColor;

  // Muted, desaturated palette that sits with the dark app theme rather than
  // fighting it. Dark enough that _inkOn picks white text automatically.
  final List<Color> _noteColors = [
    const Color(0xFF9E6B4A), // Terracotta
    const Color(0xFF3F6E6C), // Teal
    const Color(0xFF44607F), // Slate Blue
    const Color(0xFF7E5470), // Mauve
    const Color(0xFF8F5151), // Rust
    const Color(0xFF7C7A45), // Olive
    const Color(0xFF54764F), // Sage
    const Color(0xFF625A82), // Muted Lavender
  ];

  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');

    // Check if it's a custom color or preset index
    final colorValue = widget.note?.color ?? widget.colorIndex;
    if (colorValue >= 0 && colorValue < _noteColors.length) {
      _selectedColorIndex = colorValue;
      _customColor = null;
    } else {
      _selectedColorIndex = -1; // Custom color indicator
      _customColor = Color(colorValue);
    }

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
    // Save custom color value or preset index
    final colorValue = _customColor?.toARGB32() ?? _selectedColorIndex;

    if (widget.note == null) {
      // Get max sequence to put new note at top
      final maxSeqResult = await (db.notes.selectOnly()
            ..addColumns([db.notes.sequence.max()]))
          .map((row) => row.read(db.notes.sequence.max()))
          .getSingleOrNull();

      final newSequence = (maxSeqResult ?? -1) + 1;

      // Create new note with sequence
      final companion = NotesCompanion.insert(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        created: now,
        updated: now,
        color: Value(colorValue),
        sequence: Value(newSequence),
      );
      final id = await db.notes.insertOne(companion);
      final note =
          await (db.notes.select()..where((n) => n.id.equals(id))).getSingle();
      if (mounted) {
        setState(() {
          _isModified = false;
        });
        Navigator.pop(context, note);
      }
    } else {
      // Update existing note
      await (db.notes.update()..where((n) => n.id.equals(widget.note!.id)))
          .write(
        NotesCompanion(
          title: Value(title.isEmpty ? 'Untitled' : title),
          content: Value(content),
          updated: Value(now),
          color: Value(colorValue),
        ),
      );
      final note = await (db.notes.select()
            ..where((n) => n.id.equals(widget.note!.id)))
          .getSingle();
      if (mounted) {
        setState(() {
          _isModified = false;
        });
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
        content:
            const Text('You have unsaved changes. Do you want to save them?'),
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

    if (shouldSave ?? false) {
      await _saveNote();
      return false;
    }

    return shouldSave == false;
  }

  Color get _currentColor =>
      _customColor ??
      _noteColors[_selectedColorIndex >= 0 ? _selectedColorIndex : 0];

  Future<void> _showCustomColorPicker() async {
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => _SimpleColorPickerDialog(
        initialColor: _customColor ?? _noteColors[0],
      ),
    );

    if (result != null) {
      setState(() {
        _customColor = result;
        _selectedColorIndex = -1;
        _isModified = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isModified,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (await _onWillPop()) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: _currentColor,
        appBar: AppBar(
          backgroundColor: _currentColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _inkOn(_currentColor)),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.check, color: _inkOn(_currentColor)),
              onPressed: _saveNote,
              tooltip: 'Save',
            ),
          ],
        ),
        body: Column(
          children: [
            // Color picker
            Container(
              color: _currentColor,
              padding: const EdgeInsets.symmetric(
                horizontal: space16,
                vertical: space8,
              ),
              child: Row(
                children: [
                  Text(
                    'Color: ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _inkOn(_currentColor),
                        ),
                  ),
                  const SizedBox(width: space8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _noteColors.length +
                            1, // +1 for custom color button
                        itemBuilder: (context, index) {
                          // Custom color picker button
                          if (index == _noteColors.length) {
                            final isSelected = _customColor != null;
                            return Padding(
                              padding: const EdgeInsets.only(right: space8),
                              child: InkWell(
                                onTap: _showCustomColorPicker,
                                borderRadius: brPill,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _customColor ?? Colors.grey[300],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? _inkOn(_currentColor)
                                          : _inkBorderOn(_currentColor),
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check : Icons.add,
                                    color: _inkOn(_currentColor),
                                    size: 20,
                                  ),
                                ),
                              ),
                            );
                          }

                          // Preset color options
                          final isSelected = index == _selectedColorIndex &&
                              _customColor == null;
                          return Padding(
                            padding: const EdgeInsets.only(right: space8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedColorIndex = index;
                                  _customColor = null;
                                  _isModified = true;
                                });
                              },
                              borderRadius: brPill,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _noteColors[index],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? _inkOn(_currentColor)
                                        : _inkBorderOn(_currentColor),
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: _inkOn(_currentColor),
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
                color: _currentColor,
                padding: const EdgeInsets.all(space16),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: _inkOn(_currentColor),
                              ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: _inkFaintOn(_currentColor),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: space4),
                    Divider(color: _inkBorderOn(_currentColor)),
                    const SizedBox(height: space8),
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _inkOn(_currentColor),
                              height: 1.5,
                            ),
                        decoration: InputDecoration(
                          hintText: 'Start writing...',
                          hintStyle: TextStyle(
                            color: _inkFaintOn(_currentColor),
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

class _SimpleColorPickerDialog extends StatefulWidget {
  const _SimpleColorPickerDialog({required this.initialColor});
  final Color initialColor;

  @override
  State<_SimpleColorPickerDialog> createState() =>
      _SimpleColorPickerDialogState();
}

class _SimpleColorPickerDialogState extends State<_SimpleColorPickerDialog> {
  late HSLColor _hslColor;

  @override
  void initState() {
    super.initState();
    _hslColor = HSLColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hslColor.toColor();

    return AlertDialog(
      title: const Text('Pick a color'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color preview
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: brSm,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(height: space24),
            // Hue slider
            _buildSlider(
              label: 'Hue',
              value: _hslColor.hue,
              max: 360,
              onChanged: (value) {
                setState(() {
                  _hslColor = _hslColor.withHue(value);
                });
              },
              gradient: LinearGradient(
                colors: [
                  HSLColor.fromAHSL(
                    1,
                    0,
                    _hslColor.saturation,
                    _hslColor.lightness,
                  ).toColor(),
                  HSLColor.fromAHSL(
                    1,
                    60,
                    _hslColor.saturation,
                    _hslColor.lightness,
                  ).toColor(),
                  HSLColor.fromAHSL(
                    1,
                    120,
                    _hslColor.saturation,
                    _hslColor.lightness,
                  ).toColor(),
                  HSLColor.fromAHSL(
                    1,
                    180,
                    _hslColor.saturation,
                    _hslColor.lightness,
                  ).toColor(),
                  HSLColor.fromAHSL(
                    1,
                    240,
                    _hslColor.saturation,
                    _hslColor.lightness,
                  ).toColor(),
                  HSLColor.fromAHSL(
                    1,
                    300,
                    _hslColor.saturation,
                    _hslColor.lightness,
                  ).toColor(),
                  HSLColor.fromAHSL(
                    1,
                    360,
                    _hslColor.saturation,
                    _hslColor.lightness,
                  ).toColor(),
                ],
              ),
            ),
            const SizedBox(height: space16),
            // Saturation slider
            _buildSlider(
              label: 'Saturation',
              value: _hslColor.saturation * 100,
              max: 100,
              onChanged: (value) {
                setState(() {
                  _hslColor = _hslColor.withSaturation(value / 100);
                });
              },
              gradient: LinearGradient(
                colors: [
                  HSLColor.fromAHSL(1, _hslColor.hue, 0, _hslColor.lightness)
                      .toColor(),
                  HSLColor.fromAHSL(1, _hslColor.hue, 1, _hslColor.lightness)
                      .toColor(),
                ],
              ),
            ),
            const SizedBox(height: space16),
            // Lightness slider
            _buildSlider(
              label: 'Lightness',
              value: _hslColor.lightness * 100,
              max: 100,
              onChanged: (value) {
                setState(() {
                  _hslColor = _hslColor.withLightness(value / 100);
                });
              },
              gradient: LinearGradient(
                colors: [
                  HSLColor.fromAHSL(1, _hslColor.hue, _hslColor.saturation, 0)
                      .toColor(),
                  HSLColor.fromAHSL(1, _hslColor.hue, _hslColor.saturation, 0.5)
                      .toColor(),
                  HSLColor.fromAHSL(1, _hslColor.hue, _hslColor.saturation, 1)
                      .toColor(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, currentColor),
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
    required Gradient gradient,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.round()}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: space8),
        Container(
          height: 24,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: brSm,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 24,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
            ),
            child: Slider(
              value: value,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
