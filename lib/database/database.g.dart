// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PlansTable extends Plans with TableInfo<$PlansTable, Plan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<String> days = GeneratedColumn<String>(
      'days', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sequenceMeta =
      const VerificationMeta('sequence');
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [days, id, sequence, title];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(Insertable<Plan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('days')) {
      context.handle(
          _daysMeta, days.isAcceptableOrUnknown(data['days']!, _daysMeta));
    } else if (isInserting) {
      context.missing(_daysMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sequence')) {
      context.handle(_sequenceMeta,
          sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plan(
      days: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}days'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class Plan extends DataClass implements Insertable<Plan> {
  final String days;
  final int id;
  final int? sequence;
  final String? title;
  const Plan({required this.days, required this.id, this.sequence, this.title});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['days'] = Variable<String>(days);
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sequence != null) {
      map['sequence'] = Variable<int>(sequence);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      days: Value(days),
      id: Value(id),
      sequence: sequence == null && nullToAbsent
          ? const Value.absent()
          : Value(sequence),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
    );
  }

  factory Plan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plan(
      days: serializer.fromJson<String>(json['days']),
      id: serializer.fromJson<int>(json['id']),
      sequence: serializer.fromJson<int?>(json['sequence']),
      title: serializer.fromJson<String?>(json['title']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'days': serializer.toJson<String>(days),
      'id': serializer.toJson<int>(id),
      'sequence': serializer.toJson<int?>(sequence),
      'title': serializer.toJson<String?>(title),
    };
  }

  Plan copyWith(
          {String? days,
          int? id,
          Value<int?> sequence = const Value.absent(),
          Value<String?> title = const Value.absent()}) =>
      Plan(
        days: days ?? this.days,
        id: id ?? this.id,
        sequence: sequence.present ? sequence.value : this.sequence,
        title: title.present ? title.value : this.title,
      );
  Plan copyWithCompanion(PlansCompanion data) {
    return Plan(
      days: data.days.present ? data.days.value : this.days,
      id: data.id.present ? data.id.value : this.id,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      title: data.title.present ? data.title.value : this.title,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plan(')
          ..write('days: $days, ')
          ..write('id: $id, ')
          ..write('sequence: $sequence, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(days, id, sequence, title);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plan &&
          other.days == this.days &&
          other.id == this.id &&
          other.sequence == this.sequence &&
          other.title == this.title);
}

class PlansCompanion extends UpdateCompanion<Plan> {
  final Value<String> days;
  final Value<int> id;
  final Value<int?> sequence;
  final Value<String?> title;
  const PlansCompanion({
    this.days = const Value.absent(),
    this.id = const Value.absent(),
    this.sequence = const Value.absent(),
    this.title = const Value.absent(),
  });
  PlansCompanion.insert({
    required String days,
    this.id = const Value.absent(),
    this.sequence = const Value.absent(),
    this.title = const Value.absent(),
  }) : days = Value(days);
  static Insertable<Plan> custom({
    Expression<String>? days,
    Expression<int>? id,
    Expression<int>? sequence,
    Expression<String>? title,
  }) {
    return RawValuesInsertable({
      if (days != null) 'days': days,
      if (id != null) 'id': id,
      if (sequence != null) 'sequence': sequence,
      if (title != null) 'title': title,
    });
  }

  PlansCompanion copyWith(
      {Value<String>? days,
      Value<int>? id,
      Value<int?>? sequence,
      Value<String?>? title}) {
    return PlansCompanion(
      days: days ?? this.days,
      id: id ?? this.id,
      sequence: sequence ?? this.sequence,
      title: title ?? this.title,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (days.present) {
      map['days'] = Variable<String>(days.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('days: $days, ')
          ..write('id: $id, ')
          ..write('sequence: $sequence, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }
}

class $GymSetsTable extends GymSets with TableInfo<$GymSetsTable, GymSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GymSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardioMeta = const VerificationMeta('cardio');
  @override
  late final GeneratedColumn<bool> cardio = GeneratedColumn<bool>(
      'cardio', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("cardio" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdMeta =
      const VerificationMeta('created');
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
      'created', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _distanceMeta =
      const VerificationMeta('distance');
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
      'distance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<double> duration = GeneratedColumn<double>(
      'duration', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
      'hidden', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("hidden" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
      'image', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _inclineMeta =
      const VerificationMeta('incline');
  @override
  late final GeneratedColumn<int> incline = GeneratedColumn<int>(
      'incline', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
      'plan_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<double> reps = GeneratedColumn<double>(
      'reps', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _restMsMeta = const VerificationMeta('restMs');
  @override
  late final GeneratedColumn<int> restMs = GeneratedColumn<int>(
      'rest_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sequenceMeta =
      const VerificationMeta('sequence');
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _warmupMeta = const VerificationMeta('warmup');
  @override
  late final GeneratedColumn<bool> warmup = GeneratedColumn<bool>(
      'warmup', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("warmup" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _workoutIdMeta =
      const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
      'workout_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _exerciseTypeMeta =
      const VerificationMeta('exerciseType');
  @override
  late final GeneratedColumn<String> exerciseType = GeneratedColumn<String>(
      'exercise_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _brandNameMeta =
      const VerificationMeta('brandName');
  @override
  late final GeneratedColumn<String> brandName = GeneratedColumn<String>(
      'brand_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cardioMetricMeta =
      const VerificationMeta('cardioMetric');
  @override
  late final GeneratedColumn<String> cardioMetric = GeneratedColumn<String>(
      'cardio_metric', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dropSetMeta =
      const VerificationMeta('dropSet');
  @override
  late final GeneratedColumn<bool> dropSet = GeneratedColumn<bool>(
      'drop_set', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("drop_set" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _supersetIdMeta =
      const VerificationMeta('supersetId');
  @override
  late final GeneratedColumn<String> supersetId = GeneratedColumn<String>(
      'superset_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supersetPositionMeta =
      const VerificationMeta('supersetPosition');
  @override
  late final GeneratedColumn<int> supersetPosition = GeneratedColumn<int>(
      'superset_position', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _setOrderMeta =
      const VerificationMeta('setOrder');
  @override
  late final GeneratedColumn<int> setOrder = GeneratedColumn<int>(
      'set_order', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        cardio,
        category,
        created,
        distance,
        duration,
        hidden,
        id,
        image,
        incline,
        name,
        notes,
        planId,
        reps,
        restMs,
        sequence,
        unit,
        warmup,
        weight,
        workoutId,
        exerciseType,
        brandName,
        cardioMetric,
        dropSet,
        supersetId,
        supersetPosition,
        setOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gym_sets';
  @override
  VerificationContext validateIntegrity(Insertable<GymSet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cardio')) {
      context.handle(_cardioMeta,
          cardio.isAcceptableOrUnknown(data['cardio']!, _cardioMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('created')) {
      context.handle(_createdMeta,
          created.isAcceptableOrUnknown(data['created']!, _createdMeta));
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('distance')) {
      context.handle(_distanceMeta,
          distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('hidden')) {
      context.handle(_hiddenMeta,
          hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('image')) {
      context.handle(
          _imageMeta, image.isAcceptableOrUnknown(data['image']!, _imageMeta));
    }
    if (data.containsKey('incline')) {
      context.handle(_inclineMeta,
          incline.isAcceptableOrUnknown(data['incline']!, _inclineMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('rest_ms')) {
      context.handle(_restMsMeta,
          restMs.isAcceptableOrUnknown(data['rest_ms']!, _restMsMeta));
    }
    if (data.containsKey('sequence')) {
      context.handle(_sequenceMeta,
          sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('warmup')) {
      context.handle(_warmupMeta,
          warmup.isAcceptableOrUnknown(data['warmup']!, _warmupMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta,
          workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    }
    if (data.containsKey('exercise_type')) {
      context.handle(
          _exerciseTypeMeta,
          exerciseType.isAcceptableOrUnknown(
              data['exercise_type']!, _exerciseTypeMeta));
    }
    if (data.containsKey('brand_name')) {
      context.handle(_brandNameMeta,
          brandName.isAcceptableOrUnknown(data['brand_name']!, _brandNameMeta));
    }
    if (data.containsKey('cardio_metric')) {
      context.handle(
          _cardioMetricMeta,
          cardioMetric.isAcceptableOrUnknown(
              data['cardio_metric']!, _cardioMetricMeta));
    }
    if (data.containsKey('drop_set')) {
      context.handle(_dropSetMeta,
          dropSet.isAcceptableOrUnknown(data['drop_set']!, _dropSetMeta));
    }
    if (data.containsKey('superset_id')) {
      context.handle(
          _supersetIdMeta,
          supersetId.isAcceptableOrUnknown(
              data['superset_id']!, _supersetIdMeta));
    }
    if (data.containsKey('superset_position')) {
      context.handle(
          _supersetPositionMeta,
          supersetPosition.isAcceptableOrUnknown(
              data['superset_position']!, _supersetPositionMeta));
    }
    if (data.containsKey('set_order')) {
      context.handle(_setOrderMeta,
          setOrder.isAcceptableOrUnknown(data['set_order']!, _setOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GymSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GymSet(
      cardio: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}cardio'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      created: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created'])!,
      distance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}duration'])!,
      hidden: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}hidden'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      image: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image']),
      incline: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}incline']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plan_id']),
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reps'])!,
      restMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rest_ms']),
      sequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      warmup: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}warmup'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      workoutId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}workout_id']),
      exerciseType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_type']),
      brandName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}brand_name']),
      cardioMetric: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cardio_metric']),
      dropSet: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}drop_set'])!,
      supersetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}superset_id']),
      supersetPosition: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}superset_position']),
      setOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}set_order']),
    );
  }

  @override
  $GymSetsTable createAlias(String alias) {
    return $GymSetsTable(attachedDatabase, alias);
  }
}

class GymSet extends DataClass implements Insertable<GymSet> {
  final bool cardio;
  final String? category;
  final DateTime created;
  final double distance;
  final double duration;
  final bool hidden;
  final int id;
  final String? image;
  final int? incline;
  final String name;
  final String? notes;
  final int? planId;
  final double reps;
  final int? restMs;
  final int sequence;
  final String unit;
  final bool warmup;
  final double weight;
  final int? workoutId;
  final String? exerciseType;
  final String? brandName;
  final String? cardioMetric;
  final bool dropSet;
  final String? supersetId;
  final int? supersetPosition;
  final int? setOrder;
  const GymSet(
      {required this.cardio,
      this.category,
      required this.created,
      required this.distance,
      required this.duration,
      required this.hidden,
      required this.id,
      this.image,
      this.incline,
      required this.name,
      this.notes,
      this.planId,
      required this.reps,
      this.restMs,
      required this.sequence,
      required this.unit,
      required this.warmup,
      required this.weight,
      this.workoutId,
      this.exerciseType,
      this.brandName,
      this.cardioMetric,
      required this.dropSet,
      this.supersetId,
      this.supersetPosition,
      this.setOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cardio'] = Variable<bool>(cardio);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['created'] = Variable<DateTime>(created);
    map['distance'] = Variable<double>(distance);
    map['duration'] = Variable<double>(duration);
    map['hidden'] = Variable<bool>(hidden);
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || image != null) {
      map['image'] = Variable<String>(image);
    }
    if (!nullToAbsent || incline != null) {
      map['incline'] = Variable<int>(incline);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<int>(planId);
    }
    map['reps'] = Variable<double>(reps);
    if (!nullToAbsent || restMs != null) {
      map['rest_ms'] = Variable<int>(restMs);
    }
    map['sequence'] = Variable<int>(sequence);
    map['unit'] = Variable<String>(unit);
    map['warmup'] = Variable<bool>(warmup);
    map['weight'] = Variable<double>(weight);
    if (!nullToAbsent || workoutId != null) {
      map['workout_id'] = Variable<int>(workoutId);
    }
    if (!nullToAbsent || exerciseType != null) {
      map['exercise_type'] = Variable<String>(exerciseType);
    }
    if (!nullToAbsent || brandName != null) {
      map['brand_name'] = Variable<String>(brandName);
    }
    if (!nullToAbsent || cardioMetric != null) {
      map['cardio_metric'] = Variable<String>(cardioMetric);
    }
    map['drop_set'] = Variable<bool>(dropSet);
    if (!nullToAbsent || supersetId != null) {
      map['superset_id'] = Variable<String>(supersetId);
    }
    if (!nullToAbsent || supersetPosition != null) {
      map['superset_position'] = Variable<int>(supersetPosition);
    }
    if (!nullToAbsent || setOrder != null) {
      map['set_order'] = Variable<int>(setOrder);
    }
    return map;
  }

  GymSetsCompanion toCompanion(bool nullToAbsent) {
    return GymSetsCompanion(
      cardio: Value(cardio),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      created: Value(created),
      distance: Value(distance),
      duration: Value(duration),
      hidden: Value(hidden),
      id: Value(id),
      image:
          image == null && nullToAbsent ? const Value.absent() : Value(image),
      incline: incline == null && nullToAbsent
          ? const Value.absent()
          : Value(incline),
      name: Value(name),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      planId:
          planId == null && nullToAbsent ? const Value.absent() : Value(planId),
      reps: Value(reps),
      restMs:
          restMs == null && nullToAbsent ? const Value.absent() : Value(restMs),
      sequence: Value(sequence),
      unit: Value(unit),
      warmup: Value(warmup),
      weight: Value(weight),
      workoutId: workoutId == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutId),
      exerciseType: exerciseType == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseType),
      brandName: brandName == null && nullToAbsent
          ? const Value.absent()
          : Value(brandName),
      cardioMetric: cardioMetric == null && nullToAbsent
          ? const Value.absent()
          : Value(cardioMetric),
      dropSet: Value(dropSet),
      supersetId: supersetId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetId),
      supersetPosition: supersetPosition == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetPosition),
      setOrder: setOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(setOrder),
    );
  }

  factory GymSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GymSet(
      cardio: serializer.fromJson<bool>(json['cardio']),
      category: serializer.fromJson<String?>(json['category']),
      created: serializer.fromJson<DateTime>(json['created']),
      distance: serializer.fromJson<double>(json['distance']),
      duration: serializer.fromJson<double>(json['duration']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      id: serializer.fromJson<int>(json['id']),
      image: serializer.fromJson<String?>(json['image']),
      incline: serializer.fromJson<int?>(json['incline']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      planId: serializer.fromJson<int?>(json['planId']),
      reps: serializer.fromJson<double>(json['reps']),
      restMs: serializer.fromJson<int?>(json['restMs']),
      sequence: serializer.fromJson<int>(json['sequence']),
      unit: serializer.fromJson<String>(json['unit']),
      warmup: serializer.fromJson<bool>(json['warmup']),
      weight: serializer.fromJson<double>(json['weight']),
      workoutId: serializer.fromJson<int?>(json['workoutId']),
      exerciseType: serializer.fromJson<String?>(json['exerciseType']),
      brandName: serializer.fromJson<String?>(json['brandName']),
      cardioMetric: serializer.fromJson<String?>(json['cardioMetric']),
      dropSet: serializer.fromJson<bool>(json['dropSet']),
      supersetId: serializer.fromJson<String?>(json['supersetId']),
      supersetPosition: serializer.fromJson<int?>(json['supersetPosition']),
      setOrder: serializer.fromJson<int?>(json['setOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardio': serializer.toJson<bool>(cardio),
      'category': serializer.toJson<String?>(category),
      'created': serializer.toJson<DateTime>(created),
      'distance': serializer.toJson<double>(distance),
      'duration': serializer.toJson<double>(duration),
      'hidden': serializer.toJson<bool>(hidden),
      'id': serializer.toJson<int>(id),
      'image': serializer.toJson<String?>(image),
      'incline': serializer.toJson<int?>(incline),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'planId': serializer.toJson<int?>(planId),
      'reps': serializer.toJson<double>(reps),
      'restMs': serializer.toJson<int?>(restMs),
      'sequence': serializer.toJson<int>(sequence),
      'unit': serializer.toJson<String>(unit),
      'warmup': serializer.toJson<bool>(warmup),
      'weight': serializer.toJson<double>(weight),
      'workoutId': serializer.toJson<int?>(workoutId),
      'exerciseType': serializer.toJson<String?>(exerciseType),
      'brandName': serializer.toJson<String?>(brandName),
      'cardioMetric': serializer.toJson<String?>(cardioMetric),
      'dropSet': serializer.toJson<bool>(dropSet),
      'supersetId': serializer.toJson<String?>(supersetId),
      'supersetPosition': serializer.toJson<int?>(supersetPosition),
      'setOrder': serializer.toJson<int?>(setOrder),
    };
  }

  GymSet copyWith(
          {bool? cardio,
          Value<String?> category = const Value.absent(),
          DateTime? created,
          double? distance,
          double? duration,
          bool? hidden,
          int? id,
          Value<String?> image = const Value.absent(),
          Value<int?> incline = const Value.absent(),
          String? name,
          Value<String?> notes = const Value.absent(),
          Value<int?> planId = const Value.absent(),
          double? reps,
          Value<int?> restMs = const Value.absent(),
          int? sequence,
          String? unit,
          bool? warmup,
          double? weight,
          Value<int?> workoutId = const Value.absent(),
          Value<String?> exerciseType = const Value.absent(),
          Value<String?> brandName = const Value.absent(),
          Value<String?> cardioMetric = const Value.absent(),
          bool? dropSet,
          Value<String?> supersetId = const Value.absent(),
          Value<int?> supersetPosition = const Value.absent(),
          Value<int?> setOrder = const Value.absent()}) =>
      GymSet(
        cardio: cardio ?? this.cardio,
        category: category.present ? category.value : this.category,
        created: created ?? this.created,
        distance: distance ?? this.distance,
        duration: duration ?? this.duration,
        hidden: hidden ?? this.hidden,
        id: id ?? this.id,
        image: image.present ? image.value : this.image,
        incline: incline.present ? incline.value : this.incline,
        name: name ?? this.name,
        notes: notes.present ? notes.value : this.notes,
        planId: planId.present ? planId.value : this.planId,
        reps: reps ?? this.reps,
        restMs: restMs.present ? restMs.value : this.restMs,
        sequence: sequence ?? this.sequence,
        unit: unit ?? this.unit,
        warmup: warmup ?? this.warmup,
        weight: weight ?? this.weight,
        workoutId: workoutId.present ? workoutId.value : this.workoutId,
        exerciseType:
            exerciseType.present ? exerciseType.value : this.exerciseType,
        brandName: brandName.present ? brandName.value : this.brandName,
        cardioMetric:
            cardioMetric.present ? cardioMetric.value : this.cardioMetric,
        dropSet: dropSet ?? this.dropSet,
        supersetId: supersetId.present ? supersetId.value : this.supersetId,
        supersetPosition: supersetPosition.present
            ? supersetPosition.value
            : this.supersetPosition,
        setOrder: setOrder.present ? setOrder.value : this.setOrder,
      );
  GymSet copyWithCompanion(GymSetsCompanion data) {
    return GymSet(
      cardio: data.cardio.present ? data.cardio.value : this.cardio,
      category: data.category.present ? data.category.value : this.category,
      created: data.created.present ? data.created.value : this.created,
      distance: data.distance.present ? data.distance.value : this.distance,
      duration: data.duration.present ? data.duration.value : this.duration,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      id: data.id.present ? data.id.value : this.id,
      image: data.image.present ? data.image.value : this.image,
      incline: data.incline.present ? data.incline.value : this.incline,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      planId: data.planId.present ? data.planId.value : this.planId,
      reps: data.reps.present ? data.reps.value : this.reps,
      restMs: data.restMs.present ? data.restMs.value : this.restMs,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      unit: data.unit.present ? data.unit.value : this.unit,
      warmup: data.warmup.present ? data.warmup.value : this.warmup,
      weight: data.weight.present ? data.weight.value : this.weight,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exerciseType: data.exerciseType.present
          ? data.exerciseType.value
          : this.exerciseType,
      brandName: data.brandName.present ? data.brandName.value : this.brandName,
      cardioMetric: data.cardioMetric.present
          ? data.cardioMetric.value
          : this.cardioMetric,
      dropSet: data.dropSet.present ? data.dropSet.value : this.dropSet,
      supersetId:
          data.supersetId.present ? data.supersetId.value : this.supersetId,
      supersetPosition: data.supersetPosition.present
          ? data.supersetPosition.value
          : this.supersetPosition,
      setOrder: data.setOrder.present ? data.setOrder.value : this.setOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GymSet(')
          ..write('cardio: $cardio, ')
          ..write('category: $category, ')
          ..write('created: $created, ')
          ..write('distance: $distance, ')
          ..write('duration: $duration, ')
          ..write('hidden: $hidden, ')
          ..write('id: $id, ')
          ..write('image: $image, ')
          ..write('incline: $incline, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('planId: $planId, ')
          ..write('reps: $reps, ')
          ..write('restMs: $restMs, ')
          ..write('sequence: $sequence, ')
          ..write('unit: $unit, ')
          ..write('warmup: $warmup, ')
          ..write('weight: $weight, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('brandName: $brandName, ')
          ..write('cardioMetric: $cardioMetric, ')
          ..write('dropSet: $dropSet, ')
          ..write('supersetId: $supersetId, ')
          ..write('supersetPosition: $supersetPosition, ')
          ..write('setOrder: $setOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        cardio,
        category,
        created,
        distance,
        duration,
        hidden,
        id,
        image,
        incline,
        name,
        notes,
        planId,
        reps,
        restMs,
        sequence,
        unit,
        warmup,
        weight,
        workoutId,
        exerciseType,
        brandName,
        cardioMetric,
        dropSet,
        supersetId,
        supersetPosition,
        setOrder
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GymSet &&
          other.cardio == this.cardio &&
          other.category == this.category &&
          other.created == this.created &&
          other.distance == this.distance &&
          other.duration == this.duration &&
          other.hidden == this.hidden &&
          other.id == this.id &&
          other.image == this.image &&
          other.incline == this.incline &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.planId == this.planId &&
          other.reps == this.reps &&
          other.restMs == this.restMs &&
          other.sequence == this.sequence &&
          other.unit == this.unit &&
          other.warmup == this.warmup &&
          other.weight == this.weight &&
          other.workoutId == this.workoutId &&
          other.exerciseType == this.exerciseType &&
          other.brandName == this.brandName &&
          other.cardioMetric == this.cardioMetric &&
          other.dropSet == this.dropSet &&
          other.supersetId == this.supersetId &&
          other.supersetPosition == this.supersetPosition &&
          other.setOrder == this.setOrder);
}

class GymSetsCompanion extends UpdateCompanion<GymSet> {
  final Value<bool> cardio;
  final Value<String?> category;
  final Value<DateTime> created;
  final Value<double> distance;
  final Value<double> duration;
  final Value<bool> hidden;
  final Value<int> id;
  final Value<String?> image;
  final Value<int?> incline;
  final Value<String> name;
  final Value<String?> notes;
  final Value<int?> planId;
  final Value<double> reps;
  final Value<int?> restMs;
  final Value<int> sequence;
  final Value<String> unit;
  final Value<bool> warmup;
  final Value<double> weight;
  final Value<int?> workoutId;
  final Value<String?> exerciseType;
  final Value<String?> brandName;
  final Value<String?> cardioMetric;
  final Value<bool> dropSet;
  final Value<String?> supersetId;
  final Value<int?> supersetPosition;
  final Value<int?> setOrder;
  const GymSetsCompanion({
    this.cardio = const Value.absent(),
    this.category = const Value.absent(),
    this.created = const Value.absent(),
    this.distance = const Value.absent(),
    this.duration = const Value.absent(),
    this.hidden = const Value.absent(),
    this.id = const Value.absent(),
    this.image = const Value.absent(),
    this.incline = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.planId = const Value.absent(),
    this.reps = const Value.absent(),
    this.restMs = const Value.absent(),
    this.sequence = const Value.absent(),
    this.unit = const Value.absent(),
    this.warmup = const Value.absent(),
    this.weight = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exerciseType = const Value.absent(),
    this.brandName = const Value.absent(),
    this.cardioMetric = const Value.absent(),
    this.dropSet = const Value.absent(),
    this.supersetId = const Value.absent(),
    this.supersetPosition = const Value.absent(),
    this.setOrder = const Value.absent(),
  });
  GymSetsCompanion.insert({
    this.cardio = const Value.absent(),
    this.category = const Value.absent(),
    required DateTime created,
    this.distance = const Value.absent(),
    this.duration = const Value.absent(),
    this.hidden = const Value.absent(),
    this.id = const Value.absent(),
    this.image = const Value.absent(),
    this.incline = const Value.absent(),
    required String name,
    this.notes = const Value.absent(),
    this.planId = const Value.absent(),
    required double reps,
    this.restMs = const Value.absent(),
    this.sequence = const Value.absent(),
    required String unit,
    this.warmup = const Value.absent(),
    required double weight,
    this.workoutId = const Value.absent(),
    this.exerciseType = const Value.absent(),
    this.brandName = const Value.absent(),
    this.cardioMetric = const Value.absent(),
    this.dropSet = const Value.absent(),
    this.supersetId = const Value.absent(),
    this.supersetPosition = const Value.absent(),
    this.setOrder = const Value.absent(),
  })  : created = Value(created),
        name = Value(name),
        reps = Value(reps),
        unit = Value(unit),
        weight = Value(weight);
  static Insertable<GymSet> custom({
    Expression<bool>? cardio,
    Expression<String>? category,
    Expression<DateTime>? created,
    Expression<double>? distance,
    Expression<double>? duration,
    Expression<bool>? hidden,
    Expression<int>? id,
    Expression<String>? image,
    Expression<int>? incline,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<int>? planId,
    Expression<double>? reps,
    Expression<int>? restMs,
    Expression<int>? sequence,
    Expression<String>? unit,
    Expression<bool>? warmup,
    Expression<double>? weight,
    Expression<int>? workoutId,
    Expression<String>? exerciseType,
    Expression<String>? brandName,
    Expression<String>? cardioMetric,
    Expression<bool>? dropSet,
    Expression<String>? supersetId,
    Expression<int>? supersetPosition,
    Expression<int>? setOrder,
  }) {
    return RawValuesInsertable({
      if (cardio != null) 'cardio': cardio,
      if (category != null) 'category': category,
      if (created != null) 'created': created,
      if (distance != null) 'distance': distance,
      if (duration != null) 'duration': duration,
      if (hidden != null) 'hidden': hidden,
      if (id != null) 'id': id,
      if (image != null) 'image': image,
      if (incline != null) 'incline': incline,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (planId != null) 'plan_id': planId,
      if (reps != null) 'reps': reps,
      if (restMs != null) 'rest_ms': restMs,
      if (sequence != null) 'sequence': sequence,
      if (unit != null) 'unit': unit,
      if (warmup != null) 'warmup': warmup,
      if (weight != null) 'weight': weight,
      if (workoutId != null) 'workout_id': workoutId,
      if (exerciseType != null) 'exercise_type': exerciseType,
      if (brandName != null) 'brand_name': brandName,
      if (cardioMetric != null) 'cardio_metric': cardioMetric,
      if (dropSet != null) 'drop_set': dropSet,
      if (supersetId != null) 'superset_id': supersetId,
      if (supersetPosition != null) 'superset_position': supersetPosition,
      if (setOrder != null) 'set_order': setOrder,
    });
  }

  GymSetsCompanion copyWith(
      {Value<bool>? cardio,
      Value<String?>? category,
      Value<DateTime>? created,
      Value<double>? distance,
      Value<double>? duration,
      Value<bool>? hidden,
      Value<int>? id,
      Value<String?>? image,
      Value<int?>? incline,
      Value<String>? name,
      Value<String?>? notes,
      Value<int?>? planId,
      Value<double>? reps,
      Value<int?>? restMs,
      Value<int>? sequence,
      Value<String>? unit,
      Value<bool>? warmup,
      Value<double>? weight,
      Value<int?>? workoutId,
      Value<String?>? exerciseType,
      Value<String?>? brandName,
      Value<String?>? cardioMetric,
      Value<bool>? dropSet,
      Value<String?>? supersetId,
      Value<int?>? supersetPosition,
      Value<int?>? setOrder}) {
    return GymSetsCompanion(
      cardio: cardio ?? this.cardio,
      category: category ?? this.category,
      created: created ?? this.created,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      hidden: hidden ?? this.hidden,
      id: id ?? this.id,
      image: image ?? this.image,
      incline: incline ?? this.incline,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      planId: planId ?? this.planId,
      reps: reps ?? this.reps,
      restMs: restMs ?? this.restMs,
      sequence: sequence ?? this.sequence,
      unit: unit ?? this.unit,
      warmup: warmup ?? this.warmup,
      weight: weight ?? this.weight,
      workoutId: workoutId ?? this.workoutId,
      exerciseType: exerciseType ?? this.exerciseType,
      brandName: brandName ?? this.brandName,
      cardioMetric: cardioMetric ?? this.cardioMetric,
      dropSet: dropSet ?? this.dropSet,
      supersetId: supersetId ?? this.supersetId,
      supersetPosition: supersetPosition ?? this.supersetPosition,
      setOrder: setOrder ?? this.setOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardio.present) {
      map['cardio'] = Variable<bool>(cardio.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (duration.present) {
      map['duration'] = Variable<double>(duration.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (incline.present) {
      map['incline'] = Variable<int>(incline.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (reps.present) {
      map['reps'] = Variable<double>(reps.value);
    }
    if (restMs.present) {
      map['rest_ms'] = Variable<int>(restMs.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (warmup.present) {
      map['warmup'] = Variable<bool>(warmup.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    if (exerciseType.present) {
      map['exercise_type'] = Variable<String>(exerciseType.value);
    }
    if (brandName.present) {
      map['brand_name'] = Variable<String>(brandName.value);
    }
    if (cardioMetric.present) {
      map['cardio_metric'] = Variable<String>(cardioMetric.value);
    }
    if (dropSet.present) {
      map['drop_set'] = Variable<bool>(dropSet.value);
    }
    if (supersetId.present) {
      map['superset_id'] = Variable<String>(supersetId.value);
    }
    if (supersetPosition.present) {
      map['superset_position'] = Variable<int>(supersetPosition.value);
    }
    if (setOrder.present) {
      map['set_order'] = Variable<int>(setOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GymSetsCompanion(')
          ..write('cardio: $cardio, ')
          ..write('category: $category, ')
          ..write('created: $created, ')
          ..write('distance: $distance, ')
          ..write('duration: $duration, ')
          ..write('hidden: $hidden, ')
          ..write('id: $id, ')
          ..write('image: $image, ')
          ..write('incline: $incline, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('planId: $planId, ')
          ..write('reps: $reps, ')
          ..write('restMs: $restMs, ')
          ..write('sequence: $sequence, ')
          ..write('unit: $unit, ')
          ..write('warmup: $warmup, ')
          ..write('weight: $weight, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('brandName: $brandName, ')
          ..write('cardioMetric: $cardioMetric, ')
          ..write('dropSet: $dropSet, ')
          ..write('supersetId: $supersetId, ')
          ..write('supersetPosition: $supersetPosition, ')
          ..write('setOrder: $setOrder')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _alarmSoundMeta =
      const VerificationMeta('alarmSound');
  @override
  late final GeneratedColumn<String> alarmSound = GeneratedColumn<String>(
      'alarm_sound', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _automaticBackupsMeta =
      const VerificationMeta('automaticBackups');
  @override
  late final GeneratedColumn<bool> automaticBackups = GeneratedColumn<bool>(
      'automatic_backups', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("automatic_backups" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _backupPathMeta =
      const VerificationMeta('backupPath');
  @override
  late final GeneratedColumn<String> backupPath = GeneratedColumn<String>(
      'backup_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cardioUnitMeta =
      const VerificationMeta('cardioUnit');
  @override
  late final GeneratedColumn<String> cardioUnit = GeneratedColumn<String>(
      'cardio_unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _curveLinesMeta =
      const VerificationMeta('curveLines');
  @override
  late final GeneratedColumn<bool> curveLines = GeneratedColumn<bool>(
      'curve_lines', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("curve_lines" IN (0, 1))'));
  static const VerificationMeta _curveSmoothnessMeta =
      const VerificationMeta('curveSmoothness');
  @override
  late final GeneratedColumn<double> curveSmoothness = GeneratedColumn<double>(
      'curve_smoothness', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _durationEstimationMeta =
      const VerificationMeta('durationEstimation');
  @override
  late final GeneratedColumn<bool> durationEstimation = GeneratedColumn<bool>(
      'duration_estimation', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("duration_estimation" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _enableSoundMeta =
      const VerificationMeta('enableSound');
  @override
  late final GeneratedColumn<bool> enableSound = GeneratedColumn<bool>(
      'enable_sound', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enable_sound" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _explainedPermissionsMeta =
      const VerificationMeta('explainedPermissions');
  @override
  late final GeneratedColumn<bool> explainedPermissions = GeneratedColumn<bool>(
      'explained_permissions', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("explained_permissions" IN (0, 1))'));
  static const VerificationMeta _groupHistoryMeta =
      const VerificationMeta('groupHistory');
  @override
  late final GeneratedColumn<bool> groupHistory = GeneratedColumn<bool>(
      'group_history', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("group_history" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _longDateFormatMeta =
      const VerificationMeta('longDateFormat');
  @override
  late final GeneratedColumn<String> longDateFormat = GeneratedColumn<String>(
      'long_date_format', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _maxSetsMeta =
      const VerificationMeta('maxSets');
  @override
  late final GeneratedColumn<int> maxSets = GeneratedColumn<int>(
      'max_sets', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _notificationsMeta =
      const VerificationMeta('notifications');
  @override
  late final GeneratedColumn<bool> notifications = GeneratedColumn<bool>(
      'notifications', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notifications" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _peekGraphMeta =
      const VerificationMeta('peekGraph');
  @override
  late final GeneratedColumn<bool> peekGraph = GeneratedColumn<bool>(
      'peek_graph', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("peek_graph" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _planTrailingMeta =
      const VerificationMeta('planTrailing');
  @override
  late final GeneratedColumn<String> planTrailing = GeneratedColumn<String>(
      'plan_trailing', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _repEstimationMeta =
      const VerificationMeta('repEstimation');
  @override
  late final GeneratedColumn<bool> repEstimation = GeneratedColumn<bool>(
      'rep_estimation', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("rep_estimation" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _restTimersMeta =
      const VerificationMeta('restTimers');
  @override
  late final GeneratedColumn<bool> restTimers = GeneratedColumn<bool>(
      'rest_timers', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("rest_timers" IN (0, 1))'));
  static const VerificationMeta _shortDateFormatMeta =
      const VerificationMeta('shortDateFormat');
  @override
  late final GeneratedColumn<String> shortDateFormat = GeneratedColumn<String>(
      'short_date_format', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _showCategoriesMeta =
      const VerificationMeta('showCategories');
  @override
  late final GeneratedColumn<bool> showCategories = GeneratedColumn<bool>(
      'show_categories', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_categories" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showImagesMeta =
      const VerificationMeta('showImages');
  @override
  late final GeneratedColumn<bool> showImages = GeneratedColumn<bool>(
      'show_images', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("show_images" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showNotesMeta =
      const VerificationMeta('showNotes');
  @override
  late final GeneratedColumn<bool> showNotes = GeneratedColumn<bool>(
      'show_notes', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("show_notes" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showGlobalProgressMeta =
      const VerificationMeta('showGlobalProgress');
  @override
  late final GeneratedColumn<bool> showGlobalProgress = GeneratedColumn<bool>(
      'show_global_progress', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_global_progress" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showUnitsMeta =
      const VerificationMeta('showUnits');
  @override
  late final GeneratedColumn<bool> showUnits = GeneratedColumn<bool>(
      'show_units', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("show_units" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _strengthUnitMeta =
      const VerificationMeta('strengthUnit');
  @override
  late final GeneratedColumn<String> strengthUnit = GeneratedColumn<String>(
      'strength_unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _systemColorsMeta =
      const VerificationMeta('systemColors');
  @override
  late final GeneratedColumn<bool> systemColors = GeneratedColumn<bool>(
      'system_colors', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("system_colors" IN (0, 1))'));
  static const VerificationMeta _tabsMeta = const VerificationMeta('tabs');
  @override
  late final GeneratedColumn<String> tabs = GeneratedColumn<String>(
      'tabs', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(
          'HistoryPage,PlansPage,MusicPage,GraphsPage,NotesPage,SettingsPage'));
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timerDurationMeta =
      const VerificationMeta('timerDuration');
  @override
  late final GeneratedColumn<int> timerDuration = GeneratedColumn<int>(
      'timer_duration', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _vibrateMeta =
      const VerificationMeta('vibrate');
  @override
  late final GeneratedColumn<bool> vibrate = GeneratedColumn<bool>(
      'vibrate', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("vibrate" IN (0, 1))'));
  static const VerificationMeta _warmupSetsMeta =
      const VerificationMeta('warmupSets');
  @override
  late final GeneratedColumn<int> warmupSets = GeneratedColumn<int>(
      'warmup_sets', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _scrollableTabsMeta =
      const VerificationMeta('scrollableTabs');
  @override
  late final GeneratedColumn<bool> scrollableTabs = GeneratedColumn<bool>(
      'scrollable_tabs', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("scrollable_tabs" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _fivethreeoneSquatTmMeta =
      const VerificationMeta('fivethreeoneSquatTm');
  @override
  late final GeneratedColumn<double> fivethreeoneSquatTm =
      GeneratedColumn<double>('fivethreeone_squat_tm', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fivethreeoneBenchTmMeta =
      const VerificationMeta('fivethreeoneBenchTm');
  @override
  late final GeneratedColumn<double> fivethreeoneBenchTm =
      GeneratedColumn<double>('fivethreeone_bench_tm', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fivethreeoneDeadliftTmMeta =
      const VerificationMeta('fivethreeoneDeadliftTm');
  @override
  late final GeneratedColumn<double> fivethreeoneDeadliftTm =
      GeneratedColumn<double>('fivethreeone_deadlift_tm', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fivethreeonePressTmMeta =
      const VerificationMeta('fivethreeonePressTm');
  @override
  late final GeneratedColumn<double> fivethreeonePressTm =
      GeneratedColumn<double>('fivethreeone_press_tm', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fivethreeoneWeekMeta =
      const VerificationMeta('fivethreeoneWeek');
  @override
  late final GeneratedColumn<int> fivethreeoneWeek = GeneratedColumn<int>(
      'fivethreeone_week', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _customColorSeedMeta =
      const VerificationMeta('customColorSeed');
  @override
  late final GeneratedColumn<int> customColorSeed = GeneratedColumn<int>(
      'custom_color_seed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0xFF673AB7));
  static const VerificationMeta _lastAutoBackupTimeMeta =
      const VerificationMeta('lastAutoBackupTime');
  @override
  late final GeneratedColumn<DateTime> lastAutoBackupTime =
      GeneratedColumn<DateTime>('last_auto_backup_time', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastBackupStatusMeta =
      const VerificationMeta('lastBackupStatus');
  @override
  late final GeneratedColumn<String> lastBackupStatus = GeneratedColumn<String>(
      'last_backup_status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _spotifyAccessTokenMeta =
      const VerificationMeta('spotifyAccessToken');
  @override
  late final GeneratedColumn<String> spotifyAccessToken =
      GeneratedColumn<String>('spotify_access_token', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _spotifyRefreshTokenMeta =
      const VerificationMeta('spotifyRefreshToken');
  @override
  late final GeneratedColumn<String> spotifyRefreshToken =
      GeneratedColumn<String>('spotify_refresh_token', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _spotifyTokenExpiryMeta =
      const VerificationMeta('spotifyTokenExpiry');
  @override
  late final GeneratedColumn<int> spotifyTokenExpiry = GeneratedColumn<int>(
      'spotify_token_expiry', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _serverUrlMeta =
      const VerificationMeta('serverUrl');
  @override
  late final GeneratedColumn<String> serverUrl = GeneratedColumn<String>(
      'server_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serverApiKeyMeta =
      const VerificationMeta('serverApiKey');
  @override
  late final GeneratedColumn<String> serverApiKey = GeneratedColumn<String>(
      'server_api_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastPushTimeMeta =
      const VerificationMeta('lastPushTime');
  @override
  late final GeneratedColumn<DateTime> lastPushTime = GeneratedColumn<DateTime>(
      'last_push_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastPushStatusMeta =
      const VerificationMeta('lastPushStatus');
  @override
  late final GeneratedColumn<String> lastPushStatus = GeneratedColumn<String>(
      'last_push_status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        alarmSound,
        automaticBackups,
        backupPath,
        cardioUnit,
        curveLines,
        curveSmoothness,
        durationEstimation,
        enableSound,
        explainedPermissions,
        groupHistory,
        id,
        longDateFormat,
        maxSets,
        notifications,
        peekGraph,
        planTrailing,
        repEstimation,
        restTimers,
        shortDateFormat,
        showCategories,
        showImages,
        showNotes,
        showGlobalProgress,
        showUnits,
        strengthUnit,
        systemColors,
        tabs,
        themeMode,
        timerDuration,
        vibrate,
        warmupSets,
        scrollableTabs,
        fivethreeoneSquatTm,
        fivethreeoneBenchTm,
        fivethreeoneDeadliftTm,
        fivethreeonePressTm,
        fivethreeoneWeek,
        customColorSeed,
        lastAutoBackupTime,
        lastBackupStatus,
        spotifyAccessToken,
        spotifyRefreshToken,
        spotifyTokenExpiry,
        serverUrl,
        serverApiKey,
        lastPushTime,
        lastPushStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('alarm_sound')) {
      context.handle(
          _alarmSoundMeta,
          alarmSound.isAcceptableOrUnknown(
              data['alarm_sound']!, _alarmSoundMeta));
    } else if (isInserting) {
      context.missing(_alarmSoundMeta);
    }
    if (data.containsKey('automatic_backups')) {
      context.handle(
          _automaticBackupsMeta,
          automaticBackups.isAcceptableOrUnknown(
              data['automatic_backups']!, _automaticBackupsMeta));
    }
    if (data.containsKey('backup_path')) {
      context.handle(
          _backupPathMeta,
          backupPath.isAcceptableOrUnknown(
              data['backup_path']!, _backupPathMeta));
    }
    if (data.containsKey('cardio_unit')) {
      context.handle(
          _cardioUnitMeta,
          cardioUnit.isAcceptableOrUnknown(
              data['cardio_unit']!, _cardioUnitMeta));
    } else if (isInserting) {
      context.missing(_cardioUnitMeta);
    }
    if (data.containsKey('curve_lines')) {
      context.handle(
          _curveLinesMeta,
          curveLines.isAcceptableOrUnknown(
              data['curve_lines']!, _curveLinesMeta));
    } else if (isInserting) {
      context.missing(_curveLinesMeta);
    }
    if (data.containsKey('curve_smoothness')) {
      context.handle(
          _curveSmoothnessMeta,
          curveSmoothness.isAcceptableOrUnknown(
              data['curve_smoothness']!, _curveSmoothnessMeta));
    }
    if (data.containsKey('duration_estimation')) {
      context.handle(
          _durationEstimationMeta,
          durationEstimation.isAcceptableOrUnknown(
              data['duration_estimation']!, _durationEstimationMeta));
    }
    if (data.containsKey('enable_sound')) {
      context.handle(
          _enableSoundMeta,
          enableSound.isAcceptableOrUnknown(
              data['enable_sound']!, _enableSoundMeta));
    }
    if (data.containsKey('explained_permissions')) {
      context.handle(
          _explainedPermissionsMeta,
          explainedPermissions.isAcceptableOrUnknown(
              data['explained_permissions']!, _explainedPermissionsMeta));
    } else if (isInserting) {
      context.missing(_explainedPermissionsMeta);
    }
    if (data.containsKey('group_history')) {
      context.handle(
          _groupHistoryMeta,
          groupHistory.isAcceptableOrUnknown(
              data['group_history']!, _groupHistoryMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('long_date_format')) {
      context.handle(
          _longDateFormatMeta,
          longDateFormat.isAcceptableOrUnknown(
              data['long_date_format']!, _longDateFormatMeta));
    } else if (isInserting) {
      context.missing(_longDateFormatMeta);
    }
    if (data.containsKey('max_sets')) {
      context.handle(_maxSetsMeta,
          maxSets.isAcceptableOrUnknown(data['max_sets']!, _maxSetsMeta));
    } else if (isInserting) {
      context.missing(_maxSetsMeta);
    }
    if (data.containsKey('notifications')) {
      context.handle(
          _notificationsMeta,
          notifications.isAcceptableOrUnknown(
              data['notifications']!, _notificationsMeta));
    }
    if (data.containsKey('peek_graph')) {
      context.handle(_peekGraphMeta,
          peekGraph.isAcceptableOrUnknown(data['peek_graph']!, _peekGraphMeta));
    }
    if (data.containsKey('plan_trailing')) {
      context.handle(
          _planTrailingMeta,
          planTrailing.isAcceptableOrUnknown(
              data['plan_trailing']!, _planTrailingMeta));
    } else if (isInserting) {
      context.missing(_planTrailingMeta);
    }
    if (data.containsKey('rep_estimation')) {
      context.handle(
          _repEstimationMeta,
          repEstimation.isAcceptableOrUnknown(
              data['rep_estimation']!, _repEstimationMeta));
    }
    if (data.containsKey('rest_timers')) {
      context.handle(
          _restTimersMeta,
          restTimers.isAcceptableOrUnknown(
              data['rest_timers']!, _restTimersMeta));
    } else if (isInserting) {
      context.missing(_restTimersMeta);
    }
    if (data.containsKey('short_date_format')) {
      context.handle(
          _shortDateFormatMeta,
          shortDateFormat.isAcceptableOrUnknown(
              data['short_date_format']!, _shortDateFormatMeta));
    } else if (isInserting) {
      context.missing(_shortDateFormatMeta);
    }
    if (data.containsKey('show_categories')) {
      context.handle(
          _showCategoriesMeta,
          showCategories.isAcceptableOrUnknown(
              data['show_categories']!, _showCategoriesMeta));
    }
    if (data.containsKey('show_images')) {
      context.handle(
          _showImagesMeta,
          showImages.isAcceptableOrUnknown(
              data['show_images']!, _showImagesMeta));
    }
    if (data.containsKey('show_notes')) {
      context.handle(_showNotesMeta,
          showNotes.isAcceptableOrUnknown(data['show_notes']!, _showNotesMeta));
    }
    if (data.containsKey('show_global_progress')) {
      context.handle(
          _showGlobalProgressMeta,
          showGlobalProgress.isAcceptableOrUnknown(
              data['show_global_progress']!, _showGlobalProgressMeta));
    }
    if (data.containsKey('show_units')) {
      context.handle(_showUnitsMeta,
          showUnits.isAcceptableOrUnknown(data['show_units']!, _showUnitsMeta));
    }
    if (data.containsKey('strength_unit')) {
      context.handle(
          _strengthUnitMeta,
          strengthUnit.isAcceptableOrUnknown(
              data['strength_unit']!, _strengthUnitMeta));
    } else if (isInserting) {
      context.missing(_strengthUnitMeta);
    }
    if (data.containsKey('system_colors')) {
      context.handle(
          _systemColorsMeta,
          systemColors.isAcceptableOrUnknown(
              data['system_colors']!, _systemColorsMeta));
    } else if (isInserting) {
      context.missing(_systemColorsMeta);
    }
    if (data.containsKey('tabs')) {
      context.handle(
          _tabsMeta, tabs.isAcceptableOrUnknown(data['tabs']!, _tabsMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    } else if (isInserting) {
      context.missing(_themeModeMeta);
    }
    if (data.containsKey('timer_duration')) {
      context.handle(
          _timerDurationMeta,
          timerDuration.isAcceptableOrUnknown(
              data['timer_duration']!, _timerDurationMeta));
    } else if (isInserting) {
      context.missing(_timerDurationMeta);
    }
    if (data.containsKey('vibrate')) {
      context.handle(_vibrateMeta,
          vibrate.isAcceptableOrUnknown(data['vibrate']!, _vibrateMeta));
    } else if (isInserting) {
      context.missing(_vibrateMeta);
    }
    if (data.containsKey('warmup_sets')) {
      context.handle(
          _warmupSetsMeta,
          warmupSets.isAcceptableOrUnknown(
              data['warmup_sets']!, _warmupSetsMeta));
    }
    if (data.containsKey('scrollable_tabs')) {
      context.handle(
          _scrollableTabsMeta,
          scrollableTabs.isAcceptableOrUnknown(
              data['scrollable_tabs']!, _scrollableTabsMeta));
    }
    if (data.containsKey('fivethreeone_squat_tm')) {
      context.handle(
          _fivethreeoneSquatTmMeta,
          fivethreeoneSquatTm.isAcceptableOrUnknown(
              data['fivethreeone_squat_tm']!, _fivethreeoneSquatTmMeta));
    }
    if (data.containsKey('fivethreeone_bench_tm')) {
      context.handle(
          _fivethreeoneBenchTmMeta,
          fivethreeoneBenchTm.isAcceptableOrUnknown(
              data['fivethreeone_bench_tm']!, _fivethreeoneBenchTmMeta));
    }
    if (data.containsKey('fivethreeone_deadlift_tm')) {
      context.handle(
          _fivethreeoneDeadliftTmMeta,
          fivethreeoneDeadliftTm.isAcceptableOrUnknown(
              data['fivethreeone_deadlift_tm']!, _fivethreeoneDeadliftTmMeta));
    }
    if (data.containsKey('fivethreeone_press_tm')) {
      context.handle(
          _fivethreeonePressTmMeta,
          fivethreeonePressTm.isAcceptableOrUnknown(
              data['fivethreeone_press_tm']!, _fivethreeonePressTmMeta));
    }
    if (data.containsKey('fivethreeone_week')) {
      context.handle(
          _fivethreeoneWeekMeta,
          fivethreeoneWeek.isAcceptableOrUnknown(
              data['fivethreeone_week']!, _fivethreeoneWeekMeta));
    }
    if (data.containsKey('custom_color_seed')) {
      context.handle(
          _customColorSeedMeta,
          customColorSeed.isAcceptableOrUnknown(
              data['custom_color_seed']!, _customColorSeedMeta));
    }
    if (data.containsKey('last_auto_backup_time')) {
      context.handle(
          _lastAutoBackupTimeMeta,
          lastAutoBackupTime.isAcceptableOrUnknown(
              data['last_auto_backup_time']!, _lastAutoBackupTimeMeta));
    }
    if (data.containsKey('last_backup_status')) {
      context.handle(
          _lastBackupStatusMeta,
          lastBackupStatus.isAcceptableOrUnknown(
              data['last_backup_status']!, _lastBackupStatusMeta));
    }
    if (data.containsKey('spotify_access_token')) {
      context.handle(
          _spotifyAccessTokenMeta,
          spotifyAccessToken.isAcceptableOrUnknown(
              data['spotify_access_token']!, _spotifyAccessTokenMeta));
    }
    if (data.containsKey('spotify_refresh_token')) {
      context.handle(
          _spotifyRefreshTokenMeta,
          spotifyRefreshToken.isAcceptableOrUnknown(
              data['spotify_refresh_token']!, _spotifyRefreshTokenMeta));
    }
    if (data.containsKey('spotify_token_expiry')) {
      context.handle(
          _spotifyTokenExpiryMeta,
          spotifyTokenExpiry.isAcceptableOrUnknown(
              data['spotify_token_expiry']!, _spotifyTokenExpiryMeta));
    }
    if (data.containsKey('server_url')) {
      context.handle(_serverUrlMeta,
          serverUrl.isAcceptableOrUnknown(data['server_url']!, _serverUrlMeta));
    }
    if (data.containsKey('server_api_key')) {
      context.handle(
          _serverApiKeyMeta,
          serverApiKey.isAcceptableOrUnknown(
              data['server_api_key']!, _serverApiKeyMeta));
    }
    if (data.containsKey('last_push_time')) {
      context.handle(
          _lastPushTimeMeta,
          lastPushTime.isAcceptableOrUnknown(
              data['last_push_time']!, _lastPushTimeMeta));
    }
    if (data.containsKey('last_push_status')) {
      context.handle(
          _lastPushStatusMeta,
          lastPushStatus.isAcceptableOrUnknown(
              data['last_push_status']!, _lastPushStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      alarmSound: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}alarm_sound'])!,
      automaticBackups: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}automatic_backups'])!,
      backupPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backup_path']),
      cardioUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cardio_unit'])!,
      curveLines: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}curve_lines'])!,
      curveSmoothness: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}curve_smoothness']),
      durationEstimation: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}duration_estimation'])!,
      enableSound: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enable_sound'])!,
      explainedPermissions: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}explained_permissions'])!,
      groupHistory: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}group_history'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      longDateFormat: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}long_date_format'])!,
      maxSets: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_sets'])!,
      notifications: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}notifications'])!,
      peekGraph: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}peek_graph'])!,
      planTrailing: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_trailing'])!,
      repEstimation: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}rep_estimation'])!,
      restTimers: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}rest_timers'])!,
      shortDateFormat: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}short_date_format'])!,
      showCategories: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_categories'])!,
      showImages: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_images'])!,
      showNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_notes'])!,
      showGlobalProgress: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}show_global_progress'])!,
      showUnits: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_units'])!,
      strengthUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}strength_unit'])!,
      systemColors: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}system_colors'])!,
      tabs: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tabs'])!,
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      timerDuration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timer_duration'])!,
      vibrate: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}vibrate'])!,
      warmupSets: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}warmup_sets']),
      scrollableTabs: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}scrollable_tabs'])!,
      fivethreeoneSquatTm: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}fivethreeone_squat_tm']),
      fivethreeoneBenchTm: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}fivethreeone_bench_tm']),
      fivethreeoneDeadliftTm: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}fivethreeone_deadlift_tm']),
      fivethreeonePressTm: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}fivethreeone_press_tm']),
      fivethreeoneWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fivethreeone_week'])!,
      customColorSeed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}custom_color_seed'])!,
      lastAutoBackupTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_auto_backup_time']),
      lastBackupStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_backup_status']),
      spotifyAccessToken: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}spotify_access_token']),
      spotifyRefreshToken: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}spotify_refresh_token']),
      spotifyTokenExpiry: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}spotify_token_expiry']),
      serverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_url']),
      serverApiKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_api_key']),
      lastPushTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_push_time']),
      lastPushStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_push_status']),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String alarmSound;
  final bool automaticBackups;
  final String? backupPath;
  final String cardioUnit;
  final bool curveLines;
  final double? curveSmoothness;
  final bool durationEstimation;
  final bool enableSound;
  final bool explainedPermissions;
  final bool groupHistory;
  final int id;
  final String longDateFormat;
  final int maxSets;
  final bool notifications;
  final bool peekGraph;
  final String planTrailing;
  final bool repEstimation;
  final bool restTimers;
  final String shortDateFormat;
  final bool showCategories;
  final bool showImages;
  final bool showNotes;
  final bool showGlobalProgress;
  final bool showUnits;
  final String strengthUnit;
  final bool systemColors;
  final String tabs;
  final String themeMode;
  final int timerDuration;
  final bool vibrate;
  final int? warmupSets;
  final bool scrollableTabs;
  final double? fivethreeoneSquatTm;
  final double? fivethreeoneBenchTm;
  final double? fivethreeoneDeadliftTm;
  final double? fivethreeonePressTm;
  final int fivethreeoneWeek;
  final int customColorSeed;
  final DateTime? lastAutoBackupTime;
  final String? lastBackupStatus;
  final String? spotifyAccessToken;
  final String? spotifyRefreshToken;
  final int? spotifyTokenExpiry;
  final String? serverUrl;
  final String? serverApiKey;
  final DateTime? lastPushTime;
  final String? lastPushStatus;
  const Setting(
      {required this.alarmSound,
      required this.automaticBackups,
      this.backupPath,
      required this.cardioUnit,
      required this.curveLines,
      this.curveSmoothness,
      required this.durationEstimation,
      required this.enableSound,
      required this.explainedPermissions,
      required this.groupHistory,
      required this.id,
      required this.longDateFormat,
      required this.maxSets,
      required this.notifications,
      required this.peekGraph,
      required this.planTrailing,
      required this.repEstimation,
      required this.restTimers,
      required this.shortDateFormat,
      required this.showCategories,
      required this.showImages,
      required this.showNotes,
      required this.showGlobalProgress,
      required this.showUnits,
      required this.strengthUnit,
      required this.systemColors,
      required this.tabs,
      required this.themeMode,
      required this.timerDuration,
      required this.vibrate,
      this.warmupSets,
      required this.scrollableTabs,
      this.fivethreeoneSquatTm,
      this.fivethreeoneBenchTm,
      this.fivethreeoneDeadliftTm,
      this.fivethreeonePressTm,
      required this.fivethreeoneWeek,
      required this.customColorSeed,
      this.lastAutoBackupTime,
      this.lastBackupStatus,
      this.spotifyAccessToken,
      this.spotifyRefreshToken,
      this.spotifyTokenExpiry,
      this.serverUrl,
      this.serverApiKey,
      this.lastPushTime,
      this.lastPushStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['alarm_sound'] = Variable<String>(alarmSound);
    map['automatic_backups'] = Variable<bool>(automaticBackups);
    if (!nullToAbsent || backupPath != null) {
      map['backup_path'] = Variable<String>(backupPath);
    }
    map['cardio_unit'] = Variable<String>(cardioUnit);
    map['curve_lines'] = Variable<bool>(curveLines);
    if (!nullToAbsent || curveSmoothness != null) {
      map['curve_smoothness'] = Variable<double>(curveSmoothness);
    }
    map['duration_estimation'] = Variable<bool>(durationEstimation);
    map['enable_sound'] = Variable<bool>(enableSound);
    map['explained_permissions'] = Variable<bool>(explainedPermissions);
    map['group_history'] = Variable<bool>(groupHistory);
    map['id'] = Variable<int>(id);
    map['long_date_format'] = Variable<String>(longDateFormat);
    map['max_sets'] = Variable<int>(maxSets);
    map['notifications'] = Variable<bool>(notifications);
    map['peek_graph'] = Variable<bool>(peekGraph);
    map['plan_trailing'] = Variable<String>(planTrailing);
    map['rep_estimation'] = Variable<bool>(repEstimation);
    map['rest_timers'] = Variable<bool>(restTimers);
    map['short_date_format'] = Variable<String>(shortDateFormat);
    map['show_categories'] = Variable<bool>(showCategories);
    map['show_images'] = Variable<bool>(showImages);
    map['show_notes'] = Variable<bool>(showNotes);
    map['show_global_progress'] = Variable<bool>(showGlobalProgress);
    map['show_units'] = Variable<bool>(showUnits);
    map['strength_unit'] = Variable<String>(strengthUnit);
    map['system_colors'] = Variable<bool>(systemColors);
    map['tabs'] = Variable<String>(tabs);
    map['theme_mode'] = Variable<String>(themeMode);
    map['timer_duration'] = Variable<int>(timerDuration);
    map['vibrate'] = Variable<bool>(vibrate);
    if (!nullToAbsent || warmupSets != null) {
      map['warmup_sets'] = Variable<int>(warmupSets);
    }
    map['scrollable_tabs'] = Variable<bool>(scrollableTabs);
    if (!nullToAbsent || fivethreeoneSquatTm != null) {
      map['fivethreeone_squat_tm'] = Variable<double>(fivethreeoneSquatTm);
    }
    if (!nullToAbsent || fivethreeoneBenchTm != null) {
      map['fivethreeone_bench_tm'] = Variable<double>(fivethreeoneBenchTm);
    }
    if (!nullToAbsent || fivethreeoneDeadliftTm != null) {
      map['fivethreeone_deadlift_tm'] =
          Variable<double>(fivethreeoneDeadliftTm);
    }
    if (!nullToAbsent || fivethreeonePressTm != null) {
      map['fivethreeone_press_tm'] = Variable<double>(fivethreeonePressTm);
    }
    map['fivethreeone_week'] = Variable<int>(fivethreeoneWeek);
    map['custom_color_seed'] = Variable<int>(customColorSeed);
    if (!nullToAbsent || lastAutoBackupTime != null) {
      map['last_auto_backup_time'] = Variable<DateTime>(lastAutoBackupTime);
    }
    if (!nullToAbsent || lastBackupStatus != null) {
      map['last_backup_status'] = Variable<String>(lastBackupStatus);
    }
    if (!nullToAbsent || spotifyAccessToken != null) {
      map['spotify_access_token'] = Variable<String>(spotifyAccessToken);
    }
    if (!nullToAbsent || spotifyRefreshToken != null) {
      map['spotify_refresh_token'] = Variable<String>(spotifyRefreshToken);
    }
    if (!nullToAbsent || spotifyTokenExpiry != null) {
      map['spotify_token_expiry'] = Variable<int>(spotifyTokenExpiry);
    }
    if (!nullToAbsent || serverUrl != null) {
      map['server_url'] = Variable<String>(serverUrl);
    }
    if (!nullToAbsent || serverApiKey != null) {
      map['server_api_key'] = Variable<String>(serverApiKey);
    }
    if (!nullToAbsent || lastPushTime != null) {
      map['last_push_time'] = Variable<DateTime>(lastPushTime);
    }
    if (!nullToAbsent || lastPushStatus != null) {
      map['last_push_status'] = Variable<String>(lastPushStatus);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      alarmSound: Value(alarmSound),
      automaticBackups: Value(automaticBackups),
      backupPath: backupPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backupPath),
      cardioUnit: Value(cardioUnit),
      curveLines: Value(curveLines),
      curveSmoothness: curveSmoothness == null && nullToAbsent
          ? const Value.absent()
          : Value(curveSmoothness),
      durationEstimation: Value(durationEstimation),
      enableSound: Value(enableSound),
      explainedPermissions: Value(explainedPermissions),
      groupHistory: Value(groupHistory),
      id: Value(id),
      longDateFormat: Value(longDateFormat),
      maxSets: Value(maxSets),
      notifications: Value(notifications),
      peekGraph: Value(peekGraph),
      planTrailing: Value(planTrailing),
      repEstimation: Value(repEstimation),
      restTimers: Value(restTimers),
      shortDateFormat: Value(shortDateFormat),
      showCategories: Value(showCategories),
      showImages: Value(showImages),
      showNotes: Value(showNotes),
      showGlobalProgress: Value(showGlobalProgress),
      showUnits: Value(showUnits),
      strengthUnit: Value(strengthUnit),
      systemColors: Value(systemColors),
      tabs: Value(tabs),
      themeMode: Value(themeMode),
      timerDuration: Value(timerDuration),
      vibrate: Value(vibrate),
      warmupSets: warmupSets == null && nullToAbsent
          ? const Value.absent()
          : Value(warmupSets),
      scrollableTabs: Value(scrollableTabs),
      fivethreeoneSquatTm: fivethreeoneSquatTm == null && nullToAbsent
          ? const Value.absent()
          : Value(fivethreeoneSquatTm),
      fivethreeoneBenchTm: fivethreeoneBenchTm == null && nullToAbsent
          ? const Value.absent()
          : Value(fivethreeoneBenchTm),
      fivethreeoneDeadliftTm: fivethreeoneDeadliftTm == null && nullToAbsent
          ? const Value.absent()
          : Value(fivethreeoneDeadliftTm),
      fivethreeonePressTm: fivethreeonePressTm == null && nullToAbsent
          ? const Value.absent()
          : Value(fivethreeonePressTm),
      fivethreeoneWeek: Value(fivethreeoneWeek),
      customColorSeed: Value(customColorSeed),
      lastAutoBackupTime: lastAutoBackupTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAutoBackupTime),
      lastBackupStatus: lastBackupStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupStatus),
      spotifyAccessToken: spotifyAccessToken == null && nullToAbsent
          ? const Value.absent()
          : Value(spotifyAccessToken),
      spotifyRefreshToken: spotifyRefreshToken == null && nullToAbsent
          ? const Value.absent()
          : Value(spotifyRefreshToken),
      spotifyTokenExpiry: spotifyTokenExpiry == null && nullToAbsent
          ? const Value.absent()
          : Value(spotifyTokenExpiry),
      serverUrl: serverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUrl),
      serverApiKey: serverApiKey == null && nullToAbsent
          ? const Value.absent()
          : Value(serverApiKey),
      lastPushTime: lastPushTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPushTime),
      lastPushStatus: lastPushStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPushStatus),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      alarmSound: serializer.fromJson<String>(json['alarmSound']),
      automaticBackups: serializer.fromJson<bool>(json['automaticBackups']),
      backupPath: serializer.fromJson<String?>(json['backupPath']),
      cardioUnit: serializer.fromJson<String>(json['cardioUnit']),
      curveLines: serializer.fromJson<bool>(json['curveLines']),
      curveSmoothness: serializer.fromJson<double?>(json['curveSmoothness']),
      durationEstimation: serializer.fromJson<bool>(json['durationEstimation']),
      enableSound: serializer.fromJson<bool>(json['enableSound']),
      explainedPermissions:
          serializer.fromJson<bool>(json['explainedPermissions']),
      groupHistory: serializer.fromJson<bool>(json['groupHistory']),
      id: serializer.fromJson<int>(json['id']),
      longDateFormat: serializer.fromJson<String>(json['longDateFormat']),
      maxSets: serializer.fromJson<int>(json['maxSets']),
      notifications: serializer.fromJson<bool>(json['notifications']),
      peekGraph: serializer.fromJson<bool>(json['peekGraph']),
      planTrailing: serializer.fromJson<String>(json['planTrailing']),
      repEstimation: serializer.fromJson<bool>(json['repEstimation']),
      restTimers: serializer.fromJson<bool>(json['restTimers']),
      shortDateFormat: serializer.fromJson<String>(json['shortDateFormat']),
      showCategories: serializer.fromJson<bool>(json['showCategories']),
      showImages: serializer.fromJson<bool>(json['showImages']),
      showNotes: serializer.fromJson<bool>(json['showNotes']),
      showGlobalProgress: serializer.fromJson<bool>(json['showGlobalProgress']),
      showUnits: serializer.fromJson<bool>(json['showUnits']),
      strengthUnit: serializer.fromJson<String>(json['strengthUnit']),
      systemColors: serializer.fromJson<bool>(json['systemColors']),
      tabs: serializer.fromJson<String>(json['tabs']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      timerDuration: serializer.fromJson<int>(json['timerDuration']),
      vibrate: serializer.fromJson<bool>(json['vibrate']),
      warmupSets: serializer.fromJson<int?>(json['warmupSets']),
      scrollableTabs: serializer.fromJson<bool>(json['scrollableTabs']),
      fivethreeoneSquatTm:
          serializer.fromJson<double?>(json['fivethreeoneSquatTm']),
      fivethreeoneBenchTm:
          serializer.fromJson<double?>(json['fivethreeoneBenchTm']),
      fivethreeoneDeadliftTm:
          serializer.fromJson<double?>(json['fivethreeoneDeadliftTm']),
      fivethreeonePressTm:
          serializer.fromJson<double?>(json['fivethreeonePressTm']),
      fivethreeoneWeek: serializer.fromJson<int>(json['fivethreeoneWeek']),
      customColorSeed: serializer.fromJson<int>(json['customColorSeed']),
      lastAutoBackupTime:
          serializer.fromJson<DateTime?>(json['lastAutoBackupTime']),
      lastBackupStatus: serializer.fromJson<String?>(json['lastBackupStatus']),
      spotifyAccessToken:
          serializer.fromJson<String?>(json['spotifyAccessToken']),
      spotifyRefreshToken:
          serializer.fromJson<String?>(json['spotifyRefreshToken']),
      spotifyTokenExpiry: serializer.fromJson<int?>(json['spotifyTokenExpiry']),
      serverUrl: serializer.fromJson<String?>(json['serverUrl']),
      serverApiKey: serializer.fromJson<String?>(json['serverApiKey']),
      lastPushTime: serializer.fromJson<DateTime?>(json['lastPushTime']),
      lastPushStatus: serializer.fromJson<String?>(json['lastPushStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'alarmSound': serializer.toJson<String>(alarmSound),
      'automaticBackups': serializer.toJson<bool>(automaticBackups),
      'backupPath': serializer.toJson<String?>(backupPath),
      'cardioUnit': serializer.toJson<String>(cardioUnit),
      'curveLines': serializer.toJson<bool>(curveLines),
      'curveSmoothness': serializer.toJson<double?>(curveSmoothness),
      'durationEstimation': serializer.toJson<bool>(durationEstimation),
      'enableSound': serializer.toJson<bool>(enableSound),
      'explainedPermissions': serializer.toJson<bool>(explainedPermissions),
      'groupHistory': serializer.toJson<bool>(groupHistory),
      'id': serializer.toJson<int>(id),
      'longDateFormat': serializer.toJson<String>(longDateFormat),
      'maxSets': serializer.toJson<int>(maxSets),
      'notifications': serializer.toJson<bool>(notifications),
      'peekGraph': serializer.toJson<bool>(peekGraph),
      'planTrailing': serializer.toJson<String>(planTrailing),
      'repEstimation': serializer.toJson<bool>(repEstimation),
      'restTimers': serializer.toJson<bool>(restTimers),
      'shortDateFormat': serializer.toJson<String>(shortDateFormat),
      'showCategories': serializer.toJson<bool>(showCategories),
      'showImages': serializer.toJson<bool>(showImages),
      'showNotes': serializer.toJson<bool>(showNotes),
      'showGlobalProgress': serializer.toJson<bool>(showGlobalProgress),
      'showUnits': serializer.toJson<bool>(showUnits),
      'strengthUnit': serializer.toJson<String>(strengthUnit),
      'systemColors': serializer.toJson<bool>(systemColors),
      'tabs': serializer.toJson<String>(tabs),
      'themeMode': serializer.toJson<String>(themeMode),
      'timerDuration': serializer.toJson<int>(timerDuration),
      'vibrate': serializer.toJson<bool>(vibrate),
      'warmupSets': serializer.toJson<int?>(warmupSets),
      'scrollableTabs': serializer.toJson<bool>(scrollableTabs),
      'fivethreeoneSquatTm': serializer.toJson<double?>(fivethreeoneSquatTm),
      'fivethreeoneBenchTm': serializer.toJson<double?>(fivethreeoneBenchTm),
      'fivethreeoneDeadliftTm':
          serializer.toJson<double?>(fivethreeoneDeadliftTm),
      'fivethreeonePressTm': serializer.toJson<double?>(fivethreeonePressTm),
      'fivethreeoneWeek': serializer.toJson<int>(fivethreeoneWeek),
      'customColorSeed': serializer.toJson<int>(customColorSeed),
      'lastAutoBackupTime': serializer.toJson<DateTime?>(lastAutoBackupTime),
      'lastBackupStatus': serializer.toJson<String?>(lastBackupStatus),
      'spotifyAccessToken': serializer.toJson<String?>(spotifyAccessToken),
      'spotifyRefreshToken': serializer.toJson<String?>(spotifyRefreshToken),
      'spotifyTokenExpiry': serializer.toJson<int?>(spotifyTokenExpiry),
      'serverUrl': serializer.toJson<String?>(serverUrl),
      'serverApiKey': serializer.toJson<String?>(serverApiKey),
      'lastPushTime': serializer.toJson<DateTime?>(lastPushTime),
      'lastPushStatus': serializer.toJson<String?>(lastPushStatus),
    };
  }

  Setting copyWith(
          {String? alarmSound,
          bool? automaticBackups,
          Value<String?> backupPath = const Value.absent(),
          String? cardioUnit,
          bool? curveLines,
          Value<double?> curveSmoothness = const Value.absent(),
          bool? durationEstimation,
          bool? enableSound,
          bool? explainedPermissions,
          bool? groupHistory,
          int? id,
          String? longDateFormat,
          int? maxSets,
          bool? notifications,
          bool? peekGraph,
          String? planTrailing,
          bool? repEstimation,
          bool? restTimers,
          String? shortDateFormat,
          bool? showCategories,
          bool? showImages,
          bool? showNotes,
          bool? showGlobalProgress,
          bool? showUnits,
          String? strengthUnit,
          bool? systemColors,
          String? tabs,
          String? themeMode,
          int? timerDuration,
          bool? vibrate,
          Value<int?> warmupSets = const Value.absent(),
          bool? scrollableTabs,
          Value<double?> fivethreeoneSquatTm = const Value.absent(),
          Value<double?> fivethreeoneBenchTm = const Value.absent(),
          Value<double?> fivethreeoneDeadliftTm = const Value.absent(),
          Value<double?> fivethreeonePressTm = const Value.absent(),
          int? fivethreeoneWeek,
          int? customColorSeed,
          Value<DateTime?> lastAutoBackupTime = const Value.absent(),
          Value<String?> lastBackupStatus = const Value.absent(),
          Value<String?> spotifyAccessToken = const Value.absent(),
          Value<String?> spotifyRefreshToken = const Value.absent(),
          Value<int?> spotifyTokenExpiry = const Value.absent(),
          Value<String?> serverUrl = const Value.absent(),
          Value<String?> serverApiKey = const Value.absent(),
          Value<DateTime?> lastPushTime = const Value.absent(),
          Value<String?> lastPushStatus = const Value.absent()}) =>
      Setting(
        alarmSound: alarmSound ?? this.alarmSound,
        automaticBackups: automaticBackups ?? this.automaticBackups,
        backupPath: backupPath.present ? backupPath.value : this.backupPath,
        cardioUnit: cardioUnit ?? this.cardioUnit,
        curveLines: curveLines ?? this.curveLines,
        curveSmoothness: curveSmoothness.present
            ? curveSmoothness.value
            : this.curveSmoothness,
        durationEstimation: durationEstimation ?? this.durationEstimation,
        enableSound: enableSound ?? this.enableSound,
        explainedPermissions: explainedPermissions ?? this.explainedPermissions,
        groupHistory: groupHistory ?? this.groupHistory,
        id: id ?? this.id,
        longDateFormat: longDateFormat ?? this.longDateFormat,
        maxSets: maxSets ?? this.maxSets,
        notifications: notifications ?? this.notifications,
        peekGraph: peekGraph ?? this.peekGraph,
        planTrailing: planTrailing ?? this.planTrailing,
        repEstimation: repEstimation ?? this.repEstimation,
        restTimers: restTimers ?? this.restTimers,
        shortDateFormat: shortDateFormat ?? this.shortDateFormat,
        showCategories: showCategories ?? this.showCategories,
        showImages: showImages ?? this.showImages,
        showNotes: showNotes ?? this.showNotes,
        showGlobalProgress: showGlobalProgress ?? this.showGlobalProgress,
        showUnits: showUnits ?? this.showUnits,
        strengthUnit: strengthUnit ?? this.strengthUnit,
        systemColors: systemColors ?? this.systemColors,
        tabs: tabs ?? this.tabs,
        themeMode: themeMode ?? this.themeMode,
        timerDuration: timerDuration ?? this.timerDuration,
        vibrate: vibrate ?? this.vibrate,
        warmupSets: warmupSets.present ? warmupSets.value : this.warmupSets,
        scrollableTabs: scrollableTabs ?? this.scrollableTabs,
        fivethreeoneSquatTm: fivethreeoneSquatTm.present
            ? fivethreeoneSquatTm.value
            : this.fivethreeoneSquatTm,
        fivethreeoneBenchTm: fivethreeoneBenchTm.present
            ? fivethreeoneBenchTm.value
            : this.fivethreeoneBenchTm,
        fivethreeoneDeadliftTm: fivethreeoneDeadliftTm.present
            ? fivethreeoneDeadliftTm.value
            : this.fivethreeoneDeadliftTm,
        fivethreeonePressTm: fivethreeonePressTm.present
            ? fivethreeonePressTm.value
            : this.fivethreeonePressTm,
        fivethreeoneWeek: fivethreeoneWeek ?? this.fivethreeoneWeek,
        customColorSeed: customColorSeed ?? this.customColorSeed,
        lastAutoBackupTime: lastAutoBackupTime.present
            ? lastAutoBackupTime.value
            : this.lastAutoBackupTime,
        lastBackupStatus: lastBackupStatus.present
            ? lastBackupStatus.value
            : this.lastBackupStatus,
        spotifyAccessToken: spotifyAccessToken.present
            ? spotifyAccessToken.value
            : this.spotifyAccessToken,
        spotifyRefreshToken: spotifyRefreshToken.present
            ? spotifyRefreshToken.value
            : this.spotifyRefreshToken,
        spotifyTokenExpiry: spotifyTokenExpiry.present
            ? spotifyTokenExpiry.value
            : this.spotifyTokenExpiry,
        serverUrl: serverUrl.present ? serverUrl.value : this.serverUrl,
        serverApiKey:
            serverApiKey.present ? serverApiKey.value : this.serverApiKey,
        lastPushTime:
            lastPushTime.present ? lastPushTime.value : this.lastPushTime,
        lastPushStatus:
            lastPushStatus.present ? lastPushStatus.value : this.lastPushStatus,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      alarmSound:
          data.alarmSound.present ? data.alarmSound.value : this.alarmSound,
      automaticBackups: data.automaticBackups.present
          ? data.automaticBackups.value
          : this.automaticBackups,
      backupPath:
          data.backupPath.present ? data.backupPath.value : this.backupPath,
      cardioUnit:
          data.cardioUnit.present ? data.cardioUnit.value : this.cardioUnit,
      curveLines:
          data.curveLines.present ? data.curveLines.value : this.curveLines,
      curveSmoothness: data.curveSmoothness.present
          ? data.curveSmoothness.value
          : this.curveSmoothness,
      durationEstimation: data.durationEstimation.present
          ? data.durationEstimation.value
          : this.durationEstimation,
      enableSound:
          data.enableSound.present ? data.enableSound.value : this.enableSound,
      explainedPermissions: data.explainedPermissions.present
          ? data.explainedPermissions.value
          : this.explainedPermissions,
      groupHistory: data.groupHistory.present
          ? data.groupHistory.value
          : this.groupHistory,
      id: data.id.present ? data.id.value : this.id,
      longDateFormat: data.longDateFormat.present
          ? data.longDateFormat.value
          : this.longDateFormat,
      maxSets: data.maxSets.present ? data.maxSets.value : this.maxSets,
      notifications: data.notifications.present
          ? data.notifications.value
          : this.notifications,
      peekGraph: data.peekGraph.present ? data.peekGraph.value : this.peekGraph,
      planTrailing: data.planTrailing.present
          ? data.planTrailing.value
          : this.planTrailing,
      repEstimation: data.repEstimation.present
          ? data.repEstimation.value
          : this.repEstimation,
      restTimers:
          data.restTimers.present ? data.restTimers.value : this.restTimers,
      shortDateFormat: data.shortDateFormat.present
          ? data.shortDateFormat.value
          : this.shortDateFormat,
      showCategories: data.showCategories.present
          ? data.showCategories.value
          : this.showCategories,
      showImages:
          data.showImages.present ? data.showImages.value : this.showImages,
      showNotes: data.showNotes.present ? data.showNotes.value : this.showNotes,
      showGlobalProgress: data.showGlobalProgress.present
          ? data.showGlobalProgress.value
          : this.showGlobalProgress,
      showUnits: data.showUnits.present ? data.showUnits.value : this.showUnits,
      strengthUnit: data.strengthUnit.present
          ? data.strengthUnit.value
          : this.strengthUnit,
      systemColors: data.systemColors.present
          ? data.systemColors.value
          : this.systemColors,
      tabs: data.tabs.present ? data.tabs.value : this.tabs,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      timerDuration: data.timerDuration.present
          ? data.timerDuration.value
          : this.timerDuration,
      vibrate: data.vibrate.present ? data.vibrate.value : this.vibrate,
      warmupSets:
          data.warmupSets.present ? data.warmupSets.value : this.warmupSets,
      scrollableTabs: data.scrollableTabs.present
          ? data.scrollableTabs.value
          : this.scrollableTabs,
      fivethreeoneSquatTm: data.fivethreeoneSquatTm.present
          ? data.fivethreeoneSquatTm.value
          : this.fivethreeoneSquatTm,
      fivethreeoneBenchTm: data.fivethreeoneBenchTm.present
          ? data.fivethreeoneBenchTm.value
          : this.fivethreeoneBenchTm,
      fivethreeoneDeadliftTm: data.fivethreeoneDeadliftTm.present
          ? data.fivethreeoneDeadliftTm.value
          : this.fivethreeoneDeadliftTm,
      fivethreeonePressTm: data.fivethreeonePressTm.present
          ? data.fivethreeonePressTm.value
          : this.fivethreeonePressTm,
      fivethreeoneWeek: data.fivethreeoneWeek.present
          ? data.fivethreeoneWeek.value
          : this.fivethreeoneWeek,
      customColorSeed: data.customColorSeed.present
          ? data.customColorSeed.value
          : this.customColorSeed,
      lastAutoBackupTime: data.lastAutoBackupTime.present
          ? data.lastAutoBackupTime.value
          : this.lastAutoBackupTime,
      lastBackupStatus: data.lastBackupStatus.present
          ? data.lastBackupStatus.value
          : this.lastBackupStatus,
      spotifyAccessToken: data.spotifyAccessToken.present
          ? data.spotifyAccessToken.value
          : this.spotifyAccessToken,
      spotifyRefreshToken: data.spotifyRefreshToken.present
          ? data.spotifyRefreshToken.value
          : this.spotifyRefreshToken,
      spotifyTokenExpiry: data.spotifyTokenExpiry.present
          ? data.spotifyTokenExpiry.value
          : this.spotifyTokenExpiry,
      serverUrl: data.serverUrl.present ? data.serverUrl.value : this.serverUrl,
      serverApiKey: data.serverApiKey.present
          ? data.serverApiKey.value
          : this.serverApiKey,
      lastPushTime: data.lastPushTime.present
          ? data.lastPushTime.value
          : this.lastPushTime,
      lastPushStatus: data.lastPushStatus.present
          ? data.lastPushStatus.value
          : this.lastPushStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('alarmSound: $alarmSound, ')
          ..write('automaticBackups: $automaticBackups, ')
          ..write('backupPath: $backupPath, ')
          ..write('cardioUnit: $cardioUnit, ')
          ..write('curveLines: $curveLines, ')
          ..write('curveSmoothness: $curveSmoothness, ')
          ..write('durationEstimation: $durationEstimation, ')
          ..write('enableSound: $enableSound, ')
          ..write('explainedPermissions: $explainedPermissions, ')
          ..write('groupHistory: $groupHistory, ')
          ..write('id: $id, ')
          ..write('longDateFormat: $longDateFormat, ')
          ..write('maxSets: $maxSets, ')
          ..write('notifications: $notifications, ')
          ..write('peekGraph: $peekGraph, ')
          ..write('planTrailing: $planTrailing, ')
          ..write('repEstimation: $repEstimation, ')
          ..write('restTimers: $restTimers, ')
          ..write('shortDateFormat: $shortDateFormat, ')
          ..write('showCategories: $showCategories, ')
          ..write('showImages: $showImages, ')
          ..write('showNotes: $showNotes, ')
          ..write('showGlobalProgress: $showGlobalProgress, ')
          ..write('showUnits: $showUnits, ')
          ..write('strengthUnit: $strengthUnit, ')
          ..write('systemColors: $systemColors, ')
          ..write('tabs: $tabs, ')
          ..write('themeMode: $themeMode, ')
          ..write('timerDuration: $timerDuration, ')
          ..write('vibrate: $vibrate, ')
          ..write('warmupSets: $warmupSets, ')
          ..write('scrollableTabs: $scrollableTabs, ')
          ..write('fivethreeoneSquatTm: $fivethreeoneSquatTm, ')
          ..write('fivethreeoneBenchTm: $fivethreeoneBenchTm, ')
          ..write('fivethreeoneDeadliftTm: $fivethreeoneDeadliftTm, ')
          ..write('fivethreeonePressTm: $fivethreeonePressTm, ')
          ..write('fivethreeoneWeek: $fivethreeoneWeek, ')
          ..write('customColorSeed: $customColorSeed, ')
          ..write('lastAutoBackupTime: $lastAutoBackupTime, ')
          ..write('lastBackupStatus: $lastBackupStatus, ')
          ..write('spotifyAccessToken: $spotifyAccessToken, ')
          ..write('spotifyRefreshToken: $spotifyRefreshToken, ')
          ..write('spotifyTokenExpiry: $spotifyTokenExpiry, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('serverApiKey: $serverApiKey, ')
          ..write('lastPushTime: $lastPushTime, ')
          ..write('lastPushStatus: $lastPushStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        alarmSound,
        automaticBackups,
        backupPath,
        cardioUnit,
        curveLines,
        curveSmoothness,
        durationEstimation,
        enableSound,
        explainedPermissions,
        groupHistory,
        id,
        longDateFormat,
        maxSets,
        notifications,
        peekGraph,
        planTrailing,
        repEstimation,
        restTimers,
        shortDateFormat,
        showCategories,
        showImages,
        showNotes,
        showGlobalProgress,
        showUnits,
        strengthUnit,
        systemColors,
        tabs,
        themeMode,
        timerDuration,
        vibrate,
        warmupSets,
        scrollableTabs,
        fivethreeoneSquatTm,
        fivethreeoneBenchTm,
        fivethreeoneDeadliftTm,
        fivethreeonePressTm,
        fivethreeoneWeek,
        customColorSeed,
        lastAutoBackupTime,
        lastBackupStatus,
        spotifyAccessToken,
        spotifyRefreshToken,
        spotifyTokenExpiry,
        serverUrl,
        serverApiKey,
        lastPushTime,
        lastPushStatus
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.alarmSound == this.alarmSound &&
          other.automaticBackups == this.automaticBackups &&
          other.backupPath == this.backupPath &&
          other.cardioUnit == this.cardioUnit &&
          other.curveLines == this.curveLines &&
          other.curveSmoothness == this.curveSmoothness &&
          other.durationEstimation == this.durationEstimation &&
          other.enableSound == this.enableSound &&
          other.explainedPermissions == this.explainedPermissions &&
          other.groupHistory == this.groupHistory &&
          other.id == this.id &&
          other.longDateFormat == this.longDateFormat &&
          other.maxSets == this.maxSets &&
          other.notifications == this.notifications &&
          other.peekGraph == this.peekGraph &&
          other.planTrailing == this.planTrailing &&
          other.repEstimation == this.repEstimation &&
          other.restTimers == this.restTimers &&
          other.shortDateFormat == this.shortDateFormat &&
          other.showCategories == this.showCategories &&
          other.showImages == this.showImages &&
          other.showNotes == this.showNotes &&
          other.showGlobalProgress == this.showGlobalProgress &&
          other.showUnits == this.showUnits &&
          other.strengthUnit == this.strengthUnit &&
          other.systemColors == this.systemColors &&
          other.tabs == this.tabs &&
          other.themeMode == this.themeMode &&
          other.timerDuration == this.timerDuration &&
          other.vibrate == this.vibrate &&
          other.warmupSets == this.warmupSets &&
          other.scrollableTabs == this.scrollableTabs &&
          other.fivethreeoneSquatTm == this.fivethreeoneSquatTm &&
          other.fivethreeoneBenchTm == this.fivethreeoneBenchTm &&
          other.fivethreeoneDeadliftTm == this.fivethreeoneDeadliftTm &&
          other.fivethreeonePressTm == this.fivethreeonePressTm &&
          other.fivethreeoneWeek == this.fivethreeoneWeek &&
          other.customColorSeed == this.customColorSeed &&
          other.lastAutoBackupTime == this.lastAutoBackupTime &&
          other.lastBackupStatus == this.lastBackupStatus &&
          other.spotifyAccessToken == this.spotifyAccessToken &&
          other.spotifyRefreshToken == this.spotifyRefreshToken &&
          other.spotifyTokenExpiry == this.spotifyTokenExpiry &&
          other.serverUrl == this.serverUrl &&
          other.serverApiKey == this.serverApiKey &&
          other.lastPushTime == this.lastPushTime &&
          other.lastPushStatus == this.lastPushStatus);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> alarmSound;
  final Value<bool> automaticBackups;
  final Value<String?> backupPath;
  final Value<String> cardioUnit;
  final Value<bool> curveLines;
  final Value<double?> curveSmoothness;
  final Value<bool> durationEstimation;
  final Value<bool> enableSound;
  final Value<bool> explainedPermissions;
  final Value<bool> groupHistory;
  final Value<int> id;
  final Value<String> longDateFormat;
  final Value<int> maxSets;
  final Value<bool> notifications;
  final Value<bool> peekGraph;
  final Value<String> planTrailing;
  final Value<bool> repEstimation;
  final Value<bool> restTimers;
  final Value<String> shortDateFormat;
  final Value<bool> showCategories;
  final Value<bool> showImages;
  final Value<bool> showNotes;
  final Value<bool> showGlobalProgress;
  final Value<bool> showUnits;
  final Value<String> strengthUnit;
  final Value<bool> systemColors;
  final Value<String> tabs;
  final Value<String> themeMode;
  final Value<int> timerDuration;
  final Value<bool> vibrate;
  final Value<int?> warmupSets;
  final Value<bool> scrollableTabs;
  final Value<double?> fivethreeoneSquatTm;
  final Value<double?> fivethreeoneBenchTm;
  final Value<double?> fivethreeoneDeadliftTm;
  final Value<double?> fivethreeonePressTm;
  final Value<int> fivethreeoneWeek;
  final Value<int> customColorSeed;
  final Value<DateTime?> lastAutoBackupTime;
  final Value<String?> lastBackupStatus;
  final Value<String?> spotifyAccessToken;
  final Value<String?> spotifyRefreshToken;
  final Value<int?> spotifyTokenExpiry;
  final Value<String?> serverUrl;
  final Value<String?> serverApiKey;
  final Value<DateTime?> lastPushTime;
  final Value<String?> lastPushStatus;
  const SettingsCompanion({
    this.alarmSound = const Value.absent(),
    this.automaticBackups = const Value.absent(),
    this.backupPath = const Value.absent(),
    this.cardioUnit = const Value.absent(),
    this.curveLines = const Value.absent(),
    this.curveSmoothness = const Value.absent(),
    this.durationEstimation = const Value.absent(),
    this.enableSound = const Value.absent(),
    this.explainedPermissions = const Value.absent(),
    this.groupHistory = const Value.absent(),
    this.id = const Value.absent(),
    this.longDateFormat = const Value.absent(),
    this.maxSets = const Value.absent(),
    this.notifications = const Value.absent(),
    this.peekGraph = const Value.absent(),
    this.planTrailing = const Value.absent(),
    this.repEstimation = const Value.absent(),
    this.restTimers = const Value.absent(),
    this.shortDateFormat = const Value.absent(),
    this.showCategories = const Value.absent(),
    this.showImages = const Value.absent(),
    this.showNotes = const Value.absent(),
    this.showGlobalProgress = const Value.absent(),
    this.showUnits = const Value.absent(),
    this.strengthUnit = const Value.absent(),
    this.systemColors = const Value.absent(),
    this.tabs = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.timerDuration = const Value.absent(),
    this.vibrate = const Value.absent(),
    this.warmupSets = const Value.absent(),
    this.scrollableTabs = const Value.absent(),
    this.fivethreeoneSquatTm = const Value.absent(),
    this.fivethreeoneBenchTm = const Value.absent(),
    this.fivethreeoneDeadliftTm = const Value.absent(),
    this.fivethreeonePressTm = const Value.absent(),
    this.fivethreeoneWeek = const Value.absent(),
    this.customColorSeed = const Value.absent(),
    this.lastAutoBackupTime = const Value.absent(),
    this.lastBackupStatus = const Value.absent(),
    this.spotifyAccessToken = const Value.absent(),
    this.spotifyRefreshToken = const Value.absent(),
    this.spotifyTokenExpiry = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.serverApiKey = const Value.absent(),
    this.lastPushTime = const Value.absent(),
    this.lastPushStatus = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String alarmSound,
    this.automaticBackups = const Value.absent(),
    this.backupPath = const Value.absent(),
    required String cardioUnit,
    required bool curveLines,
    this.curveSmoothness = const Value.absent(),
    this.durationEstimation = const Value.absent(),
    this.enableSound = const Value.absent(),
    required bool explainedPermissions,
    this.groupHistory = const Value.absent(),
    this.id = const Value.absent(),
    required String longDateFormat,
    required int maxSets,
    this.notifications = const Value.absent(),
    this.peekGraph = const Value.absent(),
    required String planTrailing,
    this.repEstimation = const Value.absent(),
    required bool restTimers,
    required String shortDateFormat,
    this.showCategories = const Value.absent(),
    this.showImages = const Value.absent(),
    this.showNotes = const Value.absent(),
    this.showGlobalProgress = const Value.absent(),
    this.showUnits = const Value.absent(),
    required String strengthUnit,
    required bool systemColors,
    this.tabs = const Value.absent(),
    required String themeMode,
    required int timerDuration,
    required bool vibrate,
    this.warmupSets = const Value.absent(),
    this.scrollableTabs = const Value.absent(),
    this.fivethreeoneSquatTm = const Value.absent(),
    this.fivethreeoneBenchTm = const Value.absent(),
    this.fivethreeoneDeadliftTm = const Value.absent(),
    this.fivethreeonePressTm = const Value.absent(),
    this.fivethreeoneWeek = const Value.absent(),
    this.customColorSeed = const Value.absent(),
    this.lastAutoBackupTime = const Value.absent(),
    this.lastBackupStatus = const Value.absent(),
    this.spotifyAccessToken = const Value.absent(),
    this.spotifyRefreshToken = const Value.absent(),
    this.spotifyTokenExpiry = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.serverApiKey = const Value.absent(),
    this.lastPushTime = const Value.absent(),
    this.lastPushStatus = const Value.absent(),
  })  : alarmSound = Value(alarmSound),
        cardioUnit = Value(cardioUnit),
        curveLines = Value(curveLines),
        explainedPermissions = Value(explainedPermissions),
        longDateFormat = Value(longDateFormat),
        maxSets = Value(maxSets),
        planTrailing = Value(planTrailing),
        restTimers = Value(restTimers),
        shortDateFormat = Value(shortDateFormat),
        strengthUnit = Value(strengthUnit),
        systemColors = Value(systemColors),
        themeMode = Value(themeMode),
        timerDuration = Value(timerDuration),
        vibrate = Value(vibrate);
  static Insertable<Setting> custom({
    Expression<String>? alarmSound,
    Expression<bool>? automaticBackups,
    Expression<String>? backupPath,
    Expression<String>? cardioUnit,
    Expression<bool>? curveLines,
    Expression<double>? curveSmoothness,
    Expression<bool>? durationEstimation,
    Expression<bool>? enableSound,
    Expression<bool>? explainedPermissions,
    Expression<bool>? groupHistory,
    Expression<int>? id,
    Expression<String>? longDateFormat,
    Expression<int>? maxSets,
    Expression<bool>? notifications,
    Expression<bool>? peekGraph,
    Expression<String>? planTrailing,
    Expression<bool>? repEstimation,
    Expression<bool>? restTimers,
    Expression<String>? shortDateFormat,
    Expression<bool>? showCategories,
    Expression<bool>? showImages,
    Expression<bool>? showNotes,
    Expression<bool>? showGlobalProgress,
    Expression<bool>? showUnits,
    Expression<String>? strengthUnit,
    Expression<bool>? systemColors,
    Expression<String>? tabs,
    Expression<String>? themeMode,
    Expression<int>? timerDuration,
    Expression<bool>? vibrate,
    Expression<int>? warmupSets,
    Expression<bool>? scrollableTabs,
    Expression<double>? fivethreeoneSquatTm,
    Expression<double>? fivethreeoneBenchTm,
    Expression<double>? fivethreeoneDeadliftTm,
    Expression<double>? fivethreeonePressTm,
    Expression<int>? fivethreeoneWeek,
    Expression<int>? customColorSeed,
    Expression<DateTime>? lastAutoBackupTime,
    Expression<String>? lastBackupStatus,
    Expression<String>? spotifyAccessToken,
    Expression<String>? spotifyRefreshToken,
    Expression<int>? spotifyTokenExpiry,
    Expression<String>? serverUrl,
    Expression<String>? serverApiKey,
    Expression<DateTime>? lastPushTime,
    Expression<String>? lastPushStatus,
  }) {
    return RawValuesInsertable({
      if (alarmSound != null) 'alarm_sound': alarmSound,
      if (automaticBackups != null) 'automatic_backups': automaticBackups,
      if (backupPath != null) 'backup_path': backupPath,
      if (cardioUnit != null) 'cardio_unit': cardioUnit,
      if (curveLines != null) 'curve_lines': curveLines,
      if (curveSmoothness != null) 'curve_smoothness': curveSmoothness,
      if (durationEstimation != null) 'duration_estimation': durationEstimation,
      if (enableSound != null) 'enable_sound': enableSound,
      if (explainedPermissions != null)
        'explained_permissions': explainedPermissions,
      if (groupHistory != null) 'group_history': groupHistory,
      if (id != null) 'id': id,
      if (longDateFormat != null) 'long_date_format': longDateFormat,
      if (maxSets != null) 'max_sets': maxSets,
      if (notifications != null) 'notifications': notifications,
      if (peekGraph != null) 'peek_graph': peekGraph,
      if (planTrailing != null) 'plan_trailing': planTrailing,
      if (repEstimation != null) 'rep_estimation': repEstimation,
      if (restTimers != null) 'rest_timers': restTimers,
      if (shortDateFormat != null) 'short_date_format': shortDateFormat,
      if (showCategories != null) 'show_categories': showCategories,
      if (showImages != null) 'show_images': showImages,
      if (showNotes != null) 'show_notes': showNotes,
      if (showGlobalProgress != null)
        'show_global_progress': showGlobalProgress,
      if (showUnits != null) 'show_units': showUnits,
      if (strengthUnit != null) 'strength_unit': strengthUnit,
      if (systemColors != null) 'system_colors': systemColors,
      if (tabs != null) 'tabs': tabs,
      if (themeMode != null) 'theme_mode': themeMode,
      if (timerDuration != null) 'timer_duration': timerDuration,
      if (vibrate != null) 'vibrate': vibrate,
      if (warmupSets != null) 'warmup_sets': warmupSets,
      if (scrollableTabs != null) 'scrollable_tabs': scrollableTabs,
      if (fivethreeoneSquatTm != null)
        'fivethreeone_squat_tm': fivethreeoneSquatTm,
      if (fivethreeoneBenchTm != null)
        'fivethreeone_bench_tm': fivethreeoneBenchTm,
      if (fivethreeoneDeadliftTm != null)
        'fivethreeone_deadlift_tm': fivethreeoneDeadliftTm,
      if (fivethreeonePressTm != null)
        'fivethreeone_press_tm': fivethreeonePressTm,
      if (fivethreeoneWeek != null) 'fivethreeone_week': fivethreeoneWeek,
      if (customColorSeed != null) 'custom_color_seed': customColorSeed,
      if (lastAutoBackupTime != null)
        'last_auto_backup_time': lastAutoBackupTime,
      if (lastBackupStatus != null) 'last_backup_status': lastBackupStatus,
      if (spotifyAccessToken != null)
        'spotify_access_token': spotifyAccessToken,
      if (spotifyRefreshToken != null)
        'spotify_refresh_token': spotifyRefreshToken,
      if (spotifyTokenExpiry != null)
        'spotify_token_expiry': spotifyTokenExpiry,
      if (serverUrl != null) 'server_url': serverUrl,
      if (serverApiKey != null) 'server_api_key': serverApiKey,
      if (lastPushTime != null) 'last_push_time': lastPushTime,
      if (lastPushStatus != null) 'last_push_status': lastPushStatus,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? alarmSound,
      Value<bool>? automaticBackups,
      Value<String?>? backupPath,
      Value<String>? cardioUnit,
      Value<bool>? curveLines,
      Value<double?>? curveSmoothness,
      Value<bool>? durationEstimation,
      Value<bool>? enableSound,
      Value<bool>? explainedPermissions,
      Value<bool>? groupHistory,
      Value<int>? id,
      Value<String>? longDateFormat,
      Value<int>? maxSets,
      Value<bool>? notifications,
      Value<bool>? peekGraph,
      Value<String>? planTrailing,
      Value<bool>? repEstimation,
      Value<bool>? restTimers,
      Value<String>? shortDateFormat,
      Value<bool>? showCategories,
      Value<bool>? showImages,
      Value<bool>? showNotes,
      Value<bool>? showGlobalProgress,
      Value<bool>? showUnits,
      Value<String>? strengthUnit,
      Value<bool>? systemColors,
      Value<String>? tabs,
      Value<String>? themeMode,
      Value<int>? timerDuration,
      Value<bool>? vibrate,
      Value<int?>? warmupSets,
      Value<bool>? scrollableTabs,
      Value<double?>? fivethreeoneSquatTm,
      Value<double?>? fivethreeoneBenchTm,
      Value<double?>? fivethreeoneDeadliftTm,
      Value<double?>? fivethreeonePressTm,
      Value<int>? fivethreeoneWeek,
      Value<int>? customColorSeed,
      Value<DateTime?>? lastAutoBackupTime,
      Value<String?>? lastBackupStatus,
      Value<String?>? spotifyAccessToken,
      Value<String?>? spotifyRefreshToken,
      Value<int?>? spotifyTokenExpiry,
      Value<String?>? serverUrl,
      Value<String?>? serverApiKey,
      Value<DateTime?>? lastPushTime,
      Value<String?>? lastPushStatus}) {
    return SettingsCompanion(
      alarmSound: alarmSound ?? this.alarmSound,
      automaticBackups: automaticBackups ?? this.automaticBackups,
      backupPath: backupPath ?? this.backupPath,
      cardioUnit: cardioUnit ?? this.cardioUnit,
      curveLines: curveLines ?? this.curveLines,
      curveSmoothness: curveSmoothness ?? this.curveSmoothness,
      durationEstimation: durationEstimation ?? this.durationEstimation,
      enableSound: enableSound ?? this.enableSound,
      explainedPermissions: explainedPermissions ?? this.explainedPermissions,
      groupHistory: groupHistory ?? this.groupHistory,
      id: id ?? this.id,
      longDateFormat: longDateFormat ?? this.longDateFormat,
      maxSets: maxSets ?? this.maxSets,
      notifications: notifications ?? this.notifications,
      peekGraph: peekGraph ?? this.peekGraph,
      planTrailing: planTrailing ?? this.planTrailing,
      repEstimation: repEstimation ?? this.repEstimation,
      restTimers: restTimers ?? this.restTimers,
      shortDateFormat: shortDateFormat ?? this.shortDateFormat,
      showCategories: showCategories ?? this.showCategories,
      showImages: showImages ?? this.showImages,
      showNotes: showNotes ?? this.showNotes,
      showGlobalProgress: showGlobalProgress ?? this.showGlobalProgress,
      showUnits: showUnits ?? this.showUnits,
      strengthUnit: strengthUnit ?? this.strengthUnit,
      systemColors: systemColors ?? this.systemColors,
      tabs: tabs ?? this.tabs,
      themeMode: themeMode ?? this.themeMode,
      timerDuration: timerDuration ?? this.timerDuration,
      vibrate: vibrate ?? this.vibrate,
      warmupSets: warmupSets ?? this.warmupSets,
      scrollableTabs: scrollableTabs ?? this.scrollableTabs,
      fivethreeoneSquatTm: fivethreeoneSquatTm ?? this.fivethreeoneSquatTm,
      fivethreeoneBenchTm: fivethreeoneBenchTm ?? this.fivethreeoneBenchTm,
      fivethreeoneDeadliftTm:
          fivethreeoneDeadliftTm ?? this.fivethreeoneDeadliftTm,
      fivethreeonePressTm: fivethreeonePressTm ?? this.fivethreeonePressTm,
      fivethreeoneWeek: fivethreeoneWeek ?? this.fivethreeoneWeek,
      customColorSeed: customColorSeed ?? this.customColorSeed,
      lastAutoBackupTime: lastAutoBackupTime ?? this.lastAutoBackupTime,
      lastBackupStatus: lastBackupStatus ?? this.lastBackupStatus,
      spotifyAccessToken: spotifyAccessToken ?? this.spotifyAccessToken,
      spotifyRefreshToken: spotifyRefreshToken ?? this.spotifyRefreshToken,
      spotifyTokenExpiry: spotifyTokenExpiry ?? this.spotifyTokenExpiry,
      serverUrl: serverUrl ?? this.serverUrl,
      serverApiKey: serverApiKey ?? this.serverApiKey,
      lastPushTime: lastPushTime ?? this.lastPushTime,
      lastPushStatus: lastPushStatus ?? this.lastPushStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (alarmSound.present) {
      map['alarm_sound'] = Variable<String>(alarmSound.value);
    }
    if (automaticBackups.present) {
      map['automatic_backups'] = Variable<bool>(automaticBackups.value);
    }
    if (backupPath.present) {
      map['backup_path'] = Variable<String>(backupPath.value);
    }
    if (cardioUnit.present) {
      map['cardio_unit'] = Variable<String>(cardioUnit.value);
    }
    if (curveLines.present) {
      map['curve_lines'] = Variable<bool>(curveLines.value);
    }
    if (curveSmoothness.present) {
      map['curve_smoothness'] = Variable<double>(curveSmoothness.value);
    }
    if (durationEstimation.present) {
      map['duration_estimation'] = Variable<bool>(durationEstimation.value);
    }
    if (enableSound.present) {
      map['enable_sound'] = Variable<bool>(enableSound.value);
    }
    if (explainedPermissions.present) {
      map['explained_permissions'] = Variable<bool>(explainedPermissions.value);
    }
    if (groupHistory.present) {
      map['group_history'] = Variable<bool>(groupHistory.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (longDateFormat.present) {
      map['long_date_format'] = Variable<String>(longDateFormat.value);
    }
    if (maxSets.present) {
      map['max_sets'] = Variable<int>(maxSets.value);
    }
    if (notifications.present) {
      map['notifications'] = Variable<bool>(notifications.value);
    }
    if (peekGraph.present) {
      map['peek_graph'] = Variable<bool>(peekGraph.value);
    }
    if (planTrailing.present) {
      map['plan_trailing'] = Variable<String>(planTrailing.value);
    }
    if (repEstimation.present) {
      map['rep_estimation'] = Variable<bool>(repEstimation.value);
    }
    if (restTimers.present) {
      map['rest_timers'] = Variable<bool>(restTimers.value);
    }
    if (shortDateFormat.present) {
      map['short_date_format'] = Variable<String>(shortDateFormat.value);
    }
    if (showCategories.present) {
      map['show_categories'] = Variable<bool>(showCategories.value);
    }
    if (showImages.present) {
      map['show_images'] = Variable<bool>(showImages.value);
    }
    if (showNotes.present) {
      map['show_notes'] = Variable<bool>(showNotes.value);
    }
    if (showGlobalProgress.present) {
      map['show_global_progress'] = Variable<bool>(showGlobalProgress.value);
    }
    if (showUnits.present) {
      map['show_units'] = Variable<bool>(showUnits.value);
    }
    if (strengthUnit.present) {
      map['strength_unit'] = Variable<String>(strengthUnit.value);
    }
    if (systemColors.present) {
      map['system_colors'] = Variable<bool>(systemColors.value);
    }
    if (tabs.present) {
      map['tabs'] = Variable<String>(tabs.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (timerDuration.present) {
      map['timer_duration'] = Variable<int>(timerDuration.value);
    }
    if (vibrate.present) {
      map['vibrate'] = Variable<bool>(vibrate.value);
    }
    if (warmupSets.present) {
      map['warmup_sets'] = Variable<int>(warmupSets.value);
    }
    if (scrollableTabs.present) {
      map['scrollable_tabs'] = Variable<bool>(scrollableTabs.value);
    }
    if (fivethreeoneSquatTm.present) {
      map['fivethreeone_squat_tm'] =
          Variable<double>(fivethreeoneSquatTm.value);
    }
    if (fivethreeoneBenchTm.present) {
      map['fivethreeone_bench_tm'] =
          Variable<double>(fivethreeoneBenchTm.value);
    }
    if (fivethreeoneDeadliftTm.present) {
      map['fivethreeone_deadlift_tm'] =
          Variable<double>(fivethreeoneDeadliftTm.value);
    }
    if (fivethreeonePressTm.present) {
      map['fivethreeone_press_tm'] =
          Variable<double>(fivethreeonePressTm.value);
    }
    if (fivethreeoneWeek.present) {
      map['fivethreeone_week'] = Variable<int>(fivethreeoneWeek.value);
    }
    if (customColorSeed.present) {
      map['custom_color_seed'] = Variable<int>(customColorSeed.value);
    }
    if (lastAutoBackupTime.present) {
      map['last_auto_backup_time'] =
          Variable<DateTime>(lastAutoBackupTime.value);
    }
    if (lastBackupStatus.present) {
      map['last_backup_status'] = Variable<String>(lastBackupStatus.value);
    }
    if (spotifyAccessToken.present) {
      map['spotify_access_token'] = Variable<String>(spotifyAccessToken.value);
    }
    if (spotifyRefreshToken.present) {
      map['spotify_refresh_token'] =
          Variable<String>(spotifyRefreshToken.value);
    }
    if (spotifyTokenExpiry.present) {
      map['spotify_token_expiry'] = Variable<int>(spotifyTokenExpiry.value);
    }
    if (serverUrl.present) {
      map['server_url'] = Variable<String>(serverUrl.value);
    }
    if (serverApiKey.present) {
      map['server_api_key'] = Variable<String>(serverApiKey.value);
    }
    if (lastPushTime.present) {
      map['last_push_time'] = Variable<DateTime>(lastPushTime.value);
    }
    if (lastPushStatus.present) {
      map['last_push_status'] = Variable<String>(lastPushStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('alarmSound: $alarmSound, ')
          ..write('automaticBackups: $automaticBackups, ')
          ..write('backupPath: $backupPath, ')
          ..write('cardioUnit: $cardioUnit, ')
          ..write('curveLines: $curveLines, ')
          ..write('curveSmoothness: $curveSmoothness, ')
          ..write('durationEstimation: $durationEstimation, ')
          ..write('enableSound: $enableSound, ')
          ..write('explainedPermissions: $explainedPermissions, ')
          ..write('groupHistory: $groupHistory, ')
          ..write('id: $id, ')
          ..write('longDateFormat: $longDateFormat, ')
          ..write('maxSets: $maxSets, ')
          ..write('notifications: $notifications, ')
          ..write('peekGraph: $peekGraph, ')
          ..write('planTrailing: $planTrailing, ')
          ..write('repEstimation: $repEstimation, ')
          ..write('restTimers: $restTimers, ')
          ..write('shortDateFormat: $shortDateFormat, ')
          ..write('showCategories: $showCategories, ')
          ..write('showImages: $showImages, ')
          ..write('showNotes: $showNotes, ')
          ..write('showGlobalProgress: $showGlobalProgress, ')
          ..write('showUnits: $showUnits, ')
          ..write('strengthUnit: $strengthUnit, ')
          ..write('systemColors: $systemColors, ')
          ..write('tabs: $tabs, ')
          ..write('themeMode: $themeMode, ')
          ..write('timerDuration: $timerDuration, ')
          ..write('vibrate: $vibrate, ')
          ..write('warmupSets: $warmupSets, ')
          ..write('scrollableTabs: $scrollableTabs, ')
          ..write('fivethreeoneSquatTm: $fivethreeoneSquatTm, ')
          ..write('fivethreeoneBenchTm: $fivethreeoneBenchTm, ')
          ..write('fivethreeoneDeadliftTm: $fivethreeoneDeadliftTm, ')
          ..write('fivethreeonePressTm: $fivethreeonePressTm, ')
          ..write('fivethreeoneWeek: $fivethreeoneWeek, ')
          ..write('customColorSeed: $customColorSeed, ')
          ..write('lastAutoBackupTime: $lastAutoBackupTime, ')
          ..write('lastBackupStatus: $lastBackupStatus, ')
          ..write('spotifyAccessToken: $spotifyAccessToken, ')
          ..write('spotifyRefreshToken: $spotifyRefreshToken, ')
          ..write('spotifyTokenExpiry: $spotifyTokenExpiry, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('serverApiKey: $serverApiKey, ')
          ..write('lastPushTime: $lastPushTime, ')
          ..write('lastPushStatus: $lastPushStatus')
          ..write(')'))
        .toString();
  }
}

class $PlanExercisesTable extends PlanExercises
    with TableInfo<$PlanExercisesTable, PlanExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'));
  static const VerificationMeta _timersMeta = const VerificationMeta('timers');
  @override
  late final GeneratedColumn<bool> timers = GeneratedColumn<bool>(
      'timers', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("timers" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _exerciseMeta =
      const VerificationMeta('exercise');
  @override
  late final GeneratedColumn<String> exercise = GeneratedColumn<String>(
      'exercise', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES gym_sets (name)'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _maxSetsMeta =
      const VerificationMeta('maxSets');
  @override
  late final GeneratedColumn<int> maxSets = GeneratedColumn<int>(
      'max_sets', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
      'plan_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES plans (id)'));
  static const VerificationMeta _warmupSetsMeta =
      const VerificationMeta('warmupSets');
  @override
  late final GeneratedColumn<int> warmupSets = GeneratedColumn<int>(
      'warmup_sets', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sequenceMeta =
      const VerificationMeta('sequence');
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [enabled, timers, exercise, id, maxSets, planId, warmupSets, sequence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<PlanExercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('timers')) {
      context.handle(_timersMeta,
          timers.isAcceptableOrUnknown(data['timers']!, _timersMeta));
    }
    if (data.containsKey('exercise')) {
      context.handle(_exerciseMeta,
          exercise.isAcceptableOrUnknown(data['exercise']!, _exerciseMeta));
    } else if (isInserting) {
      context.missing(_exerciseMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('max_sets')) {
      context.handle(_maxSetsMeta,
          maxSets.isAcceptableOrUnknown(data['max_sets']!, _maxSetsMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('warmup_sets')) {
      context.handle(
          _warmupSetsMeta,
          warmupSets.isAcceptableOrUnknown(
              data['warmup_sets']!, _warmupSetsMeta));
    }
    if (data.containsKey('sequence')) {
      context.handle(_sequenceMeta,
          sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanExercise(
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      timers: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}timers'])!,
      exercise: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      maxSets: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_sets']),
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plan_id'])!,
      warmupSets: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}warmup_sets']),
      sequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence'])!,
    );
  }

  @override
  $PlanExercisesTable createAlias(String alias) {
    return $PlanExercisesTable(attachedDatabase, alias);
  }
}

class PlanExercise extends DataClass implements Insertable<PlanExercise> {
  final bool enabled;
  final bool timers;
  final String exercise;
  final int id;
  final int? maxSets;
  final int planId;
  final int? warmupSets;
  final int sequence;
  const PlanExercise(
      {required this.enabled,
      required this.timers,
      required this.exercise,
      required this.id,
      this.maxSets,
      required this.planId,
      this.warmupSets,
      required this.sequence});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['enabled'] = Variable<bool>(enabled);
    map['timers'] = Variable<bool>(timers);
    map['exercise'] = Variable<String>(exercise);
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || maxSets != null) {
      map['max_sets'] = Variable<int>(maxSets);
    }
    map['plan_id'] = Variable<int>(planId);
    if (!nullToAbsent || warmupSets != null) {
      map['warmup_sets'] = Variable<int>(warmupSets);
    }
    map['sequence'] = Variable<int>(sequence);
    return map;
  }

  PlanExercisesCompanion toCompanion(bool nullToAbsent) {
    return PlanExercisesCompanion(
      enabled: Value(enabled),
      timers: Value(timers),
      exercise: Value(exercise),
      id: Value(id),
      maxSets: maxSets == null && nullToAbsent
          ? const Value.absent()
          : Value(maxSets),
      planId: Value(planId),
      warmupSets: warmupSets == null && nullToAbsent
          ? const Value.absent()
          : Value(warmupSets),
      sequence: Value(sequence),
    );
  }

  factory PlanExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanExercise(
      enabled: serializer.fromJson<bool>(json['enabled']),
      timers: serializer.fromJson<bool>(json['timers']),
      exercise: serializer.fromJson<String>(json['exercise']),
      id: serializer.fromJson<int>(json['id']),
      maxSets: serializer.fromJson<int?>(json['maxSets']),
      planId: serializer.fromJson<int>(json['planId']),
      warmupSets: serializer.fromJson<int?>(json['warmupSets']),
      sequence: serializer.fromJson<int>(json['sequence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'enabled': serializer.toJson<bool>(enabled),
      'timers': serializer.toJson<bool>(timers),
      'exercise': serializer.toJson<String>(exercise),
      'id': serializer.toJson<int>(id),
      'maxSets': serializer.toJson<int?>(maxSets),
      'planId': serializer.toJson<int>(planId),
      'warmupSets': serializer.toJson<int?>(warmupSets),
      'sequence': serializer.toJson<int>(sequence),
    };
  }

  PlanExercise copyWith(
          {bool? enabled,
          bool? timers,
          String? exercise,
          int? id,
          Value<int?> maxSets = const Value.absent(),
          int? planId,
          Value<int?> warmupSets = const Value.absent(),
          int? sequence}) =>
      PlanExercise(
        enabled: enabled ?? this.enabled,
        timers: timers ?? this.timers,
        exercise: exercise ?? this.exercise,
        id: id ?? this.id,
        maxSets: maxSets.present ? maxSets.value : this.maxSets,
        planId: planId ?? this.planId,
        warmupSets: warmupSets.present ? warmupSets.value : this.warmupSets,
        sequence: sequence ?? this.sequence,
      );
  PlanExercise copyWithCompanion(PlanExercisesCompanion data) {
    return PlanExercise(
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      timers: data.timers.present ? data.timers.value : this.timers,
      exercise: data.exercise.present ? data.exercise.value : this.exercise,
      id: data.id.present ? data.id.value : this.id,
      maxSets: data.maxSets.present ? data.maxSets.value : this.maxSets,
      planId: data.planId.present ? data.planId.value : this.planId,
      warmupSets:
          data.warmupSets.present ? data.warmupSets.value : this.warmupSets,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanExercise(')
          ..write('enabled: $enabled, ')
          ..write('timers: $timers, ')
          ..write('exercise: $exercise, ')
          ..write('id: $id, ')
          ..write('maxSets: $maxSets, ')
          ..write('planId: $planId, ')
          ..write('warmupSets: $warmupSets, ')
          ..write('sequence: $sequence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      enabled, timers, exercise, id, maxSets, planId, warmupSets, sequence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanExercise &&
          other.enabled == this.enabled &&
          other.timers == this.timers &&
          other.exercise == this.exercise &&
          other.id == this.id &&
          other.maxSets == this.maxSets &&
          other.planId == this.planId &&
          other.warmupSets == this.warmupSets &&
          other.sequence == this.sequence);
}

class PlanExercisesCompanion extends UpdateCompanion<PlanExercise> {
  final Value<bool> enabled;
  final Value<bool> timers;
  final Value<String> exercise;
  final Value<int> id;
  final Value<int?> maxSets;
  final Value<int> planId;
  final Value<int?> warmupSets;
  final Value<int> sequence;
  const PlanExercisesCompanion({
    this.enabled = const Value.absent(),
    this.timers = const Value.absent(),
    this.exercise = const Value.absent(),
    this.id = const Value.absent(),
    this.maxSets = const Value.absent(),
    this.planId = const Value.absent(),
    this.warmupSets = const Value.absent(),
    this.sequence = const Value.absent(),
  });
  PlanExercisesCompanion.insert({
    required bool enabled,
    this.timers = const Value.absent(),
    required String exercise,
    this.id = const Value.absent(),
    this.maxSets = const Value.absent(),
    required int planId,
    this.warmupSets = const Value.absent(),
    this.sequence = const Value.absent(),
  })  : enabled = Value(enabled),
        exercise = Value(exercise),
        planId = Value(planId);
  static Insertable<PlanExercise> custom({
    Expression<bool>? enabled,
    Expression<bool>? timers,
    Expression<String>? exercise,
    Expression<int>? id,
    Expression<int>? maxSets,
    Expression<int>? planId,
    Expression<int>? warmupSets,
    Expression<int>? sequence,
  }) {
    return RawValuesInsertable({
      if (enabled != null) 'enabled': enabled,
      if (timers != null) 'timers': timers,
      if (exercise != null) 'exercise': exercise,
      if (id != null) 'id': id,
      if (maxSets != null) 'max_sets': maxSets,
      if (planId != null) 'plan_id': planId,
      if (warmupSets != null) 'warmup_sets': warmupSets,
      if (sequence != null) 'sequence': sequence,
    });
  }

  PlanExercisesCompanion copyWith(
      {Value<bool>? enabled,
      Value<bool>? timers,
      Value<String>? exercise,
      Value<int>? id,
      Value<int?>? maxSets,
      Value<int>? planId,
      Value<int?>? warmupSets,
      Value<int>? sequence}) {
    return PlanExercisesCompanion(
      enabled: enabled ?? this.enabled,
      timers: timers ?? this.timers,
      exercise: exercise ?? this.exercise,
      id: id ?? this.id,
      maxSets: maxSets ?? this.maxSets,
      planId: planId ?? this.planId,
      warmupSets: warmupSets ?? this.warmupSets,
      sequence: sequence ?? this.sequence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (timers.present) {
      map['timers'] = Variable<bool>(timers.value);
    }
    if (exercise.present) {
      map['exercise'] = Variable<String>(exercise.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (maxSets.present) {
      map['max_sets'] = Variable<int>(maxSets.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (warmupSets.present) {
      map['warmup_sets'] = Variable<int>(warmupSets.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanExercisesCompanion(')
          ..write('enabled: $enabled, ')
          ..write('timers: $timers, ')
          ..write('exercise: $exercise, ')
          ..write('id: $id, ')
          ..write('maxSets: $maxSets, ')
          ..write('planId: $planId, ')
          ..write('warmupSets: $warmupSets, ')
          ..write('sequence: $sequence')
          ..write(')'))
        .toString();
  }
}

class $MetadataTable extends Metadata
    with TableInfo<$MetadataTable, MetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _buildNumberMeta =
      const VerificationMeta('buildNumber');
  @override
  late final GeneratedColumn<int> buildNumber = GeneratedColumn<int>(
      'build_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [buildNumber];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metadata';
  @override
  VerificationContext validateIntegrity(Insertable<MetadataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('build_number')) {
      context.handle(
          _buildNumberMeta,
          buildNumber.isAcceptableOrUnknown(
              data['build_number']!, _buildNumberMeta));
    } else if (isInserting) {
      context.missing(_buildNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  MetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetadataData(
      buildNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}build_number'])!,
    );
  }

  @override
  $MetadataTable createAlias(String alias) {
    return $MetadataTable(attachedDatabase, alias);
  }
}

class MetadataData extends DataClass implements Insertable<MetadataData> {
  final int buildNumber;
  const MetadataData({required this.buildNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['build_number'] = Variable<int>(buildNumber);
    return map;
  }

  MetadataCompanion toCompanion(bool nullToAbsent) {
    return MetadataCompanion(
      buildNumber: Value(buildNumber),
    );
  }

  factory MetadataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetadataData(
      buildNumber: serializer.fromJson<int>(json['buildNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'buildNumber': serializer.toJson<int>(buildNumber),
    };
  }

  MetadataData copyWith({int? buildNumber}) => MetadataData(
        buildNumber: buildNumber ?? this.buildNumber,
      );
  MetadataData copyWithCompanion(MetadataCompanion data) {
    return MetadataData(
      buildNumber:
          data.buildNumber.present ? data.buildNumber.value : this.buildNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetadataData(')
          ..write('buildNumber: $buildNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => buildNumber.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetadataData && other.buildNumber == this.buildNumber);
}

class MetadataCompanion extends UpdateCompanion<MetadataData> {
  final Value<int> buildNumber;
  final Value<int> rowid;
  const MetadataCompanion({
    this.buildNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetadataCompanion.insert({
    required int buildNumber,
    this.rowid = const Value.absent(),
  }) : buildNumber = Value(buildNumber);
  static Insertable<MetadataData> custom({
    Expression<int>? buildNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (buildNumber != null) 'build_number': buildNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetadataCompanion copyWith({Value<int>? buildNumber, Value<int>? rowid}) {
    return MetadataCompanion(
      buildNumber: buildNumber ?? this.buildNumber,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (buildNumber.present) {
      map['build_number'] = Variable<int>(buildNumber.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetadataCompanion(')
          ..write('buildNumber: $buildNumber, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutsTable extends Workouts with TableInfo<$WorkoutsTable, Workout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
      'plan_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _selfieImagePathMeta =
      const VerificationMeta('selfieImagePath');
  @override
  late final GeneratedColumn<String> selfieImagePath = GeneratedColumn<String>(
      'selfie_image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, startTime, endTime, planId, name, notes, selfieImagePath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(Insertable<Workout> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('selfie_image_path')) {
      context.handle(
          _selfieImagePathMeta,
          selfieImagePath.isAcceptableOrUnknown(
              data['selfie_image_path']!, _selfieImagePathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workout(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plan_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      selfieImagePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}selfie_image_path']),
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class Workout extends DataClass implements Insertable<Workout> {
  final int id;
  final DateTime startTime;
  final DateTime? endTime;
  final int? planId;
  final String? name;
  final String? notes;
  final String? selfieImagePath;
  const Workout(
      {required this.id,
      required this.startTime,
      this.endTime,
      this.planId,
      this.name,
      this.notes,
      this.selfieImagePath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<int>(planId);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || selfieImagePath != null) {
      map['selfie_image_path'] = Variable<String>(selfieImagePath);
    }
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      planId:
          planId == null && nullToAbsent ? const Value.absent() : Value(planId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      selfieImagePath: selfieImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(selfieImagePath),
    );
  }

  factory Workout.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workout(
      id: serializer.fromJson<int>(json['id']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      planId: serializer.fromJson<int?>(json['planId']),
      name: serializer.fromJson<String?>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      selfieImagePath: serializer.fromJson<String?>(json['selfieImagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'planId': serializer.toJson<int?>(planId),
      'name': serializer.toJson<String?>(name),
      'notes': serializer.toJson<String?>(notes),
      'selfieImagePath': serializer.toJson<String?>(selfieImagePath),
    };
  }

  Workout copyWith(
          {int? id,
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          Value<int?> planId = const Value.absent(),
          Value<String?> name = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<String?> selfieImagePath = const Value.absent()}) =>
      Workout(
        id: id ?? this.id,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        planId: planId.present ? planId.value : this.planId,
        name: name.present ? name.value : this.name,
        notes: notes.present ? notes.value : this.notes,
        selfieImagePath: selfieImagePath.present
            ? selfieImagePath.value
            : this.selfieImagePath,
      );
  Workout copyWithCompanion(WorkoutsCompanion data) {
    return Workout(
      id: data.id.present ? data.id.value : this.id,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      planId: data.planId.present ? data.planId.value : this.planId,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      selfieImagePath: data.selfieImagePath.present
          ? data.selfieImagePath.value
          : this.selfieImagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workout(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('planId: $planId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('selfieImagePath: $selfieImagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startTime, endTime, planId, name, notes, selfieImagePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workout &&
          other.id == this.id &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.planId == this.planId &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.selfieImagePath == this.selfieImagePath);
}

class WorkoutsCompanion extends UpdateCompanion<Workout> {
  final Value<int> id;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int?> planId;
  final Value<String?> name;
  final Value<String?> notes;
  final Value<String?> selfieImagePath;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.planId = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.selfieImagePath = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.planId = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.selfieImagePath = const Value.absent(),
  }) : startTime = Value(startTime);
  static Insertable<Workout> custom({
    Expression<int>? id,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? planId,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<String>? selfieImagePath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (planId != null) 'plan_id': planId,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (selfieImagePath != null) 'selfie_image_path': selfieImagePath,
    });
  }

  WorkoutsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<int?>? planId,
      Value<String?>? name,
      Value<String?>? notes,
      Value<String?>? selfieImagePath}) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      selfieImagePath: selfieImagePath ?? this.selfieImagePath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (selfieImagePath.present) {
      map['selfie_image_path'] = Variable<String>(selfieImagePath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('planId: $planId, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('selfieImagePath: $selfieImagePath')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdMeta =
      const VerificationMeta('created');
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
      'created', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedMeta =
      const VerificationMeta('updated');
  @override
  late final GeneratedColumn<DateTime> updated = GeneratedColumn<DateTime>(
      'updated', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sequenceMeta =
      const VerificationMeta('sequence');
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, content, created, updated, color, sequence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<Note> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created')) {
      context.handle(_createdMeta,
          created.isAcceptableOrUnknown(data['created']!, _createdMeta));
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(_updatedMeta,
          updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta));
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('sequence')) {
      context.handle(_sequenceMeta,
          sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      created: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created'])!,
      updated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color']),
      sequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence']),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final String title;
  final String content;
  final DateTime created;
  final DateTime updated;
  final int? color;
  final int? sequence;
  const Note(
      {required this.id,
      required this.title,
      required this.content,
      required this.created,
      required this.updated,
      this.color,
      this.sequence});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['created'] = Variable<DateTime>(created);
    map['updated'] = Variable<DateTime>(updated);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || sequence != null) {
      map['sequence'] = Variable<int>(sequence);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      created: Value(created),
      updated: Value(updated),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      sequence: sequence == null && nullToAbsent
          ? const Value.absent()
          : Value(sequence),
    );
  }

  factory Note.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      created: serializer.fromJson<DateTime>(json['created']),
      updated: serializer.fromJson<DateTime>(json['updated']),
      color: serializer.fromJson<int?>(json['color']),
      sequence: serializer.fromJson<int?>(json['sequence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'created': serializer.toJson<DateTime>(created),
      'updated': serializer.toJson<DateTime>(updated),
      'color': serializer.toJson<int?>(color),
      'sequence': serializer.toJson<int?>(sequence),
    };
  }

  Note copyWith(
          {int? id,
          String? title,
          String? content,
          DateTime? created,
          DateTime? updated,
          Value<int?> color = const Value.absent(),
          Value<int?> sequence = const Value.absent()}) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        created: created ?? this.created,
        updated: updated ?? this.updated,
        color: color.present ? color.value : this.color,
        sequence: sequence.present ? sequence.value : this.sequence,
      );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      created: data.created.present ? data.created.value : this.created,
      updated: data.updated.present ? data.updated.value : this.updated,
      color: data.color.present ? data.color.value : this.color,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('created: $created, ')
          ..write('updated: $updated, ')
          ..write('color: $color, ')
          ..write('sequence: $sequence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, content, created, updated, color, sequence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.created == this.created &&
          other.updated == this.updated &&
          other.color == this.color &&
          other.sequence == this.sequence);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<DateTime> created;
  final Value<DateTime> updated;
  final Value<int?> color;
  final Value<int?> sequence;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.created = const Value.absent(),
    this.updated = const Value.absent(),
    this.color = const Value.absent(),
    this.sequence = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String content,
    required DateTime created,
    required DateTime updated,
    this.color = const Value.absent(),
    this.sequence = const Value.absent(),
  })  : title = Value(title),
        content = Value(content),
        created = Value(created),
        updated = Value(updated);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<DateTime>? created,
    Expression<DateTime>? updated,
    Expression<int>? color,
    Expression<int>? sequence,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (created != null) 'created': created,
      if (updated != null) 'updated': updated,
      if (color != null) 'color': color,
      if (sequence != null) 'sequence': sequence,
    });
  }

  NotesCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? content,
      Value<DateTime>? created,
      Value<DateTime>? updated,
      Value<int?>? color,
      Value<int?>? sequence}) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      color: color ?? this.color,
      sequence: sequence ?? this.sequence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (updated.present) {
      map['updated'] = Variable<DateTime>(updated.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('created: $created, ')
          ..write('updated: $updated, ')
          ..write('color: $color, ')
          ..write('sequence: $sequence')
          ..write(')'))
        .toString();
  }
}

class $BodyweightEntriesTable extends BodyweightEntries
    with TableInfo<$BodyweightEntriesTable, BodyweightEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyweightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, weight, unit, date, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bodyweight_entries';
  @override
  VerificationContext validateIntegrity(Insertable<BodyweightEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyweightEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyweightEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $BodyweightEntriesTable createAlias(String alias) {
    return $BodyweightEntriesTable(attachedDatabase, alias);
  }
}

class BodyweightEntry extends DataClass implements Insertable<BodyweightEntry> {
  final int id;
  final double weight;
  final String unit;
  final DateTime date;
  final String? notes;
  const BodyweightEntry(
      {required this.id,
      required this.weight,
      required this.unit,
      required this.date,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['weight'] = Variable<double>(weight);
    map['unit'] = Variable<String>(unit);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  BodyweightEntriesCompanion toCompanion(bool nullToAbsent) {
    return BodyweightEntriesCompanion(
      id: Value(id),
      weight: Value(weight),
      unit: Value(unit),
      date: Value(date),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory BodyweightEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyweightEntry(
      id: serializer.fromJson<int>(json['id']),
      weight: serializer.fromJson<double>(json['weight']),
      unit: serializer.fromJson<String>(json['unit']),
      date: serializer.fromJson<DateTime>(json['date']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weight': serializer.toJson<double>(weight),
      'unit': serializer.toJson<String>(unit),
      'date': serializer.toJson<DateTime>(date),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  BodyweightEntry copyWith(
          {int? id,
          double? weight,
          String? unit,
          DateTime? date,
          Value<String?> notes = const Value.absent()}) =>
      BodyweightEntry(
        id: id ?? this.id,
        weight: weight ?? this.weight,
        unit: unit ?? this.unit,
        date: date ?? this.date,
        notes: notes.present ? notes.value : this.notes,
      );
  BodyweightEntry copyWithCompanion(BodyweightEntriesCompanion data) {
    return BodyweightEntry(
      id: data.id.present ? data.id.value : this.id,
      weight: data.weight.present ? data.weight.value : this.weight,
      unit: data.unit.present ? data.unit.value : this.unit,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyweightEntry(')
          ..write('id: $id, ')
          ..write('weight: $weight, ')
          ..write('unit: $unit, ')
          ..write('date: $date, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, weight, unit, date, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyweightEntry &&
          other.id == this.id &&
          other.weight == this.weight &&
          other.unit == this.unit &&
          other.date == this.date &&
          other.notes == this.notes);
}

class BodyweightEntriesCompanion extends UpdateCompanion<BodyweightEntry> {
  final Value<int> id;
  final Value<double> weight;
  final Value<String> unit;
  final Value<DateTime> date;
  final Value<String?> notes;
  const BodyweightEntriesCompanion({
    this.id = const Value.absent(),
    this.weight = const Value.absent(),
    this.unit = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
  });
  BodyweightEntriesCompanion.insert({
    this.id = const Value.absent(),
    required double weight,
    required String unit,
    required DateTime date,
    this.notes = const Value.absent(),
  })  : weight = Value(weight),
        unit = Value(unit),
        date = Value(date);
  static Insertable<BodyweightEntry> custom({
    Expression<int>? id,
    Expression<double>? weight,
    Expression<String>? unit,
    Expression<DateTime>? date,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weight != null) 'weight': weight,
      if (unit != null) 'unit': unit,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
    });
  }

  BodyweightEntriesCompanion copyWith(
      {Value<int>? id,
      Value<double>? weight,
      Value<String>? unit,
      Value<DateTime>? date,
      Value<String?>? notes}) {
    return BodyweightEntriesCompanion(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyweightEntriesCompanion(')
          ..write('id: $id, ')
          ..write('weight: $weight, ')
          ..write('unit: $unit, ')
          ..write('date: $date, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $FiveThreeOneBlocksTable extends FiveThreeOneBlocks
    with TableInfo<$FiveThreeOneBlocksTable, FiveThreeOneBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FiveThreeOneBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _createdMeta =
      const VerificationMeta('created');
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
      'created', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _squatTmMeta =
      const VerificationMeta('squatTm');
  @override
  late final GeneratedColumn<double> squatTm = GeneratedColumn<double>(
      'squat_tm', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _benchTmMeta =
      const VerificationMeta('benchTm');
  @override
  late final GeneratedColumn<double> benchTm = GeneratedColumn<double>(
      'bench_tm', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _deadliftTmMeta =
      const VerificationMeta('deadliftTm');
  @override
  late final GeneratedColumn<double> deadliftTm = GeneratedColumn<double>(
      'deadlift_tm', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _pressTmMeta =
      const VerificationMeta('pressTm');
  @override
  late final GeneratedColumn<double> pressTm = GeneratedColumn<double>(
      'press_tm', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _startSquatTmMeta =
      const VerificationMeta('startSquatTm');
  @override
  late final GeneratedColumn<double> startSquatTm = GeneratedColumn<double>(
      'start_squat_tm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _startBenchTmMeta =
      const VerificationMeta('startBenchTm');
  @override
  late final GeneratedColumn<double> startBenchTm = GeneratedColumn<double>(
      'start_bench_tm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _startDeadliftTmMeta =
      const VerificationMeta('startDeadliftTm');
  @override
  late final GeneratedColumn<double> startDeadliftTm = GeneratedColumn<double>(
      'start_deadlift_tm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _startPressTmMeta =
      const VerificationMeta('startPressTm');
  @override
  late final GeneratedColumn<double> startPressTm = GeneratedColumn<double>(
      'start_press_tm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentCycleMeta =
      const VerificationMeta('currentCycle');
  @override
  late final GeneratedColumn<int> currentCycle = GeneratedColumn<int>(
      'current_cycle', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentWeekMeta =
      const VerificationMeta('currentWeek');
  @override
  late final GeneratedColumn<int> currentWeek = GeneratedColumn<int>(
      'current_week', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<DateTime> completed = GeneratedColumn<DateTime>(
      'completed', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        created,
        squatTm,
        benchTm,
        deadliftTm,
        pressTm,
        startSquatTm,
        startBenchTm,
        startDeadliftTm,
        startPressTm,
        unit,
        currentCycle,
        currentWeek,
        isActive,
        completed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'five_three_one_blocks';
  @override
  VerificationContext validateIntegrity(Insertable<FiveThreeOneBlock> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created')) {
      context.handle(_createdMeta,
          created.isAcceptableOrUnknown(data['created']!, _createdMeta));
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('squat_tm')) {
      context.handle(_squatTmMeta,
          squatTm.isAcceptableOrUnknown(data['squat_tm']!, _squatTmMeta));
    } else if (isInserting) {
      context.missing(_squatTmMeta);
    }
    if (data.containsKey('bench_tm')) {
      context.handle(_benchTmMeta,
          benchTm.isAcceptableOrUnknown(data['bench_tm']!, _benchTmMeta));
    } else if (isInserting) {
      context.missing(_benchTmMeta);
    }
    if (data.containsKey('deadlift_tm')) {
      context.handle(
          _deadliftTmMeta,
          deadliftTm.isAcceptableOrUnknown(
              data['deadlift_tm']!, _deadliftTmMeta));
    } else if (isInserting) {
      context.missing(_deadliftTmMeta);
    }
    if (data.containsKey('press_tm')) {
      context.handle(_pressTmMeta,
          pressTm.isAcceptableOrUnknown(data['press_tm']!, _pressTmMeta));
    } else if (isInserting) {
      context.missing(_pressTmMeta);
    }
    if (data.containsKey('start_squat_tm')) {
      context.handle(
          _startSquatTmMeta,
          startSquatTm.isAcceptableOrUnknown(
              data['start_squat_tm']!, _startSquatTmMeta));
    }
    if (data.containsKey('start_bench_tm')) {
      context.handle(
          _startBenchTmMeta,
          startBenchTm.isAcceptableOrUnknown(
              data['start_bench_tm']!, _startBenchTmMeta));
    }
    if (data.containsKey('start_deadlift_tm')) {
      context.handle(
          _startDeadliftTmMeta,
          startDeadliftTm.isAcceptableOrUnknown(
              data['start_deadlift_tm']!, _startDeadliftTmMeta));
    }
    if (data.containsKey('start_press_tm')) {
      context.handle(
          _startPressTmMeta,
          startPressTm.isAcceptableOrUnknown(
              data['start_press_tm']!, _startPressTmMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('current_cycle')) {
      context.handle(
          _currentCycleMeta,
          currentCycle.isAcceptableOrUnknown(
              data['current_cycle']!, _currentCycleMeta));
    }
    if (data.containsKey('current_week')) {
      context.handle(
          _currentWeekMeta,
          currentWeek.isAcceptableOrUnknown(
              data['current_week']!, _currentWeekMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FiveThreeOneBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FiveThreeOneBlock(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      created: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created'])!,
      squatTm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}squat_tm'])!,
      benchTm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bench_tm'])!,
      deadliftTm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}deadlift_tm'])!,
      pressTm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}press_tm'])!,
      startSquatTm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}start_squat_tm']),
      startBenchTm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}start_bench_tm']),
      startDeadliftTm: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}start_deadlift_tm']),
      startPressTm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}start_press_tm']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      currentCycle: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_cycle'])!,
      currentWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_week'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed']),
    );
  }

  @override
  $FiveThreeOneBlocksTable createAlias(String alias) {
    return $FiveThreeOneBlocksTable(attachedDatabase, alias);
  }
}

class FiveThreeOneBlock extends DataClass
    implements Insertable<FiveThreeOneBlock> {
  final int id;
  final DateTime created;
  final double squatTm;
  final double benchTm;
  final double deadliftTm;
  final double pressTm;
  final double? startSquatTm;
  final double? startBenchTm;
  final double? startDeadliftTm;
  final double? startPressTm;
  final String unit;

  /// 0=Leader1, 1=Leader2, 2=7th Week Deload, 3=Anchor, 4=TM Test
  final int currentCycle;

  /// 1-3 within each cycle (7th Week cycles only use week 1)
  final int currentWeek;
  final bool isActive;
  final DateTime? completed;
  const FiveThreeOneBlock(
      {required this.id,
      required this.created,
      required this.squatTm,
      required this.benchTm,
      required this.deadliftTm,
      required this.pressTm,
      this.startSquatTm,
      this.startBenchTm,
      this.startDeadliftTm,
      this.startPressTm,
      required this.unit,
      required this.currentCycle,
      required this.currentWeek,
      required this.isActive,
      this.completed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created'] = Variable<DateTime>(created);
    map['squat_tm'] = Variable<double>(squatTm);
    map['bench_tm'] = Variable<double>(benchTm);
    map['deadlift_tm'] = Variable<double>(deadliftTm);
    map['press_tm'] = Variable<double>(pressTm);
    if (!nullToAbsent || startSquatTm != null) {
      map['start_squat_tm'] = Variable<double>(startSquatTm);
    }
    if (!nullToAbsent || startBenchTm != null) {
      map['start_bench_tm'] = Variable<double>(startBenchTm);
    }
    if (!nullToAbsent || startDeadliftTm != null) {
      map['start_deadlift_tm'] = Variable<double>(startDeadliftTm);
    }
    if (!nullToAbsent || startPressTm != null) {
      map['start_press_tm'] = Variable<double>(startPressTm);
    }
    map['unit'] = Variable<String>(unit);
    map['current_cycle'] = Variable<int>(currentCycle);
    map['current_week'] = Variable<int>(currentWeek);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || completed != null) {
      map['completed'] = Variable<DateTime>(completed);
    }
    return map;
  }

  FiveThreeOneBlocksCompanion toCompanion(bool nullToAbsent) {
    return FiveThreeOneBlocksCompanion(
      id: Value(id),
      created: Value(created),
      squatTm: Value(squatTm),
      benchTm: Value(benchTm),
      deadliftTm: Value(deadliftTm),
      pressTm: Value(pressTm),
      startSquatTm: startSquatTm == null && nullToAbsent
          ? const Value.absent()
          : Value(startSquatTm),
      startBenchTm: startBenchTm == null && nullToAbsent
          ? const Value.absent()
          : Value(startBenchTm),
      startDeadliftTm: startDeadliftTm == null && nullToAbsent
          ? const Value.absent()
          : Value(startDeadliftTm),
      startPressTm: startPressTm == null && nullToAbsent
          ? const Value.absent()
          : Value(startPressTm),
      unit: Value(unit),
      currentCycle: Value(currentCycle),
      currentWeek: Value(currentWeek),
      isActive: Value(isActive),
      completed: completed == null && nullToAbsent
          ? const Value.absent()
          : Value(completed),
    );
  }

  factory FiveThreeOneBlock.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FiveThreeOneBlock(
      id: serializer.fromJson<int>(json['id']),
      created: serializer.fromJson<DateTime>(json['created']),
      squatTm: serializer.fromJson<double>(json['squatTm']),
      benchTm: serializer.fromJson<double>(json['benchTm']),
      deadliftTm: serializer.fromJson<double>(json['deadliftTm']),
      pressTm: serializer.fromJson<double>(json['pressTm']),
      startSquatTm: serializer.fromJson<double?>(json['startSquatTm']),
      startBenchTm: serializer.fromJson<double?>(json['startBenchTm']),
      startDeadliftTm: serializer.fromJson<double?>(json['startDeadliftTm']),
      startPressTm: serializer.fromJson<double?>(json['startPressTm']),
      unit: serializer.fromJson<String>(json['unit']),
      currentCycle: serializer.fromJson<int>(json['currentCycle']),
      currentWeek: serializer.fromJson<int>(json['currentWeek']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      completed: serializer.fromJson<DateTime?>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'created': serializer.toJson<DateTime>(created),
      'squatTm': serializer.toJson<double>(squatTm),
      'benchTm': serializer.toJson<double>(benchTm),
      'deadliftTm': serializer.toJson<double>(deadliftTm),
      'pressTm': serializer.toJson<double>(pressTm),
      'startSquatTm': serializer.toJson<double?>(startSquatTm),
      'startBenchTm': serializer.toJson<double?>(startBenchTm),
      'startDeadliftTm': serializer.toJson<double?>(startDeadliftTm),
      'startPressTm': serializer.toJson<double?>(startPressTm),
      'unit': serializer.toJson<String>(unit),
      'currentCycle': serializer.toJson<int>(currentCycle),
      'currentWeek': serializer.toJson<int>(currentWeek),
      'isActive': serializer.toJson<bool>(isActive),
      'completed': serializer.toJson<DateTime?>(completed),
    };
  }

  FiveThreeOneBlock copyWith(
          {int? id,
          DateTime? created,
          double? squatTm,
          double? benchTm,
          double? deadliftTm,
          double? pressTm,
          Value<double?> startSquatTm = const Value.absent(),
          Value<double?> startBenchTm = const Value.absent(),
          Value<double?> startDeadliftTm = const Value.absent(),
          Value<double?> startPressTm = const Value.absent(),
          String? unit,
          int? currentCycle,
          int? currentWeek,
          bool? isActive,
          Value<DateTime?> completed = const Value.absent()}) =>
      FiveThreeOneBlock(
        id: id ?? this.id,
        created: created ?? this.created,
        squatTm: squatTm ?? this.squatTm,
        benchTm: benchTm ?? this.benchTm,
        deadliftTm: deadliftTm ?? this.deadliftTm,
        pressTm: pressTm ?? this.pressTm,
        startSquatTm:
            startSquatTm.present ? startSquatTm.value : this.startSquatTm,
        startBenchTm:
            startBenchTm.present ? startBenchTm.value : this.startBenchTm,
        startDeadliftTm: startDeadliftTm.present
            ? startDeadliftTm.value
            : this.startDeadliftTm,
        startPressTm:
            startPressTm.present ? startPressTm.value : this.startPressTm,
        unit: unit ?? this.unit,
        currentCycle: currentCycle ?? this.currentCycle,
        currentWeek: currentWeek ?? this.currentWeek,
        isActive: isActive ?? this.isActive,
        completed: completed.present ? completed.value : this.completed,
      );
  FiveThreeOneBlock copyWithCompanion(FiveThreeOneBlocksCompanion data) {
    return FiveThreeOneBlock(
      id: data.id.present ? data.id.value : this.id,
      created: data.created.present ? data.created.value : this.created,
      squatTm: data.squatTm.present ? data.squatTm.value : this.squatTm,
      benchTm: data.benchTm.present ? data.benchTm.value : this.benchTm,
      deadliftTm:
          data.deadliftTm.present ? data.deadliftTm.value : this.deadliftTm,
      pressTm: data.pressTm.present ? data.pressTm.value : this.pressTm,
      startSquatTm: data.startSquatTm.present
          ? data.startSquatTm.value
          : this.startSquatTm,
      startBenchTm: data.startBenchTm.present
          ? data.startBenchTm.value
          : this.startBenchTm,
      startDeadliftTm: data.startDeadliftTm.present
          ? data.startDeadliftTm.value
          : this.startDeadliftTm,
      startPressTm: data.startPressTm.present
          ? data.startPressTm.value
          : this.startPressTm,
      unit: data.unit.present ? data.unit.value : this.unit,
      currentCycle: data.currentCycle.present
          ? data.currentCycle.value
          : this.currentCycle,
      currentWeek:
          data.currentWeek.present ? data.currentWeek.value : this.currentWeek,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FiveThreeOneBlock(')
          ..write('id: $id, ')
          ..write('created: $created, ')
          ..write('squatTm: $squatTm, ')
          ..write('benchTm: $benchTm, ')
          ..write('deadliftTm: $deadliftTm, ')
          ..write('pressTm: $pressTm, ')
          ..write('startSquatTm: $startSquatTm, ')
          ..write('startBenchTm: $startBenchTm, ')
          ..write('startDeadliftTm: $startDeadliftTm, ')
          ..write('startPressTm: $startPressTm, ')
          ..write('unit: $unit, ')
          ..write('currentCycle: $currentCycle, ')
          ..write('currentWeek: $currentWeek, ')
          ..write('isActive: $isActive, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      created,
      squatTm,
      benchTm,
      deadliftTm,
      pressTm,
      startSquatTm,
      startBenchTm,
      startDeadliftTm,
      startPressTm,
      unit,
      currentCycle,
      currentWeek,
      isActive,
      completed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiveThreeOneBlock &&
          other.id == this.id &&
          other.created == this.created &&
          other.squatTm == this.squatTm &&
          other.benchTm == this.benchTm &&
          other.deadliftTm == this.deadliftTm &&
          other.pressTm == this.pressTm &&
          other.startSquatTm == this.startSquatTm &&
          other.startBenchTm == this.startBenchTm &&
          other.startDeadliftTm == this.startDeadliftTm &&
          other.startPressTm == this.startPressTm &&
          other.unit == this.unit &&
          other.currentCycle == this.currentCycle &&
          other.currentWeek == this.currentWeek &&
          other.isActive == this.isActive &&
          other.completed == this.completed);
}

class FiveThreeOneBlocksCompanion extends UpdateCompanion<FiveThreeOneBlock> {
  final Value<int> id;
  final Value<DateTime> created;
  final Value<double> squatTm;
  final Value<double> benchTm;
  final Value<double> deadliftTm;
  final Value<double> pressTm;
  final Value<double?> startSquatTm;
  final Value<double?> startBenchTm;
  final Value<double?> startDeadliftTm;
  final Value<double?> startPressTm;
  final Value<String> unit;
  final Value<int> currentCycle;
  final Value<int> currentWeek;
  final Value<bool> isActive;
  final Value<DateTime?> completed;
  const FiveThreeOneBlocksCompanion({
    this.id = const Value.absent(),
    this.created = const Value.absent(),
    this.squatTm = const Value.absent(),
    this.benchTm = const Value.absent(),
    this.deadliftTm = const Value.absent(),
    this.pressTm = const Value.absent(),
    this.startSquatTm = const Value.absent(),
    this.startBenchTm = const Value.absent(),
    this.startDeadliftTm = const Value.absent(),
    this.startPressTm = const Value.absent(),
    this.unit = const Value.absent(),
    this.currentCycle = const Value.absent(),
    this.currentWeek = const Value.absent(),
    this.isActive = const Value.absent(),
    this.completed = const Value.absent(),
  });
  FiveThreeOneBlocksCompanion.insert({
    this.id = const Value.absent(),
    required DateTime created,
    required double squatTm,
    required double benchTm,
    required double deadliftTm,
    required double pressTm,
    this.startSquatTm = const Value.absent(),
    this.startBenchTm = const Value.absent(),
    this.startDeadliftTm = const Value.absent(),
    this.startPressTm = const Value.absent(),
    required String unit,
    this.currentCycle = const Value.absent(),
    this.currentWeek = const Value.absent(),
    this.isActive = const Value.absent(),
    this.completed = const Value.absent(),
  })  : created = Value(created),
        squatTm = Value(squatTm),
        benchTm = Value(benchTm),
        deadliftTm = Value(deadliftTm),
        pressTm = Value(pressTm),
        unit = Value(unit);
  static Insertable<FiveThreeOneBlock> custom({
    Expression<int>? id,
    Expression<DateTime>? created,
    Expression<double>? squatTm,
    Expression<double>? benchTm,
    Expression<double>? deadliftTm,
    Expression<double>? pressTm,
    Expression<double>? startSquatTm,
    Expression<double>? startBenchTm,
    Expression<double>? startDeadliftTm,
    Expression<double>? startPressTm,
    Expression<String>? unit,
    Expression<int>? currentCycle,
    Expression<int>? currentWeek,
    Expression<bool>? isActive,
    Expression<DateTime>? completed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (created != null) 'created': created,
      if (squatTm != null) 'squat_tm': squatTm,
      if (benchTm != null) 'bench_tm': benchTm,
      if (deadliftTm != null) 'deadlift_tm': deadliftTm,
      if (pressTm != null) 'press_tm': pressTm,
      if (startSquatTm != null) 'start_squat_tm': startSquatTm,
      if (startBenchTm != null) 'start_bench_tm': startBenchTm,
      if (startDeadliftTm != null) 'start_deadlift_tm': startDeadliftTm,
      if (startPressTm != null) 'start_press_tm': startPressTm,
      if (unit != null) 'unit': unit,
      if (currentCycle != null) 'current_cycle': currentCycle,
      if (currentWeek != null) 'current_week': currentWeek,
      if (isActive != null) 'is_active': isActive,
      if (completed != null) 'completed': completed,
    });
  }

  FiveThreeOneBlocksCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? created,
      Value<double>? squatTm,
      Value<double>? benchTm,
      Value<double>? deadliftTm,
      Value<double>? pressTm,
      Value<double?>? startSquatTm,
      Value<double?>? startBenchTm,
      Value<double?>? startDeadliftTm,
      Value<double?>? startPressTm,
      Value<String>? unit,
      Value<int>? currentCycle,
      Value<int>? currentWeek,
      Value<bool>? isActive,
      Value<DateTime?>? completed}) {
    return FiveThreeOneBlocksCompanion(
      id: id ?? this.id,
      created: created ?? this.created,
      squatTm: squatTm ?? this.squatTm,
      benchTm: benchTm ?? this.benchTm,
      deadliftTm: deadliftTm ?? this.deadliftTm,
      pressTm: pressTm ?? this.pressTm,
      startSquatTm: startSquatTm ?? this.startSquatTm,
      startBenchTm: startBenchTm ?? this.startBenchTm,
      startDeadliftTm: startDeadliftTm ?? this.startDeadliftTm,
      startPressTm: startPressTm ?? this.startPressTm,
      unit: unit ?? this.unit,
      currentCycle: currentCycle ?? this.currentCycle,
      currentWeek: currentWeek ?? this.currentWeek,
      isActive: isActive ?? this.isActive,
      completed: completed ?? this.completed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (squatTm.present) {
      map['squat_tm'] = Variable<double>(squatTm.value);
    }
    if (benchTm.present) {
      map['bench_tm'] = Variable<double>(benchTm.value);
    }
    if (deadliftTm.present) {
      map['deadlift_tm'] = Variable<double>(deadliftTm.value);
    }
    if (pressTm.present) {
      map['press_tm'] = Variable<double>(pressTm.value);
    }
    if (startSquatTm.present) {
      map['start_squat_tm'] = Variable<double>(startSquatTm.value);
    }
    if (startBenchTm.present) {
      map['start_bench_tm'] = Variable<double>(startBenchTm.value);
    }
    if (startDeadliftTm.present) {
      map['start_deadlift_tm'] = Variable<double>(startDeadliftTm.value);
    }
    if (startPressTm.present) {
      map['start_press_tm'] = Variable<double>(startPressTm.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (currentCycle.present) {
      map['current_cycle'] = Variable<int>(currentCycle.value);
    }
    if (currentWeek.present) {
      map['current_week'] = Variable<int>(currentWeek.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (completed.present) {
      map['completed'] = Variable<DateTime>(completed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FiveThreeOneBlocksCompanion(')
          ..write('id: $id, ')
          ..write('created: $created, ')
          ..write('squatTm: $squatTm, ')
          ..write('benchTm: $benchTm, ')
          ..write('deadliftTm: $deadliftTm, ')
          ..write('pressTm: $pressTm, ')
          ..write('startSquatTm: $startSquatTm, ')
          ..write('startBenchTm: $startBenchTm, ')
          ..write('startDeadliftTm: $startDeadliftTm, ')
          ..write('startPressTm: $startPressTm, ')
          ..write('unit: $unit, ')
          ..write('currentCycle: $currentCycle, ')
          ..write('currentWeek: $currentWeek, ')
          ..write('isActive: $isActive, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlansTable plans = $PlansTable(this);
  late final $GymSetsTable gymSets = $GymSetsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $PlanExercisesTable planExercises = $PlanExercisesTable(this);
  late final $MetadataTable metadata = $MetadataTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $BodyweightEntriesTable bodyweightEntries =
      $BodyweightEntriesTable(this);
  late final $FiveThreeOneBlocksTable fiveThreeOneBlocks =
      $FiveThreeOneBlocksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        plans,
        gymSets,
        settings,
        planExercises,
        metadata,
        workouts,
        notes,
        bodyweightEntries,
        fiveThreeOneBlocks
      ];
}

typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  required String days,
  Value<int> id,
  Value<int?> sequence,
  Value<String?> title,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<String> days,
  Value<int> id,
  Value<int?> sequence,
  Value<String?> title,
});

final class $$PlansTableReferences
    extends BaseReferences<_$AppDatabase, $PlansTable, Plan> {
  $$PlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlanExercisesTable, List<PlanExercise>>
      _planExercisesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.planExercises,
              aliasName:
                  $_aliasNameGenerator(db.plans.id, db.planExercises.planId));

  $$PlanExercisesTableProcessedTableManager get planExercisesRefs {
    final manager = $$PlanExercisesTableTableManager($_db, $_db.planExercises)
        .filter((f) => f.planId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_planExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PlansTableFilterComposer extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get days => $composableBuilder(
      column: $table.days, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  Expression<bool> planExercisesRefs(
      Expression<bool> Function($$PlanExercisesTableFilterComposer f) f) {
    final $$PlanExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planExercises,
        getReferencedColumn: (t) => t.planId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanExercisesTableFilterComposer(
              $db: $db,
              $table: $db.planExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlansTableOrderingComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get days => $composableBuilder(
      column: $table.days, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));
}

class $$PlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  Expression<T> planExercisesRefs<T extends Object>(
      Expression<T> Function($$PlanExercisesTableAnnotationComposer a) f) {
    final $$PlanExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.planExercises,
        getReferencedColumn: (t) => t.planId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.planExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlansTable,
    Plan,
    $$PlansTableFilterComposer,
    $$PlansTableOrderingComposer,
    $$PlansTableAnnotationComposer,
    $$PlansTableCreateCompanionBuilder,
    $$PlansTableUpdateCompanionBuilder,
    (Plan, $$PlansTableReferences),
    Plan,
    PrefetchHooks Function({bool planExercisesRefs})> {
  $$PlansTableTableManager(_$AppDatabase db, $PlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> days = const Value.absent(),
            Value<int> id = const Value.absent(),
            Value<int?> sequence = const Value.absent(),
            Value<String?> title = const Value.absent(),
          }) =>
              PlansCompanion(
            days: days,
            id: id,
            sequence: sequence,
            title: title,
          ),
          createCompanionCallback: ({
            required String days,
            Value<int> id = const Value.absent(),
            Value<int?> sequence = const Value.absent(),
            Value<String?> title = const Value.absent(),
          }) =>
              PlansCompanion.insert(
            days: days,
            id: id,
            sequence: sequence,
            title: title,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PlansTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({planExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (planExercisesRefs) db.planExercises
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (planExercisesRefs)
                    await $_getPrefetchedData<Plan, $PlansTable, PlanExercise>(
                        currentTable: table,
                        referencedTable:
                            $$PlansTableReferences._planExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PlansTableReferences(db, table, p0)
                                .planExercisesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.planId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlansTable,
    Plan,
    $$PlansTableFilterComposer,
    $$PlansTableOrderingComposer,
    $$PlansTableAnnotationComposer,
    $$PlansTableCreateCompanionBuilder,
    $$PlansTableUpdateCompanionBuilder,
    (Plan, $$PlansTableReferences),
    Plan,
    PrefetchHooks Function({bool planExercisesRefs})>;
typedef $$GymSetsTableCreateCompanionBuilder = GymSetsCompanion Function({
  Value<bool> cardio,
  Value<String?> category,
  required DateTime created,
  Value<double> distance,
  Value<double> duration,
  Value<bool> hidden,
  Value<int> id,
  Value<String?> image,
  Value<int?> incline,
  required String name,
  Value<String?> notes,
  Value<int?> planId,
  required double reps,
  Value<int?> restMs,
  Value<int> sequence,
  required String unit,
  Value<bool> warmup,
  required double weight,
  Value<int?> workoutId,
  Value<String?> exerciseType,
  Value<String?> brandName,
  Value<String?> cardioMetric,
  Value<bool> dropSet,
  Value<String?> supersetId,
  Value<int?> supersetPosition,
  Value<int?> setOrder,
});
typedef $$GymSetsTableUpdateCompanionBuilder = GymSetsCompanion Function({
  Value<bool> cardio,
  Value<String?> category,
  Value<DateTime> created,
  Value<double> distance,
  Value<double> duration,
  Value<bool> hidden,
  Value<int> id,
  Value<String?> image,
  Value<int?> incline,
  Value<String> name,
  Value<String?> notes,
  Value<int?> planId,
  Value<double> reps,
  Value<int?> restMs,
  Value<int> sequence,
  Value<String> unit,
  Value<bool> warmup,
  Value<double> weight,
  Value<int?> workoutId,
  Value<String?> exerciseType,
  Value<String?> brandName,
  Value<String?> cardioMetric,
  Value<bool> dropSet,
  Value<String?> supersetId,
  Value<int?> supersetPosition,
  Value<int?> setOrder,
});

final class $$GymSetsTableReferences
    extends BaseReferences<_$AppDatabase, $GymSetsTable, GymSet> {
  $$GymSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlanExercisesTable, List<PlanExercise>>
      _planExercisesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.planExercises,
              aliasName: $_aliasNameGenerator(
                  db.gymSets.name, db.planExercises.exercise));

  $$PlanExercisesTableProcessedTableManager get planExercisesRefs {
    final manager = $$PlanExercisesTableTableManager($_db, $_db.planExercises)
        .filter(
            (f) => f.exercise.name.sqlEquals($_itemColumn<String>('name')!));

    final cache = $_typedResult.readTableOrNull(_planExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$GymSetsTableFilterComposer
    extends Composer<_$AppDatabase, $GymSetsTable> {
  $$GymSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get cardio => $composableBuilder(
      column: $table.cardio, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hidden => $composableBuilder(
      column: $table.hidden, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get incline => $composableBuilder(
      column: $table.incline, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restMs => $composableBuilder(
      column: $table.restMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get warmup => $composableBuilder(
      column: $table.warmup, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get workoutId => $composableBuilder(
      column: $table.workoutId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseType => $composableBuilder(
      column: $table.exerciseType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get brandName => $composableBuilder(
      column: $table.brandName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardioMetric => $composableBuilder(
      column: $table.cardioMetric, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dropSet => $composableBuilder(
      column: $table.dropSet, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supersetId => $composableBuilder(
      column: $table.supersetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get supersetPosition => $composableBuilder(
      column: $table.supersetPosition,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get setOrder => $composableBuilder(
      column: $table.setOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> planExercisesRefs(
      Expression<bool> Function($$PlanExercisesTableFilterComposer f) f) {
    final $$PlanExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.name,
        referencedTable: $db.planExercises,
        getReferencedColumn: (t) => t.exercise,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanExercisesTableFilterComposer(
              $db: $db,
              $table: $db.planExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GymSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $GymSetsTable> {
  $$GymSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get cardio => $composableBuilder(
      column: $table.cardio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hidden => $composableBuilder(
      column: $table.hidden, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get incline => $composableBuilder(
      column: $table.incline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restMs => $composableBuilder(
      column: $table.restMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get warmup => $composableBuilder(
      column: $table.warmup, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get workoutId => $composableBuilder(
      column: $table.workoutId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseType => $composableBuilder(
      column: $table.exerciseType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get brandName => $composableBuilder(
      column: $table.brandName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardioMetric => $composableBuilder(
      column: $table.cardioMetric,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dropSet => $composableBuilder(
      column: $table.dropSet, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supersetId => $composableBuilder(
      column: $table.supersetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get supersetPosition => $composableBuilder(
      column: $table.supersetPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get setOrder => $composableBuilder(
      column: $table.setOrder, builder: (column) => ColumnOrderings(column));
}

class $$GymSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GymSetsTable> {
  $$GymSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get cardio =>
      $composableBuilder(column: $table.cardio, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<double> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<int> get incline =>
      $composableBuilder(column: $table.incline, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<double> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get restMs =>
      $composableBuilder(column: $table.restMs, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get warmup =>
      $composableBuilder(column: $table.warmup, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get workoutId =>
      $composableBuilder(column: $table.workoutId, builder: (column) => column);

  GeneratedColumn<String> get exerciseType => $composableBuilder(
      column: $table.exerciseType, builder: (column) => column);

  GeneratedColumn<String> get brandName =>
      $composableBuilder(column: $table.brandName, builder: (column) => column);

  GeneratedColumn<String> get cardioMetric => $composableBuilder(
      column: $table.cardioMetric, builder: (column) => column);

  GeneratedColumn<bool> get dropSet =>
      $composableBuilder(column: $table.dropSet, builder: (column) => column);

  GeneratedColumn<String> get supersetId => $composableBuilder(
      column: $table.supersetId, builder: (column) => column);

  GeneratedColumn<int> get supersetPosition => $composableBuilder(
      column: $table.supersetPosition, builder: (column) => column);

  GeneratedColumn<int> get setOrder =>
      $composableBuilder(column: $table.setOrder, builder: (column) => column);

  Expression<T> planExercisesRefs<T extends Object>(
      Expression<T> Function($$PlanExercisesTableAnnotationComposer a) f) {
    final $$PlanExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.name,
        referencedTable: $db.planExercises,
        getReferencedColumn: (t) => t.exercise,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlanExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.planExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GymSetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GymSetsTable,
    GymSet,
    $$GymSetsTableFilterComposer,
    $$GymSetsTableOrderingComposer,
    $$GymSetsTableAnnotationComposer,
    $$GymSetsTableCreateCompanionBuilder,
    $$GymSetsTableUpdateCompanionBuilder,
    (GymSet, $$GymSetsTableReferences),
    GymSet,
    PrefetchHooks Function({bool planExercisesRefs})> {
  $$GymSetsTableTableManager(_$AppDatabase db, $GymSetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GymSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GymSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GymSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<bool> cardio = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<DateTime> created = const Value.absent(),
            Value<double> distance = const Value.absent(),
            Value<double> duration = const Value.absent(),
            Value<bool> hidden = const Value.absent(),
            Value<int> id = const Value.absent(),
            Value<String?> image = const Value.absent(),
            Value<int?> incline = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int?> planId = const Value.absent(),
            Value<double> reps = const Value.absent(),
            Value<int?> restMs = const Value.absent(),
            Value<int> sequence = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<bool> warmup = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<int?> workoutId = const Value.absent(),
            Value<String?> exerciseType = const Value.absent(),
            Value<String?> brandName = const Value.absent(),
            Value<String?> cardioMetric = const Value.absent(),
            Value<bool> dropSet = const Value.absent(),
            Value<String?> supersetId = const Value.absent(),
            Value<int?> supersetPosition = const Value.absent(),
            Value<int?> setOrder = const Value.absent(),
          }) =>
              GymSetsCompanion(
            cardio: cardio,
            category: category,
            created: created,
            distance: distance,
            duration: duration,
            hidden: hidden,
            id: id,
            image: image,
            incline: incline,
            name: name,
            notes: notes,
            planId: planId,
            reps: reps,
            restMs: restMs,
            sequence: sequence,
            unit: unit,
            warmup: warmup,
            weight: weight,
            workoutId: workoutId,
            exerciseType: exerciseType,
            brandName: brandName,
            cardioMetric: cardioMetric,
            dropSet: dropSet,
            supersetId: supersetId,
            supersetPosition: supersetPosition,
            setOrder: setOrder,
          ),
          createCompanionCallback: ({
            Value<bool> cardio = const Value.absent(),
            Value<String?> category = const Value.absent(),
            required DateTime created,
            Value<double> distance = const Value.absent(),
            Value<double> duration = const Value.absent(),
            Value<bool> hidden = const Value.absent(),
            Value<int> id = const Value.absent(),
            Value<String?> image = const Value.absent(),
            Value<int?> incline = const Value.absent(),
            required String name,
            Value<String?> notes = const Value.absent(),
            Value<int?> planId = const Value.absent(),
            required double reps,
            Value<int?> restMs = const Value.absent(),
            Value<int> sequence = const Value.absent(),
            required String unit,
            Value<bool> warmup = const Value.absent(),
            required double weight,
            Value<int?> workoutId = const Value.absent(),
            Value<String?> exerciseType = const Value.absent(),
            Value<String?> brandName = const Value.absent(),
            Value<String?> cardioMetric = const Value.absent(),
            Value<bool> dropSet = const Value.absent(),
            Value<String?> supersetId = const Value.absent(),
            Value<int?> supersetPosition = const Value.absent(),
            Value<int?> setOrder = const Value.absent(),
          }) =>
              GymSetsCompanion.insert(
            cardio: cardio,
            category: category,
            created: created,
            distance: distance,
            duration: duration,
            hidden: hidden,
            id: id,
            image: image,
            incline: incline,
            name: name,
            notes: notes,
            planId: planId,
            reps: reps,
            restMs: restMs,
            sequence: sequence,
            unit: unit,
            warmup: warmup,
            weight: weight,
            workoutId: workoutId,
            exerciseType: exerciseType,
            brandName: brandName,
            cardioMetric: cardioMetric,
            dropSet: dropSet,
            supersetId: supersetId,
            supersetPosition: supersetPosition,
            setOrder: setOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GymSetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({planExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (planExercisesRefs) db.planExercises
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (planExercisesRefs)
                    await $_getPrefetchedData<GymSet, $GymSetsTable,
                            PlanExercise>(
                        currentTable: table,
                        referencedTable: $$GymSetsTableReferences
                            ._planExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GymSetsTableReferences(db, table, p0)
                                .planExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exercise == item.name),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$GymSetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GymSetsTable,
    GymSet,
    $$GymSetsTableFilterComposer,
    $$GymSetsTableOrderingComposer,
    $$GymSetsTableAnnotationComposer,
    $$GymSetsTableCreateCompanionBuilder,
    $$GymSetsTableUpdateCompanionBuilder,
    (GymSet, $$GymSetsTableReferences),
    GymSet,
    PrefetchHooks Function({bool planExercisesRefs})>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String alarmSound,
  Value<bool> automaticBackups,
  Value<String?> backupPath,
  required String cardioUnit,
  required bool curveLines,
  Value<double?> curveSmoothness,
  Value<bool> durationEstimation,
  Value<bool> enableSound,
  required bool explainedPermissions,
  Value<bool> groupHistory,
  Value<int> id,
  required String longDateFormat,
  required int maxSets,
  Value<bool> notifications,
  Value<bool> peekGraph,
  required String planTrailing,
  Value<bool> repEstimation,
  required bool restTimers,
  required String shortDateFormat,
  Value<bool> showCategories,
  Value<bool> showImages,
  Value<bool> showNotes,
  Value<bool> showGlobalProgress,
  Value<bool> showUnits,
  required String strengthUnit,
  required bool systemColors,
  Value<String> tabs,
  required String themeMode,
  required int timerDuration,
  required bool vibrate,
  Value<int?> warmupSets,
  Value<bool> scrollableTabs,
  Value<double?> fivethreeoneSquatTm,
  Value<double?> fivethreeoneBenchTm,
  Value<double?> fivethreeoneDeadliftTm,
  Value<double?> fivethreeonePressTm,
  Value<int> fivethreeoneWeek,
  Value<int> customColorSeed,
  Value<DateTime?> lastAutoBackupTime,
  Value<String?> lastBackupStatus,
  Value<String?> spotifyAccessToken,
  Value<String?> spotifyRefreshToken,
  Value<int?> spotifyTokenExpiry,
  Value<String?> serverUrl,
  Value<String?> serverApiKey,
  Value<DateTime?> lastPushTime,
  Value<String?> lastPushStatus,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> alarmSound,
  Value<bool> automaticBackups,
  Value<String?> backupPath,
  Value<String> cardioUnit,
  Value<bool> curveLines,
  Value<double?> curveSmoothness,
  Value<bool> durationEstimation,
  Value<bool> enableSound,
  Value<bool> explainedPermissions,
  Value<bool> groupHistory,
  Value<int> id,
  Value<String> longDateFormat,
  Value<int> maxSets,
  Value<bool> notifications,
  Value<bool> peekGraph,
  Value<String> planTrailing,
  Value<bool> repEstimation,
  Value<bool> restTimers,
  Value<String> shortDateFormat,
  Value<bool> showCategories,
  Value<bool> showImages,
  Value<bool> showNotes,
  Value<bool> showGlobalProgress,
  Value<bool> showUnits,
  Value<String> strengthUnit,
  Value<bool> systemColors,
  Value<String> tabs,
  Value<String> themeMode,
  Value<int> timerDuration,
  Value<bool> vibrate,
  Value<int?> warmupSets,
  Value<bool> scrollableTabs,
  Value<double?> fivethreeoneSquatTm,
  Value<double?> fivethreeoneBenchTm,
  Value<double?> fivethreeoneDeadliftTm,
  Value<double?> fivethreeonePressTm,
  Value<int> fivethreeoneWeek,
  Value<int> customColorSeed,
  Value<DateTime?> lastAutoBackupTime,
  Value<String?> lastBackupStatus,
  Value<String?> spotifyAccessToken,
  Value<String?> spotifyRefreshToken,
  Value<int?> spotifyTokenExpiry,
  Value<String?> serverUrl,
  Value<String?> serverApiKey,
  Value<DateTime?> lastPushTime,
  Value<String?> lastPushStatus,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get alarmSound => $composableBuilder(
      column: $table.alarmSound, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get automaticBackups => $composableBuilder(
      column: $table.automaticBackups,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backupPath => $composableBuilder(
      column: $table.backupPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardioUnit => $composableBuilder(
      column: $table.cardioUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get curveLines => $composableBuilder(
      column: $table.curveLines, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get curveSmoothness => $composableBuilder(
      column: $table.curveSmoothness,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get durationEstimation => $composableBuilder(
      column: $table.durationEstimation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enableSound => $composableBuilder(
      column: $table.enableSound, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get explainedPermissions => $composableBuilder(
      column: $table.explainedPermissions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get groupHistory => $composableBuilder(
      column: $table.groupHistory, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get longDateFormat => $composableBuilder(
      column: $table.longDateFormat,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxSets => $composableBuilder(
      column: $table.maxSets, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notifications => $composableBuilder(
      column: $table.notifications, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get peekGraph => $composableBuilder(
      column: $table.peekGraph, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planTrailing => $composableBuilder(
      column: $table.planTrailing, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get repEstimation => $composableBuilder(
      column: $table.repEstimation, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get restTimers => $composableBuilder(
      column: $table.restTimers, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shortDateFormat => $composableBuilder(
      column: $table.shortDateFormat,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showCategories => $composableBuilder(
      column: $table.showCategories,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showImages => $composableBuilder(
      column: $table.showImages, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showNotes => $composableBuilder(
      column: $table.showNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showGlobalProgress => $composableBuilder(
      column: $table.showGlobalProgress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showUnits => $composableBuilder(
      column: $table.showUnits, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get strengthUnit => $composableBuilder(
      column: $table.strengthUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get systemColors => $composableBuilder(
      column: $table.systemColors, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tabs => $composableBuilder(
      column: $table.tabs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timerDuration => $composableBuilder(
      column: $table.timerDuration, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get vibrate => $composableBuilder(
      column: $table.vibrate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get warmupSets => $composableBuilder(
      column: $table.warmupSets, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get scrollableTabs => $composableBuilder(
      column: $table.scrollableTabs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fivethreeoneSquatTm => $composableBuilder(
      column: $table.fivethreeoneSquatTm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fivethreeoneBenchTm => $composableBuilder(
      column: $table.fivethreeoneBenchTm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fivethreeoneDeadliftTm => $composableBuilder(
      column: $table.fivethreeoneDeadliftTm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fivethreeonePressTm => $composableBuilder(
      column: $table.fivethreeonePressTm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fivethreeoneWeek => $composableBuilder(
      column: $table.fivethreeoneWeek,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get customColorSeed => $composableBuilder(
      column: $table.customColorSeed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAutoBackupTime => $composableBuilder(
      column: $table.lastAutoBackupTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastBackupStatus => $composableBuilder(
      column: $table.lastBackupStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get spotifyAccessToken => $composableBuilder(
      column: $table.spotifyAccessToken,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get spotifyRefreshToken => $composableBuilder(
      column: $table.spotifyRefreshToken,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get spotifyTokenExpiry => $composableBuilder(
      column: $table.spotifyTokenExpiry,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverUrl => $composableBuilder(
      column: $table.serverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverApiKey => $composableBuilder(
      column: $table.serverApiKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPushTime => $composableBuilder(
      column: $table.lastPushTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastPushStatus => $composableBuilder(
      column: $table.lastPushStatus,
      builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get alarmSound => $composableBuilder(
      column: $table.alarmSound, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get automaticBackups => $composableBuilder(
      column: $table.automaticBackups,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backupPath => $composableBuilder(
      column: $table.backupPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardioUnit => $composableBuilder(
      column: $table.cardioUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get curveLines => $composableBuilder(
      column: $table.curveLines, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get curveSmoothness => $composableBuilder(
      column: $table.curveSmoothness,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get durationEstimation => $composableBuilder(
      column: $table.durationEstimation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enableSound => $composableBuilder(
      column: $table.enableSound, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get explainedPermissions => $composableBuilder(
      column: $table.explainedPermissions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get groupHistory => $composableBuilder(
      column: $table.groupHistory,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get longDateFormat => $composableBuilder(
      column: $table.longDateFormat,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxSets => $composableBuilder(
      column: $table.maxSets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notifications => $composableBuilder(
      column: $table.notifications,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get peekGraph => $composableBuilder(
      column: $table.peekGraph, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planTrailing => $composableBuilder(
      column: $table.planTrailing,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get repEstimation => $composableBuilder(
      column: $table.repEstimation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get restTimers => $composableBuilder(
      column: $table.restTimers, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shortDateFormat => $composableBuilder(
      column: $table.shortDateFormat,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showCategories => $composableBuilder(
      column: $table.showCategories,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showImages => $composableBuilder(
      column: $table.showImages, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showNotes => $composableBuilder(
      column: $table.showNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showGlobalProgress => $composableBuilder(
      column: $table.showGlobalProgress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showUnits => $composableBuilder(
      column: $table.showUnits, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get strengthUnit => $composableBuilder(
      column: $table.strengthUnit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get systemColors => $composableBuilder(
      column: $table.systemColors,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tabs => $composableBuilder(
      column: $table.tabs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timerDuration => $composableBuilder(
      column: $table.timerDuration,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get vibrate => $composableBuilder(
      column: $table.vibrate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get warmupSets => $composableBuilder(
      column: $table.warmupSets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get scrollableTabs => $composableBuilder(
      column: $table.scrollableTabs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fivethreeoneSquatTm => $composableBuilder(
      column: $table.fivethreeoneSquatTm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fivethreeoneBenchTm => $composableBuilder(
      column: $table.fivethreeoneBenchTm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fivethreeoneDeadliftTm => $composableBuilder(
      column: $table.fivethreeoneDeadliftTm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fivethreeonePressTm => $composableBuilder(
      column: $table.fivethreeonePressTm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fivethreeoneWeek => $composableBuilder(
      column: $table.fivethreeoneWeek,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get customColorSeed => $composableBuilder(
      column: $table.customColorSeed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAutoBackupTime => $composableBuilder(
      column: $table.lastAutoBackupTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastBackupStatus => $composableBuilder(
      column: $table.lastBackupStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get spotifyAccessToken => $composableBuilder(
      column: $table.spotifyAccessToken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get spotifyRefreshToken => $composableBuilder(
      column: $table.spotifyRefreshToken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get spotifyTokenExpiry => $composableBuilder(
      column: $table.spotifyTokenExpiry,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverUrl => $composableBuilder(
      column: $table.serverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverApiKey => $composableBuilder(
      column: $table.serverApiKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPushTime => $composableBuilder(
      column: $table.lastPushTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastPushStatus => $composableBuilder(
      column: $table.lastPushStatus,
      builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get alarmSound => $composableBuilder(
      column: $table.alarmSound, builder: (column) => column);

  GeneratedColumn<bool> get automaticBackups => $composableBuilder(
      column: $table.automaticBackups, builder: (column) => column);

  GeneratedColumn<String> get backupPath => $composableBuilder(
      column: $table.backupPath, builder: (column) => column);

  GeneratedColumn<String> get cardioUnit => $composableBuilder(
      column: $table.cardioUnit, builder: (column) => column);

  GeneratedColumn<bool> get curveLines => $composableBuilder(
      column: $table.curveLines, builder: (column) => column);

  GeneratedColumn<double> get curveSmoothness => $composableBuilder(
      column: $table.curveSmoothness, builder: (column) => column);

  GeneratedColumn<bool> get durationEstimation => $composableBuilder(
      column: $table.durationEstimation, builder: (column) => column);

  GeneratedColumn<bool> get enableSound => $composableBuilder(
      column: $table.enableSound, builder: (column) => column);

  GeneratedColumn<bool> get explainedPermissions => $composableBuilder(
      column: $table.explainedPermissions, builder: (column) => column);

  GeneratedColumn<bool> get groupHistory => $composableBuilder(
      column: $table.groupHistory, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get longDateFormat => $composableBuilder(
      column: $table.longDateFormat, builder: (column) => column);

  GeneratedColumn<int> get maxSets =>
      $composableBuilder(column: $table.maxSets, builder: (column) => column);

  GeneratedColumn<bool> get notifications => $composableBuilder(
      column: $table.notifications, builder: (column) => column);

  GeneratedColumn<bool> get peekGraph =>
      $composableBuilder(column: $table.peekGraph, builder: (column) => column);

  GeneratedColumn<String> get planTrailing => $composableBuilder(
      column: $table.planTrailing, builder: (column) => column);

  GeneratedColumn<bool> get repEstimation => $composableBuilder(
      column: $table.repEstimation, builder: (column) => column);

  GeneratedColumn<bool> get restTimers => $composableBuilder(
      column: $table.restTimers, builder: (column) => column);

  GeneratedColumn<String> get shortDateFormat => $composableBuilder(
      column: $table.shortDateFormat, builder: (column) => column);

  GeneratedColumn<bool> get showCategories => $composableBuilder(
      column: $table.showCategories, builder: (column) => column);

  GeneratedColumn<bool> get showImages => $composableBuilder(
      column: $table.showImages, builder: (column) => column);

  GeneratedColumn<bool> get showNotes =>
      $composableBuilder(column: $table.showNotes, builder: (column) => column);

  GeneratedColumn<bool> get showGlobalProgress => $composableBuilder(
      column: $table.showGlobalProgress, builder: (column) => column);

  GeneratedColumn<bool> get showUnits =>
      $composableBuilder(column: $table.showUnits, builder: (column) => column);

  GeneratedColumn<String> get strengthUnit => $composableBuilder(
      column: $table.strengthUnit, builder: (column) => column);

  GeneratedColumn<bool> get systemColors => $composableBuilder(
      column: $table.systemColors, builder: (column) => column);

  GeneratedColumn<String> get tabs =>
      $composableBuilder(column: $table.tabs, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<int> get timerDuration => $composableBuilder(
      column: $table.timerDuration, builder: (column) => column);

  GeneratedColumn<bool> get vibrate =>
      $composableBuilder(column: $table.vibrate, builder: (column) => column);

  GeneratedColumn<int> get warmupSets => $composableBuilder(
      column: $table.warmupSets, builder: (column) => column);

  GeneratedColumn<bool> get scrollableTabs => $composableBuilder(
      column: $table.scrollableTabs, builder: (column) => column);

  GeneratedColumn<double> get fivethreeoneSquatTm => $composableBuilder(
      column: $table.fivethreeoneSquatTm, builder: (column) => column);

  GeneratedColumn<double> get fivethreeoneBenchTm => $composableBuilder(
      column: $table.fivethreeoneBenchTm, builder: (column) => column);

  GeneratedColumn<double> get fivethreeoneDeadliftTm => $composableBuilder(
      column: $table.fivethreeoneDeadliftTm, builder: (column) => column);

  GeneratedColumn<double> get fivethreeonePressTm => $composableBuilder(
      column: $table.fivethreeonePressTm, builder: (column) => column);

  GeneratedColumn<int> get fivethreeoneWeek => $composableBuilder(
      column: $table.fivethreeoneWeek, builder: (column) => column);

  GeneratedColumn<int> get customColorSeed => $composableBuilder(
      column: $table.customColorSeed, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAutoBackupTime => $composableBuilder(
      column: $table.lastAutoBackupTime, builder: (column) => column);

  GeneratedColumn<String> get lastBackupStatus => $composableBuilder(
      column: $table.lastBackupStatus, builder: (column) => column);

  GeneratedColumn<String> get spotifyAccessToken => $composableBuilder(
      column: $table.spotifyAccessToken, builder: (column) => column);

  GeneratedColumn<String> get spotifyRefreshToken => $composableBuilder(
      column: $table.spotifyRefreshToken, builder: (column) => column);

  GeneratedColumn<int> get spotifyTokenExpiry => $composableBuilder(
      column: $table.spotifyTokenExpiry, builder: (column) => column);

  GeneratedColumn<String> get serverUrl =>
      $composableBuilder(column: $table.serverUrl, builder: (column) => column);

  GeneratedColumn<String> get serverApiKey => $composableBuilder(
      column: $table.serverApiKey, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPushTime => $composableBuilder(
      column: $table.lastPushTime, builder: (column) => column);

  GeneratedColumn<String> get lastPushStatus => $composableBuilder(
      column: $table.lastPushStatus, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> alarmSound = const Value.absent(),
            Value<bool> automaticBackups = const Value.absent(),
            Value<String?> backupPath = const Value.absent(),
            Value<String> cardioUnit = const Value.absent(),
            Value<bool> curveLines = const Value.absent(),
            Value<double?> curveSmoothness = const Value.absent(),
            Value<bool> durationEstimation = const Value.absent(),
            Value<bool> enableSound = const Value.absent(),
            Value<bool> explainedPermissions = const Value.absent(),
            Value<bool> groupHistory = const Value.absent(),
            Value<int> id = const Value.absent(),
            Value<String> longDateFormat = const Value.absent(),
            Value<int> maxSets = const Value.absent(),
            Value<bool> notifications = const Value.absent(),
            Value<bool> peekGraph = const Value.absent(),
            Value<String> planTrailing = const Value.absent(),
            Value<bool> repEstimation = const Value.absent(),
            Value<bool> restTimers = const Value.absent(),
            Value<String> shortDateFormat = const Value.absent(),
            Value<bool> showCategories = const Value.absent(),
            Value<bool> showImages = const Value.absent(),
            Value<bool> showNotes = const Value.absent(),
            Value<bool> showGlobalProgress = const Value.absent(),
            Value<bool> showUnits = const Value.absent(),
            Value<String> strengthUnit = const Value.absent(),
            Value<bool> systemColors = const Value.absent(),
            Value<String> tabs = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<int> timerDuration = const Value.absent(),
            Value<bool> vibrate = const Value.absent(),
            Value<int?> warmupSets = const Value.absent(),
            Value<bool> scrollableTabs = const Value.absent(),
            Value<double?> fivethreeoneSquatTm = const Value.absent(),
            Value<double?> fivethreeoneBenchTm = const Value.absent(),
            Value<double?> fivethreeoneDeadliftTm = const Value.absent(),
            Value<double?> fivethreeonePressTm = const Value.absent(),
            Value<int> fivethreeoneWeek = const Value.absent(),
            Value<int> customColorSeed = const Value.absent(),
            Value<DateTime?> lastAutoBackupTime = const Value.absent(),
            Value<String?> lastBackupStatus = const Value.absent(),
            Value<String?> spotifyAccessToken = const Value.absent(),
            Value<String?> spotifyRefreshToken = const Value.absent(),
            Value<int?> spotifyTokenExpiry = const Value.absent(),
            Value<String?> serverUrl = const Value.absent(),
            Value<String?> serverApiKey = const Value.absent(),
            Value<DateTime?> lastPushTime = const Value.absent(),
            Value<String?> lastPushStatus = const Value.absent(),
          }) =>
              SettingsCompanion(
            alarmSound: alarmSound,
            automaticBackups: automaticBackups,
            backupPath: backupPath,
            cardioUnit: cardioUnit,
            curveLines: curveLines,
            curveSmoothness: curveSmoothness,
            durationEstimation: durationEstimation,
            enableSound: enableSound,
            explainedPermissions: explainedPermissions,
            groupHistory: groupHistory,
            id: id,
            longDateFormat: longDateFormat,
            maxSets: maxSets,
            notifications: notifications,
            peekGraph: peekGraph,
            planTrailing: planTrailing,
            repEstimation: repEstimation,
            restTimers: restTimers,
            shortDateFormat: shortDateFormat,
            showCategories: showCategories,
            showImages: showImages,
            showNotes: showNotes,
            showGlobalProgress: showGlobalProgress,
            showUnits: showUnits,
            strengthUnit: strengthUnit,
            systemColors: systemColors,
            tabs: tabs,
            themeMode: themeMode,
            timerDuration: timerDuration,
            vibrate: vibrate,
            warmupSets: warmupSets,
            scrollableTabs: scrollableTabs,
            fivethreeoneSquatTm: fivethreeoneSquatTm,
            fivethreeoneBenchTm: fivethreeoneBenchTm,
            fivethreeoneDeadliftTm: fivethreeoneDeadliftTm,
            fivethreeonePressTm: fivethreeonePressTm,
            fivethreeoneWeek: fivethreeoneWeek,
            customColorSeed: customColorSeed,
            lastAutoBackupTime: lastAutoBackupTime,
            lastBackupStatus: lastBackupStatus,
            spotifyAccessToken: spotifyAccessToken,
            spotifyRefreshToken: spotifyRefreshToken,
            spotifyTokenExpiry: spotifyTokenExpiry,
            serverUrl: serverUrl,
            serverApiKey: serverApiKey,
            lastPushTime: lastPushTime,
            lastPushStatus: lastPushStatus,
          ),
          createCompanionCallback: ({
            required String alarmSound,
            Value<bool> automaticBackups = const Value.absent(),
            Value<String?> backupPath = const Value.absent(),
            required String cardioUnit,
            required bool curveLines,
            Value<double?> curveSmoothness = const Value.absent(),
            Value<bool> durationEstimation = const Value.absent(),
            Value<bool> enableSound = const Value.absent(),
            required bool explainedPermissions,
            Value<bool> groupHistory = const Value.absent(),
            Value<int> id = const Value.absent(),
            required String longDateFormat,
            required int maxSets,
            Value<bool> notifications = const Value.absent(),
            Value<bool> peekGraph = const Value.absent(),
            required String planTrailing,
            Value<bool> repEstimation = const Value.absent(),
            required bool restTimers,
            required String shortDateFormat,
            Value<bool> showCategories = const Value.absent(),
            Value<bool> showImages = const Value.absent(),
            Value<bool> showNotes = const Value.absent(),
            Value<bool> showGlobalProgress = const Value.absent(),
            Value<bool> showUnits = const Value.absent(),
            required String strengthUnit,
            required bool systemColors,
            Value<String> tabs = const Value.absent(),
            required String themeMode,
            required int timerDuration,
            required bool vibrate,
            Value<int?> warmupSets = const Value.absent(),
            Value<bool> scrollableTabs = const Value.absent(),
            Value<double?> fivethreeoneSquatTm = const Value.absent(),
            Value<double?> fivethreeoneBenchTm = const Value.absent(),
            Value<double?> fivethreeoneDeadliftTm = const Value.absent(),
            Value<double?> fivethreeonePressTm = const Value.absent(),
            Value<int> fivethreeoneWeek = const Value.absent(),
            Value<int> customColorSeed = const Value.absent(),
            Value<DateTime?> lastAutoBackupTime = const Value.absent(),
            Value<String?> lastBackupStatus = const Value.absent(),
            Value<String?> spotifyAccessToken = const Value.absent(),
            Value<String?> spotifyRefreshToken = const Value.absent(),
            Value<int?> spotifyTokenExpiry = const Value.absent(),
            Value<String?> serverUrl = const Value.absent(),
            Value<String?> serverApiKey = const Value.absent(),
            Value<DateTime?> lastPushTime = const Value.absent(),
            Value<String?> lastPushStatus = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            alarmSound: alarmSound,
            automaticBackups: automaticBackups,
            backupPath: backupPath,
            cardioUnit: cardioUnit,
            curveLines: curveLines,
            curveSmoothness: curveSmoothness,
            durationEstimation: durationEstimation,
            enableSound: enableSound,
            explainedPermissions: explainedPermissions,
            groupHistory: groupHistory,
            id: id,
            longDateFormat: longDateFormat,
            maxSets: maxSets,
            notifications: notifications,
            peekGraph: peekGraph,
            planTrailing: planTrailing,
            repEstimation: repEstimation,
            restTimers: restTimers,
            shortDateFormat: shortDateFormat,
            showCategories: showCategories,
            showImages: showImages,
            showNotes: showNotes,
            showGlobalProgress: showGlobalProgress,
            showUnits: showUnits,
            strengthUnit: strengthUnit,
            systemColors: systemColors,
            tabs: tabs,
            themeMode: themeMode,
            timerDuration: timerDuration,
            vibrate: vibrate,
            warmupSets: warmupSets,
            scrollableTabs: scrollableTabs,
            fivethreeoneSquatTm: fivethreeoneSquatTm,
            fivethreeoneBenchTm: fivethreeoneBenchTm,
            fivethreeoneDeadliftTm: fivethreeoneDeadliftTm,
            fivethreeonePressTm: fivethreeonePressTm,
            fivethreeoneWeek: fivethreeoneWeek,
            customColorSeed: customColorSeed,
            lastAutoBackupTime: lastAutoBackupTime,
            lastBackupStatus: lastBackupStatus,
            spotifyAccessToken: spotifyAccessToken,
            spotifyRefreshToken: spotifyRefreshToken,
            spotifyTokenExpiry: spotifyTokenExpiry,
            serverUrl: serverUrl,
            serverApiKey: serverApiKey,
            lastPushTime: lastPushTime,
            lastPushStatus: lastPushStatus,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;
typedef $$PlanExercisesTableCreateCompanionBuilder = PlanExercisesCompanion
    Function({
  required bool enabled,
  Value<bool> timers,
  required String exercise,
  Value<int> id,
  Value<int?> maxSets,
  required int planId,
  Value<int?> warmupSets,
  Value<int> sequence,
});
typedef $$PlanExercisesTableUpdateCompanionBuilder = PlanExercisesCompanion
    Function({
  Value<bool> enabled,
  Value<bool> timers,
  Value<String> exercise,
  Value<int> id,
  Value<int?> maxSets,
  Value<int> planId,
  Value<int?> warmupSets,
  Value<int> sequence,
});

final class $$PlanExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $PlanExercisesTable, PlanExercise> {
  $$PlanExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $GymSetsTable _exerciseTable(_$AppDatabase db) =>
      db.gymSets.createAlias(
          $_aliasNameGenerator(db.planExercises.exercise, db.gymSets.name));

  $$GymSetsTableProcessedTableManager get exercise {
    final $_column = $_itemColumn<String>('exercise')!;

    final manager = $$GymSetsTableTableManager($_db, $_db.gymSets)
        .filter((f) => f.name.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PlansTable _planIdTable(_$AppDatabase db) => db.plans
      .createAlias($_aliasNameGenerator(db.planExercises.planId, db.plans.id));

  $$PlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<int>('plan_id')!;

    final manager = $$PlansTableTableManager($_db, $_db.plans)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PlanExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $PlanExercisesTable> {
  $$PlanExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get timers => $composableBuilder(
      column: $table.timers, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxSets => $composableBuilder(
      column: $table.maxSets, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get warmupSets => $composableBuilder(
      column: $table.warmupSets, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnFilters(column));

  $$GymSetsTableFilterComposer get exercise {
    final $$GymSetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exercise,
        referencedTable: $db.gymSets,
        getReferencedColumn: (t) => t.name,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GymSetsTableFilterComposer(
              $db: $db,
              $table: $db.gymSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PlansTableFilterComposer get planId {
    final $$PlansTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.plans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlansTableFilterComposer(
              $db: $db,
              $table: $db.plans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlanExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanExercisesTable> {
  $$PlanExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get timers => $composableBuilder(
      column: $table.timers, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxSets => $composableBuilder(
      column: $table.maxSets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get warmupSets => $composableBuilder(
      column: $table.warmupSets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnOrderings(column));

  $$GymSetsTableOrderingComposer get exercise {
    final $$GymSetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exercise,
        referencedTable: $db.gymSets,
        getReferencedColumn: (t) => t.name,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GymSetsTableOrderingComposer(
              $db: $db,
              $table: $db.gymSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PlansTableOrderingComposer get planId {
    final $$PlansTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.plans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlansTableOrderingComposer(
              $db: $db,
              $table: $db.plans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlanExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanExercisesTable> {
  $$PlanExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get timers =>
      $composableBuilder(column: $table.timers, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get maxSets =>
      $composableBuilder(column: $table.maxSets, builder: (column) => column);

  GeneratedColumn<int> get warmupSets => $composableBuilder(
      column: $table.warmupSets, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  $$GymSetsTableAnnotationComposer get exercise {
    final $$GymSetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exercise,
        referencedTable: $db.gymSets,
        getReferencedColumn: (t) => t.name,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GymSetsTableAnnotationComposer(
              $db: $db,
              $table: $db.gymSets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PlansTableAnnotationComposer get planId {
    final $$PlansTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.plans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlansTableAnnotationComposer(
              $db: $db,
              $table: $db.plans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlanExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlanExercisesTable,
    PlanExercise,
    $$PlanExercisesTableFilterComposer,
    $$PlanExercisesTableOrderingComposer,
    $$PlanExercisesTableAnnotationComposer,
    $$PlanExercisesTableCreateCompanionBuilder,
    $$PlanExercisesTableUpdateCompanionBuilder,
    (PlanExercise, $$PlanExercisesTableReferences),
    PlanExercise,
    PrefetchHooks Function({bool exercise, bool planId})> {
  $$PlanExercisesTableTableManager(_$AppDatabase db, $PlanExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<bool> enabled = const Value.absent(),
            Value<bool> timers = const Value.absent(),
            Value<String> exercise = const Value.absent(),
            Value<int> id = const Value.absent(),
            Value<int?> maxSets = const Value.absent(),
            Value<int> planId = const Value.absent(),
            Value<int?> warmupSets = const Value.absent(),
            Value<int> sequence = const Value.absent(),
          }) =>
              PlanExercisesCompanion(
            enabled: enabled,
            timers: timers,
            exercise: exercise,
            id: id,
            maxSets: maxSets,
            planId: planId,
            warmupSets: warmupSets,
            sequence: sequence,
          ),
          createCompanionCallback: ({
            required bool enabled,
            Value<bool> timers = const Value.absent(),
            required String exercise,
            Value<int> id = const Value.absent(),
            Value<int?> maxSets = const Value.absent(),
            required int planId,
            Value<int?> warmupSets = const Value.absent(),
            Value<int> sequence = const Value.absent(),
          }) =>
              PlanExercisesCompanion.insert(
            enabled: enabled,
            timers: timers,
            exercise: exercise,
            id: id,
            maxSets: maxSets,
            planId: planId,
            warmupSets: warmupSets,
            sequence: sequence,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlanExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({exercise = false, planId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (exercise) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exercise,
                    referencedTable:
                        $$PlanExercisesTableReferences._exerciseTable(db),
                    referencedColumn:
                        $$PlanExercisesTableReferences._exerciseTable(db).name,
                  ) as T;
                }
                if (planId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.planId,
                    referencedTable:
                        $$PlanExercisesTableReferences._planIdTable(db),
                    referencedColumn:
                        $$PlanExercisesTableReferences._planIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PlanExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlanExercisesTable,
    PlanExercise,
    $$PlanExercisesTableFilterComposer,
    $$PlanExercisesTableOrderingComposer,
    $$PlanExercisesTableAnnotationComposer,
    $$PlanExercisesTableCreateCompanionBuilder,
    $$PlanExercisesTableUpdateCompanionBuilder,
    (PlanExercise, $$PlanExercisesTableReferences),
    PlanExercise,
    PrefetchHooks Function({bool exercise, bool planId})>;
typedef $$MetadataTableCreateCompanionBuilder = MetadataCompanion Function({
  required int buildNumber,
  Value<int> rowid,
});
typedef $$MetadataTableUpdateCompanionBuilder = MetadataCompanion Function({
  Value<int> buildNumber,
  Value<int> rowid,
});

class $$MetadataTableFilterComposer
    extends Composer<_$AppDatabase, $MetadataTable> {
  $$MetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get buildNumber => $composableBuilder(
      column: $table.buildNumber, builder: (column) => ColumnFilters(column));
}

class $$MetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $MetadataTable> {
  $$MetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get buildNumber => $composableBuilder(
      column: $table.buildNumber, builder: (column) => ColumnOrderings(column));
}

class $$MetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetadataTable> {
  $$MetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get buildNumber => $composableBuilder(
      column: $table.buildNumber, builder: (column) => column);
}

class $$MetadataTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MetadataTable,
    MetadataData,
    $$MetadataTableFilterComposer,
    $$MetadataTableOrderingComposer,
    $$MetadataTableAnnotationComposer,
    $$MetadataTableCreateCompanionBuilder,
    $$MetadataTableUpdateCompanionBuilder,
    (MetadataData, BaseReferences<_$AppDatabase, $MetadataTable, MetadataData>),
    MetadataData,
    PrefetchHooks Function()> {
  $$MetadataTableTableManager(_$AppDatabase db, $MetadataTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> buildNumber = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MetadataCompanion(
            buildNumber: buildNumber,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int buildNumber,
            Value<int> rowid = const Value.absent(),
          }) =>
              MetadataCompanion.insert(
            buildNumber: buildNumber,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MetadataTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MetadataTable,
    MetadataData,
    $$MetadataTableFilterComposer,
    $$MetadataTableOrderingComposer,
    $$MetadataTableAnnotationComposer,
    $$MetadataTableCreateCompanionBuilder,
    $$MetadataTableUpdateCompanionBuilder,
    (MetadataData, BaseReferences<_$AppDatabase, $MetadataTable, MetadataData>),
    MetadataData,
    PrefetchHooks Function()>;
typedef $$WorkoutsTableCreateCompanionBuilder = WorkoutsCompanion Function({
  Value<int> id,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<int?> planId,
  Value<String?> name,
  Value<String?> notes,
  Value<String?> selfieImagePath,
});
typedef $$WorkoutsTableUpdateCompanionBuilder = WorkoutsCompanion Function({
  Value<int> id,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<int?> planId,
  Value<String?> name,
  Value<String?> notes,
  Value<String?> selfieImagePath,
});

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selfieImagePath => $composableBuilder(
      column: $table.selfieImagePath,
      builder: (column) => ColumnFilters(column));
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selfieImagePath => $composableBuilder(
      column: $table.selfieImagePath,
      builder: (column) => ColumnOrderings(column));
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get selfieImagePath => $composableBuilder(
      column: $table.selfieImagePath, builder: (column) => column);
}

class $$WorkoutsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutsTable,
    Workout,
    $$WorkoutsTableFilterComposer,
    $$WorkoutsTableOrderingComposer,
    $$WorkoutsTableAnnotationComposer,
    $$WorkoutsTableCreateCompanionBuilder,
    $$WorkoutsTableUpdateCompanionBuilder,
    (Workout, BaseReferences<_$AppDatabase, $WorkoutsTable, Workout>),
    Workout,
    PrefetchHooks Function()> {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<int?> planId = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> selfieImagePath = const Value.absent(),
          }) =>
              WorkoutsCompanion(
            id: id,
            startTime: startTime,
            endTime: endTime,
            planId: planId,
            name: name,
            notes: notes,
            selfieImagePath: selfieImagePath,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<int?> planId = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> selfieImagePath = const Value.absent(),
          }) =>
              WorkoutsCompanion.insert(
            id: id,
            startTime: startTime,
            endTime: endTime,
            planId: planId,
            name: name,
            notes: notes,
            selfieImagePath: selfieImagePath,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkoutsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutsTable,
    Workout,
    $$WorkoutsTableFilterComposer,
    $$WorkoutsTableOrderingComposer,
    $$WorkoutsTableAnnotationComposer,
    $$WorkoutsTableCreateCompanionBuilder,
    $$WorkoutsTableUpdateCompanionBuilder,
    (Workout, BaseReferences<_$AppDatabase, $WorkoutsTable, Workout>),
    Workout,
    PrefetchHooks Function()>;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  required String title,
  required String content,
  required DateTime created,
  required DateTime updated,
  Value<int?> color,
  Value<int?> sequence,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> content,
  Value<DateTime> created,
  Value<DateTime> updated,
  Value<int?> color,
  Value<int?> sequence,
});

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updated => $composableBuilder(
      column: $table.updated, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnFilters(column));
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updated => $composableBuilder(
      column: $table.updated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnOrderings(column));
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<DateTime> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);
}

class $$NotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
    Note,
    PrefetchHooks Function()> {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> created = const Value.absent(),
            Value<DateTime> updated = const Value.absent(),
            Value<int?> color = const Value.absent(),
            Value<int?> sequence = const Value.absent(),
          }) =>
              NotesCompanion(
            id: id,
            title: title,
            content: content,
            created: created,
            updated: updated,
            color: color,
            sequence: sequence,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            required String content,
            required DateTime created,
            required DateTime updated,
            Value<int?> color = const Value.absent(),
            Value<int?> sequence = const Value.absent(),
          }) =>
              NotesCompanion.insert(
            id: id,
            title: title,
            content: content,
            created: created,
            updated: updated,
            color: color,
            sequence: sequence,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
    Note,
    PrefetchHooks Function()>;
typedef $$BodyweightEntriesTableCreateCompanionBuilder
    = BodyweightEntriesCompanion Function({
  Value<int> id,
  required double weight,
  required String unit,
  required DateTime date,
  Value<String?> notes,
});
typedef $$BodyweightEntriesTableUpdateCompanionBuilder
    = BodyweightEntriesCompanion Function({
  Value<int> id,
  Value<double> weight,
  Value<String> unit,
  Value<DateTime> date,
  Value<String?> notes,
});

class $$BodyweightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BodyweightEntriesTable> {
  $$BodyweightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));
}

class $$BodyweightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyweightEntriesTable> {
  $$BodyweightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$BodyweightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyweightEntriesTable> {
  $$BodyweightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$BodyweightEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BodyweightEntriesTable,
    BodyweightEntry,
    $$BodyweightEntriesTableFilterComposer,
    $$BodyweightEntriesTableOrderingComposer,
    $$BodyweightEntriesTableAnnotationComposer,
    $$BodyweightEntriesTableCreateCompanionBuilder,
    $$BodyweightEntriesTableUpdateCompanionBuilder,
    (
      BodyweightEntry,
      BaseReferences<_$AppDatabase, $BodyweightEntriesTable, BodyweightEntry>
    ),
    BodyweightEntry,
    PrefetchHooks Function()> {
  $$BodyweightEntriesTableTableManager(
      _$AppDatabase db, $BodyweightEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyweightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyweightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyweightEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> weight = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              BodyweightEntriesCompanion(
            id: id,
            weight: weight,
            unit: unit,
            date: date,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required double weight,
            required String unit,
            required DateTime date,
            Value<String?> notes = const Value.absent(),
          }) =>
              BodyweightEntriesCompanion.insert(
            id: id,
            weight: weight,
            unit: unit,
            date: date,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BodyweightEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BodyweightEntriesTable,
    BodyweightEntry,
    $$BodyweightEntriesTableFilterComposer,
    $$BodyweightEntriesTableOrderingComposer,
    $$BodyweightEntriesTableAnnotationComposer,
    $$BodyweightEntriesTableCreateCompanionBuilder,
    $$BodyweightEntriesTableUpdateCompanionBuilder,
    (
      BodyweightEntry,
      BaseReferences<_$AppDatabase, $BodyweightEntriesTable, BodyweightEntry>
    ),
    BodyweightEntry,
    PrefetchHooks Function()>;
typedef $$FiveThreeOneBlocksTableCreateCompanionBuilder
    = FiveThreeOneBlocksCompanion Function({
  Value<int> id,
  required DateTime created,
  required double squatTm,
  required double benchTm,
  required double deadliftTm,
  required double pressTm,
  Value<double?> startSquatTm,
  Value<double?> startBenchTm,
  Value<double?> startDeadliftTm,
  Value<double?> startPressTm,
  required String unit,
  Value<int> currentCycle,
  Value<int> currentWeek,
  Value<bool> isActive,
  Value<DateTime?> completed,
});
typedef $$FiveThreeOneBlocksTableUpdateCompanionBuilder
    = FiveThreeOneBlocksCompanion Function({
  Value<int> id,
  Value<DateTime> created,
  Value<double> squatTm,
  Value<double> benchTm,
  Value<double> deadliftTm,
  Value<double> pressTm,
  Value<double?> startSquatTm,
  Value<double?> startBenchTm,
  Value<double?> startDeadliftTm,
  Value<double?> startPressTm,
  Value<String> unit,
  Value<int> currentCycle,
  Value<int> currentWeek,
  Value<bool> isActive,
  Value<DateTime?> completed,
});

class $$FiveThreeOneBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $FiveThreeOneBlocksTable> {
  $$FiveThreeOneBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get squatTm => $composableBuilder(
      column: $table.squatTm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get benchTm => $composableBuilder(
      column: $table.benchTm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get deadliftTm => $composableBuilder(
      column: $table.deadliftTm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pressTm => $composableBuilder(
      column: $table.pressTm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startSquatTm => $composableBuilder(
      column: $table.startSquatTm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startBenchTm => $composableBuilder(
      column: $table.startBenchTm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startDeadliftTm => $composableBuilder(
      column: $table.startDeadliftTm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startPressTm => $composableBuilder(
      column: $table.startPressTm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentCycle => $composableBuilder(
      column: $table.currentCycle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentWeek => $composableBuilder(
      column: $table.currentWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));
}

class $$FiveThreeOneBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $FiveThreeOneBlocksTable> {
  $$FiveThreeOneBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get squatTm => $composableBuilder(
      column: $table.squatTm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get benchTm => $composableBuilder(
      column: $table.benchTm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get deadliftTm => $composableBuilder(
      column: $table.deadliftTm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pressTm => $composableBuilder(
      column: $table.pressTm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startSquatTm => $composableBuilder(
      column: $table.startSquatTm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startBenchTm => $composableBuilder(
      column: $table.startBenchTm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startDeadliftTm => $composableBuilder(
      column: $table.startDeadliftTm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startPressTm => $composableBuilder(
      column: $table.startPressTm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentCycle => $composableBuilder(
      column: $table.currentCycle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentWeek => $composableBuilder(
      column: $table.currentWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));
}

class $$FiveThreeOneBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $FiveThreeOneBlocksTable> {
  $$FiveThreeOneBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<double> get squatTm =>
      $composableBuilder(column: $table.squatTm, builder: (column) => column);

  GeneratedColumn<double> get benchTm =>
      $composableBuilder(column: $table.benchTm, builder: (column) => column);

  GeneratedColumn<double> get deadliftTm => $composableBuilder(
      column: $table.deadliftTm, builder: (column) => column);

  GeneratedColumn<double> get pressTm =>
      $composableBuilder(column: $table.pressTm, builder: (column) => column);

  GeneratedColumn<double> get startSquatTm => $composableBuilder(
      column: $table.startSquatTm, builder: (column) => column);

  GeneratedColumn<double> get startBenchTm => $composableBuilder(
      column: $table.startBenchTm, builder: (column) => column);

  GeneratedColumn<double> get startDeadliftTm => $composableBuilder(
      column: $table.startDeadliftTm, builder: (column) => column);

  GeneratedColumn<double> get startPressTm => $composableBuilder(
      column: $table.startPressTm, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get currentCycle => $composableBuilder(
      column: $table.currentCycle, builder: (column) => column);

  GeneratedColumn<int> get currentWeek => $composableBuilder(
      column: $table.currentWeek, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$FiveThreeOneBlocksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FiveThreeOneBlocksTable,
    FiveThreeOneBlock,
    $$FiveThreeOneBlocksTableFilterComposer,
    $$FiveThreeOneBlocksTableOrderingComposer,
    $$FiveThreeOneBlocksTableAnnotationComposer,
    $$FiveThreeOneBlocksTableCreateCompanionBuilder,
    $$FiveThreeOneBlocksTableUpdateCompanionBuilder,
    (
      FiveThreeOneBlock,
      BaseReferences<_$AppDatabase, $FiveThreeOneBlocksTable, FiveThreeOneBlock>
    ),
    FiveThreeOneBlock,
    PrefetchHooks Function()> {
  $$FiveThreeOneBlocksTableTableManager(
      _$AppDatabase db, $FiveThreeOneBlocksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FiveThreeOneBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FiveThreeOneBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FiveThreeOneBlocksTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> created = const Value.absent(),
            Value<double> squatTm = const Value.absent(),
            Value<double> benchTm = const Value.absent(),
            Value<double> deadliftTm = const Value.absent(),
            Value<double> pressTm = const Value.absent(),
            Value<double?> startSquatTm = const Value.absent(),
            Value<double?> startBenchTm = const Value.absent(),
            Value<double?> startDeadliftTm = const Value.absent(),
            Value<double?> startPressTm = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<int> currentCycle = const Value.absent(),
            Value<int> currentWeek = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> completed = const Value.absent(),
          }) =>
              FiveThreeOneBlocksCompanion(
            id: id,
            created: created,
            squatTm: squatTm,
            benchTm: benchTm,
            deadliftTm: deadliftTm,
            pressTm: pressTm,
            startSquatTm: startSquatTm,
            startBenchTm: startBenchTm,
            startDeadliftTm: startDeadliftTm,
            startPressTm: startPressTm,
            unit: unit,
            currentCycle: currentCycle,
            currentWeek: currentWeek,
            isActive: isActive,
            completed: completed,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime created,
            required double squatTm,
            required double benchTm,
            required double deadliftTm,
            required double pressTm,
            Value<double?> startSquatTm = const Value.absent(),
            Value<double?> startBenchTm = const Value.absent(),
            Value<double?> startDeadliftTm = const Value.absent(),
            Value<double?> startPressTm = const Value.absent(),
            required String unit,
            Value<int> currentCycle = const Value.absent(),
            Value<int> currentWeek = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> completed = const Value.absent(),
          }) =>
              FiveThreeOneBlocksCompanion.insert(
            id: id,
            created: created,
            squatTm: squatTm,
            benchTm: benchTm,
            deadliftTm: deadliftTm,
            pressTm: pressTm,
            startSquatTm: startSquatTm,
            startBenchTm: startBenchTm,
            startDeadliftTm: startDeadliftTm,
            startPressTm: startPressTm,
            unit: unit,
            currentCycle: currentCycle,
            currentWeek: currentWeek,
            isActive: isActive,
            completed: completed,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FiveThreeOneBlocksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FiveThreeOneBlocksTable,
    FiveThreeOneBlock,
    $$FiveThreeOneBlocksTableFilterComposer,
    $$FiveThreeOneBlocksTableOrderingComposer,
    $$FiveThreeOneBlocksTableAnnotationComposer,
    $$FiveThreeOneBlocksTableCreateCompanionBuilder,
    $$FiveThreeOneBlocksTableUpdateCompanionBuilder,
    (
      FiveThreeOneBlock,
      BaseReferences<_$AppDatabase, $FiveThreeOneBlocksTable, FiveThreeOneBlock>
    ),
    FiveThreeOneBlock,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$GymSetsTableTableManager get gymSets =>
      $$GymSetsTableTableManager(_db, _db.gymSets);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$PlanExercisesTableTableManager get planExercises =>
      $$PlanExercisesTableTableManager(_db, _db.planExercises);
  $$MetadataTableTableManager get metadata =>
      $$MetadataTableTableManager(_db, _db.metadata);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$BodyweightEntriesTableTableManager get bodyweightEntries =>
      $$BodyweightEntriesTableTableManager(_db, _db.bodyweightEntries);
  $$FiveThreeOneBlocksTableTableManager get fiveThreeOneBlocks =>
      $$FiveThreeOneBlocksTableTableManager(_db, _db.fiveThreeOneBlocks);
}
