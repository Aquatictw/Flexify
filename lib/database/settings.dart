import 'package:drift/drift.dart';

class Settings extends Table {
  TextColumn get alarmSound => text()();
  BoolColumn get automaticBackups =>
      boolean().withDefault(const Constant(false))();
  TextColumn get backupPath => text().nullable()();
  TextColumn get cardioUnit => text()();
  BoolColumn get curveLines => boolean()();
  RealColumn get curveSmoothness => real().nullable()();
  BoolColumn get durationEstimation =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get enableSound => boolean().withDefault(const Constant(true))();
  BoolColumn get explainedPermissions => boolean()();
  BoolColumn get groupHistory => boolean().withDefault(const Constant(true))();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get longDateFormat => text()();
  IntColumn get maxSets => integer()();
  BoolColumn get notifications => boolean().withDefault(const Constant(true))();
  BoolColumn get peekGraph => boolean().withDefault(const Constant(false))();
  TextColumn get planTrailing => text()();
  BoolColumn get repEstimation => boolean().withDefault(const Constant(true))();
  BoolColumn get restTimers => boolean()();
  TextColumn get shortDateFormat => text()();
  BoolColumn get showCategories =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showImages => boolean().withDefault(const Constant(true))();
  BoolColumn get showNotes => boolean().withDefault(const Constant(true))();
  BoolColumn get showGlobalProgress =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showUnits => boolean().withDefault(const Constant(false))();
  TextColumn get strengthUnit => text()();
  BoolColumn get systemColors => boolean()();
  TextColumn get tabs => text().withDefault(
        const Constant(
            'HistoryPage,PlansPage,MusicPage,GraphsPage,NotesPage,SettingsPage',),
      )();
  TextColumn get themeMode => text()();
  IntColumn get timerDuration => integer()();
  BoolColumn get vibrate => boolean()();
  IntColumn get warmupSets => integer().nullable()();
  BoolColumn get scrollableTabs =>
      boolean().withDefault(const Constant(true))();
  // 5/3/1 Training Max values (in user's preferred unit)
  RealColumn get fivethreeoneSquatTm => real().nullable()();
  RealColumn get fivethreeoneBenchTm => real().nullable()();
  RealColumn get fivethreeoneDeadliftTm => real().nullable()();
  RealColumn get fivethreeonePressTm => real().nullable()();
  IntColumn get fivethreeoneWeek => integer().withDefault(const Constant(1))();
  // Auto-fill 5/3/1 main lifts from the active block instead of last session
  BoolColumn get fivethreeoneAutofill =>
      boolean().withDefault(const Constant(true))();
  IntColumn get customColorSeed => integer()
      .withDefault(const Constant(0xFF673AB7))(); // Default: deep purple
  DateTimeColumn get lastAutoBackupTime => dateTime().nullable()();
  TextColumn get lastBackupStatus => text().nullable()();
  // Values: null (never attempted), 'success', 'failed'
  // Spotify integration tokens
  TextColumn get spotifyAccessToken => text().nullable()();
  TextColumn get spotifyRefreshToken => text().nullable()();
  IntColumn get spotifyTokenExpiry => integer().nullable()();
  // Server backup push settings
  TextColumn get serverUrl => text().nullable()();
  TextColumn get serverApiKey => text().nullable()();
  DateTimeColumn get lastPushTime => dateTime().nullable()();
  TextColumn get lastPushStatus => text().nullable()();
}
