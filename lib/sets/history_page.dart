import 'package:drift/drift.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_search.dart';
import '../database/database.dart';
import '../filters.dart';
import '../main.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../utils.dart';
import '../workouts/workouts_list.dart';
import 'edit_sets_page.dart';
import 'history_collapsed.dart';
import 'history_list.dart';

enum HistoryView { workouts, sets }

class HistoryDay {

  HistoryDay({required this.name, required this.gymSets, required this.day});
  final String name;
  final List<GymSet> gymSets;
  final DateTime day;
}

class HistoryPage extends StatefulWidget {

  const HistoryPage({required this.tabController, super.key});
  final TabController tabController;

  @override
  HistoryPageState createState() => HistoryPageState();
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

  const _HistoryPageWidget({required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  _HistoryPageWidgetState createState() => _HistoryPageWidgetState();
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
              showMenu: false,
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
                            expression: w.startTime, mode: OrderingMode.desc,),
                      ])
                      ..limit(limit))
                    .get();
                setState(() {
                  selectedWorkouts.addAll(workouts.map((w) => w.id));
                });
              },
              onEdit: () {},
              onShare: () {},
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
                        showMenu: false,
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
                                    '${toString(gymSet.weight)}${gymSet.unit} x ${toString(gymSet.reps)} ${gymSet.name}',
                              )
                              .join(', ');
                          await SharePlus.instance.share(
                              ShareParams(text: 'I just did $summaries'),);
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
                          selected.addAll(
                              snapshot.data!.map((gymSet) => gymSet.id),);
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
                      if (snapshot.data?.isEmpty ?? false)
                        const ListTile(
                          title: Text('No entries yet'),
                          subtitle: Text(
                            'Complete some sets to see them here',
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
      padding: const EdgeInsets.symmetric(horizontal: space16, vertical: space4),
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
    final List<HistoryDay> historyDays = [];
    for (final gymSet in gymSets) {
      final day = DateUtils.dateOnly(gymSet.created);
      // Group by day, workout, AND exercise name to properly group sets
      final index = historyDays.indexWhere((hd) =>
          isSameDay(hd.day, day) &&
          hd.name == gymSet.name &&
          hd.gymSets.first.workoutId == gymSet.workoutId,);
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
        search.toLowerCase().split(' ').where((term) => term.isNotEmpty);

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
