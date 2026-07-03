import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/tokens.dart';
import 'reps_button.dart';

class RepsInput extends StatefulWidget {

  const RepsInput({
    required this.value, required this.completed, required this.accentColor, required this.onChanged, super.key,
    this.enabled = true,
  });
  final int value;
  final bool enabled;
  final bool completed;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  @override
  State<RepsInput> createState() => _RepsInputState();
}

class _RepsInputState extends State<RepsInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      // Focus state tracked by _focusNode directly
    });
  }

  @override
  void didUpdateWidget(RepsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.completed
            ? widget.accentColor.withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: brSm,
        border: widget.completed
            ? Border.all(
                color: widget.accentColor.withValues(alpha: 0.3),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepsButton(
            icon: Icons.remove,
            accentColor: widget.accentColor,
            onPressed: widget.value > 1
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onChanged(widget.value - 1);
                  }
                : null,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.completed
                        ? widget.accentColor
                        : colorScheme.onSurface,
                  ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 10,
                ),
                border: InputBorder.none,
                hintText: 'reps',
                hintStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed > 0 && parsed < 100) {
                  widget.onChanged(parsed);
                }
              },
              onTap: () {
                _controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controller.text.length,
                );
              },
            ),
          ),
          RepsButton(
            icon: Icons.add,
            accentColor: widget.accentColor,
            onPressed: widget.value < 99
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onChanged(widget.value + 1);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
