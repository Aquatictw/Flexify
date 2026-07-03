import 'package:flutter/material.dart';
import '../../graph/overview_page.dart';
import '../../theme/components.dart';
import '../../theme/tokens.dart';

class PeriodSelector extends StatelessWidget {

  const PeriodSelector({
    required this.selectedPeriod, required this.onPeriodChanged, super.key,
  });
  final OverviewPeriod selectedPeriod;
  final ValueChanged<OverviewPeriod> onPeriodChanged;

  String _getPeriodLabel(OverviewPeriod p) {
    switch (p) {
      case OverviewPeriod.week:
        return '7D';
      case OverviewPeriod.month:
        return '1M';
      case OverviewPeriod.months3:
        return '3M';
      case OverviewPeriod.months6:
        return '6M';
      case OverviewPeriod.year:
        return '1Y';
      case OverviewPeriod.allTime:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: OverviewPeriod.values.map((p) {
          final isSelected = selectedPeriod == p;
          return Padding(
            padding: const EdgeInsets.only(right: space8),
            child: FilterPill(
              label: _getPeriodLabel(p),
              selected: isSelected,
              onTap: () => onPeriodChanged(p),
            ),
          );
        }).toList(),
      ),
    );
  }
}
