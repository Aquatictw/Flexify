import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../main.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../utils/cardio_format.dart';
import '../widgets/sticky_form_action.dart';

class AddExercisePage extends StatefulWidget {
  const AddExercisePage({super.key, this.name});
  final String? name;

  @override
  _AddExercisePageState createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController brandNameCtrl = TextEditingController();
  final TextEditingController minutes = TextEditingController();
  final TextEditingController seconds = TextEditingController();

  String? exerciseType;
  String cardioMetric = cardioMetricDuration;
  String? image;
  String? category;
  final key = GlobalKey<FormState>();

  final List<({String value, String label, IconData icon})> exerciseTypes = [
    (value: 'free_weight', label: 'Free Weight', icon: Icons.fitness_center),
    (value: 'machine', label: 'Machine', icon: Icons.settings),
    (value: 'cable', label: 'Cable', icon: Icons.cable),
    (value: 'cardio', label: 'Cardio', icon: Icons.directions_run),
  ];

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
    'Cardio',
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
      appBar: AppBar(
        title: const Text('Add Exercise'),
        elevation: 0,
      ),
      body: DecoratedBox(
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
          padding: const EdgeInsets.all(space24),
          child: Form(
            key: key,
            child: ListView(
              children: [
                // Exercise Name
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: brMd,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: space16,
                      vertical: space8,
                    ),
                    child: TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Exercise Name',
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.label_outline,
                          color: colorScheme.primary,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      autofocus: true,
                      validator: (value) =>
                          value?.isNotEmpty ?? false ? null : 'Required',
                    ),
                  ),
                ),
                const SizedBox(height: space24),

                // Rest Timer
                Text(
                  'Rest Timer',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: space12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: brMd,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: space16,
                      vertical: space8,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, color: colorScheme.primary),
                        const SizedBox(width: space16),
                        Expanded(
                          child: TextFormField(
                            controller: minutes,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Minutes',
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (int.tryParse(value) == null)
                                return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: space16),
                        Expanded(
                          child: TextFormField(
                            controller: seconds,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Seconds',
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
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
                const SizedBox(height: space24),

                // Exercise Type Section
                Text(
                  'Exercise Type',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: space12),

                // Compact Exercise Type Selection
                LayoutBuilder(
                  builder: (context, constraints) {
                    final typeWidth = constraints.maxWidth / 3;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: exerciseTypes
                            .map(
                              (type) => SizedBox(
                                width: typeWidth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: space4,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        exerciseType = type.value;
                                        if (type.value == 'cardio') {
                                          category ??= 'Cardio';
                                        } else if (category == 'Cardio') {
                                          category = null;
                                        }
                                      });
                                    },
                                    borderRadius: brMd,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
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
                                            ? colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.5)
                                            : null,
                                        borderRadius: brMd,
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
                                          const SizedBox(height: space8),
                                          Text(
                                            type.label,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  exerciseType == type.value
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                              color: exerciseType == type.value
                                                  ? colorScheme
                                                      .onPrimaryContainer
                                                  : colorScheme
                                                      .onSurfaceVariant,
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
                    );
                  },
                ),

                // Brand Name (machines and cardio machines)
                if (exerciseType == 'machine' || exerciseType == 'cardio') ...[
                  const SizedBox(height: space24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: brMd,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: space16,
                        vertical: space8,
                      ),
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

                if (exerciseType == 'cardio') ...[
                  const SizedBox(height: space24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: brMd,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: space16,
                        vertical: space4,
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Primary Measurement',
                          border: InputBorder.none,
                          icon: Icon(
                            Icons.speed_outlined,
                            color: colorScheme.primary,
                          ),
                        ),
                        initialValue: cardioMetric,
                        items: cardioMetricLabels.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => cardioMetric = value);
                        },
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: space24),

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
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: space12),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: brMd,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: space16,
                              vertical: space4,
                            ),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Bodypart',
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.accessibility_new,
                                  color: colorScheme.primary,
                                ),
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
                        const SizedBox(height: space24),
                      ],
                    );
                  },
                ),

                // Notes
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: brMd,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: space16,
                      vertical: space8,
                    ),
                    child: TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Add any notes about this exercise...',
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.note_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: space24),

                // Image Section
                if (settings.value.showImages) ...[
                  Text(
                    'Exercise Image',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: space12),
                  if (image == null)
                    InkWell(
                      onTap: pick,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: brMd,
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                            width: 2,
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
                              const SizedBox(height: space8),
                              Text(
                                'Add Image',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
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
                          borderRadius: brMd,
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
                                borderRadius: brMd,
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
                const SizedBox(height: space24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: StickyFormAction(
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
    minutes.dispose();
    seconds.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final colorScheme = Theme.of(context).colorScheme;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: colorScheme.primary),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: colorScheme.primary),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() {
      image = pickedFile.path;
    });
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;

    // Calculate rest duration in milliseconds
    Duration? duration;
    if (minutes.text.isNotEmpty || seconds.text.isNotEmpty) {
      duration = Duration(
        minutes: int.tryParse(minutes.text) ?? 0,
        seconds: int.tryParse(seconds.text) ?? 0,
      );
    }

    final settings = context.read<SettingsState>().value;
    final isCardio = exerciseType == 'cardio';
    final savedCategory = isCardio
        ? ((category?.isNotEmpty ?? false) ? category : 'Cardio')
        : category;
    final insert = GymSetsCompanion.insert(
      created: DateTime.now().toLocal(),
      reps: 0,
      weight: 0,
      name: nameCtrl.text,
      unit: isCardio ? settings.cardioUnit : 'kg',
      cardio: Value(isCardio),
      cardioMetric: Value(isCardio ? cardioMetric : null),
      hidden: const Value(true),
      image: Value(image),
      exerciseType: Value(exerciseType),
      brandName: Value(brandNameCtrl.text.isEmpty ? null : brandNameCtrl.text),
      notes: Value(notesCtrl.text.isEmpty ? null : notesCtrl.text),
      restMs: Value(duration?.inMilliseconds),
      category: Value.absentIfNull(savedCategory),
    );
    await db.gymSets.insertOne(insert);
    if (!mounted) return;

    Navigator.pop(context, nameCtrl.text);
  }
}
