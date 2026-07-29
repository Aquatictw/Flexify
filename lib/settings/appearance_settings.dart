import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/artistic_color_picker.dart';
import 'settings_state.dart';

List<Widget> getAppearanceSettings(
  BuildContext context,
  String term,
  SettingsState settings,
) {
  return [
    if ('theme'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: space16),
        child: DropdownButtonFormField<ThemeMode>(
          initialValue: ThemeMode.values
              .byName(settings.value.themeMode.replaceFirst('ThemeMode.', '')),
          decoration: InputDecoration(
            labelText: 'Theme',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            border: const OutlineInputBorder(borderRadius: brSm),
          ),
          items: const [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('System'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('Dark'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('Light'),
            ),
          ],
          onChanged: (value) => db.settings.update().write(
                SettingsCompanion(
                  themeMode: Value(value.toString()),
                ),
              ),
        ),
      ),
    if ('system color scheme'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.only(top: space8),
        child: Tooltip(
          message: 'Use the primary color of your device for the app',
          child: ListTile(
            title: const Text('System color scheme'),
            leading: settings.value.systemColors
                ? const Icon(Icons.color_lens)
                : const Icon(Icons.color_lens_outlined),
            onTap: () => db.settings.update().write(
                  SettingsCompanion(
                    systemColors: Value(!settings.value.systemColors),
                  ),
                ),
            trailing: Switch(
              value: settings.value.systemColors,
              onChanged: (value) => db.settings.update().write(
                    SettingsCompanion(
                      systemColors: Value(value),
                    ),
                  ),
            ),
          ),
        ),
      ),
    if ('custom color'.contains(term.toLowerCase()) ||
        'app color'.contains(term.toLowerCase()))
      Padding(
        padding: const EdgeInsets.only(top: space8),
        child: Tooltip(
          message: 'Choose a custom color for your app theme',
          child: ListTile(
            title: const Text('Custom app color'),
            subtitle: Text(
              settings.value.systemColors
                  ? 'Disabled (using system colors)'
                  : 'Tap to customize',
              style: TextStyle(
                color: settings.value.systemColors
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : null,
              ),
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: effectiveSeed(settings.value.customColorSeed),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: effectiveSeed(settings.value.customColorSeed)
                        .withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              // White reads legibly on any arbitrary user-chosen swatch color,
              // same rationale as the artistic_color_picker literal exception.
              child: const Icon(Icons.palette, color: Colors.white, size: 20),
            ),
            enabled: !settings.value.systemColors,
            onTap: settings.value.systemColors
                ? null
                : () async {
                    final color = await showDialog<Color>(
                      context: context,
                      builder: (context) => ArtisticColorPicker(
                        initialColor:
                            effectiveSeed(settings.value.customColorSeed),
                        onColorChanged: (color) {},
                      ),
                    );
                    if (color != null) {
                      await db.settings.update().write(
                            SettingsCompanion(
                              customColorSeed: Value(color.toARGB32()),
                            ),
                          );
                    }
                  },
            trailing: settings.value.systemColors
                ? null
                : Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    if ('show images'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Pick/display images on the history page',
        child: ListTile(
          title: const Text('Show images'),
          leading: settings.value.showImages
              ? const Icon(Icons.image)
              : const Icon(Icons.image_outlined),
          onTap: () => db.settings.update().write(
                SettingsCompanion(
                  showImages: Value(!settings.value.showImages),
                ),
              ),
          trailing: Switch(
            value: settings.value.showImages,
            onChanged: (value) => db.settings.update().write(
                  SettingsCompanion(
                    showImages: Value(value),
                  ),
                ),
          ),
        ),
      ),
    if ('5/3/1 auto-fill'.contains(term.toLowerCase()) ||
        'five three one'.contains(term.toLowerCase()))
      Tooltip(
        message: 'Load Squat, Bench Press, Deadlift and Overhead Press from '
            'the active block instead of last session, and cheer you on',
        child: ListTile(
          title: const Text('5/3/1 auto-fill'),
          subtitle: const Text('Main lifts use training max weights'),
          leading: settings.value.fivethreeoneAutofill
              ? const Icon(Icons.local_fire_department)
              : const Icon(Icons.local_fire_department_outlined),
          onTap: () => db.settings.update().write(
                SettingsCompanion(
                  fivethreeoneAutofill:
                      Value(!settings.value.fivethreeoneAutofill),
                ),
              ),
          trailing: Switch(
            value: settings.value.fivethreeoneAutofill,
            onChanged: (value) => db.settings.update().write(
                  SettingsCompanion(
                    fivethreeoneAutofill: Value(value),
                  ),
                ),
          ),
        ),
      ),
  ];
}

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(space8),
        child: ListView(
          children: getAppearanceSettings(context, '', settings),
        ),
      ),
    );
  }
}
