/// A single set prescription within a working set scheme
typedef SetScheme = ({double percentage, int reps, bool amrap});

/// Cycle type constants
const int cycleLeader1 = 0;
const int cycleLeader2 = 1;
const int cycleDeload = 2;
const int cycleAnchor = 3;
const int cycleTmTest = 4;

/// Human-readable cycle names
const List<String> cycleNames = [
  'Leader 1',
  'Leader 2',
  '7th Week Protocol',
  'Anchor',
  '7th Week Protocol',
];

/// Number of weeks per cycle type
const List<int> cycleWeeks = [3, 3, 1, 3, 1];

/// Whether TM bumps after completing this cycle
const List<bool> cycleBumpsTm = [true, true, false, true, false];

/// Total weeks in a complete block
const int totalBlockWeeks = 11; // 3+3+1+3+1

/// Supplemental template identifiers, stored on `five_three_one_blocks`
const String supplementalBbb = 'bbb';
const String supplementalFsl = 'fsl';

/// Supplemental templates selectable for the Leader cycles
const List<String> leaderSupplementalOptions = [
  supplementalBbb,
  supplementalFsl,
];

/// Supplemental templates selectable for the Anchor cycle.
/// Anchors run PR Sets main work; FSL is the only supplemental for now.
const List<String> anchorSupplementalOptions = [supplementalFsl];

/// The supplemental templates a block runs for its Leader and Anchor cycles
typedef BlockSupplementals = ({String leader, String anchor});

/// Templates used when a block predates per-block selection
const BlockSupplementals defaultSupplementals =
    (leader: supplementalBbb, anchor: supplementalFsl);

/// 5's PRO scheme (Leader cycles) - all sets x5, no AMRAP
const Map<int, List<SetScheme>> fivesProScheme = {
  1: [
    (percentage: 0.65, reps: 5, amrap: false),
    (percentage: 0.75, reps: 5, amrap: false),
    (percentage: 0.85, reps: 5, amrap: false),
  ],
  2: [
    (percentage: 0.70, reps: 5, amrap: false),
    (percentage: 0.80, reps: 5, amrap: false),
    (percentage: 0.90, reps: 5, amrap: false),
  ],
  3: [
    (percentage: 0.75, reps: 5, amrap: false),
    (percentage: 0.85, reps: 5, amrap: false),
    (percentage: 0.95, reps: 5, amrap: false),
  ],
};

/// PR Sets scheme (Anchor cycle) - AMRAP on final set
const Map<int, List<SetScheme>> prSetsScheme = {
  1: [
    (percentage: 0.65, reps: 5, amrap: false),
    (percentage: 0.75, reps: 5, amrap: false),
    (percentage: 0.85, reps: 5, amrap: true),
  ],
  2: [
    (percentage: 0.70, reps: 3, amrap: false),
    (percentage: 0.80, reps: 3, amrap: false),
    (percentage: 0.90, reps: 3, amrap: true),
  ],
  3: [
    (percentage: 0.75, reps: 5, amrap: false),
    (percentage: 0.85, reps: 3, amrap: false),
    (percentage: 0.95, reps: 1, amrap: true),
  ],
};

/// 7th Week Deload scheme (single week)
const List<SetScheme> deloadScheme = [
  (percentage: 0.70, reps: 5, amrap: false),
  (percentage: 0.80, reps: 5, amrap: false),
  (percentage: 0.90, reps: 1, amrap: false),
  (percentage: 1.00, reps: 1, amrap: false),
];

/// 7th Week TM Test scheme (single week)
const List<SetScheme> tmTestScheme = [
  (percentage: 0.70, reps: 5, amrap: false),
  (percentage: 0.80, reps: 5, amrap: false),
  (percentage: 0.90, reps: 5, amrap: false),
  (percentage: 1.00, reps: 5, amrap: false),
];

/// BBB supplemental: 5 sets x 10 reps at 60% TM
const List<SetScheme> bbbScheme = [
  (percentage: 0.60, reps: 10, amrap: false),
  (percentage: 0.60, reps: 10, amrap: false),
  (percentage: 0.60, reps: 10, amrap: false),
  (percentage: 0.60, reps: 10, amrap: false),
  (percentage: 0.60, reps: 10, amrap: false),
];

/// Returns main work scheme for given cycle type and week
List<SetScheme> getMainScheme({
  required int cycleType,
  required int week,
}) {
  switch (cycleType) {
    case cycleLeader1:
    case cycleLeader2:
      return fivesProScheme[week] ?? [];
    case cycleAnchor:
      return prSetsScheme[week] ?? [];
    case cycleDeload:
      return deloadScheme;
    case cycleTmTest:
      return tmTestScheme;
    default:
      return [];
  }
}

/// FSL supplemental: 5 sets x 5 reps at first working set percentage
/// The percentage varies by week (matches first set of main work)
List<SetScheme> getFslScheme({required int week}) {
  final firstSetPct = [0.65, 0.70, 0.75][week - 1];
  return List.generate(
    5,
    (_) => (percentage: firstSetPct, reps: 5, amrap: false),
  );
}

/// Which supplemental template applies to [cycleType], or null when the cycle
/// runs no supplemental work (the 7th week protocols).
String? supplementalForCycle(int cycleType, BlockSupplementals supplementals) {
  switch (cycleType) {
    case cycleLeader1:
    case cycleLeader2:
      return supplementals.leader;
    case cycleAnchor:
      return supplementals.anchor;
    default:
      return null;
  }
}

/// Returns supplemental scheme for given cycle type and week
List<SetScheme> getSupplementalScheme({
  required int cycleType,
  required int week,
  required BlockSupplementals supplementals,
}) {
  switch (supplementalForCycle(cycleType, supplementals)) {
    case supplementalBbb:
      return bbbScheme;
    case supplementalFsl:
      return getFslScheme(week: week);
    default:
      return [];
  }
}

/// Returns the main scheme type name for display
String getMainSchemeName(int cycleType) {
  switch (cycleType) {
    case cycleLeader1:
    case cycleLeader2:
      return "5's PRO";
    case cycleAnchor:
      return 'PR Sets';
    case cycleDeload:
      return 'Deload';
    case cycleTmTest:
      return 'TM Test';
    default:
      return '';
  }
}

/// Compact tag for a supplemental template, e.g. 'BBB'
String supplementalShortName(String? supplemental) {
  switch (supplemental) {
    case supplementalBbb:
      return 'BBB';
    case supplementalFsl:
      return 'FSL';
    default:
      return '';
  }
}

/// Display name for a supplemental template, e.g. 'BBB 5x10'
String supplementalName(String? supplemental) {
  switch (supplemental) {
    case supplementalBbb:
      return 'BBB 5x10';
    case supplementalFsl:
      return 'FSL 5x5';
    default:
      return '';
  }
}

/// Loading rule for a supplemental template, e.g. '5x10 @ 60% TM'
String supplementalDetail(String? supplemental) {
  switch (supplemental) {
    case supplementalBbb:
      return '5x10 @ 60% TM';
    case supplementalFsl:
      return '5x5 @ FSL';
    default:
      return '';
  }
}

/// Returns the supplemental type name for display
String getSupplementalName(int cycleType, BlockSupplementals supplementals) {
  return supplementalName(supplementalForCycle(cycleType, supplementals));
}

/// Returns descriptive label combining main scheme + supplemental
String getDescriptiveLabel(int cycleType, BlockSupplementals supplementals) {
  final supplemental = supplementalForCycle(cycleType, supplementals);
  if (supplemental == null) return getMainSchemeName(cycleType);
  return '${getMainSchemeName(cycleType)} ${supplementalShortName(supplemental)}';
}

/// Returns a short badge string for cycle type
String getCycleBadge(int cycleType) {
  switch (cycleType) {
    case cycleLeader1:
      return 'L1';
    case cycleLeader2:
      return 'L2';
    case cycleDeload:
      return 'D';
    case cycleAnchor:
      return 'A';
    case cycleTmTest:
      return 'T';
    default:
      return '';
  }
}
