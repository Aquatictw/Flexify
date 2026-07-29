// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class Plans extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Plans(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> days = GeneratedColumn<String>(
      'days', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  @override
  List<GeneratedColumn> get $columns => [days, id, sequence, title];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  Plans createAlias(String alias) {
    return Plans(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class GymSets extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GymSets(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> cardio = GeneratedColumn<int>(
      'cardio', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0 CHECK (cardio IN (0, 1))',
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
      'created', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
      'distance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0.0',
      defaultValue: const CustomExpression('0.0'));
  late final GeneratedColumn<double> duration = GeneratedColumn<double>(
      'duration', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0.0',
      defaultValue: const CustomExpression('0.0'));
  late final GeneratedColumn<int> hidden = GeneratedColumn<int>(
      'hidden', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0 CHECK (hidden IN (0, 1))',
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
      'image', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> incline = GeneratedColumn<int>(
      'incline', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
      'plan_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<double> reps = GeneratedColumn<double>(
      'reps', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> restMs = GeneratedColumn<int>(
      'rest_ms', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> warmup = GeneratedColumn<int>(
      'warmup', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0 CHECK (warmup IN (0, 1))',
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
      'workout_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> exerciseType = GeneratedColumn<String>(
      'exercise_type', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> brandName = GeneratedColumn<String>(
      'brand_name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> cardioMetric = GeneratedColumn<String>(
      'cardio_metric', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> dropSet = GeneratedColumn<int>(
      'drop_set', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0 CHECK (drop_set IN (0, 1))',
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<String> supersetId = GeneratedColumn<String>(
      'superset_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> supersetPosition = GeneratedColumn<int>(
      'superset_position', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> setOrder = GeneratedColumn<int>(
      'set_order', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  @override
  List<GeneratedColumn> get $columns => [
        cardio,
        category,
        created,
        distance,
        duration,
        hidden,
        id,
        image,
        incline,
        name,
        notes,
        planId,
        reps,
        restMs,
        sequence,
        unit,
        warmup,
        weight,
        workoutId,
        exerciseType,
        brandName,
        cardioMetric,
        dropSet,
        supersetId,
        supersetPosition,
        setOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gym_sets';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  GymSets createAlias(String alias) {
    return GymSets(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Settings extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Settings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> alarmSound = GeneratedColumn<String>(
      'alarm_sound', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> automaticBackups = GeneratedColumn<int>(
      'automatic_backups', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'NOT NULL DEFAULT 0 CHECK (automatic_backups IN (0, 1))',
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<String> backupPath = GeneratedColumn<String>(
      'backup_path', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> cardioUnit = GeneratedColumn<String>(
      'cardio_unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> curveLines = GeneratedColumn<int>(
      'curve_lines', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK (curve_lines IN (0, 1))');
  late final GeneratedColumn<double> curveSmoothness = GeneratedColumn<double>(
      'curve_smoothness', aliasedName, true,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> durationEstimation = GeneratedColumn<int>(
      'duration_estimation', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'NOT NULL DEFAULT 1 CHECK (duration_estimation IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> enableSound = GeneratedColumn<int>(
      'enable_sound', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 1 CHECK (enable_sound IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> explainedPermissions = GeneratedColumn<int>(
      'explained_permissions', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK (explained_permissions IN (0, 1))');
  late final GeneratedColumn<int> groupHistory = GeneratedColumn<int>(
      'group_history', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 1 CHECK (group_history IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<String> longDateFormat = GeneratedColumn<String>(
      'long_date_format', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> maxSets = GeneratedColumn<int>(
      'max_sets', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> notifications = GeneratedColumn<int>(
      'notifications', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 1 CHECK (notifications IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> peekGraph = GeneratedColumn<int>(
      'peek_graph', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0 CHECK (peek_graph IN (0, 1))',
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<String> planTrailing = GeneratedColumn<String>(
      'plan_trailing', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> repEstimation = GeneratedColumn<int>(
      'rep_estimation', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 1 CHECK (rep_estimation IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> restTimers = GeneratedColumn<int>(
      'rest_timers', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK (rest_timers IN (0, 1))');
  late final GeneratedColumn<String> shortDateFormat = GeneratedColumn<String>(
      'short_date_format', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> showCategories = GeneratedColumn<int>(
      'show_categories', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'NOT NULL DEFAULT 1 CHECK (show_categories IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> showImages = GeneratedColumn<int>(
      'show_images', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 1 CHECK (show_images IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> showNotes = GeneratedColumn<int>(
      'show_notes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 1 CHECK (show_notes IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> showGlobalProgress = GeneratedColumn<int>(
      'show_global_progress', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'NOT NULL DEFAULT 1 CHECK (show_global_progress IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> showUnits = GeneratedColumn<int>(
      'show_units', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0 CHECK (show_units IN (0, 1))',
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<String> strengthUnit = GeneratedColumn<String>(
      'strength_unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> systemColors = GeneratedColumn<int>(
      'system_colors', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK (system_colors IN (0, 1))');
  late final GeneratedColumn<String> tabs = GeneratedColumn<String>(
      'tabs', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints:
          'NOT NULL DEFAULT \'HistoryPage,PlansPage,MusicPage,GraphsPage,NotesPage,SettingsPage\'',
      defaultValue: const CustomExpression(
          '\'HistoryPage,PlansPage,MusicPage,GraphsPage,NotesPage,SettingsPage\''));
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> timerDuration = GeneratedColumn<int>(
      'timer_duration', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> vibrate = GeneratedColumn<int>(
      'vibrate', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK (vibrate IN (0, 1))');
  late final GeneratedColumn<int> warmupSets = GeneratedColumn<int>(
      'warmup_sets', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> scrollableTabs = GeneratedColumn<int>(
      'scrollable_tabs', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'NOT NULL DEFAULT 1 CHECK (scrollable_tabs IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<double> fivethreeoneSquatTm =
      GeneratedColumn<double>('fivethreeone_squat_tm', aliasedName, true,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          $customConstraints: 'NULL');
  late final GeneratedColumn<double> fivethreeoneBenchTm =
      GeneratedColumn<double>('fivethreeone_bench_tm', aliasedName, true,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          $customConstraints: 'NULL');
  late final GeneratedColumn<double> fivethreeoneDeadliftTm =
      GeneratedColumn<double>('fivethreeone_deadlift_tm', aliasedName, true,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          $customConstraints: 'NULL');
  late final GeneratedColumn<double> fivethreeonePressTm =
      GeneratedColumn<double>('fivethreeone_press_tm', aliasedName, true,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          $customConstraints: 'NULL');
  late final GeneratedColumn<int> fivethreeoneWeek = GeneratedColumn<int>(
      'fivethreeone_week', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 1',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> fivethreeoneAutofill = GeneratedColumn<int>(
      'fivethreeone_autofill', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'NOT NULL DEFAULT 1 CHECK (fivethreeone_autofill IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> customColorSeed = GeneratedColumn<int>(
      'custom_color_seed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 4284955319',
      defaultValue: const CustomExpression('4284955319'));
  late final GeneratedColumn<int> lastAutoBackupTime = GeneratedColumn<int>(
      'last_auto_backup_time', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> lastBackupStatus = GeneratedColumn<String>(
      'last_backup_status', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> spotifyAccessToken =
      GeneratedColumn<String>('spotify_access_token', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'NULL');
  late final GeneratedColumn<String> spotifyRefreshToken =
      GeneratedColumn<String>('spotify_refresh_token', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'NULL');
  late final GeneratedColumn<int> spotifyTokenExpiry = GeneratedColumn<int>(
      'spotify_token_expiry', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> serverUrl = GeneratedColumn<String>(
      'server_url', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> serverApiKey = GeneratedColumn<String>(
      'server_api_key', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> lastPushTime = GeneratedColumn<int>(
      'last_push_time', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> lastPushStatus = GeneratedColumn<String>(
      'last_push_status', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  @override
  List<GeneratedColumn> get $columns => [
        alarmSound,
        automaticBackups,
        backupPath,
        cardioUnit,
        curveLines,
        curveSmoothness,
        durationEstimation,
        enableSound,
        explainedPermissions,
        groupHistory,
        id,
        longDateFormat,
        maxSets,
        notifications,
        peekGraph,
        planTrailing,
        repEstimation,
        restTimers,
        shortDateFormat,
        showCategories,
        showImages,
        showNotes,
        showGlobalProgress,
        showUnits,
        strengthUnit,
        systemColors,
        tabs,
        themeMode,
        timerDuration,
        vibrate,
        warmupSets,
        scrollableTabs,
        fivethreeoneSquatTm,
        fivethreeoneBenchTm,
        fivethreeoneDeadliftTm,
        fivethreeonePressTm,
        fivethreeoneWeek,
        fivethreeoneAutofill,
        customColorSeed,
        lastAutoBackupTime,
        lastBackupStatus,
        spotifyAccessToken,
        spotifyRefreshToken,
        spotifyTokenExpiry,
        serverUrl,
        serverApiKey,
        lastPushTime,
        lastPushStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  Settings createAlias(String alias) {
    return Settings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PlanExercises extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PlanExercises(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> enabled = GeneratedColumn<int>(
      'enabled', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK (enabled IN (0, 1))');
  late final GeneratedColumn<int> timers = GeneratedColumn<int>(
      'timers', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 1 CHECK (timers IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<String> exercise = GeneratedColumn<String>(
      'exercise', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES gym_sets(name)');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<int> maxSets = GeneratedColumn<int>(
      'max_sets', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
      'plan_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL REFERENCES plans(id)');
  late final GeneratedColumn<int> warmupSets = GeneratedColumn<int>(
      'warmup_sets', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  @override
  List<GeneratedColumn> get $columns =>
      [enabled, timers, exercise, id, maxSets, planId, warmupSets, sequence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_exercises';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  PlanExercises createAlias(String alias) {
    return PlanExercises(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Metadata extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Metadata(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> buildNumber = GeneratedColumn<int>(
      'build_number', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [buildNumber];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metadata';
  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  Metadata createAlias(String alias) {
    return Metadata(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Workouts extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Workouts(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
      'start_time', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
      'end_time', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
      'plan_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> selfieImagePath = GeneratedColumn<String>(
      'selfie_image_path', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  @override
  List<GeneratedColumn> get $columns =>
      [id, startTime, endTime, planId, name, notes, selfieImagePath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  Workouts createAlias(String alias) {
    return Workouts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Notes extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Notes(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
      'created', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> updated = GeneratedColumn<int>(
      'updated', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, content, created, updated, color, sequence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  Notes createAlias(String alias) {
    return Notes(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class BodyweightEntries extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  BodyweightEntries(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
      'date', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  @override
  List<GeneratedColumn> get $columns => [id, weight, unit, date, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bodyweight_entries';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  BodyweightEntries createAlias(String alias) {
    return BodyweightEntries(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ChatMessages extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ChatMessages(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
      'workout_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> toolCalls = GeneratedColumn<String>(
      'tool_calls', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> toolCallId = GeneratedColumn<String>(
      'tool_call_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
      'created', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns =>
      [id, workoutId, role, content, toolCalls, toolCallId, created];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  ChatMessages createAlias(String alias) {
    return ChatMessages(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class FiveThreeOneBlocks extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FiveThreeOneBlocks(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
      'created', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<double> squatTm = GeneratedColumn<double>(
      'squat_tm', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<double> benchTm = GeneratedColumn<double>(
      'bench_tm', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<double> deadliftTm = GeneratedColumn<double>(
      'deadlift_tm', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<double> pressTm = GeneratedColumn<double>(
      'press_tm', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<double> startSquatTm = GeneratedColumn<double>(
      'start_squat_tm', aliasedName, true,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<double> startBenchTm = GeneratedColumn<double>(
      'start_bench_tm', aliasedName, true,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<double> startDeadliftTm = GeneratedColumn<double>(
      'start_deadlift_tm', aliasedName, true,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<double> startPressTm = GeneratedColumn<double>(
      'start_press_tm', aliasedName, true,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> currentCycle = GeneratedColumn<int>(
      'current_cycle', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<int> currentWeek = GeneratedColumn<int>(
      'current_week', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 1',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> isActive = GeneratedColumn<int>(
      'is_active', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))',
      defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<int> completed = GeneratedColumn<int>(
      'completed', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> leaderSupplemental =
      GeneratedColumn<String>('leader_supplemental', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'NOT NULL DEFAULT \'bbb\'',
          defaultValue: const CustomExpression('\'bbb\''));
  late final GeneratedColumn<String> anchorSupplemental =
      GeneratedColumn<String>('anchor_supplemental', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'NOT NULL DEFAULT \'fsl\'',
          defaultValue: const CustomExpression('\'fsl\''));
  late final GeneratedColumn<int> tmBumps = GeneratedColumn<int>(
      'tm_bumps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL DEFAULT 0',
      defaultValue: const CustomExpression('0'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        created,
        squatTm,
        benchTm,
        deadliftTm,
        pressTm,
        startSquatTm,
        startBenchTm,
        startDeadliftTm,
        startPressTm,
        unit,
        currentCycle,
        currentWeek,
        isActive,
        completed,
        leaderSupplemental,
        anchorSupplemental,
        tmBumps
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'five_three_one_blocks';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  FiveThreeOneBlocks createAlias(String alias) {
    return FiveThreeOneBlocks(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DatabaseAtV71 extends GeneratedDatabase {
  DatabaseAtV71(QueryExecutor e) : super(e);
  late final Plans plans = Plans(this);
  late final GymSets gymSets = GymSets(this);
  late final Settings settings = Settings(this);
  late final PlanExercises planExercises = PlanExercises(this);
  late final Metadata metadata = Metadata(this);
  late final Workouts workouts = Workouts(this);
  late final Notes notes = Notes(this);
  late final BodyweightEntries bodyweightEntries = BodyweightEntries(this);
  late final ChatMessages chatMessages = ChatMessages(this);
  late final FiveThreeOneBlocks fiveThreeOneBlocks = FiveThreeOneBlocks(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        plans,
        gymSets,
        settings,
        planExercises,
        metadata,
        workouts,
        notes,
        bodyweightEntries,
        chatMessages,
        fiveThreeOneBlocks
      ];
  @override
  int get schemaVersion => 71;
}
