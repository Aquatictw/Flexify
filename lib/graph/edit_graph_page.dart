import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:flexify/animated_fab.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/plan/plan_state.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/utils.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditGraphPage extends StatefulWidget {
  final String name;

  const EditGraphPage({required this.name, super.key});

  @override
  createState() => _EditGraphPageState();
}

class _EditGraphPageState extends State<EditGraphPage> {
  late final TextEditingController name =
      TextEditingController(text: widget.name);
  final TextEditingController minutes = TextEditingController();
  final TextEditingController seconds = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController brandNameCtrl = TextEditingController();
  final key = GlobalKey<FormState>();

  String? exerciseType;
  String? image;
  String? category;

  final List<String> bodyparts = [
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Forearms',
    'Abs',
    'Quads',
    'Hamstrings',
    'Glutes',
    'Calves',
  ];

  final List<({String value, String label, IconData icon})> exerciseTypes = [
    (value: 'free_weight', label: 'Free Weight', icon: Icons.fitness_center),
    (value: 'machine', label: 'Machine', icon: Icons.settings),
    (value: 'cable', label: 'Cable', icon: Icons.cable),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Update ${widget.name}"),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withValues(alpha: 0.95),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0,),
                    child: TextField(
                      controller: name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: "Exercise Name",
                        border: InputBorder.none,
                        icon: Icon(Icons.label_outline,
                            color: colorScheme.primary,),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Rest Timer
                Text(
                  'Rest Timer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0,),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, color: colorScheme.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: minutes,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: "Minutes",
                              border: InputBorder.none,
                            ),
                            keyboardType: material.TextInputType.number,
                            onTap: () => selectAll(minutes),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (int.tryParse(value) == null)
                                return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: seconds,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: "Seconds",
                              border: InputBorder.none,
                            ),
                            keyboardType: material.TextInputType.number,
                            onTap: () {
                              selectAll(seconds);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (int.tryParse(value) == null)
                                return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                      ],
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
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),

                // Compact Exercise Type Selection
                Row(
                  children: exerciseTypes
                      .map(
                        (type) => Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  exerciseType = type.value;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                decoration: BoxDecoration(
                                  gradient: exerciseType == type.value
                                      ? LinearGradient(
                                          colors: [
                                            colorScheme.primaryContainer,
                                            colorScheme.primaryContainer
                                                .withValues(alpha: 0.7),
                                          ],
                                        )
                                      : null,
                                  color: exerciseType != type.value
                                      ? colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5)
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
                        ),
                      )
                      .toList(),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0,),
                      child: TextField(
                        controller: brandNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Brand Name (Optional)',
                          hintText: 'e.g., Hammer Strength, Life Fitness',
                          border: InputBorder.none,
                          icon:
                              Icon(Icons.business, color: colorScheme.primary),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Bodypart
                Selector<SettingsState, bool>(
                  selector: (p0, settings) => settings.value.showCategories,
                  builder: (context, showCategories, child) {
                    if (!showCategories) return const SizedBox();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bodypart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4.0,),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Bodypart',
                                border: InputBorder.none,
                                icon: Icon(Icons.accessibility_new,
                                    color: colorScheme.primary,),
                              ),
                              initialValue: category != null &&
                                      bodyparts.contains(category)
                                  ? category
                                  : null,
                              items: bodyparts
                                  .map(
                                    (bodypart) => DropdownMenuItem(
                                      value: bodypart,
                                      child: Text(bodypart),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  category = value;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // Notes
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0,),
                    child: TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Add any notes about this exercise...',
                        border: InputBorder.none,
                        icon: Icon(Icons.note_outlined,
                            color: colorScheme.primary,),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Image Section
                Selector<SettingsState, bool>(
                  builder: (context, showImages, child) {
                    if (!showImages) return const SizedBox();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exercise Image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (image == null)
                          InkWell(
                            onTap: pick,
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.3),
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
                    );
                  },
                  selector: (context, settings) => settings.value.showImages,
                ),

                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: save,
        label: const Text("Update"),
        icon: const Icon(Icons.sync),
      ),
    );
  }

  @override
  dispose() {
    name.dispose();
    minutes.dispose();
    seconds.dispose();
    notesCtrl.dispose();
    brandNameCtrl.dispose();
    super.dispose();
  }

  Future<void> doUpdate() async {
    Duration? duration;
    if (int.tryParse(minutes.text) != null && int.tryParse(minutes.text)! > 0 ||
        int.tryParse(seconds.text) != null && int.tryParse(seconds.text)! > 0)
      duration = Duration(
        minutes: int.tryParse(minutes.text) ?? 0,
        seconds: int.tryParse(seconds.text) ?? 0,
      );

    await (db.gymSets.update()..where((tbl) => tbl.name.equals(widget.name)))
        .write(
      GymSetsCompanion(
        name: name.text.isEmpty ? const Value.absent() : Value(name.text),
        restMs: Value(duration?.inMilliseconds),
        image: Value(image),
        category: Value.absentIfNull(category),
        exerciseType: Value.absentIfNull(exerciseType),
        brandName:
            Value(brandNameCtrl.text.isEmpty ? null : brandNameCtrl.text),
        notes: Value(notesCtrl.text.isEmpty ? null : notesCtrl.text),
      ),
    );

    await (db.planExercises.update()
          ..where((tbl) => tbl.exercise.equals(widget.name)))
        .write(
      PlanExercisesCompanion(
        exercise: name.text.isEmpty ? const Value.absent() : Value(name.text),
      ),
    );

    if (!mounted) return;
    context.read<PlanState>().updatePlans(null);
  }

  Future<int> getCount() async {
    final result = await (db.gymSets.selectOnly()
          ..addColumns([db.gymSets.name.count()])
          ..where(db.gymSets.name.equals(name.text)))
        .getSingle();
    return result.read(db.gymSets.name.count()) ?? 0;
  }

  @override
  void initState() {
    super.initState();

    (db.gymSets.select()
          ..where((tbl) => tbl.name.equals(widget.name))
          ..limit(1))
        .getSingle()
        .then(
          (gymSet) => setState(() {
            image = gymSet.image;
            category = gymSet.category;
            exerciseType = gymSet.exerciseType;
            brandNameCtrl.text = gymSet.brandName ?? '';
            notesCtrl.text = gymSet.notes ?? '';

            if (gymSet.restMs != null) {
              final duration = Duration(milliseconds: gymSet.restMs!);
              minutes.text = duration.inMinutes.toString();
              seconds.text = (duration.inSeconds % 60).toString();
            }
          }),
        );
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

    final count = await getCount();

    if (count > 0 && widget.name != name.text && mounted) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Update conflict'),
            content: Text(
              'Your new name exists already for $count records. Are you sure?',
            ),
            actions: <Widget>[
              TextButton.icon(
                label: const Text('Cancel'),
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton.icon(
                label: const Text('Confirm'),
                icon: const Icon(Icons.check),
                onPressed: () async {
                  Navigator.pop(context);
                  await doUpdate();
                },
              ),
            ],
          );
        },
      );
    } else {
      await doUpdate();
    }

    if (!mounted) return;
    Navigator.pop(context, name.text);
  }
}
