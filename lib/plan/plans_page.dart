import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database.dart';
import '../main.dart';
import '../settings/settings_page.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../utils.dart';
import '../widgets/timer_quick_access.dart';
import '../workouts/workout_state.dart';
import 'edit_plan_page.dart';
import 'plan_state.dart';
import 'plans_list.dart';
import 'start_plan_page.dart';

class PlansPage extends StatefulWidget {

  const PlansPage({required this.tabController, super.key});
  final TabController tabController;

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

  const _PlansPageWidget({required this.navKey});
  final GlobalKey<NavigatorState> navKey;

  @override
  _PlansPageWidgetState createState() => _PlansPageWidgetState();
}

class _PlansPageWidgetState extends State<_PlansPageWidget> {
  PlanState? state;
  List<Plan>? plans;

  final Set<int> selected = {};
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    state = context.read<PlanState>();
    state?.addListener(_onPlansStateChanged);
    _updatePlans();
  }

  @override
  void dispose() {
    state?.removeListener(_onPlansStateChanged);
    super.dispose();
  }

  void _onPlansStateChanged() {
    _updatePlans();
  }

  void _updatePlans() {
    if (state == null) return;
    setState(() {
      plans = state!.plans;
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

    // Check if there's any active workout
    if (workoutState.hasActiveWorkout) {
      toast(
        'Finish your current workout first',
        action: SnackBarAction(
          label: 'Resume',
          onPressed: () {
            if (workoutState.activePlan != null) {
              widget.navKey.currentState!.push(
                MaterialPageRoute(
                  builder: (context) => StartPlanPage(
                    plan: workoutState.activePlan!,
                  ),
                  settings: RouteSettings(
                    name: 'StartPlanPage_${workoutState.activePlan!.id}',
                  ),
                ),
              );
            }
          },
        ),
      );
      return;
    }

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
      borderRadius: brMd,
      color: colorScheme.secondaryContainer,
      child: InkWell(
        onTap: _startFreeformWorkout,
        borderRadius: brMd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: space16,
            horizontal: space16,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(space8),
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: brSm,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: colorScheme.onSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Freeform Workout',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                    ),
                    const SizedBox(height: space4 / 2),
                    Text(
                      'Start with an empty workout',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer
                                .withValues(alpha: 0.7),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: selected.isEmpty
            ? const Text('Plans')
            : Text('${selected.length} selected'),
        leading: selected.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(selected.clear),
              ),
        actions: [
          if (selected.isEmpty)
            IconButton(
              icon: const Icon(Icons.timer),
              tooltip: 'Timer',
              onPressed: () => showTimerQuickAccess(context),
            ),
          if (selected.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete selected',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text(
                        'Are you sure you want to delete ${selected.length} plan${selected.length == 1 ? '' : 's'}? This action is not reversible.',
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
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            final state = context.read<PlanState>();
                            final copy = selected.toList();
                            setState(selected.clear);
                            await db.plans
                                .deleteWhere((tbl) => tbl.id.isIn(copy));
                            state.updatePlans(null);
                            await db.planExercises
                                .deleteWhere((tbl) => tbl.planId.isIn(copy));
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          Badge.count(
            count: selected.length,
            isLabelVisible: selected.isNotEmpty,
            backgroundColor: colorScheme.primary,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Show menu',
              onSelected: (value) async {
                switch (value) {
                  case 'add':
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
                    break;
                  case 'select_all':
                    setState(() {
                      selected.addAll(plans?.map((plan) => plan.id) ?? []);
                    });
                    break;
                  case 'edit':
                    final plan = state!.plans
                        .firstWhere(
                          (element) => element.id == selected.first,
                        )
                        .toCompanion(false);
                    await state!.setExercises(plan);
                    if (context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPlanPage(
                            plan: plan,
                          ),
                        ),
                      );
                    }
                    break;
                  case 'share':
                    final plansList = (state?.plans)!
                        .where(
                          (plan) => selected.contains(plan.id),
                        )
                        .toList();

                    final summaries = await Future.wait(
                      plansList.map((plan) async {
                        final days = plan.days.split(',').join(', ');
                        await state?.setExercises(plan.toCompanion(false));
                        final exercises = state?.exercises
                            .where((pe) => pe.enabled.value)
                            .map((pe) => '- ${pe.exercise.value}')
                            .join('\n');

                        return '$days:\n$exercises';
                      }),
                    );

                    await SharePlus.instance
                        .share(ShareParams(text: summaries.join('\n\n')));
                    setState(selected.clear);
                    break;
                  case 'settings':
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                if (selected.isEmpty)
                  const PopupMenuItem(
                    value: 'add',
                    child: ListTile(
                      leading: Icon(Icons.add),
                      title: Text('Add'),
                    ),
                  ),
                const PopupMenuItem(
                  value: 'select_all',
                  child: ListTile(
                    leading: Icon(Icons.done_all),
                    title: Text('Select all'),
                  ),
                ),
                if (selected.isNotEmpty) ...[
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Share'),
                    ),
                  ),
                ],
                if (selected.isEmpty)
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Settings'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: PlansList(
        scroll: scroll,
        plans: plans,
        navKey: widget.navKey,
        selected: selected,
        search: '',
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
    );
  }
}
