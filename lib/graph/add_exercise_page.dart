import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:flexify/animated_fab.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddExercisePage extends StatefulWidget {
  final String? name;

  const AddExercisePage({super.key, this.name});

  @override
  createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController brandNameCtrl = TextEditingController();

  String? exerciseType;
  String? image;
  final key = GlobalKey<FormState>();

  final List<({String value, String label, IconData icon})> exerciseTypes = [
    (value: 'free_weight', label: 'Free Weight', icon: Icons.fitness_center),
    (value: 'machine', label: 'Machine', icon: Icons.settings),
    (value: 'cable', label: 'Cable', icon: Icons.cable),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.name != null) nameCtrl.text = widget.name!;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Add Exercise'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: key,
            child: ListView(
              children: [
                // Exercise Name
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Exercise Name',
                        border: InputBorder.none,
                        icon: Icon(Icons.label_outline, color: colorScheme.primary),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      autofocus: true,
                      validator: (value) =>
                          value?.isNotEmpty == true ? null : 'Required',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Exercise Type Section
                Text(
                  'Exercise Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),

                // Compact Exercise Type Selection
                Row(
                  children: exerciseTypes.map((type) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            exerciseType = type.value;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          decoration: BoxDecoration(
                            gradient: exerciseType == type.value
                                ? LinearGradient(
                                    colors: [
                                      colorScheme.primaryContainer,
                                      colorScheme.primaryContainer.withOpacity(0.7),
                                    ],
                                  )
                                : null,
                            color: exerciseType != type.value
                                ? colorScheme.surfaceVariant.withOpacity(0.5)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: exerciseType == type.value
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type.icon,
                                color: exerciseType == type.value
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                type.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: exerciseType == type.value
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: exerciseType == type.value
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ),

                // Brand Name (only for machines)
                if (exerciseType == 'machine') ...[
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        controller: brandNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Brand Name (Optional)',
                          hintText: 'e.g., Hammer Strength, Life Fitness',
                          border: InputBorder.none,
                          icon: Icon(Icons.business, color: colorScheme.primary),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Notes
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Add any notes about this exercise...',
                        border: InputBorder.none,
                        icon: Icon(Icons.note_outlined, color: colorScheme.primary),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Image Section
                if (settings.value.showImages) ...[
                  Text(
                    'Exercise Image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (image == null)
                    InkWell(
                      onTap: pick,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Image',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(image!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: pick,
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.surface,
                                  foregroundColor: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    image = null;
                                  });
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.surface,
                                  foregroundColor: colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],

                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: save,
        label: const Text('Save'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    notesCtrl.dispose();
    brandNameCtrl.dispose();
    super.dispose();
  }

  void pick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result?.files.single == null) return;

    setState(() {
      image = result?.files.single.path;
    });
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;

    final insert = GymSetsCompanion.insert(
      created: DateTime.now().toLocal(),
      reps: 0,
      weight: 0,
      name: nameCtrl.text,
      unit: 'kg', // Hardcoded to kg
      cardio: const Value(false), // Always strength
      hidden: const Value(true),
      image: Value(image),
      exerciseType: Value(exerciseType),
      brandName: Value(brandNameCtrl.text.isEmpty ? null : brandNameCtrl.text),
      notes: Value(notesCtrl.text.isEmpty ? null : notesCtrl.text),
    );
    await db.gymSets.insertOne(insert);
    if (!mounted) return;

    Navigator.pop(context, insert);
  }
}
