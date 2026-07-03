import 'package:drift/drift.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../animated_fab.dart';
import '../database/database.dart';
import '../main.dart';
import '../theme/tokens.dart';
import '../utils.dart';
import 'settings_state.dart';

class TabSettings extends StatefulWidget {
  const TabSettings({super.key});

  @override
  _TabSettingsState createState() => _TabSettingsState();
}

typedef TabSetting = ({
  String name,
  bool enabled,
});

class _TabSettingsState extends State<TabSettings> {
  List<TabSetting> tabs = [
    (name: 'HistoryPage', enabled: false),
    (name: 'PlansPage', enabled: false),
    (name: 'MusicPage', enabled: false),
    (name: 'GraphsPage', enabled: false),
    (name: 'NotesPage', enabled: false),
    (name: 'SettingsPage', enabled: false),
  ];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsState>();
    final tabSplit = settings.value.tabs.split(',');

    final enabled = tabSplit.map((tab) => (name: tab, enabled: true)).toList();
    final disabled = tabs.where((tab) => !tabSplit.contains(tab.name)).toList();

    tabs = enabled + disabled;
  }

  void setTab(String name, bool enabled) {
    if (!enabled && tabs.where((tab) => tab.enabled == true).length == 1)
      return toast('You need at least one tab');
    final index = tabs.indexWhere((tappedTab) => tappedTab.name == name);
    setState(() {
      tabs[index] = (name: name, enabled: enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Tabs')),
      body: Padding(
        padding: const EdgeInsets.all(space8),
        child: material.Column(
          children: [
            ListTile(
              title: const material.Row(
                children: [
                  Icon(Icons.swipe),
                  SizedBox(width: space8),
                  Text('Swipe between tabs'),
                ],
              ),
              onTap: () => db.settings.update().write(
                    SettingsCompanion(
                      scrollableTabs: Value(!settings.value.scrollableTabs),
                    ),
                  ),
              leading: Switch(
                value: settings.value.scrollableTabs,
                onChanged: (value) {
                  db.settings.update().write(
                        SettingsCompanion(
                          scrollableTabs: Value(value),
                        ),
                      );
                },
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) {
                    newIndex--;
                  }

                  final temp = tabs[oldIndex];
                  setState(() {
                    tabs.removeAt(oldIndex);
                    tabs.insert(newIndex, temp);
                  });
                },
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  if (tab.name == 'HistoryPage') {
                    return ListTile(
                      key: Key(tab.name),
                      onTap: () => setTab(tab.name, !tab.enabled),
                      leading: Switch(
                        value: tab.enabled,
                        onChanged: (value) => setTab(tab.name, value),
                      ),
                      title: const material.Row(
                        children: [
                          Icon(Icons.history),
                          SizedBox(width: space8),
                          Text('History'),
                        ],
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    );
                  } else if (tab.name == 'PlansPage') {
                    return ListTile(
                      key: Key(tab.name),
                      onTap: () => setTab(tab.name, !tab.enabled),
                      leading: Switch(
                        value: tab.enabled,
                        onChanged: (value) => setTab(tab.name, value),
                      ),
                      title: const material.Row(
                        children: [
                          Icon(Icons.calendar_today_outlined),
                          SizedBox(width: space8),
                          Text('Plans'),
                        ],
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    );
                  } else if (tab.name == 'MusicPage') {
                    return ListTile(
                      key: Key(tab.name),
                      onTap: () => setTab(tab.name, !tab.enabled),
                      leading: Switch(
                        value: tab.enabled,
                        onChanged: (value) => setTab(tab.name, value),
                      ),
                      title: const material.Row(
                        children: [
                          Icon(Icons.music_note),
                          SizedBox(width: space8),
                          Text('Music'),
                        ],
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    );
                  } else if (tab.name == 'GraphsPage') {
                    return ListTile(
                      key: Key(tab.name),
                      onTap: () => setTab(tab.name, !tab.enabled),
                      leading: Switch(
                        value: tab.enabled,
                        onChanged: (value) => setTab(tab.name, value),
                      ),
                      title: const material.Row(
                        children: [
                          Icon(Icons.insights_rounded),
                          SizedBox(width: space8),
                          Text('Graphs'),
                        ],
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    );
                  } else if (tab.name == 'NotesPage') {
                    return ListTile(
                      key: Key(tab.name),
                      onTap: () => setTab(tab.name, !tab.enabled),
                      leading: Switch(
                        value: tab.enabled,
                        onChanged: (value) => setTab(tab.name, value),
                      ),
                      title: const material.Row(
                        children: [
                          Icon(Icons.note),
                          SizedBox(width: space8),
                          Text('Notes'),
                        ],
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    );
                  } else if (tab.name == 'SettingsPage') {
                    return ListTile(
                      key: Key(tab.name),
                      onTap: () => setTab(tab.name, !tab.enabled),
                      leading: Switch(
                        value: tab.enabled,
                        onChanged: (value) => setTab(tab.name, value),
                      ),
                      title: const material.Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: space8),
                          Text('Settings'),
                        ],
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    );
                  } else
                    return ErrorWidget('Invalid tab settings.');
                },
                itemCount: tabs.length,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () async {
          await db.settings.update().write(
                SettingsCompanion(
                  tabs: Value(
                    tabs
                        .where((tab) => tab.enabled)
                        .map((tab) => tab.name)
                        .join(','),
                  ),
                ),
              );
          if (context.mounted) Navigator.of(context).pop();
        },
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
    );
  }
}
