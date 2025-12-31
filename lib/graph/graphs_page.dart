import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flexify/animated_fab.dart';
import 'package:flexify/constants.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/database/gym_sets.dart';
import 'package:flexify/graph/add_exercise_page.dart';
import 'package:flexify/graph/cardio_data.dart';
import 'package:flexify/graph/edit_graph_page.dart';
import 'package:flexify/graph/flex_line.dart';
import 'package:flexify/graphs_filters.dart';
import 'package:flexify/main.dart';
import 'package:flexify/plan/plan_state.dart';
import 'package:flexify/settings/settings_page.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/utils.dart';
import 'package:flexify/weight_page.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'graph_tile.dart';

class GraphsPage extends StatefulWidget {
  final TabController tabController;

  const GraphsPage({super.key, required this.tabController});

  @override
  createState() => GraphsPageState();
}

class GraphsPageState extends State<GraphsPage>
    with AutomaticKeepAliveClientMixin {
  late final Stream<List<GymSetsCompanion>> stream = watchGraphs();

  final Set<String> selected = {};
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  String? category;
  final scroll = ScrollController();
  bool extendFab = true;
  int total = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NavigatorPopHandler(
      onPopWithResult: (result) {
        if (navKey.currentState!.canPop() == false) return;
        final settings = context.read<SettingsState>().value;
        final graphsIndex = settings.tabs.split(',').indexOf('GraphsPage');
        if (widget.tabController.index == graphsIndex)
          Navigator.of(navKey.currentContext!).pop();
      },
      child: Navigator(
        key: navKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => graphsPage(),
          settings: settings,
        ),
      ),
    );
  }

  void onDelete() async {
    final state = context.read<PlanState>();
    final copy = selected.toList();
    setState(() {
      selected.clear();
    });

    await (db.delete(db.gymSets)..where((tbl) => tbl.name.isIn(copy))).go();

    final plans = await db.plans.select().get();
    for (final plan in plans) {
      db
          .delete(db.planExercises)
          .where((x) => x.planId.equals(plan.id) & x.exercise.isIn(copy));
    }
    state.updatePlans(null);
  }

  LineTouchTooltipData tooltipData(
    List<dynamic> data,
    String unit,
    String format,
  ) {
    return LineTouchTooltipData(
      getTooltipColor: (touch) => Theme.of(context).colorScheme.surface,
      getTooltipItems: (touchedSpots) {
        final row = data.elementAt(touchedSpots.last.spotIndex);
        final created = DateFormat(format).format(row.created);

        String text;
        if (row is CardioData)
          text = "${row.value} ${row.unit} / min";
        else
          text = "${row.reps} x ${row.value.toStringAsFixed(2)}$unit $created";

        return [
          LineTooltipItem(
            text,
            TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
          ),
          if (touchedSpots.length > 1) null,
        ];
      },
    );
  }

  Widget getPeek(GymSetsCompanion gymSet, List<dynamic> data, String format) {
    List<FlSpot> spots = [];
    for (var index = 0; index < data.length; index++) {
      spots.add(FlSpot(index.toDouble(), data[index].value));
    }

    return material.SizedBox(
      height: MediaQuery.of(context).size.height * 0.15,
      child: material.Padding(
        padding: const EdgeInsets.only(right: 48.0, top: 16.0, left: 48.0),
        child: FlexLine(
          data: data,
          spots: spots,
          tooltipData: () => tooltipData(
            data,
            gymSet.unit.value,
            format,
          ),
          hideBottom: true,
          hideLeft: true,
        ),
      ),
    );
  }

  Scaffold graphsPage() {
    final settings = context.watch<SettingsState>().value;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: selected.isEmpty
            ? const Text('Graphs')
            : Text('${selected.length} selected'),
        leading: selected.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  selected.clear();
                }),
              ),
        actions: [
          if (selected.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Delete selected",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text(
                        'This will delete $total records. Are you sure?',
                      ),
                      actions: <Widget>[
                        TextButton.icon(
                          label: const Text('Cancel'),
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                        TextButton.icon(
                          label: const Text('Delete'),
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            onDelete();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: "Edit",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditGraphPage(
                    name: selected.first,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: "Share",
              onPressed: onShare,
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: "More options",
            onSelected: (value) async {
              switch (value) {
                case 'select_all':
                  final gymSets = await stream.first;
                  setState(() {
                    selected.addAll(gymSets.map((g) => g.name.value));
                  });
                  break;
                case 'weight':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeightPage(),
                    ),
                  );
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                  break;
                case 'debug':
                  await _addDebugWorkouts();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'select_all',
                child: ListTile(
                  leading: Icon(Icons.done_all),
                  title: Text('Select all'),
                ),
              ),
              if (settings.showBodyWeight)
                const PopupMenuItem(
                  value: 'weight',
                  child: ListTile(
                    leading: Icon(Icons.scale),
                    title: Text('Weight'),
                  ),
                ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ),
              const PopupMenuItem(
                value: 'debug',
                child: ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Add test data'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorWidget(snapshot.error.toString());
          if (!snapshot.hasData) return const SizedBox();

          var filteredStream = snapshot.data!.where((gymSet) {
            if (category != null) {
              return gymSet.category.value == category;
            }
            return true;
          });

          final gymSets = filteredStream.toList();

          return material.Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GraphsFilters(
                  category: category,
                  setCategory: (value) {
                    setState(() {
                      category = value;
                    });
                  },
                ),
              ),
              if (gymSets.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text("No exercises yet. Add one to get started!"),
                  ),
                ),
              if (gymSets.isNotEmpty)
                Expanded(
                  child: graphList(gymSets),
                ),
            ],
          );
        },
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () => navKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => const AddExercisePage(),
          ),
        ),
        label: const Text('Add'),
        scroll: scroll,
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addDebugWorkouts() async {
    final exercises = ['Bench Press', 'Squat', 'Deadlift'];
    final now = DateTime.now();

    for (var monthOffset = 0; monthOffset < 4; monthOffset++) {
      final workoutDate = DateTime(now.year, now.month - monthOffset, 15);

      // Create a workout
      final workoutId = await db.workouts.insertOne(
        WorkoutsCompanion.insert(
          startTime: workoutDate,
          endTime: Value(workoutDate.add(const Duration(hours: 1))),
          name: Value('Debug Workout ${monthOffset + 1}'),
        ),
      );

      // Add sets for each exercise
      for (var i = 0; i < exercises.length; i++) {
        for (var setNum = 0; setNum < 3; setNum++) {
          await db.gymSets.insertOne(
            GymSetsCompanion.insert(
              name: exercises[i],
              reps: (10 - setNum).toDouble(),
              weight: 50.0 + (monthOffset * 5) + (setNum * 2.5),
              unit: 'kg',
              created: workoutDate.add(Duration(minutes: i * 10 + setNum * 2)),
              workoutId: Value(workoutId),
              category: Value(i == 2 ? 'Back' : 'Chest'),
            ),
          );
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added 4 debug workouts')),
      );
    }
  }

  Future<void> onShare() async {
    final copy = selected.toList();
    setState(() {
      selected.clear();
    });
    final sets = (await stream.first)
        .where(
          (gymSet) => copy.contains(gymSet.name.value),
        )
        .toList();
    final text = sets
        .map(
          (gymSet) =>
              "${toString(gymSet.reps.value)}x${toString(gymSet.weight.value)}${gymSet.unit.value} ${gymSet.name.value}",
        )
        .join(', ');
    await SharePlus.instance.share(ShareParams(text: "I just did $text"));
  }

  material.ListView graphList(List<GymSetsCompanion> gymSets) {
    var itemCount = gymSets.length + 1;

    final settings = context.read<SettingsState>().value;
    final showPeekGraph = settings.peekGraph && gymSets.firstOrNull != null;
    if (showPeekGraph) itemCount++;

    return ListView.builder(
      itemCount: itemCount,
      controller: scroll,
      padding: const EdgeInsets.only(bottom: 50, top: 8),
      itemBuilder: (context, index) {
        int currentIdx = index;

        if (showPeekGraph && currentIdx == 0) {
          return Consumer<SettingsState>(
            builder: (
              BuildContext context,
              SettingsState settings,
              Widget? child,
            ) {
              if (!settings.value.peekGraph) return const SizedBox();
              if (gymSets.firstOrNull == null) return const SizedBox();

              return FutureBuilder(
                builder: (context, snapshot) => snapshot.data != null
                    ? getPeek(
                        gymSets.first,
                        snapshot.data!,
                        settings.value.shortDateFormat,
                      )
                    : const SizedBox(),
                future: gymSets.first.cardio.value
                    ? getCardioData(name: gymSets.first.name.value)
                    : getStrengthData(
                        target: gymSets.first.unit.value,
                        name: gymSets.first.name.value,
                        metric: StrengthMetric.bestWeight,
                        period: Period.day,
                        start: null,
                        end: null,
                        limit: 20,
                      ),
              );
            },
          );
        }

        if (index == itemCount - 1) return const SizedBox(height: 96);

        if (showPeekGraph && currentIdx > 0) {
          currentIdx--;
        }

        final set = gymSets.elementAtOrNull(currentIdx);
        if (set == null) return const SizedBox();

        return GraphTile(
          selected: selected,
          gymSet: set,
          onSelect: (name) async {
            if (selected.contains(name))
              setState(() {
                selected.remove(name);
              });
            else
              setState(() {
                selected.add(name);
              });
            final result = await (db.gymSets.selectOnly()
                  ..addColumns([db.gymSets.name.count()])
                  ..where(db.gymSets.name.isIn(selected)))
                .getSingle();
            setState(() {
              total = result.read(db.gymSets.name.count()) ?? 0;
            });
          },
          tabCtrl: widget.tabController,
        );
      },
    );
  }
}
