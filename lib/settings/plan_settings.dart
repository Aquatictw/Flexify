import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../database/database.dart';
import '../main.dart';
import '../theme/tokens.dart';
import '../utils.dart';

List<Widget> getPlanSettings(
  String term,
  Setting settings,
  TextEditingController max,
  TextEditingController warmup,
) {
  return [
    if ('warmup sets'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: space16),
        child: Tooltip(
          message: 'Warmup sets have no rest timers',
          child: TextField(
            controller: warmup,
            decoration: const InputDecoration(
              labelText: 'Warmup sets',
              hintText: '0',
            ),
            keyboardType: TextInputType.number,
            onTap: () => selectAll(warmup),
            onChanged: (value) => db.settings.update().write(
                  SettingsCompanion(
                    warmupSets: Value(int.parse(value)),
                  ),
                ),
          ),
        ),
      ),
    if ('sets per exercise'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: space16),
        child: Tooltip(
          message: 'Default # of exercises in a plan',
          child: TextField(
            controller: max,
            decoration: const InputDecoration(
              labelText: 'Sets per exercise (max: 20)',
            ),
            keyboardType: TextInputType.number,
            onTap: () => selectAll(max),
            onChanged: (value) {
              if (int.parse(value) > 0 && int.parse(value) <= 20) {
                db.settings.update().write(
                      SettingsCompanion(
                        maxSets: Value(int.parse(value)),
                      ),
                    );
              }
            },
          ),
        ),
      ),
    if ('plan trailing display'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: space16),
        child: Tooltip(
          message: 'Right side of list displays in Plans + Plan view',
          child: Builder(
            builder: (context) => DropdownButtonFormField<PlanTrailing>(
              initialValue: PlanTrailing.values.byName(
                settings.planTrailing.replaceFirst('PlanTrailing.', ''),
              ),
              decoration: InputDecoration(
                labelText: 'Plan trailing display',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: const OutlineInputBorder(borderRadius: brSm),
              ),
              items: const [
                DropdownMenuItem(
                  value: PlanTrailing.reorder,
                  child: Row(
                    children: [
                      Text('Re-order'),
                      SizedBox(width: space8),
                      Icon(Icons.menu, size: 18),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PlanTrailing.count,
                  child: Row(
                    children: [
                      Text('Count'),
                      SizedBox(width: space8),
                      Text('(5)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PlanTrailing.percent,
                  child: Row(
                    children: [
                      Text('Percent'),
                      SizedBox(width: space8),
                      Text('(50%)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PlanTrailing.ratio,
                  child: Row(
                    children: [
                      Text('Ratio'),
                      SizedBox(width: space8),
                      Text('(5 / 10)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PlanTrailing.none,
                  child: Text('None'),
                ),
              ],
              onChanged: (value) => db.settings.update().write(
                    SettingsCompanion(
                      planTrailing: Value(value.toString()),
                    ),
                  ),
            ),
          ),
        ),
      ),
  ];
}
