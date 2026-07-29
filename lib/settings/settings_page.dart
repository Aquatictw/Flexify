import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../theme/tokens.dart';
import 'appearance_settings.dart';
import 'data_settings.dart';
import 'format_settings.dart';
import 'plan_settings.dart';
import 'settings_state.dart';
import '../server/server_settings_page.dart';
import '../widgets/depth_ember_reveal.dart';
import 'spotify_settings.dart';
import 'tab_settings.dart';
import 'timer_settings.dart';
import 'workout_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  final searchCtrl = TextEditingController();

  late final Setting settings;
  late final TextEditingController maxSets;
  late final TextEditingController warmupSets;
  late final TextEditingController minutes;
  late final TextEditingController seconds;

  AudioPlayer? player;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<Widget> filtered = [];
    final settings = context.watch<SettingsState>();
    if (searchCtrl.text.isNotEmpty) {
      filtered.addAll(
        getAppearanceSettings(context, searchCtrl.text, settings),
      );
      filtered.addAll(getFormatSettings(searchCtrl.text, settings.value));
      filtered.addAll(
        getWorkoutSettings(
          context,
          searchCtrl.text,
          settings.value,
        ),
      );
      if (player != null)
        filtered.addAll(
          getTimerSettings(
            searchCtrl.text,
            settings.value,
            minutes,
            seconds,
            player!,
            context,
          ),
        );
      filtered.addAll(getDataSettings(searchCtrl.text, settings, context));
      filtered.addAll(
        getPlanSettings(
          searchCtrl.text,
          settings.value,
          maxSets,
          warmupSets,
        ),
      );
      filtered.addAll(
        getSpotifySettings(
          context,
          searchCtrl.text,
          settings,
        ),
      );
    }

    if (filtered.isEmpty)
      filtered = [
        const ListTile(
          title: Text('No settings found'),
        ),
      ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(space8),
        child: Column(
          children: <Widget>[
            SearchBar(
              hintText: 'Search...',
              controller: searchCtrl,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: space16),
              ),
              onChanged: (_) {
                setState(() {});
              },
              leading: const Icon(Icons.search),
            ),
            const SizedBox(
              height: space8,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
                children: searchCtrl.text.isNotEmpty
                    ? filtered
                    : [
                        RevealBlock(
                          child: ListTile(
                            leading: const Icon(Icons.color_lens),
                            title: const Text('Appearance'),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AppearanceSettings(),
                              ),
                            ),
                          ),
                        ),
                        RevealBlock(
                          index: 1,
                          child: ListTile(
                            leading: const Icon(Icons.storage),
                            title: const Text('Data management'),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const DataSettings(),
                              ),
                            ),
                          ),
                        ),
                        RevealBlock(
                          index: 2,
                          child: ListTile(
                            leading: const Icon(Icons.cloud_upload),
                            title: const Text('Backup Server'),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ServerSettingsPage(),
                              ),
                            ),
                          ),
                        ),
                        RevealBlock(
                          index: 3,
                          child: ListTile(
                            leading: const Icon(Icons.format_bold),
                            title: const Text('Plans & Formats'),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PlansAndFormatsSettings(),
                              ),
                            ),
                          ),
                        ),
                        RevealBlock(
                          index: 4,
                          child: ListTile(
                            leading: const Icon(Icons.tab_sharp),
                            title: const Text('Tabs'),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const TabSettings(),
                              ),
                            ),
                          ),
                        ),
                        RevealBlock(
                          index: 5,
                          child: ListTile(
                            leading: const Icon(Icons.timer),
                            title: const Text('Timers'),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const TimerSettings(),
                              ),
                            ),
                          ),
                        ),
                        RevealBlock(
                          index: 6,
                          child: ListTile(
                            leading: const Icon(Icons.music_note),
                            title: const Text('Spotify'),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SpotifySettings(),
                              ),
                            ),
                          ),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    maxSets.dispose();
    warmupSets.dispose();
    minutes.dispose();
    seconds.dispose();
    player?.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    settings = context.read<SettingsState>().value;
    maxSets = TextEditingController(text: settings.maxSets.toString());
    warmupSets = TextEditingController(text: settings.warmupSets?.toString());
    minutes = TextEditingController(
      text: Duration(milliseconds: settings.timerDuration).inMinutes.toString(),
    );
    seconds = TextEditingController(
      text: (Duration(milliseconds: settings.timerDuration).inSeconds % 60)
          .toString(),
    );

    if (!kIsWeb) {
      try {
        player = AudioPlayer();
      } catch (e) {
        print('Failed to create AudioPlayer: $e');
        player = null;
      }
    }
  }
}
