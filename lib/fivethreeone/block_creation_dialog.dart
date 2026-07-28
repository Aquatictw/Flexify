import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import 'fivethreeone_state.dart';
import 'schemes.dart';

/// Dialog for creating a new 5/3/1 training block
class BlockCreationDialog extends StatefulWidget {
  const BlockCreationDialog({super.key});

  @override
  State<BlockCreationDialog> createState() => _BlockCreationDialogState();
}

class _BlockCreationDialogState extends State<BlockCreationDialog> {
  late TextEditingController _squatController;
  late TextEditingController _benchController;
  late TextEditingController _deadliftController;
  late TextEditingController _pressController;
  String _unit = 'kg';
  String _leaderSupplemental = supplementalBbb;

  /// Anchors run PR Sets + FSL; kept as a field so the write path reads the
  /// same way as the Leader choice once more anchor templates land.
  final String _anchorSupplemental = anchorSupplementalOptions.single;

  @override
  void initState() {
    super.initState();
    _squatController = TextEditingController();
    _benchController = TextEditingController();
    _deadliftController = TextEditingController();
    _pressController = TextEditingController();
    _loadSettings();
  }

  String _formatTm(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  Future<void> _loadSettings() async {
    final settings = context.read<SettingsState>().value;
    _unit = settings.strengthUnit;

    // Try to pre-fill from last completed block first
    final completedBlocks =
        await context.read<FiveThreeOneState>().getCompletedBlocks();
    if (completedBlocks.isNotEmpty) {
      final last = completedBlocks.first;
      _unit = last.unit;
      setState(() {
        _leaderSupplemental = last.leaderSupplemental;
        _squatController.text = _formatTm(last.squatTm);
        _benchController.text = _formatTm(last.benchTm);
        _deadliftController.text = _formatTm(last.deadliftTm);
        _pressController.text = _formatTm(last.pressTm);
      });
      return;
    }

    // Fall back to Settings-based TMs
    setState(() {
      _squatController.text =
          settings.fivethreeoneSquatTm?.toStringAsFixed(1) ?? '';
      _benchController.text =
          settings.fivethreeoneBenchTm?.toStringAsFixed(1) ?? '';
      _deadliftController.text =
          settings.fivethreeoneDeadliftTm?.toStringAsFixed(1) ?? '';
      _pressController.text =
          settings.fivethreeonePressTm?.toStringAsFixed(1) ?? '';
    });
  }

  bool _isValid() {
    final squat = double.tryParse(_squatController.text);
    final bench = double.tryParse(_benchController.text);
    final deadlift = double.tryParse(_deadliftController.text);
    final press = double.tryParse(_pressController.text);
    return squat != null &&
        squat > 0 &&
        bench != null &&
        bench > 0 &&
        deadlift != null &&
        deadlift > 0 &&
        press != null &&
        press > 0;
  }

  Future<void> _startBlock() async {
    if (!_isValid()) return;

    final squat = double.parse(_squatController.text);
    final bench = double.parse(_benchController.text);
    final deadlift = double.parse(_deadliftController.text);
    final press = double.parse(_pressController.text);

    await context.read<FiveThreeOneState>().createBlock(
          squatTm: squat,
          benchTm: bench,
          deadliftTm: deadlift,
          pressTm: press,
          unit: _unit,
          leaderSupplemental: _leaderSupplemental,
          anchorSupplemental: _anchorSupplemental,
        );

    if (mounted) Navigator.pop(context);
  }

  Widget _buildTmField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: _unit,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  /// Leader/Anchor supplemental selection. Leaders offer BBB or FSL; the
  /// Anchor always runs PR Sets + FSL, so it is shown as a fixed summary.
  Widget _buildSupplementalPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Supplemental Work',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Leaders · 5's PRO main work",
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            for (final option in leaderSupplementalOptions)
              ButtonSegment(
                value: option,
                label: Text(supplementalName(option)),
              ),
          ],
          selected: {_leaderSupplemental},
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            setState(() => _leaderSupplemental = selection.first);
          },
        ),
        const SizedBox(height: 6),
        Text(
          supplementalDetail(_leaderSupplemental),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Anchor · PR Sets main work',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(space12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: brSm,
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline,
                  size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${supplementalName(_anchorSupplemental)} '
                  '· ${supplementalDetail(_anchorSupplemental)}',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _squatController.dispose();
    _benchController.dispose();
    _deadliftController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasActiveBlock = context.read<FiveThreeOneState>().hasActiveBlock;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(space16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(radiusLg)),
              ),
              child: Row(
                children: [
                  Icon(Icons.fitness_center,
                      color: colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Start 5/3/1 Block',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasActiveBlock) ...[
                      Container(
                        padding: const EdgeInsets.all(space12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: brSm,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber,
                                color: colorScheme.onErrorContainer, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Starting a new block will end your current one.',
                                style: TextStyle(
                                    color: colorScheme.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _buildTmField(
                            label: 'Squat',
                            controller: _squatController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTmField(
                            label: 'Bench',
                            controller: _benchController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTmField(
                            label: 'Deadlift',
                            controller: _deadliftController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTmField(
                            label: 'OHP',
                            controller: _pressController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSupplementalPicker(context),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(space16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(radiusLg)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '11-week block: 2 Leaders + Deload + Anchor + TM Test',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isValid() ? _startBlock : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Start Block'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
