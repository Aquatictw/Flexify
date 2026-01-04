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
  'bench press (smith machine)': ('Bench press (Smith machine)', 'Chest'),
  'flat bench press (barbell)': ('Barbell bench press', 'Chest'),
  'flat bench press (dumbbell)': ('Dumbbell bench press', 'Chest'),
  'incline bench press (barbell)': ('Incline bench press', 'Chest'),
  'incline bench press (dumbbell)': ('Incline dumbbell press', 'Chest'),
  'incline bench press (smith machine)': (
    'Incline bench press (Smith machine)',
    'Chest'
  ),
  'incline chest press (machine)': ('Incline chest press (Machine)', 'Chest'),
  'decline bench press (barbell)': ('Decline bench press', 'Chest'),
  'decline bench press (dumbbell)': ('Decline dumbbell press', 'Chest'),
  'decline bench press (machine)': ('Decline bench press (Machine)', 'Chest'),
  'chest press (machine)': ('Chest press (Machine)', 'Chest'),
  'iso-lateral chest press (machine)': (
    'Iso-lateral chest press (Machine)',
    'Chest'
  ),
  'chest fly': ('Chest fly', 'Chest'),
  'chest fly (dumbbell)': ('Dumbbell fly', 'Chest'),
  'chest fly (cable)': ('Cable fly', 'Chest'),
  'chest fly (machine)': ('Chest fly (Machine)', 'Chest'),
  'cable fly': ('Cable fly', 'Chest'),
  'cable fly crossovers': ('Cable fly crossover', 'Chest'),
  'low cable fly crossovers': ('Low cable fly', 'Chest'),
  'seated chest flys (cable)': ('Seated cable fly', 'Chest'),
  'pec deck': ('Pec deck', 'Chest'),
  'butterfly (pec deck)': ('Pec deck', 'Chest'),
  'push up': ('Push-up', 'Chest'),
  'push-up': ('Push-up', 'Chest'),
  'pushup': ('Push-up', 'Chest'),
  'push ups': ('Push-up', 'Chest'),
  'diamond push up': ('Diamond push-up', 'Chest'),
  'wide push up': ('Wide-grip push-up', 'Chest'),
  'dips': ('Dip', 'Chest'),
  'dip': ('Dip', 'Chest'),
  'chest dip': ('Chest dip', 'Chest'),
  'chest dip (assisted)': ('Assisted chest dip', 'Chest'),
  'seated dip machine': ('Seated dip (Machine)', 'Chest'),

  // Back exercises
  'deadlift (barbell)': ('Deadlift', 'Back'),
  'deadlift': ('Deadlift', 'Back'),
  'deadlift (smith machine)': ('Deadlift (Smith machine)', 'Back'),
  'deadlift (trap bar)': ('Trap bar deadlift', 'Back'),
  'conventional deadlift': ('Deadlift', 'Back'),
  'sumo deadlift': ('Sumo deadlift', 'Back'),
  'romanian deadlift (barbell)': ('Romanian deadlift', 'Back'),
  'romanian deadlift (dumbbell)': ('Dumbbell Romanian deadlift', 'Back'),
  'romanian deadlift': ('Romanian deadlift', 'Back'),
  'stiff leg deadlift': ('Stiff Leg deadlift', 'Back'),
  'bent over row (barbell)': ('Barbell bent-over row', 'Back'),
  'bent over row (dumbbell)': ('Dumbbell bent-over row', 'Back'),
  'barbell row': ('Barbell bent-over row', 'Back'),
  'dumbbell row': ('Dumbbell row', 'Back'),
  'one arm dumbbell row': ('Dumbbell row', 'Back'),
  'single arm dumbbell row': ('Dumbbell row', 'Back'),
  'chest supported incline row (dumbbell)': (
    'Chest supported incline row',
    'Back'
  ),
  'single arm cable row': ('Single arm cable row', 'Back'),
  't-bar row': ('T-bar row', 'Back'),
  't bar row': ('T-bar row', 'Back'),
  'meadows rows (barbell)': ('Meadows row', 'Back'),
  'seal row': ('Seal row', 'Back'),
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
  'lat pulldown (machine)': ('Lat pull-down (Machine)', 'Back'),
  'lat pull down': ('Lat pull-down', 'Back'),
  'lat pulldown - close grip (cable)': ('Close grip lat pull-down', 'Back'),
  'wide grip lat pulldown': ('Wide grip lat pull-down', 'Back'),
  'close grip lat pulldown': ('Close grip lat pull-down', 'Back'),
  'single arm lat pulldown': ('Single arm lat pull-down', 'Back'),
  'cable pulldown': ('Straight arm lat pull-down', 'Back'),
  'straight arm lat pulldown (cable)': ('Straight arm lat pull-down', 'Back'),
  'rope straight arm pulldown': ('Rope straight arm pull-down', 'Back'),
  'seated cable row': ('Seated cable row', 'Back'),
  'seated cable row - bar grip': ('Seated cable row', 'Back'),
  'seated cable row - v grip (cable)': ('Seated cable row (V-grip)', 'Back'),
  'cable row': ('Seated cable row', 'Back'),
  'seated row': ('Seated cable row', 'Back'),
  'seated row (cable)': ('Seated cable row', 'Back'),
  'seated row (machine)': ('Seated row (Machine)', 'Back'),
  'iso-lateral row (machine)': ('Iso-lateral row (Machine)', 'Back'),
  'iso-lateral high row (machine)': ('Iso-lateral high row (Machine)', 'Back'),
  'iso-lateral low row': ('Iso-lateral low row (Machine)', 'Back'),
  'rhomboid cable high pull': ('Rhomboid cable pull', 'Back'),
  'vertical traction': ('Vertical traction', 'Back'),
  'back extension': ('Back extension', 'Back'),
  'back extension (machine)': ('Back extension (Machine)', 'Back'),
  'back extension (weighted hyperextension)': (
    'Weighted hyperextension',
    'Back'
  ),
  'hyperextension': ('Hyperextension', 'Back'),
  'good morning': ('Good morning', 'Back'),
  'good morning (barbell)': ('Good morning', 'Back'),
  'reverse grip pulldown': ('Reverse grip pull-down', 'Back'),
  'techno gym cable standing roa': ('Cable row', 'Back'),

  // Shoulder exercises
  'overhead press (barbell)': ('Overhead press', 'Shoulders'),
  'overhead press (dumbbell)': ('Dumbbell shoulder press', 'Shoulders'),
  'overhead press': ('Overhead press', 'Shoulders'),
  'overhead press (smith machine)': (
    'Overhead press (Smith machine)',
    'Shoulders'
  ),
  'military press': ('Overhead press', 'Shoulders'),
  'shoulder press (barbell)': ('Overhead press', 'Shoulders'),
  'shoulder press (dumbbell)': ('Dumbbell shoulder press', 'Shoulders'),
  'shoulder press (machine)': ('Shoulder press (Machine)', 'Shoulders'),
  'shoulder press (machine plates)': ('Shoulder press (Machine)', 'Shoulders'),
  'seated overhead press (barbell)': ('Seated overhead press', 'Shoulders'),
  'seated shoulder press (machine)': ('Shoulder press (Machine)', 'Shoulders'),
  'arnold press': ('Arnold press', 'Shoulders'),
  'arnold press (dumbbell)': ('Arnold press', 'Shoulders'),
  'lateral raise': ('Dumbbell lateral raise', 'Shoulders'),
  'lateral raise (dumbbell)': ('Dumbbell lateral raise', 'Shoulders'),
  'lateral raise (cable)': ('Cable lateral raise', 'Shoulders'),
  'lateral raise (machine)': ('Lateral raise (Machine)', 'Shoulders'),
  'side lateral raise': ('Dumbbell lateral raise', 'Shoulders'),
  'seated lateral raise (dumbbell)': ('Seated lateral raise', 'Shoulders'),
  'lying lateral raise': ('Lying lateral raise', 'Shoulders'),
  'cable lateral raise': ('Cable lateral raise', 'Shoulders'),
  'single arm lateral raise (cable)': (
    'Single arm cable lateral raise',
    'Shoulders'
  ),
  'egyptian cable lateral raise': ('Egyptian lateral raise', 'Shoulders'),
  'cuffed behind lateral raise': ('Behind back lateral raise', 'Shoulders'),
  'front raise': ('Front raise', 'Shoulders'),
  'front raise (dumbbell)': ('Front raise', 'Shoulders'),
  'front raise (barbell)': ('Barbell front raise', 'Shoulders'),
  'front raise (cable)': ('Cable front raise', 'Shoulders'),
  'rear delt fly': ('Rear delt fly', 'Shoulders'),
  'rear delt fly (dumbbell)': ('Dumbbell rear delt fly', 'Shoulders'),
  'rear delt reverse fly (dumbbell)': ('Dumbbell rear delt fly', 'Shoulders'),
  'rear delt reverse fly (cable)': ('Cable rear delt fly', 'Shoulders'),
  'rear delt reverse fly (machine)': ('Rear delt fly (Machine)', 'Shoulders'),
  'reverse fly': ('Rear delt fly', 'Shoulders'),
  'reverse fly single arm (cable)': ('Single arm reverse fly', 'Shoulders'),
  'face pull': ('Face pull', 'Shoulders'),
  'face pull (cable)': ('Face pull', 'Shoulders'),
  'shrug (barbell)': ('Barbell shrug', 'Shoulders'),
  'shrug (dumbbell)': ('Dumbbell shrug', 'Shoulders'),
  'shrug': ('Barbell shrug', 'Shoulders'),
  'barbell shrug': ('Barbell shrug', 'Shoulders'),
  'dumbbell shrug': ('Dumbbell shrug', 'Shoulders'),
  'upright row': ('Upright row', 'Shoulders'),
  'upright row (barbell)': ('Upright row', 'Shoulders'),
  'upright row (dumbbell)': ('Dumbbell upright row', 'Shoulders'),
  'upright row (cable)': ('Cable upright row', 'Shoulders'),

  // Arms - Biceps
  'bicep curl (barbell)': ('Barbell biceps curl', 'Arms'),
  'bicep curl (dumbbell)': ('Dumbbell biceps curl', 'Arms'),
  'bicep curl (cable)': ('Cable biceps curl', 'Arms'),
  'bicep curl (machine)': ('Biceps curl (Machine)', 'Arms'),
  'biceps curl (barbell)': ('Barbell biceps curl', 'Arms'),
  'biceps curl (dumbbell)': ('Dumbbell biceps curl', 'Arms'),
  'barbell curl': ('Barbell biceps curl', 'Arms'),
  'dumbbell curl': ('Dumbbell biceps curl', 'Arms'),
  '21s bicep curl': ('21s biceps curl', 'Arms'),
  'single arm bicep curl (cable)': ('Single arm cable curl', 'Arms'),
  'hammer curl': ('Hammer curl', 'Arms'),
  'hammer curl (dumbbell)': ('Hammer curl', 'Arms'),
  'hammer curl (cable)': ('Cable hammer curl', 'Arms'),
  'cross body hammer curl': ('Cross body hammer curl', 'Arms'),
  'lying bicep hammer curls': ('Lying hammer curl', 'Arms'),
  'preacher curl': ('Preacher curl', 'Arms'),
  'preacher curl (barbell)': ('Barbell preacher curl', 'Arms'),
  'preacher curl (dumbbell)': ('Preacher curl', 'Arms'),
  'preacher curl (machine)': ('Preacher curl (Machine)', 'Arms'),
  'hammer preacher curl': ('Hammer preacher curl', 'Arms'),
  'concentration curl': ('Concentration curl', 'Arms'),
  'incline curl': ('Incline curl', 'Arms'),
  'incline dumbbell curl': ('Incline curl', 'Arms'),
  'seated incline curl (dumbbell)': ('Seated incline curl', 'Arms'),
  'cable curl': ('Cable curl', 'Arms'),
  'rope cable curl': ('Rope cable curl', 'Arms'),
  'bicep cable high pull': ('Cable high pull', 'Arms'),
  'ez bar curl': ('EZ bar curl', 'Arms'),
  'ez bar biceps curl': ('EZ bar curl', 'Arms'),
  'reverse curl (barbell)': ('Reverse barbell curl', 'Arms'),
  'behind the back bicep wrist curl (barbell)': (
    'Behind back wrist curl',
    'Arms'
  ),
  'seated palms up wrist curl': ('Wrist curl', 'Arms'),

  // Arms - Triceps
  'bench press - close grip (barbell)': ('Close grip bench press', 'Arms'),
  'close grip bench press': ('Close grip bench press', 'Arms'),
  'tricep pushdown': ('Triceps pushdown', 'Arms'),
  'triceps pushdown': ('Triceps pushdown', 'Arms'),
  'tricep pushdown (cable)': ('Triceps pushdown', 'Arms'),
  'triceps pushdown (cable)': ('Triceps pushdown', 'Arms'),
  'rope pushdown': ('Rope triceps pushdown', 'Arms'),
  'triceps rope pushdown': ('Rope triceps pushdown', 'Arms'),
  'single arm triceps pushdown (cable)': (
    'Single arm triceps pushdown',
    'Arms'
  ),
  'tricep extension': ('Triceps extension', 'Arms'),
  'triceps extension': ('Triceps extension', 'Arms'),
  'tricep extension (straight bar)': (
    'Triceps extension (Straight bar)',
    'Arms'
  ),
  'triceps extension (barbell)': ('Barbell triceps extension', 'Arms'),
  'triceps extension (cable)': ('Cable triceps extension', 'Arms'),
  'triceps extension (dumbbell)': ('Dumbbell triceps extension', 'Arms'),
  'overhead tricep extension': ('Triceps extension', 'Arms'),
  'overhead triceps extension': ('Triceps extension', 'Arms'),
  'single arm tricep extension (dumbbell)': (
    'Single arm triceps extension',
    'Arms'
  ),
  'seated triceps press': ('Seated triceps press', 'Arms'),
  'skull crusher': ('Skull crusher', 'Arms'),
  'skull crushers': ('Skull crusher', 'Arms'),
  'skullcrusher (barbell)': ('Skull crusher', 'Arms'),
  'skullcrusher (dumbbell)': ('Dumbbell skull crusher', 'Arms'),
  'lying tricep extension': ('Skull crusher', 'Arms'),
  'tricep dip': ('Dip', 'Arms'),
  'triceps dip': ('Dip', 'Arms'),
  'triceps dip (assisted)': ('Assisted dip', 'Arms'),
  'tricep kickback': ('Tricep kickback', 'Arms'),

  // Legs
  'squat (barbell)': ('Squat', 'Legs'),
  'squat': ('Squat', 'Legs'),
  'squat (machine)': ('Squat (Machine)', 'Legs'),
  'back squat': ('Squat', 'Legs'),
  'front squat': ('Front squat', 'Legs'),
  'front squat (barbell)': ('Front squat', 'Legs'),
  'goblet squat': ('Goblet squat', 'Legs'),
  'hack squat': ('Hack squat', 'Legs'),
  'hack squat (machine)': ('Hack squat (Machine)', 'Legs'),
  'bulgarian split squat': ('Bulgarian split squat', 'Legs'),
  'pendulum squat (machine)': ('Pendulum squat (Machine)', 'Legs'),
  'leg press': ('Leg press', 'Legs'),
  'leg press (machine)': ('Leg press', 'Legs'),
  'leg press horizontal (machine)': ('Horizontal leg press', 'Legs'),
  'leg extension': ('Leg extension', 'Legs'),
  'leg extension (machine)': ('Leg extension', 'Legs'),
  'nautilus leg extension': ('Nautilus leg extension', 'Legs'),
  'single leg extensions': ('Single leg extension', 'Legs'),
  'leg curl': ('Leg curl', 'Legs'),
  'leg curl (machine)': ('Leg curl', 'Legs'),
  'lying leg curl': ('Lying leg curl', 'Legs'),
  'lying leg curl (machine)': ('Lying leg curl', 'Legs'),
  'seated leg curl': ('Leg curl', 'Legs'),
  'seated leg curl (machine)': ('Leg curl', 'Legs'),
  'iso leg curl': ('Iso leg curl', 'Legs'),
  'lunge': ('Lunge', 'Legs'),
  'lunge (barbell)': ('Barbell lunge', 'Legs'),
  'lunge (dumbbell)': ('Lunge', 'Legs'),
  'walking lunge': ('Lunge', 'Legs'),
  'hip thrust': ('Hip thrust', 'Legs'),
  'hip thrust (barbell)': ('Hip thrust', 'Legs'),
  'hip thrust (machine)': ('Hip thrust (Machine)', 'Legs'),
  'hip abduction (machine)': ('Hip abduction (Machine)', 'Legs'),
  'hip adduction (machine)': ('Hip adduction (Machine)', 'Legs'),
  'glute bridge': ('Glute bridge', 'Legs'),

  // Calves
  'calf raise (standing)': ('Standing calf raise', 'Calves'),
  'calf raise (seated)': ('Seated calf raise', 'Calves'),
  'standing calf raise': ('Standing calf raise', 'Calves'),
  'standing calf raise (smith)': (
    'Standing calf raise (Smith machine)',
    'Calves'
  ),
  'seated calf raise': ('Seated calf raise', 'Calves'),
  'calf raise': ('Standing calf raise', 'Calves'),
  'calf press': ('Calf press', 'Calves'),
  'calf press (machine)': ('Calf press (Machine)', 'Calves'),
  'calf extension (machine)': ('Calf extension (Machine)', 'Calves'),
  'leg press calf raise': ('Leg press calf raise', 'Calves'),

  // Core
  'crunch': ('Crunch', 'Core'),
  'crunches': ('Crunch', 'Core'),
  'crunch (machine)': ('Crunch (Machine)', 'Core'),
  'cable crunch': ('Cable crunch', 'Core'),
  'decline crunch': ('Decline crunch', 'Core'),
  'decline crunch (weighted)': ('Weighted decline crunch', 'Core'),
  'bicycle crunch': ('Bicycle crunch', 'Core'),
  'sit up': ('Sit-up', 'Core'),
  'sit-up': ('Sit-up', 'Core'),
  'situp': ('Sit-up', 'Core'),
  'sit ups': ('Sit-up', 'Core'),
  'plank': ('Plank', 'Core'),
  'russian twist': ('Russian twist', 'Core'),
  'leg raise': ('Leg raise', 'Core'),
  'leg raises': ('Leg raise', 'Core'),
  'hanging leg raise': ('Hanging leg raise', 'Core'),
  'hanging knee raise': ('Hanging knee raise', 'Core'),
  'knee raise parallel bars': ('Parallel bar knee raise', 'Core'),
  'leg raise parallel bars': ('Parallel bar leg raise', 'Core'),
  'ab wheel': ('Ab wheel', 'Core'),
  'ab wheel rollout': ('Ab wheel', 'Core'),
  'wood chop': ('Wood chop', 'Core'),
  'mountain climber': ('Mountain climber', 'Core'),
  'dead bug': ('Dead bug', 'Core'),

  // Cardio
  'running': ('Running', 'Cardio'),
  'running (time)': ('Running', 'Cardio'),
  'treadmill': ('Treadmill', 'Cardio'),
  'cycling': ('Cycling', 'Cardio'),
  'bike': ('Cycling', 'Cardio'),
  'stationary bike': ('Stationary bike', 'Cardio'),
  'spinning': ('Spinning', 'Cardio'),
  'elliptical': ('Elliptical', 'Cardio'),
  'rowing': ('Rowing', 'Cardio'),
  'rowing machine': ('Rowing', 'Cardio'),
  'stair climber': ('Stair climber', 'Cardio'),
  'jump rope': ('Jump rope', 'Cardio'),
  'walking': ('Walking', 'Cardio'),
  'sled push': ('Sled push', 'Cardio'),

  // Other
  'dead hang': ('Dead hang', 'Other'),
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
      .map(
        (word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
      )
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

      final headers =
          rows.first.map((e) => e.toString().toLowerCase()).toList();

      // Find column indices
      final titleIdx =
          _findColumnIndex(headers, ['title', 'workout_name', 'workout']);
      final startTimeIdx =
          _findColumnIndex(headers, ['start_time', 'date', 'start']);
      final endTimeIdx = _findColumnIndex(headers, ['end_time', 'end']);
      final exerciseIdx = _findColumnIndex(
        headers,
        ['exercise_title', 'exercise_name', 'exercise'],
      );
      final weightIdx = _findColumnIndex(
        headers,
        ['weight_kg', 'weight_lbs', 'weight (kg)', 'weight (lbs)', 'weight'],
      );
      final repsIdx = _findColumnIndex(headers, ['reps', 'repetitions']);
      final distanceIdx = _findColumnIndex(
        headers,
        ['distance_km', 'distance_m', 'distance (km)', 'distance'],
      );
      final durationIdx = _findColumnIndex(
        headers,
        ['duration_seconds', 'duration_s', 'duration'],
      );
      final notesIdx = _findColumnIndex(
        headers,
        ['exercise_notes', 'notes', 'note', 'set_notes'],
      );
      final setTypeIdx = _findColumnIndex(headers, ['set_type', 'type']);

      if (exerciseIdx == -1) {
        throw Exception(
          'Could not find exercise column in CSV. Expected columns: exercise_title, exercise_name, or exercise',
        );
      }
      if (weightIdx == -1 && repsIdx == -1) {
        throw Exception('Could not find weight or reps columns in CSV');
      }

      // Determine if weight is in lbs
      final isLbs = headers.any((h) => h.contains('lbs'));
      final unit = isLbs ? 'lb' : 'kg';

      // First pass: collect all unique workouts and their sets
      final workoutSets = <String, List<Map<String, dynamic>>>{};
      final workoutInfo = <String, Map<String, dynamic>>{};
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

        // Parse workout info
        DateTime startTime = DateTime.now();
        DateTime? endTime;
        String workoutName = 'Imported Workout';
        String workoutKey = '';

        if (startTimeIdx != -1 && row.elementAtOrNull(startTimeIdx) != null) {
          final startTimeStr = row[startTimeIdx].toString();
          startTime = _parseHevyDate(startTimeStr);
          workoutKey = startTimeStr; // Use the raw start_time as unique key
        }

        if (endTimeIdx != -1 && row.elementAtOrNull(endTimeIdx) != null) {
          final endTimeStr = row[endTimeIdx].toString();
          endTime = _parseHevyDate(endTimeStr);
        }

        if (titleIdx != -1 && row.elementAtOrNull(titleIdx) != null) {
          workoutName = row[titleIdx].toString();
        }

        // Store workout info if not already stored
        if (workoutKey.isNotEmpty && !workoutInfo.containsKey(workoutKey)) {
          workoutInfo[workoutKey] = {
            'startTime': startTime,
            'endTime': endTime,
            'name': workoutName,
          };
        }

        // Parse set data
        double weight = 0;
        if (weightIdx != -1 && row.elementAtOrNull(weightIdx) != null) {
          weight = double.tryParse(row[weightIdx].toString()) ?? 0;
        }

        double reps = 0;
        if (repsIdx != -1 && row.elementAtOrNull(repsIdx) != null) {
          reps = double.tryParse(row[repsIdx].toString()) ?? 0;
        }

        double distance = 0;
        if (distanceIdx != -1 && row.elementAtOrNull(distanceIdx) != null) {
          distance = double.tryParse(row[distanceIdx].toString()) ?? 0;
        }

        double duration = 0;
        if (durationIdx != -1 && row.elementAtOrNull(durationIdx) != null) {
          final durationSeconds =
              double.tryParse(row[durationIdx].toString()) ?? 0;
          duration = durationSeconds / 60;
        }

        String? notes;
        if (notesIdx != -1 && row.elementAtOrNull(notesIdx) != null) {
          final noteStr = row[notesIdx].toString().trim();
          if (noteStr.isNotEmpty) notes = noteStr;
        }

        bool isWarmup = false;
        bool isDropSet = false;
        if (setTypeIdx != -1 && row.elementAtOrNull(setTypeIdx) != null) {
          final setType = row[setTypeIdx].toString().toLowerCase();
          isWarmup = setType == 'warmup';
          isDropSet = setType == 'dropset';
        }

        final isCardio =
            distance > 0 || (duration > 0 && weight == 0 && reps == 0);

        // Add to workout's sets
        workoutSets.putIfAbsent(workoutKey, () => []);
        workoutSets[workoutKey]!.add({
          'name': mappedName,
          'category': category,
          'reps': reps,
          'weight': weight,
          'created': startTime,
          'unit': unit,
          'cardio': isCardio,
          'distance': distance,
          'duration': duration,
          'notes': notes,
          'warmup': isWarmup,
          'dropSet': isDropSet,
        });
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

      // Second pass: create workouts and insert sets
      int totalSets = 0;
      int totalWorkouts = 0;

      for (final entry in workoutInfo.entries) {
        final workoutKey = entry.key;
        final info = entry.value;
        final sets = workoutSets[workoutKey] ?? [];

        if (sets.isEmpty) continue;

        // Create the workout record
        final workoutId = await db.into(db.workouts).insert(
              WorkoutsCompanion(
                startTime: Value(info['startTime'] as DateTime),
                endTime: Value(info['endTime'] as DateTime?),
                name: Value(info['name'] as String?),
              ),
            );

        totalWorkouts++;

        // Insert all sets for this workout
        int sequence = 0;
        for (final setData in sets) {
          await db.into(db.gymSets).insert(
                GymSetsCompanion(
                  name: Value(setData['name'] as String),
                  reps: Value(setData['reps'] as double),
                  weight: Value(setData['weight'] as double),
                  created: Value(setData['created'] as DateTime),
                  unit: Value(setData['unit'] as String),
                  category: Value(setData['category'] as String),
                  cardio: Value(setData['cardio'] as bool),
                  distance: Value(setData['distance'] as double),
                  duration: Value(setData['duration'] as double),
                  notes: Value(setData['notes'] as String?),
                  hidden: const Value(false),
                  workoutId: Value(workoutId),
                  warmup: Value(setData['warmup'] as bool),
                  dropSet: Value(setData['dropSet'] as bool),
                  sequence: Value(sequence++),
                ),
              );
          totalSets++;
        }
      }

      if (!ctx.mounted) return;

      final message =
          'Imported $totalSets sets in $totalWorkouts workouts from Hevy. '
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
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    // Try Hevy format: "31 Dec 2025, 14:59"
    final hevyPattern =
        RegExp(r'(\d{1,2})\s+(\w{3})\s+(\d{4}),?\s+(\d{1,2}):(\d{2})');
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
}
