import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../theme/tokens.dart';

/// Wrapper widget for Rive-animated navigation icons with fallback to Material Icons
class MorphingNavIcon extends StatefulWidget {

  const MorphingNavIcon({
    required this.animationAsset, required this.fallbackIcon, required this.isSelected, required this.color, super.key,
    this.size = 24.0,
  });
  final String animationAsset;
  final IconData fallbackIcon;
  final bool isSelected;
  final Color color;
  final double size;

  @override
  State<MorphingNavIcon> createState() => _MorphingNavIconState();
}

class _MorphingNavIconState extends State<MorphingNavIcon> {
  StateMachineController? _controller;
  SMIBool? _isSelectedInput;
  bool _useRive = true;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    try {
      // Attempt to load Rive file, will throw if not found
      await RiveFile.asset(widget.animationAsset);
      if (mounted) setState(() => _useRive = true);
    } catch (e) {
      // Fallback to Material Icon if Rive file not found
      if (mounted) setState(() => _useRive = false);
    }
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'NavIconStateMachine', // State machine name in Rive
    );

    if (controller != null) {
      artboard.addController(controller);
      _controller = controller;
      _isSelectedInput = controller.findInput<bool>('isSelected') as SMIBool?;
      _isSelectedInput?.value = widget.isSelected;
    }
  }

  @override
  void didUpdateWidget(MorphingNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      _isSelectedInput?.value = widget.isSelected;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_useRive) {
      // Fallback to Material Icon with scale animation
      return AnimatedScale(
        scale: widget.isSelected ? 1.1 : 1.0,
        duration: durMed,
        curve: curveStandard,
        child: Icon(
          widget.fallbackIcon,
          color: widget.color,
          size: widget.size,
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RiveAnimation.asset(
        widget.animationAsset,
        fit: BoxFit.contain,
        onInit: _onRiveInit,
      ),
    );
  }
}
