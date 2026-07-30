import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../database/database.dart';
import '../main.dart';
import 'schemes.dart';

/// Reads a block's chosen Leader/Anchor supplemental templates as the record
/// the scheme helpers take.
extension BlockSupplementalsX on FiveThreeOneBlock {
  BlockSupplementals get supplementals =>
      (leader: leaderSupplemental, anchor: anchorSupplemental);
}

class FiveThreeOneState extends ChangeNotifier {
  FiveThreeOneState() {
    _initialLoad = _loadActiveBlock().catchError((error) {
      print('Warning: Error loading active 5/3/1 block: $error');
    });
  }

  Future<void>? _initialLoad;

  /// Awaits the constructor's first load of [activeBlock].
  ///
  /// This provider is registered lazily and every other consumer sits on a
  /// 5/3/1, plan or notes screen, so the coach is often the first thing to read
  /// it: the provider is constructed at the moment the user hits send, and a
  /// synchronous [activeBlock] read then returns null while the query is still
  /// in flight. The coach would tell a lifter mid-block that they have no
  /// active 5/3/1 block. Await this before reading the block for a turn.
  Future<void> ensureLoaded() => _initialLoad ?? Future<void>.value();

  FiveThreeOneBlock? _activeBlock;

  /// Ensure the five_three_one_blocks table exists (handles imported databases
  /// from before the table was added).
  Future<void> _ensureTable() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS five_three_one_blocks (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        created INTEGER NOT NULL,
        squat_tm REAL NOT NULL,
        bench_tm REAL NOT NULL,
        deadlift_tm REAL NOT NULL,
        press_tm REAL NOT NULL,
        start_squat_tm REAL,
        start_bench_tm REAL,
        start_deadlift_tm REAL,
        start_press_tm REAL,
        unit TEXT NOT NULL,
        current_cycle INTEGER NOT NULL DEFAULT 0,
        current_week INTEGER NOT NULL DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 1,
        completed INTEGER,
        leader_supplemental TEXT NOT NULL DEFAULT 'bbb',
        anchor_supplemental TEXT NOT NULL DEFAULT 'fsl',
        tm_bumps INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  FiveThreeOneBlock? get activeBlock => _activeBlock;
  bool get hasActiveBlock => _activeBlock != null;

  /// Current cycle position (0-4), defaults to 0 if no active block
  int get currentCycle => _activeBlock?.currentCycle ?? 0;

  /// Current week within cycle (1-3), defaults to 1 if no active block
  int get currentWeek => _activeBlock?.currentWeek ?? 1;

  /// Whether TM bump dialog should be shown before advancing
  bool get needsTmBump {
    if (_activeBlock == null) return false;
    final block = _activeBlock!;
    return block.currentWeek >= cycleWeeks[block.currentCycle] &&
        cycleBumpsTm[block.currentCycle];
  }

  /// Whether going back a week would undo a TM bump that was actually applied.
  /// True only at week 1 of the cycle right after a bumping cycle, and only if
  /// the bump was taken rather than skipped.
  bool get needsTmUnbump {
    if (_activeBlock == null) return false;
    final block = _activeBlock!;
    if (block.currentWeek != 1 || block.currentCycle < 1) return false;
    if (!cycleBumpsTm[block.currentCycle - 1]) return false;
    return block.tmBumps > bumpsThroughCycle(block.currentCycle - 1);
  }

  /// Whether the user can go back a week (not at the very start)
  bool get canGoBack {
    if (_activeBlock == null) return false;
    final block = _activeBlock!;
    return block.currentCycle > 0 || block.currentWeek > 1;
  }

  /// Whether the block has reached completion
  bool get isBlockComplete {
    if (_activeBlock == null) return false;
    final block = _activeBlock!;
    return block.currentCycle == cycleTmTest &&
        block.currentWeek >= cycleWeeks[cycleTmTest];
  }

  /// Supplemental templates of the active block, or the legacy defaults
  BlockSupplementals get supplementals =>
      _activeBlock?.supplementals ?? defaultSupplementals;

  /// Human-readable position label for display
  String get positionLabel {
    if (_activeBlock == null) return '';
    final block = _activeBlock!;
    return cyclePositionLabel(
      block.currentCycle,
      block.currentWeek,
      block.supplementals,
      separator: ' - ',
    );
  }

  /// Short badge string for cycle type (L1, L2, D, A, T)
  String get cycleBadge {
    if (_activeBlock == null) return '';
    return getCycleBadge(_activeBlock!.currentCycle);
  }

  Future<void> _loadActiveBlock() async {
    await _ensureTable();
    _activeBlock = await (db.select(db.fiveThreeOneBlocks)
          ..where((b) => b.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
    notifyListeners();
  }

  /// Reload active block from database (call after mutations)
  Future<void> refresh() async {
    await _loadActiveBlock();
  }

  /// Create a new block, deactivating any existing active block first
  Future<void> createBlock({
    required double squatTm,
    required double benchTm,
    required double deadliftTm,
    required double pressTm,
    required String unit,
    required String leaderSupplemental,
    required String anchorSupplemental,
  }) async {
    await _ensureTable();
    // Deactivate any existing active block
    await (db.update(db.fiveThreeOneBlocks)
          ..where((b) => b.isActive.equals(true)))
        .write(
      FiveThreeOneBlocksCompanion(
        isActive: const Value(false),
        completed: Value(DateTime.now()),
      ),
    );

    // Insert new block (defaults: cycle=0, week=1, isActive=true)
    await db.into(db.fiveThreeOneBlocks).insert(
          FiveThreeOneBlocksCompanion.insert(
            created: DateTime.now(),
            squatTm: squatTm,
            benchTm: benchTm,
            deadliftTm: deadliftTm,
            pressTm: pressTm,
            startSquatTm: Value(squatTm),
            startBenchTm: Value(benchTm),
            startDeadliftTm: Value(deadliftTm),
            startPressTm: Value(pressTm),
            unit: unit,
            leaderSupplemental: Value(leaderSupplemental),
            anchorSupplemental: Value(anchorSupplemental),
          ),
        );

    await refresh();
  }

  /// Advance to the next week or cycle, or complete the block
  Future<void> advanceWeek() async {
    if (_activeBlock == null) return;
    final block = _activeBlock!;
    final maxWeeks = cycleWeeks[block.currentCycle];

    FiveThreeOneBlocksCompanion companion;

    if (block.currentWeek < maxWeeks) {
      // Advance within current cycle
      companion = FiveThreeOneBlocksCompanion(
        currentWeek: Value(block.currentWeek + 1),
      );
    } else if (block.currentCycle < cycleTmTest) {
      // Move to next cycle, reset week to 1
      companion = FiveThreeOneBlocksCompanion(
        currentCycle: Value(block.currentCycle + 1),
        currentWeek: const Value(1),
      );
    } else {
      // Block complete
      companion = FiveThreeOneBlocksCompanion(
        isActive: const Value(false),
        completed: Value(DateTime.now()),
      );
    }

    await (db.update(db.fiveThreeOneBlocks)
          ..where((b) => b.id.equals(block.id)))
        .write(companion);

    await refresh();
  }

  /// Go back to the previous week (inverse of advanceWeek)
  Future<void> goBackWeek() async {
    if (_activeBlock == null) return;
    final block = _activeBlock!;

    // Already at the very start — nothing to undo
    if (block.currentCycle == 0 && block.currentWeek == 1) return;

    FiveThreeOneBlocksCompanion companion;

    if (block.currentWeek > 1) {
      // Move back within the same cycle
      companion = FiveThreeOneBlocksCompanion(
        currentWeek: Value(block.currentWeek - 1),
      );
    } else {
      // At week 1 — move to last week of previous cycle
      final prevCycle = block.currentCycle - 1;
      companion = FiveThreeOneBlocksCompanion(
        currentCycle: Value(prevCycle),
        currentWeek: Value(cycleWeeks[prevCycle]),
      );
    }

    await (db.update(db.fiveThreeOneBlocks)
          ..where((b) => b.id.equals(block.id)))
        .write(companion);

    await refresh();
  }

  /// Bump training max values: +4.5 for lower body, +2.2 for upper body
  Future<void> bumpTms() => _shiftTms(1);

  /// Undo a TM bump, putting the training maxes back where they were
  Future<void> unbumpTms() => _shiftTms(-1);

  /// Move every training max by [direction] bump steps and record it, so a
  /// bump and its undo stay in sync with the [tmBumps] counter.
  Future<void> _shiftTms(int direction) async {
    if (_activeBlock == null) return;
    final block = _activeBlock!;
    final lower = tmBumpLower * direction;
    final upper = tmBumpUpper * direction;

    double shift(double tm, double by) =>
        double.parse((tm + by).toStringAsFixed(1));

    await (db.update(db.fiveThreeOneBlocks)
          ..where((b) => b.id.equals(block.id)))
        .write(
      FiveThreeOneBlocksCompanion(
        squatTm: Value(shift(block.squatTm, lower)),
        benchTm: Value(shift(block.benchTm, upper)),
        deadliftTm: Value(shift(block.deadliftTm, lower)),
        pressTm: Value(shift(block.pressTm, upper)),
        tmBumps: Value(block.tmBumps + direction),
      ),
    );

    await refresh();
  }

  /// Get all completed blocks, most recent first
  Future<List<FiveThreeOneBlock>> getCompletedBlocks() async {
    return (db.select(db.fiveThreeOneBlocks)
          ..where((b) => b.isActive.equals(false))
          ..where((b) => b.completed.isNotNull())
          ..orderBy([
            (b) => OrderingTerm(
                expression: b.completed, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Update a single training max value for inline editing
  Future<void> updateTm({
    required String exercise,
    required double value,
  }) async {
    if (_activeBlock == null) return;
    final block = _activeBlock!;

    FiveThreeOneBlocksCompanion companion;
    switch (exercise) {
      case 'squat':
        companion = FiveThreeOneBlocksCompanion(squatTm: Value(value));
        break;
      case 'bench':
        companion = FiveThreeOneBlocksCompanion(benchTm: Value(value));
        break;
      case 'deadlift':
        companion = FiveThreeOneBlocksCompanion(deadliftTm: Value(value));
        break;
      case 'press':
        companion = FiveThreeOneBlocksCompanion(pressTm: Value(value));
        break;
      default:
        return;
    }

    await (db.update(db.fiveThreeOneBlocks)
          ..where((b) => b.id.equals(block.id)))
        .write(companion);

    await refresh();
  }
}
