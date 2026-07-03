import 'package:drift/drift.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'backup/auto_backup_service.dart';
import 'constants.dart';
import 'database/database.dart';
import 'database/failed_migrations_page.dart';
import 'fivethreeone/fivethreeone_state.dart';
import 'home_page.dart';
import 'plan/plan_state.dart';
import 'screens/splash_screen.dart';
import 'settings/settings_state.dart';
import 'theme/app_theme.dart';
import 'spotify/spotify_state.dart';
import 'timer/timer_state.dart';
import 'workouts/workout_state.dart';

final rootScaffoldMessenger = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Setting setting;

  try {
    final settingOrNull = await (db.settings.select()..limit(1)).getSingleOrNull();

    if (settingOrNull == null) {
      // Settings table is empty - create default settings
      print('⚠️ Settings table is empty, creating default settings...');
      await db.settings.insertOne(defaultSettings);
      setting = await (db.settings.select()..limit(1)).getSingle();
      print('✓ Default settings created successfully');
    } else {
      setting = settingOrNull;
    }
  } catch (error) {
    return runApp(FailedMigrationsPage(error: error));
  }

  final state = SettingsState(setting);
  runApp(appProviders(state));
}

AppDatabase db = AppDatabase();

MethodChannel androidChannel =
    const MethodChannel('com.presley.jackedlog/android');

Widget appProviders(SettingsState state) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => state),
        ChangeNotifierProvider(create: (context) => TimerState()),
        ChangeNotifierProvider(create: (context) => PlanState()),
        ChangeNotifierProvider(create: (context) => WorkoutState()),
        ChangeNotifierProvider(create: (context) => SpotifyState()),
        ChangeNotifierProvider(create: (context) => FiveThreeOneState()),
      ],
      child: const App(),
    );

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Trigger auto-backup when app is paused or detached
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AutoBackupService.performAutoBackup();
    }
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen during initialization
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          onInitComplete: _onSplashComplete,
        ),
      );
    }

    final colors = context.select<SettingsState, bool>(
      (settings) => settings.value.systemColors,
    );
    final mode = context.select<SettingsState, ThemeMode>(
      (settings) => ThemeMode.values
          .byName(settings.value.themeMode.replaceFirst('ThemeMode.', '')),
    );
    final customColor = context.select<SettingsState, int>(
      (settings) => settings.value.customColorSeed,
    );

    final light = jlScheme(customColor, Brightness.light);
    final dark = jlScheme(customColor, Brightness.dark);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final settings = context.watch<SettingsState>();
        final currentBrightness =
            settings.value.themeMode == 'ThemeMode.dark' ||
                    (settings.value.themeMode == 'ThemeMode.system' &&
                        MediaQuery.of(context).platformBrightness ==
                            Brightness.dark)
                ? Brightness.dark
                : Brightness.light;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarIconBrightness: currentBrightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarIconBrightness:
                currentBrightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          ),
        );

        return MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessenger,
          title: 'JackedLog',
          theme: jlTheme((colors ? lightDynamic : null) ?? light),
          darkTheme: jlTheme((colors ? darkDynamic : null) ?? dark),
          themeMode: mode,
          home: const HomePage(),
        );
      },
    );
  }
}
