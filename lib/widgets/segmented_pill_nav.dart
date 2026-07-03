import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'morphing_nav_icon.dart';

/// Unified segmented pill navigation bar with morphing icons
class SegmentedPillNav extends StatefulWidget {

  const SegmentedPillNav({
    required this.tabs, required this.currentIndex, required this.onTap, super.key,
    this.onLongPress,
  });
  final List<String> tabs;
  final int currentIndex;
  final Function(int) onTap;
  final Function(BuildContext, String)? onLongPress;

  @override
  State<SegmentedPillNav> createState() => _SegmentedPillNavState();
}

class _SegmentedPillNavState extends State<SegmentedPillNav>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: durMed,
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: curveStandard,
      ),
    );
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(SegmentedPillNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _slideController.reset();
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  String _getRiveAssetForTab(String tab) {
    switch (tab) {
      case 'HistoryPage':
        return 'assets/animations/nav_history.riv';
      case 'PlansPage':
        return 'assets/animations/nav_plans.riv';
      case 'MusicPage':
        return 'assets/animations/nav_music.riv';
      case 'GraphsPage':
        return 'assets/animations/nav_graphs.riv';
      case 'NotesPage':
        return 'assets/animations/nav_notes.riv';
      case 'SettingsPage':
        return 'assets/animations/nav_settings.riv';
      default:
        return '';
    }
  }

  IconData _getFallbackIconForTab(String tab) {
    switch (tab) {
      case 'HistoryPage':
        return Icons.history_rounded;
      case 'PlansPage':
        return Icons.calendar_today_rounded;
      case 'MusicPage':
        return Icons.music_note;
      case 'GraphsPage':
        return Icons.insights_rounded;
      case 'NotesPage':
        return Icons.note_rounded;
      case 'SettingsPage':
        return Icons.settings_rounded;
      default:
        return Icons.error_rounded;
    }
  }

  String _getLabelForTab(String tab) {
    switch (tab) {
      case 'HistoryPage':
        return 'History';
      case 'PlansPage':
        return 'Plans';
      case 'MusicPage':
        return 'Music';
      case 'GraphsPage':
        return 'Graphs';
      case 'NotesPage':
        return 'Notes';
      case 'SettingsPage':
        return 'Settings';
      default:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = space16;
    const pillPadding = space8;
    final tabWidth =
        (screenWidth - (horizontalPadding * 2) - (pillPadding * 2)) /
            widget.tabs.length;

    return ColoredBox(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: space8,
          bottom: space16,
        ),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: color.surfaceContainerHigh,
            borderRadius: brPill,
            border: Border.all(
              color: color.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.all(pillPadding),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Sliding background indicator
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  final double startX = _previousIndex * tabWidth;
                  final double endX = widget.currentIndex * tabWidth;
                  final double currentX =
                      startX + (endX - startX) * _slideAnimation.value;

                  return Positioned(
                    left: currentX,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: tabWidth,
                      decoration: BoxDecoration(
                        color: color.primary,
                        borderRadius: brPill,
                        boxShadow: [
                          BoxShadow(
                            color: color.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Tab items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: widget.tabs.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final String tab = entry.value;
                  final bool isSelected = index == widget.currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      key: Key(tab),
                      onTap: () => widget.onTap(index),
                      onLongPress: widget.onLongPress != null
                          ? () => widget.onLongPress!(context, tab)
                          : null,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: brPill,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MorphingNavIcon(
                              animationAsset: _getRiveAssetForTab(tab),
                              fallbackIcon: _getFallbackIconForTab(tab),
                              isSelected: isSelected,
                              color: isSelected
                                  ? color.onPrimary
                                  : color.onSurface,
                            ),
                            const SizedBox(height: space4),
                            AnimatedDefaultTextStyle(
                              duration: durMed,
                              curve: curveStandard,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    color: isSelected
                                        ? color.onPrimary
                                        : color.onSurface
                                            .withValues(alpha: 0.7),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                              child: Text(
                                _getLabelForTab(tab),
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
