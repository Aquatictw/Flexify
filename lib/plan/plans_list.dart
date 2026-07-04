import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../database/database.dart';
import '../main.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import '../widgets/depth_ember_reveal.dart';
import 'edit_plan_page.dart';
import 'plan_state.dart';
import 'plan_tile.dart';

class PlansList extends StatefulWidget {
  const PlansList({
    required this.plans,
    required this.navKey,
    required this.selected,
    required this.onSelect,
    required this.search,
    required this.scroll,
    super.key,
    this.footer,
  });
  final List<Plan>? plans;
  final GlobalKey<NavigatorState> navKey;
  final Set<int> selected;
  final Function(int) onSelect;
  final String search;
  final ScrollController scroll;
  final Widget? footer;

  @override
  State<PlansList> createState() => _PlansListState();
}

class _PlansListState extends State<PlansList> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlanState>();

    final noneFound = ListTile(
      title: const Text('No plans found'),
      subtitle: Text('Tap to create ${widget.search}'),
      onTap: () async {
        final plan = PlansCompanion(
          days: const drift.Value(''),
          title: drift.Value(widget.search),
        );
        await state.setExercises(plan);
        if (context.mounted)
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPlanPage(
                plan: plan,
              ),
            ),
          );
      },
    );

    if (widget.plans == null) return noneFound;

    final weekday = weekdays[DateTime.now().weekday - 1];

    final filteredPlans = widget.plans!.where((plan) {
      final term = widget.search.toLowerCase();
      return (plan.title?.toLowerCase().contains(term) ?? false) ||
          plan.days.toLowerCase().contains(term);
    }).toList();

    if (widget.plans!.isEmpty || filteredPlans.isEmpty) return noneFound;

    final settings = context.read<SettingsState>();

    if (settings.value.planTrailing == PlanTrailing.reorder.toString())
      return CustomScrollView(
        controller: widget.scroll,
        slivers: [
          SliverReorderableList(
            itemCount: filteredPlans.length,
            itemBuilder: (context, index) {
              final plan = filteredPlans[index];

              return RevealBlock(
                key: Key(plan.id.toString()),
                index: index,
                child: PlanTile(
                  plan: plan,
                  weekday: weekday,
                  index: index,
                  navigatorKey: widget.navKey,
                  selected: widget.selected,
                  onSelect: (id) => widget.onSelect(id),
                ),
              );
            },
            onReorder: (int old, int idx) async {
              if (old < idx) {
                idx--;
              }

              final temp = filteredPlans[old];
              filteredPlans.removeAt(old);
              filteredPlans.insert(idx, temp);

              final state = context.read<PlanState>();
              state.updatePlans(filteredPlans);
              await db.transaction(() async {
                for (int i = 0; i < filteredPlans.length; i++) {
                  final plan = filteredPlans[i];
                  final updated = plan
                      .toCompanion(false)
                      .copyWith(sequence: drift.Value(i));
                  await db.update(db.plans).replace(updated);
                }
              });
            },
          ),
          if (widget.footer != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  space16,
                  space8,
                  space16,
                  space16,
                ),
                child: widget.footer,
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
          ),
        ],
      );

    return CustomScrollView(
      controller: widget.scroll,
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: space8)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final plan = filteredPlans[index];

              return RevealBlock(
                index: index,
                child: PlanTile(
                  plan: plan,
                  weekday: weekday,
                  index: index,
                  navigatorKey: widget.navKey,
                  selected: widget.selected,
                  onSelect: (id) => widget.onSelect(id),
                ),
              );
            },
            childCount: filteredPlans.length,
          ),
        ),
        if (widget.footer != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                space16,
                space8,
                space16,
                space16,
              ),
              child: widget.footer,
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
        ),
      ],
    );
  }
}
