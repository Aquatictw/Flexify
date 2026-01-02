import 'package:drift/drift.dart';
import 'package:flexify/constants.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/graph/cardio_data.dart';
import 'package:flexify/graph/strength_data.dart';
import 'package:flexify/main.dart';

const inclineAdjustedPace = CustomExpression<double>(
  "SUM(distance) * POW(1.1, AVG(incline)) / SUM(duration)",
);

const volumeCol = CustomExpression<double>("ROUND(SUM(weight * reps), 2)");

// Brzycki formula https://en.wikipedia.org/wiki/One-repetition_maximum#cite_ref-6
const ormCol = CustomExpression<double>(
  'MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END)',
);
double getCardio(TypedResult row, CardioMetric metric) {
  switch (metric) {
    case CardioMetric.pace:
      return row.read(db.gymSets.distance.sum() / db.gymSets.duration.sum()) ??
          0;
    case CardioMetric.distance:
      return row.read(db.gymSets.distance.sum())!;
    case CardioMetric.duration:
      return row.read(db.gymSets.duration.sum())!;
    case CardioMetric.incline:
      return row.read(db.gymSets.incline.avg())!;
    case CardioMetric.inclineAdjustedPace:
      return row.read(inclineAdjustedPace)!;
  }
}

Future<List<CardioData>> getCardioData({
  Period period = Period.days30,
  String name = "",
  CardioMetric metric = CardioMetric.pace,
  String target = "km",
}) async {
  Expression<String> col = getCreated(period);
  final periodStart = getPeriodStart(period);

  var query = db.selectOnly(db.gymSets)
    ..addColumns([
      db.gymSets.duration.sum(),
      db.gymSets.distance.sum(),
      db.gymSets.distance.sum() / db.gymSets.duration.sum(),
      db.gymSets.incline.avg(),
      inclineAdjustedPace,
      db.gymSets.created,
      db.gymSets.unit,
    ])
    ..where(db.gymSets.name.equals(name))
    ..where(db.gymSets.hidden.equals(false))
    ..orderBy([
      OrderingTerm(
        expression: col,
        mode: OrderingMode.desc,
      ),
    ])
    ..groupBy([col]);

  if (periodStart != null) {
    query = query
      ..where(
        db.gymSets.created.isBiggerOrEqualValue(periodStart),
      );
  }

  final results = await query.get();

  List<CardioData> list = [];

  for (final result in results.reversed) {
    var value = getCardio(result, metric);
    final unit = result.read(db.gymSets.unit)!;

    if (unit == 'km' && target == 'mi') {
      value /= 1.609;
    } else if (unit == 'mi' && target == 'km') {
      value *= 1.609;
    } else if (unit == 'm' && target == 'km') {
      value /= 1000;
    } else if (unit == 'km' && target == 'm') {
      value *= 1000;
    } else if (unit == 'm' && target == 'mi') {
      value /= 1609.34;
    } else if (unit == 'mi' && target == 'm') {
      value *= 1609.34;
    }

    list.add(
      CardioData(
        created: result.read(db.gymSets.created)!.toLocal(),
        value: double.parse(value.toStringAsFixed(2)),
        unit: target,
      ),
    );
  }

  return list;
}

Expression<String> getCreated(Period groupBy) {
  // For all new period types, group by day to show individual data points
  return const CustomExpression<String>(
    "STRFTIME('%Y-%m-%d', DATE(created, 'unixepoch', 'localtime'))",
  );
}

DateTime? getPeriodStart(Period period) {
  final now = DateTime.now();
  switch (period) {
    case Period.days30:
      return now.subtract(const Duration(days: 30));
    case Period.months3:
      return DateTime(now.year, now.month - 3, now.day);
    case Period.months6:
      return DateTime(now.year, now.month - 6, now.day);
    case Period.year:
      return DateTime(now.year - 1, now.month, now.day);
    case Period.allTime:
      return null;
  }
}

Future<List<Rpm>> getRpms() async {
  final results = await db.customSelect("""
    WITH time_diffs AS (
      SELECT
        name,
        reps,
        ((created - LAG(created) OVER (PARTITION BY name ORDER BY created)) / 60.0) as time_diff,
        weight
      FROM gym_sets
      WHERE created >= strftime('%s', 'now') - 60*60*24*30
        AND cardio = false
    ),
    reps_per_min AS (
      SELECT
        name,
        (reps / time_diff) as rpm,
        weight
      FROM time_diffs
      WHERE time_diff IS NOT NULL
        AND time_diff <= 5
    )
    SELECT
      name,
      AVG(rpm) as rpm,
      weight
    FROM reps_per_min
    WHERE rpm IS NOT NULL
      AND rpm BETWEEN 0.1 AND 10
    GROUP BY name, weight;
  """).get();
  return results
      .map(
        (result) => (
          name: result.read<String>('name'),
          rpm: result.read<double>('rpm'),
          weight: result.read<double>('weight')
        ),
      )
      .toList();
}

// Typedef for graph list items with workout count
typedef GraphExercise = ({
  String name,
  String unit,
  double weight,
  double reps,
  bool cardio,
  double duration,
  double distance,
  DateTime created,
  String? image,
  String? category,
  String? exerciseType,
  String? brandName,
  int setCount,
  int workoutCount,
});

Stream<List<GraphExercise>> watchGraphs({bool showHidden = false}) {
  final setCountCol = db.gymSets.name.count();
  final workoutCountCol = const CustomExpression<int>(
    'COUNT(DISTINCT workout_id)',
  );

  var query = db.gymSets.selectOnly()
        ..addColumns([
          db.gymSets.name,
          db.gymSets.unit,
          db.gymSets.weight,
          db.gymSets.reps,
          db.gymSets.cardio,
          db.gymSets.duration,
          db.gymSets.distance,
          db.gymSets.created.max(),
          db.gymSets.image,
          db.gymSets.category,
          db.gymSets.exerciseType,
          db.gymSets.brandName,
          setCountCol,
          workoutCountCol,
        ])
        ..orderBy([
          OrderingTerm(
            expression: workoutCountCol,
            mode: OrderingMode.desc,
          ),
        ])
        ..groupBy([db.gymSets.name]);

  if (!showHidden) {
    query = query..where(db.gymSets.hidden.equals(false));
  }

  return query
      .watch()
      .map(
        (results) => results
            .map(
              (result) => (
                name: result.read(db.gymSets.name)!,
                weight: result.read(db.gymSets.weight)!,
                unit: result.read(db.gymSets.unit)!,
                reps: result.read(db.gymSets.reps)!,
                cardio: result.read(db.gymSets.cardio)!,
                duration: result.read(db.gymSets.duration)!,
                distance: result.read(db.gymSets.distance)!,
                created: result.read(db.gymSets.created.max())!,
                image: result.read(db.gymSets.image),
                category: result.read(db.gymSets.category),
                exerciseType: result.read(db.gymSets.exerciseType),
                brandName: result.read(db.gymSets.brandName),
                setCount: result.read(setCountCol)!,
                workoutCount: result.read(workoutCountCol)!,
              ),
            )
            .toList(),
      );
}

const bestVolumeCol = CustomExpression<double>('MAX(weight * reps)');

double getStrength(TypedResult row, StrengthMetric metric) {
  switch (metric) {
    case StrengthMetric.oneRepMax:
      return row.read(ormCol)!;
    case StrengthMetric.volume:
      return row.read(volumeCol)!;
    case StrengthMetric.bestWeight:
      return row.read(db.gymSets.weight.max())!;
    case StrengthMetric.bestVolume:
      return row.read(bestVolumeCol) ?? 0;
  }
}

Future<List<StrengthData>> getStrengthData({
  required String target,
  required String name,
  required StrengthMetric metric,
  required Period period,
}) async {
  final periodStart = getPeriodStart(period);

  // Build the metric-specific SQL expression and ordering
  String metricExpression;
  String orderColumn;
  switch (metric) {
    case StrengthMetric.bestWeight:
      metricExpression = 'weight';
      orderColumn = 'weight';
      break;
    case StrengthMetric.oneRepMax:
      metricExpression = 'CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END';
      orderColumn = metricExpression;
      break;
    case StrengthMetric.volume:
      metricExpression = 'weight * reps';
      orderColumn = metricExpression;
      break;
    case StrengthMetric.bestVolume:
      metricExpression = 'weight * reps';
      orderColumn = metricExpression;
      break;
  }

  // Use a custom SQL query to get the best set for each day along with its workout_id
  final whereClause = periodStart != null
      ? 'AND created >= ${periodStart.millisecondsSinceEpoch ~/ 1000}'
      : '';

  final sql = '''
    SELECT
      created,
      weight,
      reps,
      unit,
      workout_id,
      $metricExpression as metric_value
    FROM gym_sets
    WHERE name = ?
      AND hidden = 0
      $whereClause
    GROUP BY STRFTIME('%Y-%m-%d', DATE(created, 'unixepoch', 'localtime'))
    HAVING $metricExpression = MAX($orderColumn)
    ORDER BY created DESC
  ''';

  final results = await db.customSelect(
    sql,
    variables: [Variable.withString(name)],
  ).get();

  List<StrengthData> list = [];
  for (final result in results.reversed) {
    final unit = result.read<String>('unit');
    var value = result.read<double>('metric_value');
    var weight = result.read<double>('weight');

    if (unit == 'lb' && target == 'kg') {
      value *= 0.45359237;
      weight *= 0.45359237;
    } else if (unit == 'kg' && target == 'lb') {
      value *= 2.20462262;
      weight *= 2.20462262;
    }

    final reps = result.read<double>('reps');
    final created = DateTime.fromMillisecondsSinceEpoch(
      result.read<int>('created') * 1000,
    ).toLocal();
    final workoutId = result.read<int?>('workout_id');

    list.add(
      StrengthData(
        created: created,
        value: value,
        unit: unit,
        reps: reps,
        workoutId: workoutId,
        weight: weight,
      ),
    );
  }

  return list;
}

Future<List<String?>> getCategories() {
  return (db.selectOnly(db.gymSets)
        ..addColumns([db.gymSets.category])
        ..where(db.gymSets.category.isNotNull())
        ..groupBy([db.gymSets.category]))
      .map((result) => result.read(db.gymSets.category))
      .get();
}

Future<List<StrengthData>> getGlobalData({
  required String target,
  required StrengthMetric metric,
  required Period period,
}) async {
  final periodStart = getPeriodStart(period);

  // Build the metric-specific SQL expression and ordering
  String metricExpression;
  String orderColumn;
  switch (metric) {
    case StrengthMetric.bestWeight:
      metricExpression = 'weight';
      orderColumn = 'weight';
      break;
    case StrengthMetric.oneRepMax:
      metricExpression = 'CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END';
      orderColumn = metricExpression;
      break;
    case StrengthMetric.volume:
      metricExpression = 'weight * reps';
      orderColumn = metricExpression;
      break;
    case StrengthMetric.bestVolume:
      metricExpression = 'weight * reps';
      orderColumn = metricExpression;
      break;
  }

  final whereClause = periodStart != null
      ? 'AND created >= ${periodStart.millisecondsSinceEpoch ~/ 1000}'
      : '';

  final sql = '''
    SELECT
      created,
      weight,
      reps,
      unit,
      category,
      workout_id,
      $metricExpression as metric_value
    FROM gym_sets
    WHERE hidden = 0
      AND category IS NOT NULL
      $whereClause
    GROUP BY category, STRFTIME('%Y-%m-%d', DATE(created, 'unixepoch', 'localtime'))
    HAVING $metricExpression = MAX($orderColumn)
    ORDER BY created DESC
  ''';

  final results = await db.customSelect(sql).get();

  List<StrengthData> list = [];
  for (final result in results.reversed) {
    final unit = result.read<String>('unit');
    var value = result.read<double>('metric_value');
    var weight = result.read<double>('weight');

    if (unit == 'lb' && target == 'kg') {
      value *= 0.45359237;
      weight *= 0.45359237;
    } else if (unit == 'kg' && target == 'lb') {
      value *= 2.20462262;
      weight *= 2.20462262;
    }

    final reps = result.read<double>('reps');
    final created = DateTime.fromMillisecondsSinceEpoch(
      result.read<int>('created') * 1000,
    ).toLocal();
    final category = result.read<String?>('category');
    final workoutId = result.read<int?>('workout_id');

    list.add(
      StrengthData(
        created: created,
        value: value,
        unit: unit,
        reps: reps,
        category: category,
        workoutId: workoutId,
        weight: weight,
      ),
    );
  }

  return list;
}

Future<bool> isBest(GymSet gymSet) async {
  if (gymSet.cardio) {
    final best = await (db.gymSets.select()
          ..addColumns([db.gymSets.distance.sum() / db.gymSets.duration.sum()])
          ..orderBy([
            (u) => OrderingTerm(
                  expression: u.weight,
                  mode: OrderingMode.desc,
                ),
            (u) => OrderingTerm(
                  expression: u.reps,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (best == null) return false;
    return gymSet.distance / gymSet.duration > best.distance / best.duration;
  } else {
    final result = await (db.gymSets.selectOnly()
          ..addColumns(
            [db.gymSets.weight, db.gymSets.reps],
          )
          ..where(db.gymSets.id.isNotValue(gymSet.id))
          ..orderBy([
            OrderingTerm(
              expression: db.gymSets.weight,
              mode: OrderingMode.desc,
            ),
            OrderingTerm(
              expression: db.gymSets.reps,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (result == null) return false;
    final weight = result.read(db.gymSets.weight)!;
    final reps = result.read(db.gymSets.reps)!;

    if (gymSet.weight > weight) return true;
    if (gymSet.weight == weight && gymSet.reps > reps) return true;
    return false;
  }
}

typedef Rpm = ({String name, double rpm, double weight});

/// Rep record: best weight achieved at a specific rep count
typedef RepRecord = ({int reps, double weight, DateTime created, int? workoutId});

/// Get best weight for each rep count (1-15) for a specific exercise
Future<List<RepRecord>> getRepRecords({
  required String name,
  required String targetUnit,
}) async {
  final results = await db.customSelect("""
    SELECT
      CAST(reps AS INTEGER) as rep_count,
      MAX(weight) as max_weight,
      created,
      unit,
      workout_id
    FROM gym_sets
    WHERE name = ?
      AND hidden = 0
      AND reps BETWEEN 1 AND 15
      AND reps = CAST(reps AS INTEGER)
    GROUP BY CAST(reps AS INTEGER)
    ORDER BY rep_count ASC
  """, variables: [Variable.withString(name)]).get();

  List<RepRecord> records = [];
  for (final row in results) {
    final reps = row.read<int>('rep_count');
    var weight = row.read<double>('max_weight');
    final unit = row.read<String>('unit');
    final created = DateTime.fromMillisecondsSinceEpoch(
      row.read<int>('created') * 1000,
    );
    final workoutId = row.read<int?>('workout_id');

    // Convert units if needed
    if (unit == 'lb' && targetUnit == 'kg') {
      weight *= 0.45359237;
    } else if (unit == 'kg' && targetUnit == 'lb') {
      weight *= 2.20462262;
    }

    records.add((reps: reps, weight: weight, created: created, workoutId: workoutId));
  }

  return records;
}

/// All-time records for an exercise
typedef ExerciseRecords = ({
  double bestWeight,
  double best1RM,
  double bestVolume,
  DateTime? bestWeightDate,
  DateTime? best1RMDate,
  DateTime? bestVolumeDate,
  int? bestWeightWorkoutId,
  int? best1RMWorkoutId,
  int? bestVolumeWorkoutId,
  double? bestWeightReps,
  double? best1RMReps,
  double? best1RMWeight,
  double? bestVolumeReps,
  double? bestVolumeWeight,
});

/// Get all-time records for a specific exercise
Future<ExerciseRecords> getExerciseRecords({
  required String name,
  required String targetUnit,
}) async {
  final result = await db.customSelect("""
    SELECT
      MAX(weight) as best_weight,
      MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END) as best_1rm,
      MAX(weight * reps) as best_volume
    FROM gym_sets
    WHERE name = ? AND hidden = 0
  """, variables: [Variable.withString(name)]).getSingleOrNull();

  if (result == null) {
    return (
      bestWeight: 0.0,
      best1RM: 0.0,
      bestVolume: 0.0,
      bestWeightDate: null,
      best1RMDate: null,
      bestVolumeDate: null,
      bestWeightWorkoutId: null,
      best1RMWorkoutId: null,
      bestVolumeWorkoutId: null,
      bestWeightReps: null,
      best1RMReps: null,
      best1RMWeight: null,
      bestVolumeReps: null,
      bestVolumeWeight: null,
    );
  }

  var bestWeight = result.read<double?>('best_weight') ?? 0.0;
  var best1RM = result.read<double?>('best_1rm') ?? 0.0;
  var bestVolume = result.read<double?>('best_volume') ?? 0.0;

  // Get dates, workout IDs, and set details for each record
  final weightDate = await db.customSelect("""
    SELECT created, workout_id, reps FROM gym_sets
    WHERE name = ? AND hidden = 0 AND weight = (SELECT MAX(weight) FROM gym_sets WHERE name = ? AND hidden = 0)
    LIMIT 1
  """, variables: [Variable.withString(name), Variable.withString(name)]).getSingleOrNull();

  final ormDate = await db.customSelect("""
    SELECT created, workout_id, reps, weight FROM gym_sets
    WHERE name = ? AND hidden = 0
    ORDER BY CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END DESC
    LIMIT 1
  """, variables: [Variable.withString(name)]).getSingleOrNull();

  final volumeDate = await db.customSelect("""
    SELECT created, workout_id, reps, weight FROM gym_sets
    WHERE name = ? AND hidden = 0
    ORDER BY weight * reps DESC
    LIMIT 1
  """, variables: [Variable.withString(name)]).getSingleOrNull();

  return (
    bestWeight: bestWeight,
    best1RM: best1RM,
    bestVolume: bestVolume,
    bestWeightDate: weightDate != null
        ? DateTime.fromMillisecondsSinceEpoch(weightDate.read<int>('created') * 1000)
        : null,
    best1RMDate: ormDate != null
        ? DateTime.fromMillisecondsSinceEpoch(ormDate.read<int>('created') * 1000)
        : null,
    bestVolumeDate: volumeDate != null
        ? DateTime.fromMillisecondsSinceEpoch(volumeDate.read<int>('created') * 1000)
        : null,
    bestWeightWorkoutId: weightDate?.read<int?>('workout_id'),
    best1RMWorkoutId: ormDate?.read<int?>('workout_id'),
    bestVolumeWorkoutId: volumeDate?.read<int?>('workout_id'),
    bestWeightReps: weightDate?.read<double?>('reps'),
    best1RMReps: ormDate?.read<double?>('reps'),
    best1RMWeight: ormDate?.read<double?>('weight'),
    bestVolumeReps: volumeDate?.read<double?>('reps'),
    bestVolumeWeight: volumeDate?.read<double?>('weight'),
  );
}

class GymSets extends Table {
  RealColumn get bodyWeight => real().withDefault(const Constant(0.0))();
  BoolColumn get cardio => boolean().withDefault(const Constant(false))();
  TextColumn get category => text().nullable()();
  DateTimeColumn get created => dateTime()();
  RealColumn get distance => real().withDefault(const Constant(0.0))();
  RealColumn get duration => real().withDefault(const Constant(0.0))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get image => text().nullable()();
  IntColumn get incline => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get planId => integer().nullable()();
  RealColumn get reps => real()();
  IntColumn get restMs => integer().nullable()();
  IntColumn get sequence => integer().withDefault(const Constant(0))(); // Exercise order within workout
  TextColumn get unit => text()();
  BoolColumn get warmup => boolean().withDefault(const Constant(false))();
  RealColumn get weight => real()();
  IntColumn get workoutId => integer().nullable()();
  TextColumn get exerciseType => text().nullable()(); // free weight, machine, cable
  TextColumn get brandName => text().nullable()(); // brand for machine
}

final categoriesStream = (db.gymSets.selectOnly(distinct: true)
      ..addColumns([db.gymSets.category])
      ..where(db.gymSets.category.isNotNull()))
    .watch()
    .map(
      (results) =>
          results.map((result) => result.read(db.gymSets.category) ?? ""),
    );
