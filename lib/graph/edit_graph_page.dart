import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../main.dart';
import '../plan/plan_state.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../utils.dart';
import '../utils/cardio_format.dart';
import '../widgets/sticky_form_action.dart';

class EditGraphPage extends StatefulWidget {
  const EditGraphPage({required this.name, super.key});
  final String name;

  @override
  _EditGraphPageState createState() => _EditGraphPageState();
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
  String cardioMetric = cardioMetricDuration;
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
    'Cardio',
  ];

  final List<({String value, String label, IconData icon})> exerciseTypes = [
    (value: 'free_weight', label: 'Free Weight', icon: Icons.fitness_center),
    (value: 'machine', label: 'Machine', icon: Icons.settings),
    (value: 'cable', label: 'Cable', icon: Icons.cable),
    (value: 'cardio', label: 'Cardio', icon: Icons.directions_run),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Update ${widget.name}'),
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
                    child: TextField(
                      controller: name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Exercise Name',
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.label_outline,
                          color: colorScheme.primary,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
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
                        const SizedBox(width: space16),
                        Expanded(
                          child: TextFormField(
                            controller: seconds,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Seconds',
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
                Selector<SettingsState, bool>(
                  builder: (context, showImages, child) {
                    if (!showImages) return const SizedBox();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exercise Image',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
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
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.3),
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
                    );
                  },
                  selector: (context, settings) => settings.value.showImages,
                ),
                const SizedBox(height: space24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: StickyFormAction(
        onPressed: save,
        label: const Text('Update'),
        icon: const Icon(Icons.sync),
      ),
    );
  }

  @override
  void dispose() {
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

    final isCardio = exerciseType == 'cardio';
    final savedCategory = isCardio
        ? ((category?.isNotEmpty ?? false) ? category : 'Cardio')
        : category;

    await (db.gymSets.update()..where((tbl) => tbl.name.equals(widget.name)))
        .write(
      GymSetsCompanion(
        name: name.text.isEmpty ? const Value.absent() : Value(name.text),
        restMs: Value(duration?.inMilliseconds),
        image: Value(image),
        category: Value.absentIfNull(savedCategory),
        exerciseType: Value.absentIfNull(exerciseType),
        cardioMetric: Value(isCardio ? cardioMetric : null),
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
            exerciseType = gymSet.cardio ? 'cardio' : gymSet.exerciseType;
            category = gymSet.category ?? (gymSet.cardio ? 'Cardio' : null);
            cardioMetric = gymSet.cardioMetric ?? cardioMetricDuration;
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
