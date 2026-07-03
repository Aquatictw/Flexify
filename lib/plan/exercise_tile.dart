import 'package:drift/drift.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../main.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../utils.dart';

class ExerciseTile extends StatefulWidget {

  const ExerciseTile({
    required this.onChange, required this.planExercise, super.key,
  });
  final PlanExercisesCompanion planExercise;
  final Function(PlanExercisesCompanion) onChange;

  @override
  State<ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<ExerciseTile> {
  late final max = TextEditingController(
    text: widget.planExercise.maxSets.value?.toString(),
  );
  late final warmup = TextEditingController(
    text: widget.planExercise.warmupSets.value?.toString(),
  );

  Future<String?> _getBrandName() async {
    final result = await (db.gymSets.select()
          ..where((tbl) => tbl.name.equals(widget.planExercise.exercise.value))
          ..orderBy([
            (u) => OrderingTerm(expression: u.created, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    return result?.brandName;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              bool timers = !widget.planExercise.timers.present || widget.planExercise.timers.value;

              return AlertDialog.adaptive(
                title: Text(widget.planExercise.exercise.value),
                content: SingleChildScrollView(
                  child: material.Column(
                    children: [
                      Selector<SettingsState, int?>(
                        selector: (context, settings) =>
                            settings.value.warmupSets,
                        builder: (context, value, child) => TextField(
                          controller: warmup,
                          keyboardType: TextInputType.number,
                          onTap: () => selectAll(warmup),
                          onChanged: (value) {
                            final pe = widget.planExercise.copyWith(
                              enabled: const Value(true),
                              warmupSets: Value(int.tryParse(warmup.text)),
                            );
                            widget.onChange(pe);
                          },
                          decoration: InputDecoration(
                            labelText: 'Warmup sets',
                            border: const OutlineInputBorder(),
                            hintText: (value ?? 0).toString(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Selector<SettingsState, int>(
                        selector: (context, settings) => settings.value.maxSets,
                        builder: (context, value, child) => TextField(
                          controller: max,
                          keyboardType: TextInputType.number,
                          onTap: () => selectAll(max),
                          onChanged: (value) {
                            if (int.parse(max.text) > 0 &&
                                int.parse(max.text) <= 20) {
                              final pe = widget.planExercise.copyWith(
                                enabled: const Value(true),
                                maxSets: Value(int.parse(max.text)),
                              );
                              widget.onChange(pe);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Working sets (max: 20)',
                            border: const OutlineInputBorder(),
                            hintText: value.toString(),
                          ),
                        ),
                      ),
                      StatefulBuilder(
                        builder: (context, setState) => ListTile(
                          title: const Text('Rest timers'),
                          trailing: Switch(
                            value: timers,
                            onChanged: (value) {
                              setState(() {
                                timers = value;
                              });
                              widget.onChange(
                                widget.planExercise.copyWith(
                                  timers: Value(value),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    label: const Text('OK'),
                    icon: const Icon(Icons.check),
                  ),
                ],
              );
            },
          );
        },
      ),
      title: FutureBuilder<String?>(
        future: _getBrandName(),
        builder: (context, snapshot) {
          final brandName = snapshot.data;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(widget.planExercise.exercise.value),
              ),
              if (brandName != null && brandName.isNotEmpty) ...[
                const SizedBox(width: space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: space8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withValues(alpha: 0.7),
                    borderRadius: brSm,
                  ),
                  child: Text(
                    brandName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      trailing: Switch(
        value: widget.planExercise.enabled.value,
        onChanged: (value) {
          widget.onChange(
            widget.planExercise.copyWith(
              enabled: Value(value),
            ),
          );
        },
      ),
      onTap: () {
        widget.onChange(
          widget.planExercise.copyWith(
            enabled: Value(!widget.planExercise.enabled.value),
          ),
        );
      },
    );
  }
}
