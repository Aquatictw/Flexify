import 'package:drift/drift.dart';

@DataClassName('FiveThreeOneBlock')
class FiveThreeOneBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get created => dateTime()();
  RealColumn get squatTm => real()();
  RealColumn get benchTm => real()();
  RealColumn get deadliftTm => real()();
  RealColumn get pressTm => real()();
  RealColumn get startSquatTm => real().nullable()();
  RealColumn get startBenchTm => real().nullable()();
  RealColumn get startDeadliftTm => real().nullable()();
  RealColumn get startPressTm => real().nullable()();
  TextColumn get unit => text()();

  /// 0=Leader1, 1=Leader2, 2=7th Week Deload, 3=Anchor, 4=TM Test
  IntColumn get currentCycle => integer().withDefault(const Constant(0))();

  /// 1-3 within each cycle (7th Week cycles only use week 1)
  IntColumn get currentWeek => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get completed => dateTime().nullable()();

  /// Supplemental template run during both Leader cycles.
  /// Values are the `supplemental*` constants in `fivethreeone/schemes.dart`;
  /// spelled literally here because drift inlines defaults into generated code
  /// that does not import that file.
  TextColumn get leaderSupplemental =>
      text().withDefault(const Constant('bbb'))();

  /// Supplemental template run during the Anchor cycle ('fsl' for now)
  TextColumn get anchorSupplemental =>
      text().withDefault(const Constant('fsl'))();

  /// How many TM bumps have actually been applied to this block. Bumps are
  /// skippable, so the position alone cannot tell whether one happened — this
  /// is what makes "Back" able to undo the bump it really did apply.
  IntColumn get tmBumps => integer().withDefault(const Constant(0))();
}
