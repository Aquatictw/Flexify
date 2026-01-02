import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Mapping of Hevy exercise names to Flexify exercise names and categories
/// Format: 'hevy_name': ('flexify_name', 'category')
const Map<String, (String, String)> hevyToFlexifyMapping = {
  // Chest exercises
  'bench press (barbell)': ('Barbell bench press', 'Chest'),
  'bench press (dumbbell)': ('Dumbbell bench press', 'Chest'),
  'flat bench press (barbell)': ('Barbell bench press', 'Chest'),
  'flat bench press (dumbbell)': ('Dumbbell bench press', 'Chest'),
  'incline bench press (barbell)': ('Incline bench press', 'Chest'),
  'incline bench press (dumbbell)': ('Incline bench press', 'Chest'),
  'incline chest press (machine)': ('Incline chest press (Machine)', 'Chest'),
  'decline bench press (barbell)': ('Decline bench press', 'Chest'),
  'decline bench press (dumbbell)': ('Decline bench press', 'Chest'),
  'chest press (machine)': ('Chest press (Machine)', 'Chest'),
  'chest fly': ('Chest fly', 'Chest'),
  'chest fly (dumbbell)': ('Dumbbell fly', 'Chest'),
  'chest fly (cable)': ('Cable fly', 'Chest'),
  'cable fly': ('Cable fly', 'Chest'),
  'pec deck': ('Chest fly', 'Chest'),
  'push up': ('Push-up', 'Chest'),
  'push-up': ('Push-up', 'Chest'),
  'pushup': ('Push-up', 'Chest'),
  'push ups': ('Push-up', 'Chest'),
  'diamond push up': ('Diamond push-up', 'Chest'),
  'wide push up': ('Wide-grip push-up', 'Chest'),
  'dips': ('Triceps dip', 'Chest'),
  'dip': ('Triceps dip', 'Chest'),
  'chest dip': ('Triceps dip', 'Chest'),
  'seated dip machine': ('Seated dip (Machine)', 'Chest'),

  // Back exercises
  'deadlift (barbell)': ('Deadlift', 'Back'),
  'deadlift': ('Deadlift', 'Back'),
  'conventional deadlift': ('Deadlift', 'Back'),
  'romanian deadlift (barbell)': ('Romanian deadlift', 'Back'),
  'romanian deadlift (dumbbell)': ('Romanian deadlift', 'Back'),
  'romanian deadlift': ('Romanian deadlift', 'Back'),
  'stiff leg deadlift': ('Romanian deadlift', 'Back'),
  'bent over row (barbell)': ('Barbell bent-over row', 'Back'),
  'bent over row (dumbbell)': ('Dumbbell bent-over row', 'Back'),
  'barbell row': ('Barbell bent-over row', 'Back'),
  'dumbbell row': ('Dumbbell bent-over row', 'Back'),
  'one arm dumbbell row': ('Dumbbell bent-over row', 'Back'),
  'single arm dumbbell row': ('Dumbbell bent-over row', 'Back'),
  't-bar row': ('T-bar row', 'Back'),
  't bar row': ('T-bar row', 'Back'),
  'pull up': ('Pull-up', 'Back'),
  'pull-up': ('Pull-up', 'Back'),
  'pullup': ('Pull-up', 'Back'),
  'pull ups': ('Pull-up', 'Back'),
  'pull up (assisted)': ('Assisted pull-up', 'Back'),
  'assisted pull up': ('Assisted pull-up', 'Back'),
  'chin up': ('Chin-up', 'Back'),
  'chin-up': ('Chin-up', 'Back'),
  'chinup': ('Chin-up', 'Back'),
  'chin ups': ('Chin-up', 'Back'),
  'wide grip pull up': ('Wide-grip pull-up', 'Back'),
  'close grip pull up': ('Close-grip pull-up', 'Back'),
  'lat pulldown': ('Lat pull-down', 'Back'),
  'lat pulldown (cable)': ('Lat pull-down', 'Back'),
  'lat pull down': ('Lat pull-down', 'Back'),
  'wide grip lat pulldown': ('Lat pull-down', 'Back'),
  'close grip lat pulldown': ('Lat pull-down', 'Back'),
  'cable pulldown': ('Cable pull-down', 'Back'),
  'seated cable row': ('Seated cable row', 'Back'),
  'cable row': ('Seated cable row', 'Back'),
  'seated row': ('Seated cable row', 'Back'),
  'seated row (cable)': ('Seated cable row', 'Back'),
  'back extension': ('Back extension', 'Back'),
  'hyperextension': ('Hyperextension', 'Back'),
  'good morning': ('Good morning', 'Back'),
  'good morning (barbell)': ('Good morning', 'Back'),
  'reverse grip pulldown': ('Reverse grip pull-down', 'Back'),

  // Shoulder exercises
  'overhead press (barbell)': ('Barbell shoulder press', 'Shoulders'),
  'overhead press (dumbbell)': ('Dumbbell shoulder press', 'Shoulders'),
  'overhead press': ('Barbell shoulder press', 'Shoulders'),
  'military press': ('Barbell shoulder press', 'Shoulders'),
  'shoulder press (barbell)': ('Barbell shoulder press', 'Shoulders'),
  'shoulder press (dumbbell)': ('Dumbbell shoulder press', 'Shoulders'),
  'shoulder press (machine)': ('Shoulder press (Machine)', 'Shoulders'),
  'seated overhead press (barbell)': ('Barbell shoulder press', 'Shoulders'),
  'arnold press': ('Arnold press', 'Shoulders'),
  'arnold press (dumbbell)': ('Arnold press', 'Shoulders'),
  'lateral raise': ('Dumbbell lateral raise', 'Shoulders'),
  'lateral raise (dumbbell)': ('Dumbbell lateral raise', 'Shoulders'),
  'lateral raise (cable)': ('Cable lateral raise', 'Shoulders'),
  'lateral raise (machine)': ('Lateral raise (Machine)', 'Shoulders'),
  'side lateral raise': ('Dumbbell lateral raise', 'Shoulders'),
  'cable lateral raise': ('Cable lateral raise', 'Shoulders'),
  'front raise': ('Front raise', 'Shoulders'),
  'front raise (dumbbell)': ('Front raise', 'Shoulders'),
  'rear delt fly': ('Rear delt fly', 'Shoulders'),
  'rear delt fly (dumbbell)': ('Rear delt fly', 'Shoulders'),
  'reverse fly': ('Rear delt fly', 'Shoulders'),
  'face pull': ('Face pull', 'Shoulders'),
  'face pull (cable)': ('Face pull', 'Shoulders'),
  'shrug (barbell)': ('Barbell shrug', 'Shoulders'),
  'shrug (dumbbell)': ('Dumbbell shrug', 'Shoulders'),
  'shrug': ('Shoulder shrug', 'Shoulders'),
  'barbell shrug': ('Barbell shrug', 'Shoulders'),
  'dumbbell shrug': ('Dumbbell shrug', 'Shoulders'),
  'upright row': ('Upright row', 'Shoulders'),
  'upright row (barbell)': ('Upright row', 'Shoulders'),
  'upright row (dumbbell)': ('Upright row', 'Shoulders'),

  // Arms - Biceps
  'bicep curl (barbell)': ('Barbell biceps curl', 'Arms'),
  'bicep curl (dumbbell)': ('Dumbbell biceps curl', 'Arms'),
  'biceps curl (barbell)': ('Barbell biceps curl', 'Arms'),
  'biceps curl (dumbbell)': ('Dumbbell biceps curl', 'Arms'),
  'barbell curl': ('Barbell biceps curl', 'Arms'),
  'dumbbell curl': ('Dumbbell biceps curl', 'Arms'),
  'hammer curl': ('Hammer curl', 'Arms'),
  'hammer curl (dumbbell)': ('Hammer curl', 'Arms'),
  'preacher curl': ('Preacher curl', 'Arms'),
  'preacher curl (barbell)': ('Preacher curl', 'Arms'),
  'preacher curl (dumbbell)': ('Preacher curl', 'Arms'),
  'concentration curl': ('Concentration curl', 'Arms'),
  'incline curl': ('Incline curl', 'Arms'),
  'incline dumbbell curl': ('Incline curl', 'Arms'),
  'cable curl': ('Cable curl', 'Arms'),
  'ez bar curl': ('EZ bar curl', 'Arms'),

  // Arms - Triceps
  'tricep pushdown': ('Triceps pushdown', 'Arms'),
  'triceps pushdown': ('Triceps pushdown', 'Arms'),
  'tricep pushdown (cable)': ('Triceps pushdown', 'Arms'),
  'triceps pushdown (cable)': ('Triceps pushdown', 'Arms'),
  'tricep extension': ('Triceps extension', 'Arms'),
  'triceps extension': ('Triceps extension', 'Arms'),
  'overhead tricep extension': ('Overhead triceps extension', 'Arms'),
  'overhead triceps extension': ('Overhead triceps extension', 'Arms'),
  'skull crusher': ('Skull crusher', 'Arms'),
  'skull crushers': ('Skull crusher', 'Arms'),
  'lying tricep extension': ('Skull crusher', 'Arms'),
  'tricep dip': ('Triceps dip', 'Arms'),
  'triceps dip': ('Triceps dip', 'Arms'),
  'close grip bench press': ('Close grip bench press', 'Arms'),
  'rope pushdown': ('Triceps pushdown', 'Arms'),
  'tricep kickback': ('Tricep kickback', 'Arms'),

  // Legs
  'squat (barbell)': ('Squat', 'Legs'),
  'squat': ('Squat', 'Legs'),
  'back squat': ('Squat', 'Legs'),
  'front squat': ('Front squat', 'Legs'),
  'front squat (barbell)': ('Front squat', 'Legs'),
  'goblet squat': ('Goblet squat', 'Legs'),
  'leg press': ('Leg press', 'Legs'),
  'leg press (machine)': ('Leg press', 'Legs'),
  'leg press horizontal (machine)': ('Leg press', 'Legs'),
  'leg extension': ('Leg extension', 'Legs'),
  'leg extension (machine)': ('Leg extension', 'Legs'),
  'leg curl': ('Leg curl', 'Legs'),
  'leg curl (machine)': ('Leg curl', 'Legs'),
  'lying leg curl': ('Leg curl', 'Legs'),
  'seated leg curl': ('Leg curl', 'Legs'),
  'seated leg curl (machine)': ('Leg curl', 'Legs'),
  'lunge': ('Lunge', 'Legs'),
  'lunge (barbell)': ('Lunge', 'Legs'),
  'lunge (dumbbell)': ('Lunge', 'Legs'),
  'walking lunge': ('Lunge', 'Legs'),
  'bulgarian split squat': ('Bulgarian split squat', 'Legs'),
  'hip thrust': ('Hip thrust', 'Legs'),
  'hip thrust (barbell)': ('Hip thrust', 'Legs'),
  'glute bridge': ('Glute bridge', 'Legs'),
  'hack squat': ('Hack squat', 'Legs'),
  'hack squat (machine)': ('Hack squat', 'Legs'),
  'sumo deadlift': ('Sumo deadlift', 'Legs'),

  // Calves
  'calf raise (standing)': ('Standing calf raise', 'Calves'),
  'calf raise (seated)': ('Seated calf raise', 'Calves'),
  'standing calf raise': ('Standing calf raise', 'Calves'),
  'seated calf raise': ('Seated calf raise', 'Calves'),
  'calf raise': ('Standing calf raise', 'Calves'),
  'calf press': ('Calf press', 'Calves'),

  // Core
  'crunch': ('Crunch', 'Core'),
  'crunches': ('Crunch', 'Core'),
  'sit up': ('Sit-up', 'Core'),
  'sit-up': ('Sit-up', 'Core'),
  'situp': ('Sit-up', 'Core'),
  'sit ups': ('Sit-up', 'Core'),
  'plank': ('Plank', 'Core'),
  'russian twist': ('Russian twist', 'Core'),
  'leg raise': ('Leg raise', 'Core'),
  'leg raises': ('Leg raise', 'Core'),
  'hanging leg raise': ('Hanging leg raise', 'Core'),
  'hanging knee raise': ('Hanging leg raise', 'Core'),
  'cable crunch': ('Cable crunch', 'Core'),
  'ab wheel': ('Ab wheel', 'Core'),
  'ab wheel rollout': ('Ab wheel', 'Core'),
  'wood chop': ('Wood chop', 'Core'),
  'mountain climber': ('Mountain climber', 'Core'),
  'bicycle crunch': ('Bicycle crunch', 'Core'),
  'dead bug': ('Dead bug', 'Core'),

  // Cardio
  'running': ('Running', 'Cardio'),
  'treadmill': ('Treadmill', 'Cardio'),
  'cycling': ('Cycling', 'Cardio'),
  'bike': ('Cycling', 'Cardio'),
  'stationary bike': ('Stationary bike', 'Cardio'),
  'elliptical': ('Elliptical', 'Cardio'),
  'rowing': ('Rowing', 'Cardio'),
  'rowing machine': ('Rowing', 'Cardio'),
  'stair climber': ('Stair climber', 'Cardio'),
  'jump rope': ('Jump rope', 'Cardio'),
  'walking': ('Walking', 'Cardio'),
};

/// Parse Hevy exercise name to Flexify format
(String, String) mapHevyExercise(String hevyName) {
  final normalizedName = hevyName.toLowerCase().trim();

  // Check direct mapping first
  if (hevyToFlexifyMapping.containsKey(normalizedName)) {
    return hevyToFlexifyMapping[normalizedName]!;
  }

  // Try partial matches
  for (final entry in hevyToFlexifyMapping.entries) {
    if (normalizedName.contains(entry.key) ||
        entry.key.contains(normalizedName)) {
      return entry.value;
    }
  }

  // If no match found, return the original name with a guessed category
  final category = _guessCategory(normalizedName);
  // Capitalize the first letter of each word
  final formattedName = hevyName
      .split(' ')
      .map((word) =>
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
      .join(' ');
  return (formattedName, category);
}

String _guessCategory(String name) {
  if (name.contains('bench') ||
      name.contains('chest') ||
      name.contains('push') ||
      name.contains('fly') ||
      name.contains('pec')) {
    return 'Chest';
  }
  if (name.contains('pull') ||
      name.contains('row') ||
      name.contains('lat') ||
      name.contains('back') ||
      name.contains('deadlift')) {
    return 'Back';
  }
  if (name.contains('shoulder') ||
      name.contains('press') ||
      name.contains('lateral') ||
      name.contains('raise') ||
      name.contains('shrug')) {
    return 'Shoulders';
  }
  if (name.contains('curl') ||
      name.contains('tricep') ||
      name.contains('bicep') ||
      name.contains('arm')) {
    return 'Arms';
  }
  if (name.contains('squat') ||
      name.contains('leg') ||
      name.contains('lunge') ||
      name.contains('hip') ||
      name.contains('glute')) {
    return 'Legs';
  }
  if (name.contains('calf') || name.contains('calves')) {
    return 'Calves';
  }
  if (name.contains('crunch') ||
      name.contains('ab') ||
      name.contains('core') ||
      name.contains('plank')) {
    return 'Core';
  }
  if (name.contains('run') ||
      name.contains('bike') ||
      name.contains('cycle') ||
      name.contains('cardio') ||
      name.contains('walk') ||
      name.contains('row')) {
    return 'Cardio';
  }
  return 'Other';
}

class ImportHevy extends StatelessWidget {
  final BuildContext ctx;

  const ImportHevy({
    super.key,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _importHevy(context),
      icon: const Icon(Icons.fitness_center),
      label: const Text('Import from Hevy'),
    );
  }

  Future<void> _importHevy(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null) return;

      String csvContent;
      if (kIsWeb) {
        final fileBytes = result.files.single.bytes;
        if (fileBytes == null) throw Exception('Could not read file data');
        csvContent = String.fromCharCodes(fileBytes);
      } else {
        Uint8List fileBytes;
        if (result.files.single.bytes != null) {
          fileBytes = result.files.single.bytes!;
        } else {
          final file = File(result.files.single.path!);
          fileBytes = await file.readAsBytes();
        }
        try {
          csvContent = utf8.decode(fileBytes, allowMalformed: false);
        } catch (e) {
          csvContent = latin1.decode(fileBytes);
        }
      }

      final rows = const CsvToListConverter(eol: "\n").convert(csvContent);

      if (rows.isEmpty) throw Exception('CSV file is empty');
      if (rows.length <= 1) {
        throw Exception('CSV file must contain at least one data row');
      }

      final headers = rows.first.map((e) => e.toString().toLowerCase()).toList();

      // Find column indices
      final titleIdx = _findColumnIndex(headers, ['title', 'workout_name', 'workout']);
      final startTimeIdx = _findColumnIndex(headers, ['start_time', 'date', 'start']);
      final exerciseIdx = _findColumnIndex(headers, ['exercise_title', 'exercise_name', 'exercise']);
      final weightIdx = _findColumnIndex(headers, ['weight_kg', 'weight_lbs', 'weight (kg)', 'weight (lbs)', 'weight']);
      final repsIdx = _findColumnIndex(headers, ['reps', 'repetitions']);
      final distanceIdx = _findColumnIndex(headers, ['distance_km', 'distance_m', 'distance (km)', 'distance']);
      final durationIdx = _findColumnIndex(headers, ['duration_seconds', 'duration_s', 'duration']);
      final notesIdx = _findColumnIndex(headers, ['exercise_notes', 'notes', 'note', 'set_notes']);
      final setTypeIdx = _findColumnIndex(headers, ['set_type', 'type']);

      if (exerciseIdx == -1) {
        throw Exception('Could not find exercise column in CSV. Expected columns: exercise_title, exercise_name, or exercise');
      }
      if (weightIdx == -1 && repsIdx == -1) {
        throw Exception('Could not find weight or reps columns in CSV');
      }

      // Determine if weight is in lbs
      final isLbs = headers.any((h) => h.contains('lbs'));
      final unit = isLbs ? 'lb' : 'kg';

      // Track workouts and imported sets
      int currentWorkoutId = await _getNextWorkoutId();
      String? lastWorkoutKey;
      final importedSets = <GymSetsCompanion>[];
      final newExercises = <String, String>{}; // name -> category

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        final exerciseName = row.elementAtOrNull(exerciseIdx)?.toString() ?? '';
        if (exerciseName.isEmpty) continue;

        // Map the exercise
        final (mappedName, category) = mapHevyExercise(exerciseName);

        // Check if this exercise exists, if not mark it as new
        final existingExercise = await (db.gymSets.select()
              ..where((tbl) => tbl.name.equals(mappedName))
              ..limit(1))
            .getSingleOrNull();

        if (existingExercise == null) {
          newExercises[mappedName] = category;
        }

        // Parse workout grouping
        String workoutKey = '';
        DateTime created = DateTime.now();

        if (startTimeIdx != -1 && row.elementAtOrNull(startTimeIdx) != null) {
          try {
            final startTimeStr = row[startTimeIdx].toString();
            created = _parseHevyDate(startTimeStr);
            workoutKey = '${created.year}-${created.month}-${created.day}';
            if (titleIdx != -1) {
              workoutKey += '_${row[titleIdx]}';
            }
          } catch (e) {
            // Use current date if parsing fails
          }
        }

        // New workout if key changed
        if (workoutKey.isNotEmpty && workoutKey != lastWorkoutKey) {
          currentWorkoutId = await _getNextWorkoutId();
          lastWorkoutKey = workoutKey;
        }

        // Parse weight
        double weight = 0;
        if (weightIdx != -1 && row.elementAtOrNull(weightIdx) != null) {
          weight = double.tryParse(row[weightIdx].toString()) ?? 0;
        }

        // Parse reps
        double reps = 0;
        if (repsIdx != -1 && row.elementAtOrNull(repsIdx) != null) {
          reps = double.tryParse(row[repsIdx].toString()) ?? 0;
        }

        // Parse distance (for cardio)
        double distance = 0;
        if (distanceIdx != -1 && row.elementAtOrNull(distanceIdx) != null) {
          distance = double.tryParse(row[distanceIdx].toString()) ?? 0;
        }

        // Parse duration (for cardio, in minutes)
        double duration = 0;
        if (durationIdx != -1 && row.elementAtOrNull(durationIdx) != null) {
          final durationSeconds = double.tryParse(row[durationIdx].toString()) ?? 0;
          duration = durationSeconds / 60; // Convert to minutes
        }

        // Parse notes
        String? notes;
        if (notesIdx != -1 && row.elementAtOrNull(notesIdx) != null) {
          final noteStr = row[notesIdx].toString().trim();
          if (noteStr.isNotEmpty) notes = noteStr;
        }

        // Parse set type (warmup, normal, dropset)
        bool isWarmup = false;
        if (setTypeIdx != -1 && row.elementAtOrNull(setTypeIdx) != null) {
          final setType = row[setTypeIdx].toString().toLowerCase();
          isWarmup = setType == 'warmup';
        }

        // Determine if cardio
        final isCardio = distance > 0 || duration > 0 && weight == 0 && reps == 0;

        importedSets.add(
          GymSetsCompanion(
            name: Value(mappedName),
            reps: Value(reps),
            weight: Value(weight),
            created: Value(created),
            unit: Value(unit),
            category: Value(category),
            cardio: Value(isCardio),
            distance: Value(distance),
            duration: Value(duration),
            notes: Value(notes),
            hidden: const Value(false),
            workoutId: Value(currentWorkoutId),
            warmup: Value(isWarmup),
          ),
        );
      }

      // Insert new exercises as hidden template entries
      for (final entry in newExercises.entries) {
        await db.into(db.gymSets).insert(
              GymSetsCompanion(
                name: Value(entry.key),
                reps: const Value(0),
                weight: const Value(0),
                created: Value(DateTime.now()),
                unit: Value(unit),
                category: Value(entry.value),
                hidden: const Value(true),
              ),
            );
      }

      // Insert all imported sets
      await db.gymSets.insertAll(importedSets);

      if (!ctx.mounted) return;

      final message = 'Imported ${importedSets.length} sets from Hevy. '
          '${newExercises.isNotEmpty ? 'Created ${newExercises.length} new exercises.' : ''}';

      toast(message);
    } catch (e) {
      if (!ctx.mounted) return;
      toast(
        'Failed to import from Hevy: ${e.toString()}',
        duration: const Duration(seconds: 10),
      );
    }
  }

  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (final name in possibleNames) {
      final idx = headers.indexOf(name);
      if (idx != -1) return idx;
    }
    // Try partial match
    for (int i = 0; i < headers.length; i++) {
      for (final name in possibleNames) {
        if (headers[i].contains(name)) return i;
      }
    }
    return -1;
  }

  DateTime _parseHevyDate(String dateStr) {
    // Try common Hevy date formats
    // Format 1: "2024-01-15 10:30:00"
    // Format 2: "31 Dec 2025, 14:59" (actual Hevy format)
    // Format 3: "Jan 15, 2024 10:30:00"
    // Format 4: ISO 8601

    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // Month name mapping
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    // Try Hevy format: "31 Dec 2025, 14:59"
    final hevyPattern = RegExp(r'(\d{1,2})\s+(\w{3})\s+(\d{4}),?\s+(\d{1,2}):(\d{2})');
    final hevyMatch = hevyPattern.firstMatch(dateStr);
    if (hevyMatch != null) {
      try {
        final day = int.parse(hevyMatch.group(1)!);
        final monthStr = hevyMatch.group(2)!.toLowerCase();
        final year = int.parse(hevyMatch.group(3)!);
        final hour = int.parse(hevyMatch.group(4)!);
        final minute = int.parse(hevyMatch.group(5)!);
        final month = months[monthStr] ?? 1;
        return DateTime(year, month, day, hour, minute);
      } catch (_) {}
    }

    // Try other formats
    final patterns = [
      RegExp(r'(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})'),
      RegExp(r'(\w{3})\s+(\d{1,2}),?\s+(\d{4})\s+(\d{1,2}):(\d{2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(dateStr);
      if (match != null) {
        try {
          if (pattern == patterns[0]) {
            return DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
              int.parse(match.group(4)!),
              int.parse(match.group(5)!),
            );
          } else if (pattern == patterns[1]) {
            final monthStr = match.group(1)!.toLowerCase();
            final month = months[monthStr] ?? 1;
            return DateTime(
              int.parse(match.group(3)!),
              month,
              int.parse(match.group(2)!),
              int.parse(match.group(4)!),
              int.parse(match.group(5)!),
            );
          }
        } catch (_) {}
      }
    }

    return DateTime.now();
  }

  Future<int> _getNextWorkoutId() async {
    final result = await db.customSelect(
      'SELECT COALESCE(MAX(workout_id), 0) + 1 as next_id FROM gym_sets',
    ).getSingleOrNull();
    return result?.read<int>('next_id') ?? 1;
  }
}
