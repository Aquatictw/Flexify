import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Represents a weight plate with its properties
class WeightPlate { // Relative size for visual representation

  const WeightPlate({
    required this.weight,
    required this.color,
    required this.colorName,
    required this.size,
  });
  final double weight;
  final Color color;
  final String colorName;
  final double size;
}

/// Available weight plates in descending order (for greedy algorithm)
const List<WeightPlate> availablePlates = [
  WeightPlate(
    weight: 25,
    color: Color(0xFFEF5350),
    colorName: 'Red',
    size: 1,
  ),
  WeightPlate(
    weight: 20,
    color: Color(0xFF42A5F5),
    colorName: 'Blue',
    size: 0.92,
  ),
  WeightPlate(
    weight: 15,
    color: Color(0xFFFFEE58),
    colorName: 'Yellow',
    size: 0.84,
  ),
  WeightPlate(
    weight: 10,
    color: Color(0xFF66BB6A),
    colorName: 'Green',
    size: 0.76,
  ),
  WeightPlate(
    weight: 5,
    color: Color(0xFF424242),
    colorName: 'Black',
    size: 0.68,
  ),
  WeightPlate(
    weight: 2.5,
    color: Color(0xFFEF5350),
    colorName: 'Red',
    size: 0.56,
  ),
  WeightPlate(
    weight: 1.25,
    color: Color(0xFFEEEEEE),
    colorName: 'White',
    size: 0.48,
  ),
];

/// Calculates the optimal plate loading for one side of the barbell
class PlateLoadingResult {

  PlateLoadingResult({
    required this.plates,
    required this.actualWeight,
    required this.targetWeight,
    required this.exactMatch,
  });
  final List<WeightPlate> plates;
  final double actualWeight;
  final double targetWeight;
  final bool exactMatch;

  /// Total weight including both sides and bar
  double totalWeight(double barWeight) => actualWeight * 2 + barWeight;
}

/// Calculate optimal plate loading using greedy algorithm
PlateLoadingResult calculatePlateLoading(
  double targetWeight,
  double barWeight,
) {
  // Weight needed per side
  final double weightPerSide = (targetWeight - barWeight) / 2;

  // Handle impossible cases
  if (weightPerSide < 0) {
    return PlateLoadingResult(
      plates: [],
      actualWeight: 0,
      targetWeight: weightPerSide,
      exactMatch: false,
    );
  }

  final List<WeightPlate> result = [];
  double remaining = weightPerSide;

  // Greedy algorithm - use largest plates first
  for (final plate in availablePlates) {
    while (remaining >= plate.weight - 0.001) {
      // Small epsilon for floating point
      result.add(plate);
      remaining -= plate.weight;
    }
  }

  final actualWeight = weightPerSide - remaining;
  final exactMatch = remaining < 0.001;

  return PlateLoadingResult(
    plates: result,
    actualWeight: actualWeight,
    targetWeight: weightPerSide,
    exactMatch: exactMatch,
  );
}

/// Plate Calculator Dialog
class PlateCalculatorDialog extends StatefulWidget {
  const PlateCalculatorDialog({super.key});

  @override
  State<PlateCalculatorDialog> createState() => _PlateCalculatorDialogState();
}

class _PlateCalculatorDialogState extends State<PlateCalculatorDialog> {
  final TextEditingController _weightController = TextEditingController();
  double _barWeight = 20; // Default to 20kg bar
  PlateLoadingResult? _result;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final targetWeight = double.tryParse(_weightController.text);
    if (targetWeight == null || targetWeight <= 0) {
      setState(() => _result = null);
      return;
    }

    setState(() {
      _result = calculatePlateLoading(targetWeight, _barWeight);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.calculate,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Plate Calculator',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Target weight input
              TextField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Target Weight (kg)',
                  hintText: '100',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 8),

              // Bar weight selector
              Row(
                children: [
                  Text(
                    'Bar:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<double>(
                      segments: const [
                        ButtonSegment(
                          value: 10,
                          label: Text('10 kg'),
                        ),
                        ButtonSegment(
                          value: 20,
                          label: Text('20 kg'),
                        ),
                      ],
                      selected: {_barWeight},
                      onSelectionChanged: (Set<double> selection) {
                        setState(() {
                          _barWeight = selection.first;
                          _calculate();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Results
              if (_result != null)
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Weight summary
                        _buildWeightSummary(theme, colorScheme),
                        const SizedBox(height: 12),

                        // Visual representation
                        _buildBarVisualization(theme, colorScheme),
                        const SizedBox(height: 12),

                        // Plate list
                        _buildPlateList(theme, colorScheme),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 80,
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Enter a target weight to calculate',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightSummary(ThemeData theme, ColorScheme colorScheme) {
    final result = _result!;

    return Container(
      padding: const EdgeInsets.all(space12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: brSm,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          if (!result.exactMatch) ...[
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Closest achievable weight',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeightInfo(
                'Per Side',
                '${result.actualWeight.toStringAsFixed(2)} kg',
                theme,
                colorScheme,
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outlineVariant,
              ),
              _buildWeightInfo(
                'Bar',
                '${_barWeight.toStringAsFixed(0)} kg',
                theme,
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInfo(
    String label,
    String value,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBarVisualization(ThemeData theme, ColorScheme colorScheme) {
    final result = _result!;

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: result.plates.isEmpty
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(radiusSm),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 20,
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Text(
                        'No plates needed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : CustomPaint(
              size: const Size(double.infinity, 110),
              painter: _PlatePainter(
                plates: result.plates,
                colorScheme: colorScheme,
              ),
            ),
    );
  }

  Widget _buildPlateList(ThemeData theme, ColorScheme colorScheme) {
    final result = _result!;

    if (result.plates.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group plates by weight
    final Map<double, int> plateCount = {};
    for (final plate in result.plates) {
      plateCount[plate.weight] = (plateCount[plate.weight] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plates Needed (Per Side)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: space8),
        ...plateCount.entries.map((entry) {
          final plate =
              availablePlates.firstWhere((p) => p.weight == entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: space8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: plate.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                const SizedBox(width: space12),
                Expanded(
                  child: Text(
                    '${plate.weight} kg (${plate.colorName})',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: space12,
                    vertical: space4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: brSm,
                  ),
                  child: Text(
                    'x${entry.value}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Custom painter for the plate visualization
class _PlatePainter extends CustomPainter {

  _PlatePainter({
    required this.plates,
    required this.colorScheme,
  });
  final List<WeightPlate> plates;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    const barHeight = 12.0;
    final centerY = size.height / 2;
    const plateSpacing = 2.0;
    const barEndPadding = 12.0; // Space after last plate

    // Calculate plate widths based on weight
    double getPlateWidth(double weight) {
      if (weight >= 20) return 30;
      if (weight >= 10) return 26;
      if (weight >= 5) return 20;
      if (weight >= 2.5) return 14;
      return 10; // 1.25kg - even smaller
    }

    // Calculate plate heights - bigger weights all same height
    double getPlateHeight(double weight) {
      final maxHeight = size.height * 0.85;
      if (weight >= 10) return maxHeight; // 25, 20, 15, 10 all same height
      if (weight >= 5) return maxHeight * 0.75;
      if (weight >= 2.5) return maxHeight * 0.60;
      return maxHeight * 0.45; // 1.25kg smallest
    }

    // Calculate total width needed for plates
    double totalPlatesWidth = 0;
    for (final plate in plates) {
      totalPlatesWidth += getPlateWidth(plate.weight);
    }
    totalPlatesWidth += plateSpacing * (plates.length - 1);

    // Center the plates horizontally
    final startX = (size.width - totalPlatesWidth) / 2;

    // Calculate bar width - from left edge to just past last plate
    final barWidth = startX + totalPlatesWidth + barEndPadding;

    // Draw bar extending from left edge to just past rightmost plate
    final barPaint = Paint()
      ..color = colorScheme.outline
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, centerY - barHeight / 2, barWidth, barHeight),
        topRight: const Radius.circular(radiusSm),
        bottomRight: const Radius.circular(radiusSm),
      ),
      barPaint,
    );

    // Draw plates on top of bar
    double xOffset = startX;

    for (int i = 0; i < plates.length; i++) {
      final plate = plates[i];
      final plateHeight = getPlateHeight(plate.weight);
      final plateWidth = getPlateWidth(plate.weight);

      // Draw plate shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            xOffset + 2,
            centerY - plateHeight / 2 + 2,
            plateWidth,
            plateHeight,
          ),
          const Radius.circular(6),
        ),
        shadowPaint,
      );

      // Draw plate
      final platePaint = Paint()
        ..color = plate.color
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            xOffset,
            centerY - plateHeight / 2,
            plateWidth,
            plateHeight,
          ),
          const Radius.circular(6),
        ),
        platePaint,
      );

      // Draw plate border
      final borderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            xOffset,
            centerY - plateHeight / 2,
            plateWidth,
            plateHeight,
          ),
          const Radius.circular(6),
        ),
        borderPaint,
      );

      // Draw weight label on plate
      final weightText = plate.weight % 1 == 0
          ? plate.weight.toInt().toString()
          : plate.weight.toString();
      final textPainter = TextPainter(
        text: TextSpan(
          text: weightText,
          style: TextStyle(
            color: _getContrastColor(plate.color),
            fontSize: plateWidth > 20 ? 11 : 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Center text on plate
      textPainter.paint(
        canvas,
        Offset(
          xOffset + (plateWidth - textPainter.width) / 2,
          centerY - textPainter.height / 2,
        ),
      );

      xOffset += plateWidth + plateSpacing;
    }
  }

  // Helper to get contrasting text color
  Color _getContrastColor(Color background) {
    // Calculate luminance
    final luminance = (0.299 * (background.r * 255.0).round().clamp(0, 255) +
            0.587 * (background.g * 255.0).round().clamp(0, 255) +
            0.114 * (background.b * 255.0).round().clamp(0, 255)) /
        255;
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  bool shouldRepaint(covariant _PlatePainter oldDelegate) {
    return plates != oldDelegate.plates;
  }
}

/// Show the plate calculator dialog
Future<void> showPlateCalculator(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) => const PlateCalculatorDialog(),
  );
}
