import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/set_data.dart';
import '../../records/records_service.dart';
import '../../theme/tokens.dart';
import '../../utils/cardio_format.dart';
import '../../utils/duration_format.dart';
import 'complete_button.dart';

class CardioBout extends StatelessWidget {
  const CardioBout({
    required this.index,
    required this.setData,
    required this.unit,
    required this.onDurationChanged,
    required this.onDistanceChanged,
    required this.onSpeedChanged,
    required this.onInclineChanged,
    required this.onToggle,
    required this.onDelete,
    super.key,
    this.records = const {},
  });

  final int index;
  final SetData setData;
  final String unit;
  final ValueChanged<double> onDurationChanged;
  final ValueChanged<double> onDistanceChanged;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<int?> onInclineChanged;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Set<RecordType> records;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = setData.completed;
    final accentColor = completed ? colorScheme.primary : colorScheme.tertiary;
    final primary = setData.cardioMetric ?? cardioMetricDuration;
    final metrics = [
      _MetricField(
        metric: cardioMetricDuration,
        label: 'Time',
        value: formatDurationMinutes(setData.duration),
        suffix: 'mm:ss',
        formatAsDuration: true,
        parse: _parseDuration,
        onChanged: onDurationChanged,
      ),
      _MetricField(
        metric: cardioMetricDistance,
        label: 'Distance',
        value: _formatNumber(setData.distance),
        suffix: unit,
        parse: double.tryParse,
        onChanged: onDistanceChanged,
      ),
      _MetricField(
        metric: cardioMetricSpeed,
        label: 'Speed',
        value: _formatNumber(cardioSpeed(setData.distance, setData.duration)),
        suffix: '$unit/h',
        parse: double.tryParse,
        onChanged: onSpeedChanged,
      ),
      _MetricField(
        metric: cardioMetricIncline,
        label: 'Incline',
        value: setData.incline?.toString() ?? '',
        suffix: '%',
        parse: (value) => int.tryParse(value)?.toDouble(),
        onChanged: (value) => onInclineChanged(value.toInt()),
        onCleared: () => onInclineChanged(null),
      ),
    ];

    final ordered = [
      metrics.firstWhere((metric) => metric.metric == primary),
      ...metrics.where((metric) => metric.metric != primary),
    ];

    return Dismissible(
      key: Key('dismissible_bout_${setData.savedSetId ?? index}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        margin:
            const EdgeInsets.symmetric(horizontal: space12, vertical: space4),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: brMd,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: space24),
        child: Icon(Icons.delete_outline, color: colorScheme.error),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: space12, vertical: 6),
        padding: const EdgeInsets.all(space12),
        decoration: BoxDecoration(
          color: completed
              ? colorScheme.primaryContainer.withValues(alpha: 0.22)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: brMd,
          border: Border.all(
            color: completed
                ? colorScheme.primary.withValues(alpha: 0.45)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: brSm,
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.directions_run, size: 14, color: accentColor),
                      Text(
                        '$index',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: accentColor,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: space12),
                Expanded(
                  child: ordered.first.build(
                    context,
                    completed: completed,
                    accentColor: accentColor,
                    featured: true,
                  ),
                ),
                const SizedBox(width: space8),
                CompleteButton(
                  completed: completed,
                  isWarmup: false,
                  records: completed ? records : {},
                  onPressed: onToggle,
                ),
              ],
            ),
            const SizedBox(height: space8),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth >= 320
                    ? (constraints.maxWidth - space8 * 2) / 3
                    : constraints.maxWidth >= 220
                        ? (constraints.maxWidth - space8) / 2
                        : constraints.maxWidth;
                return Wrap(
                  spacing: space8,
                  runSpacing: space8,
                  children: ordered.skip(1).map((field) {
                    return SizedBox(
                      width: itemWidth,
                      child: field.build(
                        context,
                        completed: completed,
                        accentColor: accentColor,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static double? _parseDuration(String value) {
    final trimmed = value.trim();
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length != 2) return null;
      final minutes = int.tryParse(parts[0]);
      final seconds = int.tryParse(parts[1]);
      if (minutes == null || seconds == null || seconds < 0 || seconds > 59) {
        return null;
      }
      return minutes + seconds / 60;
    }
    return double.tryParse(trimmed);
  }

  static String _formatDurationInput(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final seconds = digits.length == 1
        ? int.parse(digits)
        : int.parse(digits.substring(digits.length - 2));
    final minuteDigits = digits.length > 2
        ? digits.substring(0, digits.length - 2).replaceFirst(RegExp('^0+'), '')
        : '0';
    final minutes = minuteDigits.isEmpty ? '0' : minuteDigits;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String _formatNumber(double value) {
    if (value == 0) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  }
}

class _MetricField {
  const _MetricField({
    required this.metric,
    required this.label,
    required this.value,
    required this.suffix,
    required this.parse,
    required this.onChanged,
    this.onCleared,
    this.formatAsDuration = false,
  });

  final String metric;
  final String label;
  final String value;
  final String suffix;
  final double? Function(String) parse;
  final ValueChanged<double> onChanged;
  final VoidCallback? onCleared;
  final bool formatAsDuration;

  Widget build(
    BuildContext context, {
    required bool completed,
    required Color accentColor,
    bool featured = false,
  }) {
    return _SyncedNumberField(
      label: label,
      value: value,
      suffix: suffix,
      parse: parse,
      onChanged: onChanged,
      onCleared: onCleared,
      formatAsDuration: formatAsDuration,
      completed: completed,
      accentColor: accentColor,
      featured: featured,
    );
  }
}

class _SyncedNumberField extends StatefulWidget {
  const _SyncedNumberField({
    required this.label,
    required this.value,
    required this.suffix,
    required this.parse,
    required this.onChanged,
    required this.completed,
    required this.accentColor,
    this.onCleared,
    this.formatAsDuration = false,
    this.featured = false,
  });

  final String label;
  final String value;
  final String suffix;
  final double? Function(String) parse;
  final ValueChanged<double> onChanged;
  final VoidCallback? onCleared;
  final bool formatAsDuration;
  final bool completed;
  final Color accentColor;
  final bool featured;

  @override
  State<_SyncedNumberField> createState() => _SyncedNumberFieldState();
}

class _SyncedNumberFieldState extends State<_SyncedNumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(_SyncedNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: widget.formatAsDuration
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: widget.formatAsDuration
              ? [FilteringTextInputFormatter.allow(RegExp('[0-9:]'))]
              : null,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: widget.featured ? 20 : 15,
                fontWeight: FontWeight.w700,
                color: widget.completed
                    ? widget.accentColor
                    : colorScheme.onSurface,
              ),
          decoration: InputDecoration(
            isDense: true,
            labelText: widget.label,
            contentPadding: EdgeInsetsDirectional.fromSTEB(
              widget.featured ? 40 : space8,
              widget.featured ? space12 : 10,
              widget.featured ? 56 : space8,
              widget.featured ? space12 : 10,
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
            if (widget.formatAsDuration) {
              final formatted = CardioBout._formatDurationInput(value);
              if (formatted != value) {
                _controller.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
              value = formatted;
            }
            if (value.isEmpty) {
              widget.onCleared?.call();
              return;
            }
            final parsed = widget.parse(value);
            if (parsed != null && parsed >= 0) widget.onChanged(parsed);
          },
          onTap: () {
            _controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _controller.text.length,
            );
          },
        ),
        PositionedDirectional(
          end: space8,
          child: IgnorePointer(
            child: Text(
              widget.suffix,
              softWrap: false,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: widget.featured ? 12 : 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
