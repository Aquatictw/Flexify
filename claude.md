# Flexify - Claude Code Context

## Project Overview
Flexify is a Flutter/Dart fitness tracking mobile app (cross-platform: Android, iOS, Linux, macOS, Windows).

### Key Technologies
- **Framework**: Flutter with Dart (SDK >= 3.2.6)
- **Database**: Drift (Dart SQLite ORM) - Version 2.28.1
- **State Management**: Provider pattern (v6.1.1)
- **UI**: Material Design 3

## Database Architecture

### Current Schema (v50)

#### Tables

1. **Workouts** (workout sessions - groups sets together)
   - `id` (autoincrement, primary key)
   - `startTime` (DateTime - when workout started)
   - `endTime` (DateTime, nullable - when workout finished)
   - `planId` (nullable int - which plan template was used)
   - `name` (nullable text - workout name, e.g., "Monday Chest")
   - `notes` (nullable text)

2. **GymSets** (individual exercise sets)
   - `id` (autoincrement, primary key)
   - `name` (exercise name)
   - `reps`, `weight`, `unit`
   - `created` (DateTime)
   - `cardio`, `duration`, `distance`, `incline`
   - `bodyWeight`, `restMs`, `hidden`
   - `planId` (nullable - plan template reference)
   - `workoutId` (nullable int - **links to Workouts.id** for session grouping)
   - `image`, `category`, `notes`
   - `sequence` (int, default 0 - **preserves exercise display order in history**)
   - `warmup` (bool, default false - **indicates if set is a warmup set**)

3. **Plans** (workout templates)
   - `id`, `days`, `sequence`, `title`

4. **PlanExercises** (exercises in a plan template)
   - `id`, `planId`, `exercise`, `enabled`, `maxSets`, `warmupSets`, `timers`, `sequence`

5. **Settings** (app preferences - 30+ fields)

6. **Metadata** (version tracking)

### Data Hierarchy
```
Workout Session (e.g., "Monday Chest - Dec 29, 5pm")
  └── Exercise 1 (e.g., Bench Press)
  │     ├── Set 1: 10x135lb
  │     ├── Set 2: 8x155lb
  │     └── Set 3: 6x175lb
  └── Exercise 2 (e.g., Incline Press)
        ├── Set 1: 12x50lb
        └── Set 2: 10x55lb
```

## Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry, database init, Provider setup |
| `lib/database/database.dart` | Drift DB definition, all migrations (v1-v49) |
| `lib/database/database.steps.dart` | **Generated** migration steps, Schema classes, Shape classes |
| `lib/database/workouts.dart` | Workouts table definition |
| `lib/database/gym_sets.dart` | GymSets table + graph utilities |
| `lib/database/plans.dart` | Plans table |
| `lib/database/plan_exercises.dart` | PlanExercises junction table |
| `lib/sets/history_page.dart` | History tab - toggle between Workouts/Sets view |
| `lib/workouts/workouts_list.dart` | Workout cards list for history |
| `lib/workouts/workout_detail_page.dart` | View a complete workout session (sorts by sequence) |
| `lib/workouts/workout_state.dart` | WorkoutState provider - manages single active workout |
| `lib/workouts/active_workout_bar.dart` | Floating bar showing ongoing workout |
| `lib/plan/start_plan_page.dart` | Workout execution UI - creates workout sessions |
| `lib/plan/exercise_sets_card.dart` | Exercise card with sets, popup menu, notes dialog |
| `lib/plan/plans_page.dart` | Plans list page with freeform workout option |
| `lib/plan/plan_tile.dart` | Plan list tile - checks for active workout before starting |
| `lib/app_search.dart` | Reusable search AppBar with optional Add menu item |
| `drift_schemas/db/drift_schema_vN.json` | Schema JSON files for each version |

## Workout Session Feature

### How It Works

1. **Starting a Workout**: When user opens `StartPlanPage`, `WorkoutState` manages workout creation. Only ONE workout can be active at a time.

2. **Logging Sets**: Each set saved gets the current `workoutId` attached, linking it to the workout session.

3. **Active Workout Bar**: A floating bar appears above the bottom navigation showing the current workout with:
   - Workout name and elapsed time
   - Tap to resume (navigate to StartPlanPage)
   - "End" button to stop the workout

4. **Single Workout Limit**: If a user tries to start a different plan while a workout is active, they see a toast message "Finish your current workout first" with a "Resume" option.

5. **Ending a Workout**: User must explicitly end via the ActiveWorkoutBar dialog. Workout persists even when navigating away from StartPlanPage.

6. **Viewing History**: The History tab has a toggle between:
   - **Workouts view**: Shows workout session cards with exercise count, set count, and duration
   - **Sets view**: Shows individual sets (legacy view)

7. **Workout Details**: Tapping a workout card opens `WorkoutDetailPage` showing all exercises and sets grouped together.

### Key Code Paths

**WorkoutState provider** (`lib/workouts/workout_state.dart`):
- `startWorkout(Plan plan)` - Creates new workout, returns null if one already exists
- `stopWorkout()` - Sets endTime on active workout and clears state
- `hasActiveWorkout` - Boolean indicating if a workout is in progress

**Starting a workout via WorkoutState** (`lib/plan/start_plan_page.dart`):
```dart
final workoutState = context.read<WorkoutState>();
if (workoutState.activeWorkout == null) {
  final workout = await workoutState.startWorkout(widget.plan);
  workoutId = workout.id;
}
```

**Preventing multiple workouts** (`lib/plan/plan_tile.dart`):
```dart
if (workoutState.hasActiveWorkout && workoutState.activePlan?.id != widget.plan.id) {
  toast('Finish your current workout first');
  return;
}
```

**Linking sets to workout** (`lib/plan/start_plan_page.dart`):
```dart
workoutId: Value(workoutId),
```

**Ending workout via ActiveWorkoutBar** (`lib/workouts/active_workout_bar.dart`):
```dart
await workoutState.stopWorkout();
```

## Development Commands

```bash
# Run database migrations after schema changes (recommended)
./scripts/migrate.sh

# Generate Drift database code manually (if not using migrate.sh)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Build for release
flutter build apk
flutter build ios
```

## Architecture Notes

- **Stream-based UI**: Real-time updates via Drift watchers
- **Provider State**: Global state managed through Provider pattern
- **Offline-first**: Pure SQLite, no network dependency
- **Workout Grouping**: Sets are grouped into workout sessions via `workoutId` foreign key

## UI/UX Implementation Patterns

### Modal Dialogs Over Overlays

When showing dialogs/bottom sheets that need to appear above other overlays (like the ActiveWorkoutBar), use `useRootNavigator: true`:

```dart
// Bottom sheet that appears above all overlays
showModalBottomSheet(
  context: parentContext,
  useRootNavigator: true,  // Critical for overlay visibility
  builder: (context) => ...
);

// Dialog that appears above all overlays
showDialog(
  context: parentContext,
  useRootNavigator: true,  // Critical for overlay visibility
  builder: (context) => AlertDialog(...)
);
```

### TextEditingController in Dialogs

**DO NOT** manually dispose TextEditingController in dialog callbacks. Flutter manages the dialog lifecycle automatically:

```dart
// CORRECT - let Flutter manage lifecycle
Future<void> _showNotesDialog(BuildContext parentContext) async {
  final controller = TextEditingController(text: existingNotes);
  final result = await showDialog<String>(
    context: parentContext,
    useRootNavigator: true,
    builder: (context) => AlertDialog(
      content: TextField(controller: controller),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text('Save'),
        ),
      ],
    ),
  );
  // DO NOT call controller.dispose() here - causes "_dependents.isEmpty" error
  if (result != null) onNotesChanged(result);
}
```

### Exercise Reordering

Exercise reordering uses a dedicated mode toggle in the AppBar rather than always-visible drag handles:
- `_isReorderMode` state variable toggles between normal and reorder views
- `ReorderableListView` used only in reorder mode
- Pass `sequence: index` when saving sets to preserve order in history

### Freeform Workouts

Freeform workouts use time-based titles:
```dart
String _getTimeBasedWorkoutTitle() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Morning Workout';
  if (hour < 14) return 'Noon Workout';
  if (hour < 18) return 'Afternoon Workout';
  return 'Evening Workout';
}
```

Create with a temporary Plan object (id: -1) that has no exercises.

## Migration Notes

When adding new columns or tables, follow these steps:

### Standard Migration Process

1. **Edit table definition** (e.g., `lib/database/gym_sets.dart`):
   ```dart
   IntColumn get sequence => integer().withDefault(const Constant(0))();
   ```

2. **Update `@DriftDatabase` annotation** in `database.dart` if adding new tables

3. **Increment `schemaVersion`** in `lib/database/database.dart`:
   ```dart
   int get schemaVersion => 49;  // Bump from 48 to 49
   ```

4. **Run the migration script**:
   ```bash
   ./scripts/migrate.sh
   ```

   This script automatically:
   - Runs build_runner to generate code
   - Generates migration code with `drift_dev make-migrations`
   - Updates schema JSON files in `drift_schemas/`

5. **Add the migration step** in `onUpgrade: stepByStep(...)` in `database.dart`:
   ```dart
   from48To49: (Migrator m, Schema49 schema) async {
     await m.addColumn(schema.gymSets, schema.gymSets.sequence);
   },
   ```

### Manual Migration (Fallback)

If the automatic migration script doesn't generate the Schema class properly (e.g., Schema50 not found), you'll need to manually update both the schema JSON and `database.steps.dart`:

**a. Create the new schema JSON file** in `drift_schemas/db/`:
Copy the previous version's JSON (e.g., `drift_schema_v49.json` → `drift_schema_v50.json`) and add the new column to the appropriate table's columns array:
```json
{
  "name": "warmup",
  "getter_name": "warmup",
  "moor_type": "bool",
  "nullable": false,
  "customConstraints": null,
  "defaultConstraints": "CHECK (\"warmup\" IN (0, 1))",
  "dialectAwareDefaultConstraints": {"sqlite": "CHECK (\"warmup\" IN (0, 1))"},
  "default_dart": "const CustomExpression('0')",
  "default_client_dart": null,
  "dsl_features": []
}
```

**b. Add new column definition** in `database.steps.dart`:
```dart
i1.GeneratedColumn<bool> _column_89(String aliasedName) =>
    i1.GeneratedColumn<bool>('warmup', aliasedName, false,
        type: i1.DriftSqlType.bool,
        defaultValue: const CustomExpression('0'),
        defaultConstraints: i1.GeneratedColumn.constraintIsAlways(
            'CHECK ("warmup" IN (0, 1))'));
```

**c. Add new Shape class** (copy previous Shape, add new column getter):
```dart
class Shape39 extends i0.VersionedTable {
  Shape39({required super.source, required super.alias}) : super.aliased();
  // Copy all getters from Shape38, then add:
  i1.GeneratedColumn<bool> get warmup =>
      columnsByName['warmup']! as i1.GeneratedColumn<bool>;
}
```

**d. Add Schema class** (copy previous Schema, use new Shape for modified table, add new column to columns list):
```dart
final class Schema50 extends i0.VersionedSchema {
  Schema50({required super.database}) : super(version: 50);
  @override
  late final List<i1.DatabaseSchemaEntity> entities = [
    plans, gymSets, settings, planExercises, metadata, workouts,
  ];
  // Use Shape39 instead of Shape38 for gymSets:
  late final Shape39 gymSets = Shape39(
      source: i0.VersionedTable(
        entityName: 'gym_sets',
        // ... copy from previous Schema, add _column_89 to columns list
        columns: [..., _column_89],
      ),
      alias: null);
  // Copy other tables from previous Schema unchanged
}
```

**e. Update `migrationSteps()` function:**
- Add parameter: `required Future<void> Function(i1.Migrator m, Schema50 schema) from49To50,`
- Add switch case:
  ```dart
  case 49:
    final schema = Schema50(database: database);
    final migrator = i1.Migrator(database, schema);
    await from49To50(migrator, schema);
    return 50;
  ```

**f. Update `stepByStep()` function:**
- Add parameter: `required Future<void> Function(i1.Migrator m, Schema50 schema) from49To50,`
- Add to migrationSteps call: `from49To50: from49To50,`

**g. Run build_runner** to regenerate database.g.dart with the new column:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Type Usage in Migrations

- **In `constants.dart` `SettingsCompanion.insert()`**: required fields use plain values, optional use `Value()`
- **In migrations with `RawValuesInsertable()`**: ALL fields use `Variable()`
- **In table schema `withDefault()`**: use `const Constant(value)`

### Import Conflicts

When using both Drift and Flutter Material, hide Drift's `Column`:
```dart
import 'package:drift/drift.dart' hide Column;
```

## Common Gotchas

1. **Plan constructor**: The `Plan` class has no `exercises` field - exercises are in the separate `PlanExercises` table
2. **Popup menu context**: When showing dialogs from bottom sheets, capture the parent context before the bottom sheet opens
3. **Exercise order in history**: Use the `sequence` column in GymSets to sort, not creation time
4. **Schema JSON structure**: The JSON includes all tables and their columns - ensure column order matches the schema class
