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
| `lib/records/records_service.dart` | Personal record detection and calculation |
| `lib/records/record_notification.dart` | PR celebration UI and badge widgets |
| `lib/app_search.dart` | Reusable search AppBar with optional Add menu item |
| `lib/graph/overview_page.dart` | Workout overview with stats, heatmap, and muscle charts |
| `drift_schemas/db/drift_schema_vN.json` | Schema JSON files for each version |

## Workout Overview & Statistics

The workout overview page (`lib/graph/overview_page.dart`) displays comprehensive statistics and visualizations:

**Features:**
- **Period Selector**: 7D, 1M, 3M, 6M, 1Y, All-time
- **Statistics Cards**: Workouts, Total Volume, Streak, Top Muscle
- **Training Heatmap**:
  - GitHub-style activity calendar showing workout days
  - Days of week column is fixed (doesn't scroll)
  - Grid is reversed (latest workouts on left for consistency)
  - Days properly aligned to Monday-Sunday weeks
  - Clicking a day shows workout details popup with clickable workout name
- **Muscle Group Volume Chart**: Top 10 muscles by weight × reps
- **Muscle Group Set Count Chart**: Top 10 muscles by total sets performed

**Implementation Details:**
- Uses `fl_chart` package for bar charts
- Heatmap uses Monday as week start (weekday 1-7)
- All queries filter out hidden sets (`hidden = 0`)
- Popup navigation creates Workout object from query results
- Charts use different colors (primary for volume, secondary for sets)

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

8. **Active Workout Navigation**: Clicking the ActiveWorkoutBar switches to the Plans tab (if needed) and navigates to the active workout. It clears the Plans navigator stack before pushing the workout page to avoid duplicate routes.

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

## Multi-Select Workout Deletion

### Overview

The History tab's Workouts view supports multi-selection for batch deletion of workout sessions, mirroring the UI/UX pattern used in the Plans tab.

### How It Works

1. **Entering Selection Mode**:
   - Long press any workout card to begin selecting
   - The card shows a checkbox instead of the date badge
   - Card gets highlighted with primary color

2. **Selecting Multiple Workouts**:
   - When in selection mode, tap any workout to toggle its selection
   - Selected cards show a checked checkbox and highlighted background
   - Badge in AppSearch menu shows selection count

3. **Batch Operations**:
   - **Delete**: Removes selected workouts and all associated gym sets
   - **Select All**: Selects all currently visible workouts (respects limit/filters)
   - **Clear**: Exit selection mode

4. **Exiting Selection Mode**:
   - Tap the back arrow in the search bar
   - Or complete a delete operation

### Implementation Details

**Files Modified:**
- `lib/workouts/workouts_list.dart` - Added selection UI support
- `lib/sets/history_page.dart` - Integrated AppSearch with selection handlers

**Key Features:**
- Cards change appearance when selected (highlighted background, border color)
- Smooth animations for checkbox transitions (150ms ScaleTransition)
- Checkboxes conditionally replace date badges during selection
- More compact vertical spacing (reduced padding from 16 to 12, margins from 6 to 4)
- Deletion is cascading: removes both workouts and their gym sets

**Selection State Management:**
```dart
// In history_page.dart
Set<int> selectedWorkouts = {};

// Toggle selection
onSelect: (id) {
  if (selectedWorkouts.contains(id))
    setState(() {
      selectedWorkouts.remove(id);
    });
  else
    setState(() {
      selectedWorkouts.add(id);
    });
}

// Delete operation
onDelete: () async {
  final copy = selectedWorkouts.toList();
  setState(() {
    selectedWorkouts.clear();
  });
  // Delete all gym sets associated with these workouts
  await db.gymSets.deleteWhere((tbl) => tbl.workoutId.isIn(copy));
  // Delete the workouts themselves
  await db.workouts.deleteWhere((tbl) => tbl.id.isIn(copy));
}
```

**Card Behavior:**
```dart
// In workouts_list.dart
onTap: () {
  if (selected.isNotEmpty) {
    onSelect(workout.id);  // Toggle selection when in selection mode
  } else {
    Navigator.push(...);  // Navigate to details when not selecting
  }
}
onLongPress: () {
  onSelect(workout.id);  // Enter selection mode
}
```

**Visual Styling:**
- Selected: `primary.withValues(alpha: .08)` background, `primary.withValues(alpha: 0.3)` border
- Unselected: Default card color, `outlineVariant.withValues(alpha: 0.1)` border
- Checkbox size: 24x24 with AnimatedSwitcher for smooth transitions

### UI/UX Patterns

This implementation follows the same pattern as Plans tab (`lib/plan/plans_page.dart` and `lib/plan/plan_tile.dart`):
- Uses `Set<int>` for tracking selected IDs
- AppSearch component handles search, select all, clear, and delete
- Long press initiates selection mode
- Visual feedback with color changes and borders
- Confirmation dialog before deletion

## Rest Timers & Exercise Data Loading

### How Rest Timers Work

Rest timers start automatically after completing a set (when marking it as not hidden). The timer duration comes from:
1. **Custom rest time**: Stored in `GymSet.restMs` field (per exercise, in milliseconds)
2. **Global default**: Falls back to `Settings.timerDuration` if no custom time is set

**Key locations:**
- Timer state management: `lib/timer/timer_state.dart`
- Timer UI bar: `lib/timer/rest_timer_bar.dart`
- Timer started in: `_completeSet()` method in both `ExerciseSetsCard` and `_AdHocExerciseCard`

### Exercise Data Loading Pattern

When loading an exercise in workout execution, both `ExerciseSetsCard` (`lib/plan/exercise_sets_card.dart`) and `_AdHocExerciseCard` (`lib/plan/start_plan_page.dart`) follow this pattern:

**1. Load last set from exercise history** to get defaults:
```dart
final lastSet = await (db.gymSets.select()
  ..where((tbl) => tbl.name.equals(exerciseName))
  ..orderBy([(u) => OrderingTerm(expression: u.created, mode: OrderingMode.desc)])
  ..limit(1))
  .getSingleOrNull();

// Extract defaults from last set
_defaultWeight = lastSet?.weight ?? 0.0;
_defaultReps = lastSet?.reps.toInt() ?? 8;
_brandName = lastSet?.brandName;
_exerciseType = lastSet?.exerciseType;
_restMs = lastSet?.restMs; // Custom rest time (nullable)
```

**2. Load existing sets from current workout** (if resuming):
```dart
existingSets = await (db.gymSets.select()
  ..where((tbl) =>
      tbl.name.equals(exerciseName) &
      tbl.workoutId.equals(workoutId) &
      tbl.sequence.equals(sequence))) // sequence identifies exercise instance
  .get();
```

**3. Start timer after completing a set**:
```dart
if (settings.restTimers) {
  final timerState = context.read<TimerState>();
  // Use custom rest time if set, otherwise use global default
  final restMs = _restMs ?? settings.timerDuration;
  timerState.startTimer(
    "$exerciseName ($completedCount)",
    Duration(milliseconds: restMs),
    settings.alarmSound,
    settings.vibrate,
  );
}
```

### Setting Custom Rest Times

Custom rest times are configured via:
- **Edit exercise page**: `lib/graph/edit_graph_page.dart`
- Updates all sets for that exercise with `restMs: Value(duration?.inMilliseconds)`
- Stored per exercise, not per plan or workout

**Important**: Custom rest times are stored at the GymSet level (not PlanExercise level), meaning they're tied to the exercise name across all workouts.

## Personal Records (PR) Feature

### Overview

The Personal Records feature automatically detects and celebrates when a user achieves a new personal best during their workout. It tracks three types of records per exercise:

1. **Best 1RM** (💪): Estimated one-rep max using Brzycki formula
2. **Best Volume** (🔥): Single-set volume (weight × reps)
3. **Best Weight** (🏆): Heaviest weight lifted

### Key Files

| File | Purpose |
|------|---------|
| `lib/records/records_service.dart` | Record calculation and checking logic |
| `lib/records/record_notification.dart` | Celebration notification UI and badge widgets |
| `lib/plan/exercise_sets_card.dart` | PR checking for plan exercises |
| `lib/plan/start_plan_page.dart` | PR checking for ad-hoc exercises |

### How It Works

**1. Record Detection** (`records_service.dart`):

When a set is completed, `checkForRecords()` queries the database to compare against historical bests:

```dart
final achievements = await checkForRecords(
  exerciseName: exerciseName,
  weight: weight,
  reps: reps,
  unit: unit,
  excludeSetId: setId, // Exclude current set from comparison
);
```

The function:
- Calculates 1RM using Brzycki formula: `weight / (1.0278 - 0.0278 * reps)`
- Handles negative weights (bodyweight assistance): `weight * (1.0278 - 0.0278 * reps)`
- Compares current set against all-time bests for that exercise
- Returns list of `RecordAchievement` objects for each record broken

**2. Celebration Notification** (`record_notification.dart`):

When records are detected, `showRecordNotification()` displays an animated celebration dialog:

```dart
if (achievements.isNotEmpty && mounted) {
  showRecordNotification(
    context,
    achievements: achievements,
    exerciseName: exerciseName,
  );
}
```

Features:
- Heavy haptic feedback on record achievement
- Animated confetti particles (30 particles with physics)
- Elastic bounce animation using `Curves.elasticOut`
- Golden crown icon with shimmer effect
- Shows all records broken in one notification
- Displays improvement percentage over previous best
- Auto-dismisses after 3 seconds

**Important**: The notification uses `.clamp(0.0, 1.0)` on opacity values because `Curves.easeOutBack` overshoots 1.0, which would cause assertion errors in the `Opacity` widget.

**3. Visual Indicators**:

- **RecordCrown**: Badge showing crown icon for sets that hold records
  - Colored by record type (amber for weight, orange for 1RM, deep orange for volume)
  - Shows tooltip with record types (e.g., "PR: Weight, 1RM")
  - Used in workout detail view to highlight PR sets

- **RecordIndicator**: Compact row of mini icons for each record type
  - Used in history/list views where space is limited

**4. Implementation in Exercise Cards**:

Both `ExerciseSetsCard` (plan exercises) and `_AdHocExerciseCard` (ad-hoc exercises) check for PRs in their `_completeSet()` methods:

```dart
// Check for records (only for non-warmup, non-cardio sets)
final setData = sets[index];
if (!setData.isWarmup && setData.weight > 0 && setData.reps > 0) {
  final achievements = await checkForRecords(
    exerciseName: exerciseName,
    weight: setData.weight,
    reps: setData.reps.toDouble(),
    unit: unit,
    excludeSetId: sets[index].savedSetId,
  );

  if (achievements.isNotEmpty) {
    // Store record types on the set for badge display
    setState(() {
      sets[index].records = achievements.map((a) => a.type).toSet();
    });

    // Show celebration notification
    if (mounted) {
      showRecordNotification(
        context,
        achievements: achievements,
        exerciseName: exerciseName,
      );
    }
  }
}
```

**5. Record Queries**:

Other utility functions in `records_service.dart`:

- `getSetRecords()`: Check if a specific set holds any records
- `getWorkoutRecords()`: Get all record-holding sets in a workout
- `workoutHasRecords()`: Boolean check if workout contains any PRs
- `getWorkoutRecordCount()`: Count of record-breaking sets in a workout
- `getBatchWorkoutRecordCounts()`: Efficient batch query for multiple workouts

All queries exclude hidden sets (`hidden = 0`) and use SQL MAX aggregations for performance.

### Brzycki Formula Implementation

The 1RM calculation handles both standard weights and bodyweight assistance:

```dart
double calculate1RM(double weight, double reps) {
  if (reps <= 0) return 0;
  if (reps == 1) return weight;
  if (weight >= 0) {
    return weight / (1.0278 - 0.0278 * reps);  // Standard weights
  } else {
    return weight * (1.0278 - 0.0278 * reps);  // Bodyweight assistance
  }
}
```

### Important Notes

- PRs are checked **only** for non-warmup, non-cardio sets with weight > 0 and reps > 0
- Records are tracked per exercise name (case-sensitive)
- The `excludeSetId` parameter prevents comparing a set against itself when editing
- Multiple records can be broken in a single set (e.g., both best weight and best 1RM)
- Record badges are stored in the set's local state for immediate UI updates
- The notification dialog uses `useRootNavigator: true` to appear above overlays

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

When adding new columns or tables, you'll need to manually update both the schema JSON and `database.steps.dart`:

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
