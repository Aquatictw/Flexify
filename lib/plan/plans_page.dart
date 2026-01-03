import 'package:drift/drift.dart' as drift;
import 'package:flexify/app_search.dart';
import 'package:flexify/database/database.dart';
import 'package:flexify/main.dart';
import 'package:flexify/plan/edit_plan_page.dart';
import 'package:flexify/plan/plan_state.dart';
import 'package:flexify/plan/plans_list.dart';
import 'package:flexify/plan/start_plan_page.dart';
import 'package:flexify/settings/settings_state.dart';
import 'package:flexify/workouts/workout_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class PlansPage extends StatefulWidget {
  final TabController tabController;

  const PlansPage({super.key, required this.tabController});

  @override
  State<PlansPage> createState() => PlansPageState();
}

class PlansPageState extends State<PlansPage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Register navigator key with WorkoutState for ActiveWorkoutBar navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutState>().setPlansNavigatorKey(navKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NavigatorPopHandler(
      onPopWithResult: (result) {
        if (navKey.currentState!.canPop() == false) return;
        final settings = context.read<SettingsState>().value;
        final index = settings.tabs.split(',').indexOf('PlansPage');
        if (widget.tabController.index == index) navKey.currentState!.pop();
      },
      child: Navigator(
        key: navKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => _PlansPageWidget(
            navKey: navKey,
          ),
          settings: settings,
        ),
      ),
    );
  }
}

class _PlansPageWidget extends StatefulWidget {
  final GlobalKey<NavigatorState> navKey;

  const _PlansPageWidget({required this.navKey});

  @override
  createState() => _PlansPageWidgetState();
}

class _PlansPageWidgetState extends State<_PlansPageWidget> {
  PlanState? state;
  String search = '';
  List<Plan>? filtered;

  final Set<int> selected = {};
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    state = context.read<PlanState>();
    state?.addListener(_onPlansStateChanged);
    _filterPlans();
  }

  @override
  void dispose() {
    state?.removeListener(_onPlansStateChanged);
    super.dispose();
  }

  void _onPlansStateChanged() {
    _filterPlans();
  }

  Future<void> _filterPlans() async {
    if (state == null) return;

    final allPlans = state!.plans;
    List<Plan> tempFiltered = [];

    for (final plan in allPlans) {
      bool matches = plan.days.toLowerCase().contains(search.toLowerCase());
      if (!matches && search.isNotEmpty) {
        final planExercises = await (db.planExercises.select()
              ..where(
                (tbl) =>
                    tbl.planId.equals(plan.id) & tbl.exercise.like('%$search%'),
              ))
            .get();
        matches = planExercises.isNotEmpty;
      }
      if (matches) {
        tempFiltered.add(plan);
      }
    }

    setState(() {
      filtered = tempFiltered;
    });
  }

  String _getTimeBasedWorkoutTitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning Workout';
    if (hour < 14) return 'Noon Workout';
    if (hour < 18) return 'Afternoon Workout';
    return 'Evening Workout';
  }

  Future<void> _startFreeformWorkout() async {
    final workoutState = context.read<WorkoutState>();

    // Create a temporary plan for freeform workout
    final freeformPlan = Plan(
      id: -1, // Temporary ID
      days: _getTimeBasedWorkoutTitle(),
      sequence: 0,
      title: _getTimeBasedWorkoutTitle(),
    );

    // Start workout directly without a real plan
    final workoutId = await db.workouts.insertOne(
      WorkoutsCompanion(
        startTime: drift.Value(DateTime.now()),
        name: drift.Value(_getTimeBasedWorkoutTitle()),
      ),
    );

    final workout = await (db.workouts.select()
          ..where((w) => w.id.equals(workoutId)))
        .getSingle();

    // Pass the freeform plan so the active workout overlay can reopen it
    workoutState.setActiveWorkout(workout, freeformPlan);

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StartPlanPage(plan: freeformPlan),
          settings: RouteSettings(
            name: 'StartPlanPage_${freeformPlan.id}',
          ),
        ),
      );
    }
  }

  Widget _buildFreeformButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      borderRadius: BorderRadius.circular(16),
      color: colorScheme.secondaryContainer,
      child: InkWell(
        onTap: _startFreeformWorkout,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: colorScheme.onSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Freeform Workout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Start with an empty workout',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSecondaryContainer.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    state = context.watch<PlanState>(); // Watch for changes to rebuild

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          AppSearch(
            onAdd: () async {
              const plan = PlansCompanion(
                days: drift.Value(''),
              );
              await state!.setExercises(plan);
              if (context.mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditPlanPage(
                      plan: plan,
                    ),
                  ),
                );
              }
            },
            onShare: () async {
              final plans = (state?.plans)!
                  .where(
                    (plan) => selected.contains(plan.id),
                  )
                  .toList();

              final summaries = await Future.wait(
                plans.map((plan) async {
                  final days = plan.days.split(',').join(', ');
                  await state?.setExercises(plan.toCompanion(false));
                  final exercises = state?.exercises
                      .where((pe) => pe.enabled.value)
                      .map((pe) => "- ${pe.exercise.value}")
                      .join('\n');

                  return "$days:\n$exercises";
                }),
              );

              await SharePlus.instance
                  .share(ShareParams(text: summaries.join('\n\n')));
              setState(() {
                selected.clear();
              });
            },
            onChange: (value) {
              setState(() {
                search = value;
                _filterPlans(); // Re-filter when search changes
              });
            },
            onClear: () => setState(() {
              selected.clear();
            }),
            onDelete: () async {
              final state = context.read<PlanState>();
              final copy = selected.toList();
              setState(() {
                selected.clear();
              });
              await db.plans.deleteWhere((tbl) => tbl.id.isIn(copy));
              state.updatePlans(null);
              await db.planExercises
                  .deleteWhere((tbl) => tbl.planId.isIn(copy));
            },
            onSelect: () => setState(() {
              selected.addAll(filtered?.map((plan) => plan.id) ?? []);
            }),
            selected: selected,
            onEdit: () async {
              final plan = state!.plans
                  .firstWhere(
                    (element) => element.id == selected.first,
                  )
                  .toCompanion(false);
              await state!.setExercises(plan);
              if (context.mounted)
                return Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPlanPage(
                      plan: plan,
                    ),
                  ),
                );
            },
          ),
          Expanded(
            child: PlansList(
              scroll: scroll,
              plans: filtered,
              navKey: widget.navKey,
              selected: selected,
              search: search,
              footer: _buildFreeformButton(context),
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
            ),
          ),
        ],
      ),
    );
  }
}
