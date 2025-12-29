# Drift Database Migrations Guide

This guide explains how to update database defaults and create migrations in this Flutter project using Drift.

## Updating Default Values for Settings

When you want to change the default values for existing settings (without changing the table structure), follow these steps:

### 1. Update Schema Defaults (`lib/database/settings.dart`)

Update the default values in the table definition:

```dart
BoolColumn get groupHistory =>
    boolean().withDefault(const Constant(true))();  // Change default here
```

**Note:** These defaults only apply when adding NEW columns. For existing columns, you need a migration.

### 2. Update Fresh Install Defaults (`lib/constants.dart`)

Update the `defaultSettings` object for new installations:

```dart
final defaultSettings = SettingsCompanion.insert(
  groupHistory: true,  // Use plain bool (no Value wrapper)
  showUnits: false,    // Use plain bool (no Value wrapper)
  showBodyWeight: const Value(false),  // Use Value wrapper for optional fields
  // ...
);
```

**Important:**
- Required fields: use plain values (e.g., `true`, `false`, `'string'`)
- Optional fields: use `Value()` wrapper (e.g., `const Value(true)`)

### 3. Create Migration for Existing Users

#### Step 1: Increment Schema Version

In `lib/database/database.dart`, increment the `schemaVersion`:

```dart
@override
int get schemaVersion => 47;  // Increment this number
```

#### Step 2: Add Migration Function

Add a new migration in the `stepByStep()` function in `lib/database/database.dart`:

```dart
from46To47: (Migrator m, schema) async {
  await schema.settings.update().write(
        const RawValuesInsertable({
          'group_history': Variable(true),
          'show_units': Variable(false),
          'show_body_weight': Variable(false),
          'rep_estimation': Variable(true),
        }),
      );
},
```

**Note:** In migrations, ALL values use `Variable()` wrapper.

#### Step 3: Create Schema Files

You need to create schema definition files for the new version:

1. **Copy JSON schema file:**
   ```bash
   cp drift_schemas/db/drift_schema_v46.json drift_schemas/db/drift_schema_v47.json
   ```

2. **Copy Dart test schema file:**
   ```bash
   cp test/drift/db/generated/schema_v46.dart test/drift/db/generated/schema_v47.dart
   ```

3. **Update class name in test schema:**
   ```bash
   sed -i 's/Schema46/Schema47/g' test/drift/db/generated/schema_v47.dart
   ```

#### Step 4: Regenerate Code

Run build_runner to generate updated code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Step 5: Manually Update database.steps.dart (If Needed)

If build_runner doesn't generate the migration parameter, manually add it:

1. Add Schema47 class (copy from Schema46, update version number)
2. Add `from46To47` parameter to `migrationSteps()` function
3. Add `from46To47` parameter to `stepByStep()` function
4. Add case 46 to the switch statement in `migrationSteps()`
5. Add `from46To47: from46To47` to the migrationSteps call

## Adding New Columns

When adding a new column to a table:

### 1. Add Column to Table Definition

In `lib/database/settings.dart`:

```dart
BoolColumn get newFeature =>
    boolean().withDefault(const Constant(false))();
```

### 2. Update Default Settings

Add the field to `defaultSettings` in `lib/constants.dart`:

```dart
final defaultSettings = SettingsCompanion.insert(
  newFeature: const Value(false),
  // ...
);
```

### 3. Create Migration

```dart
from46To47: (Migrator m, schema) async {
  await m.addColumn(schema.settings, schema.settings.newFeature);
},
```

### 4. Follow Steps 3-5 Above

Create schema files, run build_runner, and verify generated code.

## Common Issues

### Issue: "No named parameter with the name 'fromXToY'"

**Solution:** The `database.steps.dart` file wasn't regenerated. Manually add the migration parameter or delete `.dart_tool/build` and re-run build_runner.

### Issue: Type errors with Value<T>

**Solution:**
- In `constants.dart` `SettingsCompanion.insert()`: required fields use plain values, optional fields use `Value()`
- In migrations with `RawValuesInsertable()`: ALL fields use `Variable()`
- In table schema `withDefault()`: use `const Constant(value)`

### Issue: Build runner doesn't create new schema version

**Solution:** Manually create the schema files (JSON and Dart) by copying from the previous version.

## Testing

After making changes:

1. **Test fresh install:** Clear app data and verify defaults are correct
2. **Test migration:** Keep existing data and verify migration updates values correctly
3. **Verify schema version:** Check that `schemaVersion` matches the latest migration

## File Checklist

When creating a migration, these files should be modified:

- [ ] `lib/database/settings.dart` (or relevant table file)
- [ ] `lib/constants.dart` (defaultSettings)
- [ ] `lib/database/database.dart` (migration + schema version)
- [ ] `drift_schemas/db/drift_schema_vXX.json` (new file)
- [ ] `test/drift/db/generated/schema_vXX.dart` (new file)
- [ ] `lib/database/database.steps.dart` (usually auto-generated, but may need manual updates)

## Useful Commands

```bash
# Regenerate drift code
flutter pub run build_runner build --delete-conflicting-outputs

# Clean build cache
rm -rf .dart_tool/build

# Check current schema version
grep "schemaVersion" lib/database/database.dart
```
