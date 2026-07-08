import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'main.dart';
import 'utils.dart';

class ExportData extends StatelessWidget {
  const ExportData({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          builder: (context) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: const Text('Workouts'),
                    onTap: () async {
                      Navigator.pop(context);
                      if (!await requestNotificationPermission()) return;

                      // Export workouts table
                      final workouts = await db.workouts.select().get();
                      final List<List<dynamic>> workoutsData = [
                        [
                          'id',
                          'startTime',
                          'endTime',
                          'planId',
                          'name',
                          'notes',
                        ],
                      ];
                      for (final workout in workouts) {
                        workoutsData.add([
                          workout.id,
                          workout.startTime.toIso8601String(),
                          workout.endTime?.toIso8601String() ?? '',
                          workout.planId ?? '',
                          workout.name ?? '',
                          workout.notes ?? '',
                        ]);
                      }
                      final workoutsCsv = const ListToCsvConverter(eol: '\n')
                          .convert(workoutsData);

                      // Export gym sets table
                      final gymSets = await db.gymSets.select().get();
                      final List<List<dynamic>> setsData = [
                        [
                          'id',
                          'name',
                          'reps',
                          'weight',
                          'unit',
                          'created',
                          'cardio',
                          'duration',
                          'distance',
                          'incline',
                          'restMs',
                          'hidden',
                          'workoutId',
                          'planId',
                          'image',
                          'category',
                          'notes',
                          'sequence',
                          'setOrder',
                          'warmup',
                          'exerciseType',
                          'brandName',
                          'cardio_metric',
                          'dropSet',
                          'supersetId',
                          'supersetPosition',
                        ]
                      ];
                      for (final gymSet in gymSets) {
                        setsData.add([
                          gymSet.id,
                          gymSet.name,
                          gymSet.reps,
                          gymSet.weight,
                          gymSet.unit,
                          gymSet.created.toIso8601String(),
                          gymSet.cardio,
                          gymSet.duration,
                          gymSet.distance,
                          gymSet.incline ?? '',
                          gymSet.restMs ?? '',
                          gymSet.hidden,
                          gymSet.workoutId ?? '',
                          gymSet.planId ?? '',
                          gymSet.image ?? '',
                          gymSet.category ?? '',
                          gymSet.notes ?? '',
                          gymSet.sequence,
                          gymSet.setOrder ?? '',
                          gymSet.warmup,
                          gymSet.exerciseType ?? '',
                          gymSet.brandName ?? '',
                          gymSet.cardioMetric ?? '',
                          gymSet.dropSet,
                          gymSet.supersetId ?? '',
                          gymSet.supersetPosition ?? '',
                        ]);
                      }
                      final setsCsv =
                          const ListToCsvConverter(eol: '\n').convert(setsData);

                      // Create ZIP archive
                      final archive = Archive();
                      archive.addFile(
                        ArchiveFile(
                          'workouts.csv',
                          workoutsCsv.length,
                          workoutsCsv.codeUnits,
                        ),
                      );
                      archive.addFile(
                        ArchiveFile(
                          'gym_sets.csv',
                          setsCsv.length,
                          setsCsv.codeUnits,
                        ),
                      );

                      final zipBytes = ZipEncoder().encode(archive);
                      await FilePicker.platform.saveFile(
                        fileName: 'jackedlog_workouts.zip',
                        bytes: Uint8List.fromList(zipBytes),
                        type: FileType.custom,
                        allowedExtensions: ['zip'],
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('Database'),
                    onTap: () async {
                      Navigator.pop(context);

                      // Checkpoint WAL to ensure all changes are in the main database file
                      await db
                          .customStatement('PRAGMA wal_checkpoint(TRUNCATE)');

                      final dbFolder = await getApplicationDocumentsDirectory();
                      final file =
                          File(p.join(dbFolder.path, 'jackedlog.sqlite'));
                      final bytes = await file.readAsBytes();
                      await FilePicker.platform.saveFile(
                        fileName: 'jackedlog.sqlite',
                        bytes: bytes,
                        type: FileType.custom,
                        allowedExtensions: ['sqlite'],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.download),
      label: const Text('Export data'),
    );
  }
}
