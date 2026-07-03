import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class WeightInput extends StatefulWidget {

  const WeightInput({
    required this.value, required this.unit, required this.completed, required this.accentColor, required this.onChanged, super.key,
    this.enabled = true,
  });
  final double value;
  final String unit;
  final bool enabled;
  final bool completed;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  @override
  State<WeightInput> createState() => _WeightInputState();
}

class _WeightInputState extends State<WeightInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatWeight(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(WeightInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_hasFocus) {
      _controller.text = _formatWeight(widget.value);
    }
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
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

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: widget.completed ? widget.accentColor : colorScheme.onSurface,
          ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: space8, vertical: 10),
        suffixText: widget.unit,
        suffixStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
        border: OutlineInputBorder(
          borderRadius: brSm,
          borderSide: widget.completed
              ? BorderSide(
                  color: widget.accentColor.withValues(alpha: 0.3),
                )
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: brSm,
          borderSide: widget.completed
              ? BorderSide(
                  color: widget.accentColor.withValues(alpha: 0.3),
                )
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: brSm,
          borderSide: BorderSide(color: widget.accentColor, width: 2),
        ),
        filled: true,
        fillColor: widget.completed
            ? widget.accentColor.withValues(alpha: 0.1)
            : colorScheme.surface,
      ),
      onChanged: (value) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          widget.onChanged(parsed);
        }
      },
      onTap: () {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      },
    );
  }
}
