import 'package:drift/drift.dart';

import '../constants.dart';
import 'bodyweight_entries.dart';
import 'database_connection_native.dart';
import 'defaults.dart';
import 'fivethreeone_blocks.dart';
import 'gym_sets.dart';
import 'metadata.dart';
import 'notes.dart';
import 'plan_exercises.dart';
import 'plans.dart';
import 'settings.dart';
import 'workouts.dart';

part 'database.g.dart';

LazyDatabase openConnection() {
  return createNativeConnection();
}

@DriftDatabase(
  tables: [
    Plans,
    GymSets,
    Settings,
    PlanExercises,
    Metadata,
    Workouts,
    Notes,
    BodyweightEntries,
    FiveThreeOneBlocks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await m.createIndex(
          Index(
            'GymSets',
            'CREATE INDEX IF NOT EXISTS gym_sets_name_created ON gym_sets(name, created);',
          ),
        );
        await m.createIndex(
          Index(
            'gym_sets',
            'CREATE INDEX IF NOT EXISTS gym_sets_workout_id ON gym_sets(workout_id)',
          ),
        );

        await batch((batch) {
          batch.insertAll(gymSets, defaultSets);
          batch.insertAll(plans, defaultPlans);
          batch.insertAll(planExercises, defaultPlanExercises);
        });

        await settings.insertOne(defaultSettings);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Reject unsupported database versions (< v31)
        if (from < 31) {
          throw UnsupportedError(
            'Database version $from is too old (minimum: v31).\n'
            'Please export your data, uninstall the app, then reinstall and import.',
          );
        }

        // Consolidated migration handlers
        // Each handler runs when crossing its version boundary

        // from31To48: Consolidates v31-v47 changes
        // Runs when migrating FROM a version <=47 TO a version >=48
        if (from < 48 && to >= 48) {
          // v31→32: Reset estimation settings
          await m.database.customUpdate(
            'UPDATE settings SET rep_estimation = 0, duration_estimation = 0',
          );

          // v32→33: Add peekGraph setting
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN peek_graph INTEGER',
              )
              .catchError((e) {});

          // v33→34: Add curve_smoothness and notifications
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN curve_smoothness INTEGER',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN notifications INTEGER',
              )
              .catchError((e) {});

          // v35→36: Add showCategories
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN show_categories INTEGER',
              )
              .catchError((e) {});

          // v36→37: Add showNotes
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN show_notes INTEGER',
              )
              .catchError((e) {});

          // v37→38: Add notes to gymSets
          await m.database
              .customStatement(
                'ALTER TABLE gym_sets ADD COLUMN notes TEXT',
              )
              .catchError((e) {});

          // v38→39: Add showGlobalProgress
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN show_global_progress INTEGER',
              )
              .catchError((e) {});

          // v39→40: Create metadata table
          await m.database.customStatement('''
            CREATE TABLE IF NOT EXISTS metadata (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              key TEXT NOT NULL UNIQUE,
              value TEXT NOT NULL
            )
          ''');

          // v40→41: Update unit settings
          await m.database.customUpdate(
            "UPDATE settings SET strength_unit = 'last-entry', cardio_unit = 'last-entry'",
          );

          // v42→43: Add scrollableTabs
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN scrollable_tabs INTEGER',
              )
              .catchError((e) {});

          // v43→44: Delete disabled plan exercises
          await m.database.customStatement('''
            DELETE FROM plan_exercises WHERE enabled = 0
          ''');

          // v45→46: Add and backfill sequence column in plan_exercises
          await m.database
              .customStatement(
                'ALTER TABLE plan_exercises ADD COLUMN sequence INTEGER',
              )
              .catchError((e) {});
          await m.database.customStatement('''
            UPDATE plan_exercises
            SET sequence = (
              SELECT COUNT(*)
              FROM plan_exercises pe2
              WHERE pe2.plan_id = plan_exercises.plan_id
                AND pe2.id < plan_exercises.id
            )
          ''');

          // v46→47: Update settings defaults
          await m.database.customUpdate(
            'UPDATE settings SET group_history = 1, show_units = 0, show_body_weight = 0, rep_estimation = 1',
          );

          // v47→48: Create workouts table and add workout_id to gym_sets
          await m.database.customStatement('''
            CREATE TABLE IF NOT EXISTS workouts (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              start_time INTEGER NOT NULL,
              end_time INTEGER,
              plan_id INTEGER,
              name TEXT,
              notes TEXT
            )
          ''');
          await m.database
              .customStatement(
                'ALTER TABLE gym_sets ADD COLUMN workout_id INTEGER',
              )
              .catchError((e) {});
          await m.createIndex(
            Index(
              'gym_sets',
              'CREATE INDEX IF NOT EXISTS gym_sets_workout_id ON gym_sets(workout_id)',
            ),
          );
        }

        // from48To52: Consolidates v48-v51 changes
        // Runs when migrating FROM a version <=51 TO a version >=52
        if (from < 52 && to >= 52) {
          // v48→49: Add sequence column to gym_sets
          await m.database
              .customStatement(
                'ALTER TABLE gym_sets ADD COLUMN sequence INTEGER',
              )
              .catchError((e) {});

          // v49→50: Add warmup flag
          await m.database
              .customStatement(
                'ALTER TABLE gym_sets ADD COLUMN warmup INTEGER',
              )
              .catchError((e) {});

          // v50→52: Add exercise_type, brand_name, create notes table
          await m.database
              .customStatement(
                'ALTER TABLE gym_sets ADD COLUMN exercise_type TEXT',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE gym_sets ADD COLUMN brand_name TEXT',
              )
              .catchError((e) {});
          await m.database.customStatement('''
            CREATE TABLE IF NOT EXISTS notes (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              created INTEGER NOT NULL,
              updated INTEGER NOT NULL,
              color INTEGER NOT NULL
            )
          ''');
        }

        // from52To57: Consolidates v52-v56 changes
        // Runs when migrating FROM a version <=56 TO a version >=57
        if (from < 57 && to >= 57) {
          // v52→53: Add drop_set column
          await m.database
              .customStatement(
                'ALTER TABLE gym_sets ADD COLUMN drop_set INTEGER',
              )
              .catchError((e) {});

          // v53→54: Add 5/3/1 training columns
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN fivethreeone_squat_tm REAL',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN fivethreeone_bench_tm REAL',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN fivethreeone_deadlift_tm REAL',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN fivethreeone_press_tm REAL',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN fivethreeone_week INTEGER NOT NULL DEFAULT 1',
              )
              .catchError((e) {});

          // v54→57: Add customColorSeed, create bodyweight_entries, remove TimerPage, add lastAutoBackupTime, add superset columns
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN custom_color_seed INTEGER',
              )
              .catchError((e) {});

          await m.database.customStatement('''
            CREATE TABLE IF NOT EXISTS bodyweight_entries (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              weight REAL NOT NULL,
              unit TEXT NOT NULL,
              date INTEGER NOT NULL
            )
          ''');

          // Remove TimerPage from existing users' tabs
          final result = await m.database
              .customSelect(
                'SELECT tabs FROM settings LIMIT 1',
              )
              .getSingleOrNull();

          if (result != null) {
            final currentTabs = result.read<String>('tabs');
            final updatedTabs = currentTabs
                .split(',')
                .where((tab) => tab != 'TimerPage')
                .join(',');

            if (currentTabs != updatedTabs && updatedTabs.isNotEmpty) {
              await m.database.customUpdate(
                'UPDATE settings SET tabs = ?',
                variables: [Variable.withString(updatedTabs)],
              );
            }
          }

          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN last_auto_backup_time INTEGER',
              )
              .catchError((e) {});

          // Add superset columns
          await m.database
              .customStatement(
                'ALTER TABLE gym_sets ADD COLUMN superset_id TEXT',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE gym_sets ADD COLUMN superset_position INTEGER',
              )
              .catchError((e) {});
        }

        // from57To61: Consolidates v57-v61 changes
        // Runs when migrating FROM a version <=60 TO a version >=61
        if (from < 61 && to >= 61) {
          // v57→58: Add set_order with backfill logic
          await m.database
              .customStatement(
                'ALTER TABLE gym_sets ADD COLUMN set_order INTEGER',
              )
              .catchError((e) {});

          await m.database.customStatement('''
            UPDATE gym_sets
            SET set_order = (
              SELECT COUNT(*)
              FROM gym_sets gs2
              WHERE gs2.workout_id = gym_sets.workout_id
                AND gs2.name = gym_sets.name
                AND gs2.sequence = gym_sets.sequence
                AND gs2.created < gym_sets.created
            )
            WHERE workout_id IS NOT NULL
          ''');

          // v58→59: Add selfie_image_path to workouts
          await m.database
              .customStatement(
                'ALTER TABLE workouts ADD COLUMN selfie_image_path TEXT',
              )
              .catchError((e) {});

          // v59→60: Add Spotify columns
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN spotify_access_token TEXT',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN spotify_refresh_token TEXT',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN spotify_token_expiry INTEGER',
              )
              .catchError((e) {});

          // v60→61: CRITICAL - sequence normalization fix (keep exactly as-is)
          // Fix old workout data where each set had unique sequence values
          // This migration normalizes sequences so all sets of same exercise instance share same sequence

          // Old pattern: Bench has sets with sequence 0,1,2,3,4,5,6 (each set different sequence)
          // New pattern: Bench has sets with sequence 0,0,0,0,0,0,0 and set_order 0,1,2,3,4,5,6

          // Create temp table to calculate new values
          await m.database.customStatement('''
            CREATE TEMP TABLE sequence_corrections (
              id INTEGER PRIMARY KEY,
              new_sequence INTEGER,
              new_set_order INTEGER
            )
          ''');

          // Calculate new sequence and set_order values
          // For each workout, group consecutive same-exercise sets together
          await m.database.customStatement('''
            INSERT INTO sequence_corrections (id, new_sequence, new_set_order)
            WITH RECURSIVE
            SetRanks AS (
              SELECT
                id,
                workout_id,
                name,
                sequence AS old_sequence,
                created,
                ROW_NUMBER() OVER (PARTITION BY workout_id ORDER BY sequence, created) AS row_num,
                LAG(name) OVER (PARTITION BY workout_id ORDER BY sequence, created) AS prev_name
              FROM gym_sets
              WHERE workout_id IS NOT NULL AND sequence >= 0
            ),
            ExerciseGroups AS (
              SELECT
                id,
                workout_id,
                name,
                old_sequence,
                created,
                row_num,
                -- Count how many times exercise name changed before this row
                SUM(CASE WHEN prev_name IS NULL OR name != prev_name THEN 1 ELSE 0 END)
                  OVER (PARTITION BY workout_id ORDER BY row_num) - 1 AS new_sequence
              FROM SetRanks
            )
            SELECT
              id,
              new_sequence,
              ROW_NUMBER() OVER (
                PARTITION BY workout_id, name, new_sequence
                ORDER BY old_sequence, created
              ) - 1 AS new_set_order
            FROM ExerciseGroups
          ''');

          // Apply corrections
          await m.database.customStatement('''
            UPDATE gym_sets
            SET
              sequence = (SELECT new_sequence FROM sequence_corrections WHERE sequence_corrections.id = gym_sets.id),
              set_order = (SELECT new_set_order FROM sequence_corrections WHERE sequence_corrections.id = gym_sets.id)
            WHERE id IN (SELECT id FROM sequence_corrections)
          ''');

          // Clean up temp table
          await m.database.customStatement('DROP TABLE sequence_corrections');
        }

        // from61To62: Add sequence to notes
        // Runs when migrating FROM a version <=61 TO a version >=62
        if (from < 62 && to >= 62) {
          // Add sequence column
          await m.database
              .customStatement(
                'ALTER TABLE notes ADD COLUMN sequence INTEGER',
              )
              .catchError((e) {});

          // Backfill: assign sequence based on updated timestamp (most recent = highest)
          await m.database.customStatement('''
            UPDATE notes
            SET sequence = (
              SELECT COUNT(*)
              FROM notes n2
              WHERE n2.updated > notes.updated
            )
          ''');
        }

        // from62To63: Add backup status tracking
        // Runs when migrating FROM a version <=62 TO a version >=63
        if (from < 63 && to >= 63) {
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN last_backup_status TEXT',
              )
              .catchError((e) {});
        }

        // from63To64: Add five_three_one_blocks table for block programming
        if (from < 64 && to >= 64) {
          await m.database.customStatement('''
            CREATE TABLE IF NOT EXISTS five_three_one_blocks (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              created INTEGER NOT NULL,
              squat_tm REAL NOT NULL,
              bench_tm REAL NOT NULL,
              deadlift_tm REAL NOT NULL,
              press_tm REAL NOT NULL,
              unit TEXT NOT NULL,
              current_cycle INTEGER NOT NULL DEFAULT 0,
              current_week INTEGER NOT NULL DEFAULT 1,
              is_active INTEGER NOT NULL DEFAULT 1,
              completed INTEGER
            )
          ''');
        }

        // from64To65: Add starting TM columns for block completion tracking
        if (from < 65 && to >= 65) {
          await m.database
              .customStatement(
                'ALTER TABLE five_three_one_blocks ADD COLUMN start_squat_tm REAL',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE five_three_one_blocks ADD COLUMN start_bench_tm REAL',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE five_three_one_blocks ADD COLUMN start_deadlift_tm REAL',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE five_three_one_blocks ADD COLUMN start_press_tm REAL',
              )
              .catchError((e) {});
          // Backfill existing blocks with current TMs as starting TMs
          await m.database
              .customStatement(
                'UPDATE five_three_one_blocks SET start_squat_tm = squat_tm, start_bench_tm = bench_tm, start_deadlift_tm = deadlift_tm, start_press_tm = press_tm',
              )
              .catchError((e) {});
        }

        // from65To66: Add server backup push columns
        if (from < 66 && to >= 66) {
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN server_url TEXT',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN server_api_key TEXT',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN last_push_time INTEGER',
              )
              .catchError((e) {});
          await m.database
              .customStatement(
                'ALTER TABLE settings ADD COLUMN last_push_status TEXT',
              )
              .catchError((e) {});
        }

        // from66To67: Add primary cardio metric metadata
        if (from < 67 && to >= 67) {
          await m.database
              .customStatement(
                'ALTER TABLE gym_sets ADD COLUMN cardio_metric TEXT',
              )
              .catchError((e) {});
        }
      },
      beforeOpen: (details) async {
        // Ensure bodyweight_entries table exists (safety check for migration issues)
        await customStatement('''
          CREATE TABLE IF NOT EXISTS bodyweight_entries (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            weight REAL NOT NULL,
            unit TEXT NOT NULL,
            date INTEGER NOT NULL
          )
        ''');

        // Drop notes column if it exists (from earlier version)
        try {
          await customStatement(
            'ALTER TABLE bodyweight_entries DROP COLUMN notes',
          );
        } catch (e) {
          // Column might not exist, ignore error
        }

        // five_three_one_blocks table safety check moved to
        // _ensureTables() in database_connection_native.dart (setup callback)
      },
    );
  }

  @override
  int get schemaVersion => 67;
}
