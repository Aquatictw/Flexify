import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

void _ensureTables(Database database) {
  database.execute('''
    CREATE TABLE IF NOT EXISTS five_three_one_blocks (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      created INTEGER NOT NULL,
      squat_tm REAL NOT NULL,
      bench_tm REAL NOT NULL,
      deadlift_tm REAL NOT NULL,
      press_tm REAL NOT NULL,
      start_squat_tm REAL,
      start_bench_tm REAL,
      start_deadlift_tm REAL,
      start_press_tm REAL,
      unit TEXT NOT NULL,
      current_cycle INTEGER NOT NULL DEFAULT 0,
      current_week INTEGER NOT NULL DEFAULT 1,
      is_active INTEGER NOT NULL DEFAULT 1,
      completed INTEGER
    )
  ''');
}

/// Overridable at compile time so integration tests (e.g. README screenshot
/// runs) can use a throwaway database instead of the user's real data.
const databaseFilename = String.fromEnvironment(
  'JACKEDLOG_DATABASE_FILENAME',
  defaultValue: 'jackedlog.sqlite',
);

LazyDatabase createNativeConnection() {
  return LazyDatabase(() async {
    final folder = await getApplicationDocumentsDirectory();
    final oldFile = File(p.join(folder.path, 'flexify.sqlite'));
    final newFile = File(p.join(folder.path, databaseFilename));
    const useDefaultDatabase = databaseFilename == 'jackedlog.sqlite';

    // Migration: Copy old database to new location if it exists
    try {
      if (useDefaultDatabase &&
          await oldFile.exists() &&
          !await newFile.exists()) {
        await oldFile.copy(newFile.path);
        // Verify copy succeeded
        if (await newFile.exists()) {
          final oldSize = await oldFile.length();
          final newSize = await newFile.length();
          if (oldSize == newSize) {
            debugPrint('Database migrated: flexify.sqlite → jackedlog.sqlite');
            // Keep old file as backup (don't delete)
          } else {
            debugPrint('Database migration warning: file sizes differ');
          }
        }
      }
    } catch (e) {
      debugPrint('Database migration error: $e');
      // Fall back to old file if new one doesn't exist
      if (useDefaultDatabase &&
          !await newFile.exists() &&
          await oldFile.exists()) {
        final file = oldFile;
        if (Platform.isAndroid) {
          await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
        }

        final cache = (await getTemporaryDirectory()).path;
        sqlite3.tempDirectory = cache;
        return NativeDatabase.createInBackground(
          file,
          logStatements: kDebugMode,
          setup: _ensureTables,
        );
      }
    }

    final file = newFile;

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cache = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cache;
    return NativeDatabase.createInBackground(
      file,
      logStatements: kDebugMode,
      setup: _ensureTables,
    );
  });
}

LazyDatabase createWebConnection() {
  throw UnsupportedError('Web connection not supported on native platforms');
}
