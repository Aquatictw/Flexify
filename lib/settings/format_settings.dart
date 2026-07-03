import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../database/database.dart';
import '../main.dart';
import '../theme/tokens.dart';
import 'plan_settings.dart';
import 'settings_state.dart';

final List<String> long = [
  'timeago',
  'dd/MM/yy',
  'dd/MM/yy h:mm a',
  'dd/MM/yy H:mm',
  'dd.MM.yyyy H:mm',
  'EEE h:mm a',
  'yyyy-MM-dd',
  'yyyy-MM-dd h:mm a',
  'yyyy-MM-dd H:mm',
  'yyyy.MM.dd',
  'yyyy.MM.dd h:mm a',
  'yyyy.MM.dd H:mm',
  'MMM d (EEE) h:mm a',
  'EEE, dd.MM.yyyy H:mm',
];

final List<String> short = [
  'd/M/yy',
  'M/d/yy',
  'd-M-yy',
  'M-d-yy',
  'd.M.yy',
  'M.d.yy',
  'dd.MM.yy',
];

List<Widget> getFormatSettings(String term, Setting settings) {
  return [
    if ('strength unit'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: space16),
        child: Builder(
          builder: (context) => DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Strength unit',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              border: const OutlineInputBorder(borderRadius: brSm),
            ),
            initialValue: settings.strengthUnit,
            items: const [
              DropdownMenuItem(
                value: 'last-entry',
                child: Text('Last entry'),
              ),
              DropdownMenuItem(
                value: 'kg',
                child: Text('Kilograms (kg)'),
              ),
              DropdownMenuItem(
                value: 'lb',
                child: Text('Pounds (lb)'),
              ),
              DropdownMenuItem(
                value: 'stone',
                child: Text('Stone'),
              ),
            ],
            onChanged: (value) {
              db.settings.update().write(
                    SettingsCompanion(
                      strengthUnit: Value(value!),
                    ),
                  );
            },
          ),
        ),
      ),
    if ('cardio unit'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: space16),
        child: Builder(
          builder: (context) => DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Cardio unit',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              border: const OutlineInputBorder(borderRadius: brSm),
            ),
            initialValue: settings.cardioUnit,
            items: const [
              DropdownMenuItem(
                value: 'last-entry',
                child: Text('Last entry'),
              ),
              DropdownMenuItem(
                value: 'km',
                child: Text('Kilometers (km)'),
              ),
              DropdownMenuItem(
                value: 'mi',
                child: Text('Miles (mi)'),
              ),
              DropdownMenuItem(
                value: 'm',
                child: Text('Meters (m)'),
              ),
              DropdownMenuItem(
                value: 'kcal',
                child: Text('Kilocalories (kcal)'),
              ),
            ],
            onChanged: (value) {
              db.settings.update().write(
                    SettingsCompanion(
                      cardioUnit: Value(value!),
                    ),
                  );
            },
          ),
        ),
      ),
    if ('long date format'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: space16),
        child: Tooltip(
          message: 'Used where space is abundant',
          child: Builder(
            builder: (context) {
              var format = timeago.format(DateTime.now());

              if (settings.longDateFormat != 'timeago')
                format =
                    DateFormat(settings.longDateFormat).format(DateTime.now());

              return DropdownButtonFormField<String>(
                initialValue: settings.longDateFormat,
                items: long.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => db.settings.update().write(
                      SettingsCompanion(
                        longDateFormat: Value(value!),
                      ),
                    ),
                decoration: InputDecoration(
                  labelText: 'Long date format ($format)',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  border: const OutlineInputBorder(borderRadius: brSm),
                ),
              );
            },
          ),
        ),
      ),
    if ('short date format'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: space16),
        child: Tooltip(
          message: 'For where space is cramped (Graph lines)',
          child: Builder(
            builder: (context) => DropdownButtonFormField<String>(
              initialValue: settings.shortDateFormat,
              items: short.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) => db.settings.update().write(
                    SettingsCompanion(
                      shortDateFormat: Value(value!),
                    ),
                  ),
              decoration: InputDecoration(
                labelText:
                    'Short date format (${DateFormat(settings.shortDateFormat).format(DateTime.now())})',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: const OutlineInputBorder(borderRadius: brSm),
              ),
            ),
          ),
        ),
      ),
  ];
}

class PlansAndFormatsSettings extends StatefulWidget {
  const PlansAndFormatsSettings({super.key});

  @override
  State<PlansAndFormatsSettings> createState() =>
      _PlansAndFormatsSettingsState();
}

class _PlansAndFormatsSettingsState extends State<PlansAndFormatsSettings> {
  late Setting settings = context.read<SettingsState>().value;

  late final max = TextEditingController(text: settings.maxSets.toString());
  late final warmup =
      TextEditingController(text: settings.warmupSets?.toString());

  @override
  Widget build(BuildContext context) {
    settings = context.watch<SettingsState>().value;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Plans & Formats'),
      ),
      body: ListView(
        children: [
          ...getFormatSettings('', settings),
          const Divider(), // uses global DividerThemeData, no custom color
          ...getPlanSettings('', settings, max, warmup),
        ],
      ),
    );
  }

  @override
  void dispose() {
    max.dispose();
    warmup.dispose();
    super.dispose();
  }
}
