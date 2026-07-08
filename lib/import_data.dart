import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'database/database.dart';
import 'fivethreeone/fivethreeone_state.dart';
import 'main.dart';
import 'settings/settings_state.dart';
import 'utils.dart';

class ImportData extends StatelessWidget {
  const ImportData({
    required this.ctx,
    super.key,
  });
  final BuildContext ctx;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showModalBottomSheet(
          useRootNavigator: true,
          context: context,
          builder: (context) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: const Text('Workouts'),
                    onTap: () => importWorkouts(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('Database'),
                    onTap: () => importDatabase(context),
                  ),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.upload),
      label: const Text('Import data'),
    );
  }

  Future<void> importDatabase(BuildContext context) async {
    Navigator.pop(context);

    FilePickerResult? result;
    try {
      if (kIsWeb) {
        await _importDatabaseWeb(context);
      } else {
        result = await _importDatabaseNativeWithResult(context);
      }
    } catch (e) {
      if (!ctx.mounted) return;

      print('ERROR [ImportDatabase] Import failed');
      print('  File path: ${result?.files.single.path ?? 'unknown'}');
      print('  Exception type: ${e.runtimeType}');
      print('  Message: $e');
      if (e is FileSystemException) {
        print('  OS Error: ${e.osError}');
      }

      toast(
        _getImportErrorMessage(e, result?.files.single.path),
        duration: const Duration(seconds: 10),
      );
    }
  }

  Future<FilePickerResult?> _importDatabaseNativeWithResult(
    BuildContext context,
  ) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return null;

    final File sourceFile = File(result.files.single.path!);

    if (!await sourceFile.exists()) {
      throw Exception('Selected file does not exist');
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    await db.close();

    // Delete WAL and SHM files to prevent corruption from old write-ahead logs
    final walFile = File(p.join(dbFolder.path, 'jackedlog.sqlite-wal'));
    final shmFile = File(p.join(dbFolder.path, 'jackedlog.sqlite-shm'));
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();

    await sourceFile.copy(p.join(dbFolder.path, 'jackedlog.sqlite'));
    db = AppDatabase();

    // Reset alarm sound and set backup time to now for imported database
    await db.settings.update().write(
          SettingsCompanion(
            alarmSound: const Value(''),
            lastAutoBackupTime: Value(DateTime.now()),
          ),
        );

    if (!ctx.mounted) return result;
    final settingsState = ctx.read<SettingsState>();
    await settingsState.init();

    if (!ctx.mounted) return result;
    await ctx.read<FiveThreeOneState>().refresh();

    if (!ctx.mounted) return result;
    Navigator.of(ctx, rootNavigator: true)
        .pushNamedAndRemoveUntil('/', (_) => false);

    return result;
  }

  Future<void> _importDatabaseWeb(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final Uint8List? fileBytes = result.files.single.bytes;
    if (fileBytes == null) {
      throw Exception('Could not read file data');
    }

    throw Exception(
      'Database import on web requires manual data migration. Please export your data as CSV files and import those instead.',
    );
  }

  Future<void> importWorkouts(BuildContext context) async {
    Navigator.pop(context);

    String? filePath;
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null) return;
      filePath = result.files.single.path;

      // Read ZIP file
      Uint8List zipBytes;
      if (kIsWeb) {
        final fileBytes = result.files.single.bytes;
        if (fileBytes == null) throw Exception('Could not read file data');
        zipBytes = fileBytes;
      } else {
        if (result.files.single.bytes != null) {
          zipBytes = result.files.single.bytes!;
        } else {
          final file = File(result.files.single.path!);
          zipBytes = await file.readAsBytes();
        }
      }

      // Extract ZIP
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Find workouts.csv and gym_sets.csv
      ArchiveFile? workoutsFile;
      ArchiveFile? setsFile;
      for (final file in archive) {
        if (file.name == 'workouts.csv') workoutsFile = file;
        if (file.name == 'gym_sets.csv') setsFile = file;
      }

      if (workoutsFile == null || setsFile == null) {
        throw Exception('Invalid backup file: missing required CSV files');
      }

      // Parse workouts CSV
      String workoutsCsvContent;
      try {
        workoutsCsvContent = utf8.decode(
          workoutsFile.content as List<int>,
          allowMalformed: false,
        );
      } catch (e) {
        workoutsCsvContent = latin1.decode(workoutsFile.content as List<int>);
      }

      final workoutsRows =
          const CsvToListConverter(eol: '\n').convert(workoutsCsvContent);
      if (workoutsRows.isEmpty) throw Exception('Workouts CSV is empty');

      // Parse gym sets CSV
      String setsCsvContent;
      try {
        setsCsvContent =
            utf8.decode(setsFile.content as List<int>, allowMalformed: false);
      } catch (e) {
        setsCsvContent = latin1.decode(setsFile.content as List<int>);
      }

      final setsRows =
          const CsvToListConverter(eol: '\n').convert(setsCsvContent);
      if (setsRows.isEmpty) throw Exception('Gym sets CSV is empty');

      // Check CSV format version by examining header row
      final setsHeader =
          setsRows.first.map((e) => e.toString().toLowerCase()).toList();
      final hasBodyWeightColumn = setsHeader.contains('bodyweight');
      final hasSupersetColumns = setsHeader.contains('supersetid');
      final hasSetOrderColumn = setsHeader.contains('setorder');
      final cardioMetricIndex = setsHeader.indexWhere(
        (column) => column == 'cardio_metric' || column == 'cardiometric',
      );
      final hasCardioMetricColumn = cardioMetricIndex != -1;

      // Import workouts first (skip header row)
      final workoutsToInsert = workoutsRows.skip(1).map((row) {
        if (row.length < 6) {
          throw Exception(
            'Workout row has insufficient columns: ${row.length}',
          );
        }

        return WorkoutsCompanion(
          id: Value(int.tryParse(row[0]?.toString() ?? '0') ?? 0),
          startTime: Value(parseDate(row[1])),
          endTime: Value(_parseNullableDateTime(row[2])),
          planId: Value(_parseNullableInt(row[3])),
          name: Value(_parseNullableString(row[4])),
          notes: Value(_parseNullableString(row[5])),
        );
      });

      // Import gym sets (skip header row)
      final gymSets = setsRows.skip(1).map((row) {
        if (row.length < 6) {
          throw Exception('Set row has insufficient columns: ${row.length}');
        }

        final reps = _parseDouble(row[2], 'reps', setsRows.indexOf(row) + 1);
        final weight =
            _parseDouble(row[3], 'weight', setsRows.indexOf(row) + 1);

        // Adjust column indices based on CSV format version
        // Old format (v54 and earlier): had bodyWeight column at index 9
        // New format (v55+): removed bodyWeight column
        final offset = hasBodyWeightColumn ? 1 : 0;
        final cardioMetricOffset = hasCardioMetricColumn ? 1 : 0;

        return GymSetsCompanion(
          id: Value(int.tryParse(row[0]?.toString() ?? '0') ?? 0),
          name: Value(row[1]?.toString() ?? ''),
          reps: reps,
          weight: weight,
          unit: Value(row[4]?.toString() ?? ''),
          created: Value(parseDate(row[5])),
          cardio: Value(parseBool(row.elementAtOrNull(6))),
          duration: Value(
            double.tryParse(row.elementAtOrNull(7)?.toString() ?? '0') ?? 0,
          ),
          distance: Value(
            double.tryParse(row.elementAtOrNull(8)?.toString() ?? '0') ?? 0,
          ),
          // Skip bodyWeight column (index 9) if present in old format
          incline: Value(_parseNullableInt(row.elementAtOrNull(9 + offset))),
          restMs: Value(_parseNullableInt(row.elementAtOrNull(10 + offset))),
          hidden: Value(parseBool(row.elementAtOrNull(11 + offset))),
          workoutId: Value(_parseNullableInt(row.elementAtOrNull(12 + offset))),
          planId: Value(_parseNullableInt(row.elementAtOrNull(13 + offset))),
          image: Value(_parseNullableString(row.elementAtOrNull(14 + offset))),
          category:
              Value(_parseNullableString(row.elementAtOrNull(15 + offset))),
          notes: Value(_parseNullableString(row.elementAtOrNull(16 + offset))),
          sequence: Value(
            int.tryParse(
                  row.elementAtOrNull(17 + offset)?.toString() ?? '0',
                ) ??
                0,
          ),
          setOrder: Value(
            hasSetOrderColumn
                ? _parseNullableInt(row.elementAtOrNull(18 + offset))
                : null,
          ),
          warmup: Value(
            parseBool(
              row.elementAtOrNull(
                  hasSetOrderColumn ? 19 + offset : 18 + offset),
            ),
          ),
          exerciseType: Value(
            _parseNullableString(
              row.elementAtOrNull(
                  hasSetOrderColumn ? 20 + offset : 19 + offset),
            ),
          ),
          brandName: Value(
            _parseNullableString(
              row.elementAtOrNull(
                  hasSetOrderColumn ? 21 + offset : 20 + offset),
            ),
          ),
          cardioMetric: Value(
            hasCardioMetricColumn
                ? _parseNullableString(row.elementAtOrNull(cardioMetricIndex))
                : null,
          ),
          dropSet: Value(
            parseBool(
              row.elementAtOrNull(
                hasSetOrderColumn
                    ? 22 + offset + cardioMetricOffset
                    : 21 + offset + cardioMetricOffset,
              ),
            ),
          ),
          supersetId: Value(
            hasSupersetColumns
                ? _parseNullableString(
                    row.elementAtOrNull(
                      hasSetOrderColumn
                          ? 23 + offset + cardioMetricOffset
                          : 22 + offset + cardioMetricOffset,
                    ),
                  )
                : null,
          ),
          supersetPosition: Value(
            hasSupersetColumns
                ? _parseNullableInt(
                    row.elementAtOrNull(
                      hasSetOrderColumn
                          ? 24 + offset + cardioMetricOffset
                          : 23 + offset + cardioMetricOffset,
                    ),
                  )
                : null,
          ),
        );
      });

      // Delete existing data and import new data
      // Clear plans and plan exercises to avoid orphaned entries
      await db.planExercises.deleteAll();
      await db.plans.deleteAll();
      await db.workouts.deleteAll();
      await db.gymSets.deleteAll();
      await db.workouts.insertAll(workoutsToInsert);
      await db.gymSets.insertAll(gymSets);

      if (!ctx.mounted) return;
      Navigator.pop(ctx);

      toast('Workout data imported successfully!');
    } catch (e) {
      if (!ctx.mounted) return;

      print('ERROR [ImportWorkouts] Import failed');
      print('  File path: $filePath');
      print('  Exception type: ${e.runtimeType}');
      print('  Message: $e');

      toast(
        _getImportErrorMessage(e, filePath),
        duration: const Duration(seconds: 10),
      );
    }
  }

  Value<double> _parseDouble(dynamic value, String fieldName, int rowNumber) {
    if (value is num) return Value(value.toDouble());
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null) {
        throw Exception('Invalid $fieldName value in row $rowNumber: $value');
      }
      return Value(parsed);
    }
    throw Exception(
      'Invalid $fieldName data type in row $rowNumber: ${value.runtimeType}',
    );
  }

  int? _parseNullableInt(dynamic value) {
    if (value == null || value == '') return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _parseNullableString(dynamic value) {
    if (value == null || value == '') return null;
    return value.toString();
  }

  DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null || value == '') return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    if (value is num) return value != 0;
    return false;
  }

  String _getImportErrorMessage(Object error, String? filePath) {
    if (error is FormatException) {
      return 'Import failed: Invalid file format. Ensure this is a valid backup file.';
    }
    if (error is FileSystemException) {
      final osError = error.osError;
      if (osError != null) {
        if (osError.errorCode == 13) {
          return 'Import failed: Storage permission denied.';
        }
        if (osError.errorCode == 2) return 'Import failed: File not found.';
      }
      return 'Import failed: Could not read file.';
    }
    final msg = error.toString().toLowerCase();
    if (msg.contains('missing required csv')) {
      return 'Import failed: Invalid backup file (missing workouts or sets data).';
    }
    if (msg.contains('insufficient columns')) {
      return 'Import failed: Backup file format is outdated or corrupted.';
    }
    if (msg.contains('csv is empty')) {
      return 'Import failed: Backup file contains no data.';
    }
    final firstLine = error.toString().split('\n').first;
    return 'Import failed: ${firstLine.length > 80 ? '${firstLine.substring(0, 80)}...' : firstLine}';
  }
}
