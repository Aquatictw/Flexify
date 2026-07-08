import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class StickyFormAction extends StatelessWidget {
  const StickyFormAction({
    required this.onPressed,
    required this.label,
    required this.icon,
    super.key,
  });

  final VoidCallback onPressed;
  final Widget label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: durFast,
      curve: curveStandard,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            space24,
            space12,
            space24,
            space12,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            heightFactor: 1,
            child: FloatingActionButton.extended(
              heroTag: null,
              onPressed: onPressed,
              label: label,
              icon: icon,
            ),
          ),
        ),
      ),
    );
  }
}
