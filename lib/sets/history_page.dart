import 'package:drift/drift.dart';
import 'package:flexify/app_search.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/filters.dart';
import 'package:flexify/main.dart';
import 'package:flexify/sets/edit_sets_page.dart';
import 'package:flexify/sets/history_collapsed.dart';
import 'package:flexify/sets/history_list.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/utils.dart';
import 'package:flexify/workouts/workout_detail_page.dart';
import 'package:flexify/workouts/workouts_list.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

enum HistoryView { workouts, sets }

class HistoryDay {
  final String name;
  final List<GymSet> gymSets;
  final DateTime day;

  HistoryDay({required this.name, required this.gymSets, required this.day});
}

class HistoryPage extends StatefulWidget {
  final TabController tabController;

  const HistoryPage({super.key, required this.tabController});

  @override
  createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NavigatorPopHandler(
      onPopWithResult: (result) {
        if (navKey.currentState!.canPop() == false) return;
        final settings = context.read<SettingsState>().value;
        final historyIndex = settings.tabs.split(',').indexOf('HistoryPage');
        if (widget.tabController.index == historyIndex)
          navKey.currentState!.pop();
      },
      child: Navigator(
        key: navKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => _HistoryPageWidget(
            navigatorKey: navKey,
          ),
          settings: settings,
        ),
      ),
    );
  }
}

class _HistoryPageWidget extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const _HistoryPageWidget({required this.navigatorKey});

  @override
  createState() => _HistoryPageWidgetState();
}

class _HistoryPageWidgetState extends State<_HistoryPageWidget> {
  late Stream<List<GymSet>> stream;

  final repsGt = TextEditingController();
  final repsLt = TextEditingController();
  final weightGt = TextEditingController();
  final weightLt = TextEditingController();
  final scroll = ScrollController();

  Set<int> selected = {};
  Set<int> selectedWorkouts = {};
  String search = '';
  int limit = 100;
  DateTime? startDate;
  DateTime? endDate;
  String? category;
  HistoryView historyView = HistoryView.workouts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: material.Column(
        children: [
          _buildViewToggle(),
          if (historyView == HistoryView.workouts) ...[
            AppSearch(
              onChange: (value) {
                setState(() {
                  search = value;
                  limit = 100;
                });
              },
              onClear: () => setState(() {
                selectedWorkouts.clear();
              }),
              onDelete: () async {
                final copy = selectedWorkouts.toList();
                setState(() {
                  selectedWorkouts.clear();
                });
                // Delete all gym sets associated with these workouts
                await db.gymSets.deleteWhere((tbl) => tbl.workoutId.isIn(copy));
                // Delete the workouts themselves
                await db.workouts.deleteWhere((tbl) => tbl.id.isIn(copy));
              },
              onSelect: () async {
                // Get all workout IDs currently visible
                final workouts = await (db.workouts.select()
                      ..orderBy([
                        (w) => OrderingTerm(
                            expression: w.startTime, mode: OrderingMode.desc),
                      ])
                      ..limit(limit))
                    .get();
                setState(() {
                  selectedWorkouts.addAll(workouts.map((w) => w.id));
                });
              },
              onEdit: () async {
                // Navigate to workout detail page if only one workout is selected
                if (selectedWorkouts.length == 1) {
                  final workoutId = selectedWorkouts.first;
                  final workout = await (db.workouts.select()
                        ..where((w) => w.id.equals(workoutId)))
                      .getSingle();
                  if (context.mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailPage(workout: workout),
                      ),
                    );
                  }
                }
              },
              onShare: () async {
                final workouts = await (db.workouts.select()
                      ..where((w) => w.id.isIn(selectedWorkouts.toList()))
                      ..orderBy([
                        (w) => OrderingTerm(
                            expression: w.startTime, mode: OrderingMode.desc),
                      ]))
                    .get();

                final summaries = await Future.wait(
                  workouts.map((workout) async {
                    final sets = await (db.gymSets.select()
                          ..where((s) =>
                              s.workoutId.equals(workout.id) &
                              s.hidden.equals(false)))
                        .get();
                    final exerciseCount = sets.map((s) => s.name).toSet().length;
                    final date = DateFormat('MMM d, yyyy').format(workout.startTime);
                    return "${workout.name ?? 'Workout'} - $date\n$exerciseCount exercises, ${sets.length} sets";
                  }),
                );

                await SharePlus.instance.share(
                  ShareParams(text: summaries.join('\n\n')),
                );
                setState(() {
                  selectedWorkouts.clear();
                });
              },
              selected: selectedWorkouts,
            ),
            Expanded(
              child: WorkoutsList(
                scroll: scroll,
                onNext: () {
                  setState(() {
                    limit += 100;
                  });
                },
                search: search,
                startDate: startDate,
                endDate: endDate,
                limit: limit,
                selected: selectedWorkouts,
                onSelect: (id) {
                  if (selectedWorkouts.contains(id))
                    setState(() {
                      selectedWorkouts.remove(id);
                    });
                  else
                    setState(() {
                      selectedWorkouts.add(id);
                    });
                },
              ),
            ),
          ] else
            Expanded(
              child: StreamBuilder(
                stream: stream,
                builder: (context, snapshot) {
                  return material.Column(
                    children: [
                      AppSearch(
                        filter: Filters(
                          repsGtCtrl: repsGt,
                          repsLtCtrl: repsLt,
                          weightGtCtrl: weightGt,
                          weightLtCtrl: weightLt,
                          setStream: () {
                            setState(() {
                              limit = 100;
                            });
                            setStream();
                          },
                          endDate: endDate,
                          startDate: startDate,
                          setEnd: (value) {
                            setState(() {
                              endDate = value;
                              limit = 100;
                            });
                            setStream();
                          },
                          setStart: (value) {
                            setState(() {
                              startDate = value;
                              limit = 100;
                            });
                            setStream();
                          },
                          category: category,
                          setCategory: (value) {
                            setState(() {
                              category = value;
                              limit = 100;
                            });
                            setStream();
                          },
                        ),
                        onShare: () async {
                          final gymSets = snapshot.data!
                              .where(
                                (gymSet) => selected.contains(gymSet.id),
                              )
                              .toList();
                          final summaries = gymSets
                              .map(
                                (gymSet) =>
                                    "${toString(gymSet.reps)}x${toString(gymSet.weight)}${gymSet.unit} ${gymSet.name}",
                              )
                              .join(', ');
                          await SharePlus.instance
                              .share(ShareParams(text: "I just did $summaries"));
                          setState(() {
                            selected.clear();
                          });
                        },
                        onChange: (value) {
                          setState(() {
                            search = value;
                            limit = 100;
                          });
                          setStream();
                        },
                        onClear: () => setState(() {
                          selected.clear();
                        }),
                        onDelete: () {
                          (db.delete(db.gymSets)
                                ..where((tbl) => tbl.id.isIn(selected)))
                              .go();
                          setState(() {
                            selected.clear();
                          });
                        },
                        onSelect: () => setState(() {
                          if (snapshot.data == null) return;
                          selected
                              .addAll(snapshot.data!.map((gymSet) => gymSet.id));
                        }),
                        selected: selected,
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditSetsPage(
                              ids: selected.toList(),
                            ),
                          ),
                        ),
                      ),
                      if (snapshot.data?.isEmpty == true)
                        const ListTile(
                          title: Text("No entries yet"),
                          subtitle: Text(
                            "Complete some sets to see them here",
                          ),
                        ),
                      if (snapshot.hasError)
                        Expanded(child: ErrorWidget(snapshot.error.toString())),
                      if (snapshot.hasData)
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final groupHistory =
                                  context.select<SettingsState, bool>(
                                (settings) => settings.value.groupHistory,
                              );

                              if (groupHistory) {
                                final historyDays =
                                    getHistoryDays(snapshot.data!);
                                return HistoryCollapsed(
                                  scroll: scroll,
                                  days: historyDays,
                                  onSelect: (id) {
                                    if (selected.contains(id))
                                      setState(() {
                                        selected.remove(id);
                                      });
                                    else
                                      setState(() {
                                        selected.add(id);
                                      });
                                  },
                                  selected: selected,
                                  onNext: () {
                                    setState(() {
                                      limit += 100;
                                    });
                                    setStream();
                                  },
                                );
                              } else
                                return HistoryList(
                                  scroll: scroll,
                                  sets: snapshot.data!,
                                  onSelect: (id) {
                                    if (selected.contains(id))
                                      setState(() {
                                        selected.remove(id);
                                      });
                                    else
                                      setState(() {
                                        selected.add(id);
                                      });
                                  },
                                  selected: selected,
                                  onNext: () {
                                    setState(() {
                                      limit += 100;
                                    });
                                    setStream();
                                  },
                                );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<HistoryView>(
        segments: const [
          ButtonSegment<HistoryView>(
            value: HistoryView.workouts,
            label: Text('Workouts'),
            icon: Icon(Icons.fitness_center),
          ),
          ButtonSegment<HistoryView>(
            value: HistoryView.sets,
            label: Text('Sets'),
            icon: Icon(Icons.list),
          ),
        ],
        selected: {historyView},
        onSelectionChanged: (Set<HistoryView> selection) {
          setState(() {
            historyView = selection.first;
            limit = 100;
          });
        },
      ),
    );
  }

  List<HistoryDay> getHistoryDays(List<GymSet> gymSets) {
    List<HistoryDay> historyDays = [];
    for (final gymSet in gymSets) {
      final day = DateUtils.dateOnly(gymSet.created);
      // Group by day, workout, AND exercise name to properly group sets
      final index = historyDays.indexWhere((hd) =>
          isSameDay(hd.day, day) &&
          hd.name == gymSet.name &&
          hd.gymSets.first.workoutId == gymSet.workoutId);
      if (index == -1)
        historyDays.add(
          HistoryDay(name: gymSet.name, gymSets: [gymSet], day: day),
        );
      else
        historyDays[index].gymSets.add(gymSet);
    }
    return historyDays;
  }

  @override
  void initState() {
    super.initState();
    setStream();
  }

  void setStream() {
    final terms =
        search.toLowerCase().split(" ").where((term) => term.isNotEmpty);

    var query = (db.gymSets.select()
      ..orderBy(
        [
          (u) => OrderingTerm(
                expression: u.created,
                mode: OrderingMode.desc,
              ),
        ],
      )
      ..where((tbl) => tbl.hidden.equals(false))
      ..limit(limit));

    for (final term in terms) {
      query = query..where((tbl) => tbl.name.contains(term));
    }

    if (category != null)
      query = query..where((tbl) => tbl.category.equals(category!));
    if (startDate != null)
      query = query
        ..where((tbl) => tbl.created.isBiggerOrEqualValue(startDate!));
    if (endDate != null)
      query = query
        ..where((tbl) => tbl.created.isSmallerOrEqualValue(endDate!));
    if (repsGt.text.isNotEmpty)
      query = query
        ..where(
          (tbl) =>
              tbl.reps.isBiggerThanValue(
                double.tryParse(repsGt.text) ?? 0,
              ) &
              tbl.cardio.equals(false),
        );
    if (repsLt.text.isNotEmpty)
      query = query
        ..where(
          (tbl) =>
              tbl.reps.isSmallerThanValue(
                double.tryParse(repsLt.text) ?? 0,
              ) &
              tbl.cardio.equals(false),
        );
    if (weightGt.text.isNotEmpty)
      query = query
        ..where(
          (tbl) =>
              tbl.weight.isBiggerThanValue(
                double.tryParse(weightGt.text) ?? 0,
              ) &
              tbl.cardio.equals(false),
        );
    if (weightLt.text.isNotEmpty)
      query = query
        ..where(
          (tbl) =>
              tbl.weight.isSmallerThanValue(
                double.tryParse(weightLt.text) ?? 0,
              ) &
              tbl.cardio.equals(false),
        );

    setState(() {
      stream = query.watch();
    });
  }
}
