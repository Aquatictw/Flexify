import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/database/database.dart';
import 'package:jackedlog/main.dart' as app;
import 'package:jackedlog/spotify/spotify_service.dart';
import 'package:jackedlog/spotify/spotify_web_api_service.dart';
import 'package:mockito/annotations.dart';

// Mock annotations for code generation - main() required by Mockito build_runner
@GenerateMocks([SpotifyService, SpotifyWebApiService])
void main() {} // Empty: mocks generated via: dart run build_runner build

/// Create in-memory database for testing
///
/// Returns a fresh database instance that automatically cleans up after tests.
/// No manual cleanup required - in-memory databases are garbage collected.
///
/// Also points the global `db` at it: production code (WorkoutState and
/// friends) reads that global, and without this it would fall through to the
/// real on-device database via path_provider.
Future<AppDatabase> createTestDatabase() async {
  // Use in-memory database that gets cleaned up automatically
  return app.db = AppDatabase(NativeDatabase.memory());
}

/// Create test GymSet with sensible defaults
GymSetsCompanion createTestSet({
  int? workoutId,
  String name = 'Test Exercise',
  double weight = 100.0,
  double reps = 10.0,
  int sequence = 0,
  int? setOrder,
  bool warmup = false,
  bool dropSet = false,
  bool cardio = false,
  String? notes,
  String unit = 'kg',
  String? category,
  String? image,
  double duration = 0.0,
  double distance = 0.0,
  int? incline,
  int? restMs,
  int? planId,
  String? exerciseType,
  String? brandName,
}) {
  return GymSetsCompanion.insert(
    name: name,
    reps: reps,
    weight: weight,
    unit: unit,
    created: DateTime.now(),
    cardio: Value(cardio),
    warmup: Value(warmup),
    dropSet: Value(dropSet),
    sequence: Value(sequence),
    setOrder: Value(setOrder),
    workoutId: Value(workoutId),
    notes: Value(notes),
    hidden: const Value(false),
    category: Value(category),
    image: Value(image),
    duration: Value(duration),
    distance: Value(distance),
    incline: Value(incline),
    restMs: Value(restMs),
    planId: Value(planId),
    exerciseType: Value(exerciseType),
    brandName: Value(brandName),
  );
}

/// Create test Workout with sensible defaults
WorkoutsCompanion createTestWorkout({
  DateTime? startTime,
  DateTime? endTime, // null = active workout
  int? planId,
  String name = 'Test Workout',
  String? notes,
  String? selfieImagePath,
}) {
  return WorkoutsCompanion.insert(
    startTime: startTime ?? DateTime.now(),
    endTime: Value(endTime),
    planId: Value(planId),
    name: Value(name),
    notes: Value(notes),
    selfieImagePath: Value(selfieImagePath),
  );
}

/// CSV fixtures for backward compatibility testing
const csvV59Format = '''
id,name,reps,weight,unit,created,cardio,duration,distance,incline,restMs,hidden,planId,workoutId,sequence,setOrder,image,category,notes,warmup,dropSet,exerciseType,brandName
1,Bench Press,10,225.0,kg,2026-01-13 10:00:00,0,,,,120000,0,,,0,0,,,Test notes,0,0,,''';

const csvV58Format = '''
id,name,reps,weight,unit,created,cardio,duration,distance,incline,restMs,hidden,planId,workoutId,sequence,setorder,image,category,notes,warmup,dropSet,exerciseType,brandName
1,Bench Press,10,225.0,kg,2026-01-13 10:00:00,0,,,,120000,0,,,0,0,,,Test notes,0,0,,''';

const csvV57Format = '''
id,name,reps,weight,unit,created,cardio,duration,distance,incline,restMs,hidden,planId,workoutId,sequence,image,category,notes,warmup,dropSet,exerciseType,brandName
1,Bench Press,10,225.0,kg,2026-01-13 10:00:00,0,,,,120000,0,,,0,,,Test notes,0,0,,''';

/// Edge case test data
const unicodeExerciseName = '벤치프레스 💪';
const specialCharsNote = '''
Test "quotes" & <brackets>
with newlines''';
