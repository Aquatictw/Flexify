import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart';
import 'package:flexify/animated_fab.dart';
import 'package:flexify/constants.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/database/gym_sets.dart';
import 'package:flexify/graph/add_exercise_page.dart';
import 'package:flexify/graphs_filters.dart';
import 'package:flexify/main.dart';
import 'package:flexify/plan/plan_state.dart';
import 'package:flexify/settings/settings_page.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'graph_tile.dart';
import 'overview_page.dart';

class GraphsPage extends StatefulWidget {
  final TabController tabController;

  const GraphsPage({super.key, required this.tabController});

  @override
  createState() => GraphsPageState();
}

class GraphsPageState extends State<GraphsPage>
    with AutomaticKeepAliveClientMixin {
  Stream<List<GraphExercise>> stream = watchGraphs();

  final Set<String> selected = {};
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  String search = '';
  String? category;
  final scroll = ScrollController();
  final searchController = TextEditingController();
  bool extendFab = true;
  int total = 0;
  bool _showEmptyExercises = false;

  bool get showEmptyExercises => _showEmptyExercises;
  set showEmptyExercises(bool value) {
    _showEmptyExercises = value;
    stream = watchGraphs(showHidden: value);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

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
          if (selected.isEmpty)
            IconButton(
              icon: const Icon(Icons.dashboard),
              tooltip: "Overview",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OverviewPage(),
                  ),
                );
              },
            ),
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
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: "More options",
            onSelected: (value) async {
              switch (value) {
                case 'select_all':
                  final gymSets = await stream.first;
                  setState(() {
                    selected.addAll(gymSets.map((g) => g.name));
                  });
                  break;
                case 'toggle_empty':
                  setState(() {
                    showEmptyExercises = !showEmptyExercises;
                  });
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
              PopupMenuItem(
                value: 'toggle_empty',
                child: ListTile(
                  leading: Icon(
                    showEmptyExercises
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  title: Text(
                    showEmptyExercises
                        ? 'Hide empty exercises'
                        : 'Show empty exercises',
                  ),
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

          final searchTerms =
              search.toLowerCase().split(' ').where((t) => t.isNotEmpty);
          var filteredStream = snapshot.data!.where((gymSet) {
            // Filter by category
            if (category != null && gymSet.category != category) {
              return false;
            }
            // Filter empty exercises
            if (!showEmptyExercises && gymSet.workoutCount == 0) {
              return false;
            }
            // Filter by search
            for (final term in searchTerms) {
              if (!gymSet.name.toLowerCase().contains(term)) {
                return false;
              }
            }
            return true;
          });

          final gymSets = filteredStream.toList();

          return material.Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (search.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() => search = '');
                            },
                          ),
                        GraphsFilters(
                          category: category,
                          setCategory: (value) {
                            setState(() {
                              category = value;
                            });
                          },
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() => search = value),
                ),
              ),
              if (gymSets.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text("No exercises found"),
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
    // Diverse exercises with proper muscle group categories
    final exerciseGroups = [
      // Chest exercises
      {
        'exercises': ['Bench Press', 'Incline Dumbbell Press', 'Cable Flyes'],
        'categories': ['Chest', 'Chest', 'Chest'],
        'repRanges': [5, 8, 12],
        'baseWeight': 100.0,
        'weightIncrement': 5.0,
      },
      // Back exercises
      {
        'exercises': ['Deadlift', 'Pull-ups', 'Barbell Row'],
        'categories': ['Back', 'Back', 'Back'],
        'repRanges': [5, 8, 10],
        'baseWeight': 80.0,
        'weightIncrement': 5.0,
      },
      // Leg exercises
      {
        'exercises': ['Squat', 'Leg Press', 'Romanian Deadlift'],
        'categories': ['Quads', 'Quads', 'Hamstrings'],
        'repRanges': [5, 10, 10],
        'baseWeight': 100.0,
        'weightIncrement': 5.0,
      },
      // Shoulder exercises
      {
        'exercises': ['Overhead Press', 'Lateral Raises', 'Face Pulls'],
        'categories': ['Shoulders', 'Shoulders', 'Shoulders'],
        'repRanges': [6, 12, 15],
        'baseWeight': 50.0,
        'weightIncrement': 2.5,
      },
      // Arm exercises
      {
        'exercises': ['Bicep Curls', 'Tricep Extensions', 'Hammer Curls'],
        'categories': ['Biceps', 'Triceps', 'Biceps'],
        'repRanges': [10, 12, 10],
        'baseWeight': 15.0,
        'weightIncrement': 1.25,
      },
    ];

    final now = DateTime.now();
    int workoutCount = 0;
    int totalSets = 0;

    // Create workouts spread across the last 6 months
    // 3-4 workouts per month on different days
    for (var monthOffset = 0; monthOffset < 6; monthOffset++) {
      final daysInMonth = [3, 10, 17, 24];
      for (var dayIndex = 0; dayIndex < 4; dayIndex++) {
        final day = daysInMonth[dayIndex];
        final workoutDate = DateTime(
          now.year,
          now.month - monthOffset,
          day,
          9 + (dayIndex * 3),
        ); // Vary workout times

        // Skip dates in the future
        if (workoutDate.isAfter(now)) continue;

        // Create a workout
        final workoutId = await db.workouts.insertOne(
          WorkoutsCompanion.insert(
            startTime: workoutDate,
            endTime:
                Value(workoutDate.add(const Duration(hours: 1, minutes: 30))),
            name: Value('Test Workout ${workoutDate.month}/${workoutDate.day}'),
          ),
        );

        // Add sets from different exercise groups
        final progressMultiplier = (6 - monthOffset) * 4 + dayIndex;

        // Cycle through exercise groups
        final groupIndex = (workoutCount % exerciseGroups.length);
        final group = exerciseGroups[groupIndex];

        for (var exerciseIndex = 0;
            exerciseIndex < (group['exercises'] as List).length;
            exerciseIndex++) {
          final exerciseName = (group['exercises'] as List)[exerciseIndex];
          final exerciseCategory = (group['categories'] as List)[exerciseIndex];
          final repRanges = group['repRanges'] as List<int>;
          final baseWeight = group['baseWeight'] as double;
          final weightIncrement = group['weightIncrement'] as double;

          // Vary number of sets (3-5 sets per exercise)
          final numSets = 3 + (exerciseIndex % 3);

          for (var setNum = 0; setNum < numSets; setNum++) {
            // Use different rep ranges from the group
            final reps = repRanges[setNum % repRanges.length].toDouble();

            // Progressive overload: weight increases over time
            final weight = baseWeight +
                (progressMultiplier * weightIncrement) -
                (setNum * weightIncrement * 0.5);

            await db.gymSets.insertOne(
              GymSetsCompanion.insert(
                name: exerciseName,
                reps: reps,
                weight: weight > 0 ? weight : baseWeight,
                unit: 'kg',
                created: workoutDate.add(
                  Duration(
                    minutes: exerciseIndex * 15 + setNum * 3,
                    seconds: setNum * 10,
                  ),
                ),
                workoutId: Value(workoutId),
                category: Value(exerciseCategory),
              ),
            );
            totalSets++;
          }
        }

        // Add some one-rep max attempts occasionally
        if (workoutCount % 5 == 0 && monthOffset < 3) {
          final heavyExercises = [
            {'name': 'Bench Press', 'category': 'Chest'},
            {'name': 'Squat', 'category': 'Quads'},
            {'name': 'Deadlift', 'category': 'Back'},
          ];
          for (var i = 0; i < heavyExercises.length; i++) {
            await db.gymSets.insertOne(
              GymSetsCompanion.insert(
                name: heavyExercises[i]['name']!,
                reps: 1.0,
                weight: 120.0 + (progressMultiplier * 5.0) + (i * 10.0),
                unit: 'kg',
                created: workoutDate.add(Duration(minutes: 60 + i * 10)),
                workoutId: Value(workoutId),
                category: Value(heavyExercises[i]['category']!),
              ),
            );
            totalSets++;
          }
        }

        workoutCount++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added $workoutCount workouts with $totalSets sets across 15 exercises with proper muscle groups',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  material.ListView graphList(List<GraphExercise> gymSets) {
    var itemCount = gymSets.length + 1;

    return ListView.builder(
      itemCount: itemCount,
      controller: scroll,
      padding: const EdgeInsets.only(bottom: 50, top: 8),
      itemBuilder: (context, index) {
        if (index == itemCount - 1) return const SizedBox(height: 96);

        final set = gymSets.elementAtOrNull(index);
        if (set == null) return const SizedBox();

        return GraphTile(
          selected: selected,
          exercise: set,
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
