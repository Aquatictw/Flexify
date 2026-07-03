import 'package:flutter/material.dart';

import 'theme/tokens.dart';

class AnimatedFab extends StatefulWidget {

  const AnimatedFab({
    required this.onPressed, required this.label, required this.icon, super.key,
    this.scroll,
  });
  final Function onPressed;
  final Widget label;
  final ScrollController? scroll;
  final Widget? icon;

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<AnimatedFab> {
  bool extended = true;

  @override
  void initState() {
    super.initState();
    widget.scroll?.addListener(onScroll);
  }

  @override
  void dispose() {
    widget.scroll?.removeListener(onScroll);
    super.dispose();
  }

  void onScroll() {
    if (widget.scroll!.position.atEdge && widget.scroll!.position.pixels == 0)
      setState(() {
        extended = true;
      });
    else
      setState(() {
        extended = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
      child: AnimatedContainer(
        duration: durFast,
        curve: curveStandard,
        width: extended ? 100 : 56,
        height: 56,
        child: FloatingActionButton.extended(
          heroTag: 'hero',
          onPressed: () => widget.onPressed(),
          label: AnimatedOpacity(
            duration: durFast,
            opacity: extended ? 1.0 : 0.0,
            child: widget.label,
          ),
          icon: widget.icon,
          isExtended: extended,
        ),
      ),
    );
  }
}
