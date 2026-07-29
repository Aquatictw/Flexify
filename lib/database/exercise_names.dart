/// Exercise names that were renamed after data had already been logged.
///
/// Keys are lower-cased old names. The v69 migration in `database.dart` applies
/// the same mapping to rows already in the database; this map exists so data
/// arriving later (CSV import, Hevy import) lands on the current name too.
const Map<String, String> exerciseRenames = {
  'barbell bench press': 'Bench Press',
};

/// Applies pending exercise renames so imported data joins existing history
/// instead of creating a second exercise under the old name.
String normalizeExerciseName(String name) =>
    exerciseRenames[name.trim().toLowerCase()] ?? name;
