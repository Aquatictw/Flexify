import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../main.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';

/// Dialog for adding or editing a bodyweight entry
class BodyweightEntryDialog extends StatefulWidget { // Null for new entry

  const BodyweightEntryDialog({
    super.key,
    this.entry,
  });
  final BodyweightEntry? entry;

  @override
  State<BodyweightEntryDialog> createState() => _BodyweightEntryDialogState();
}

class _BodyweightEntryDialogState extends State<BodyweightEntryDialog> {
  late TextEditingController _weightController;
  late DateTime _selectedDate;
  String _unit = 'kg';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.entry?.weight.toStringAsFixed(1) ?? '',
    );
    _selectedDate = widget.entry?.date ?? DateTime.now();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = context.read<SettingsState>().value;
    setState(() {
      _unit = settings.strengthUnit;
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (widget.entry != null) {
        // Update existing entry
        await db.bodyweightEntries.update().replace(
              BodyweightEntriesCompanion(
                id: Value(widget.entry!.id),
                weight: Value(weight),
                unit: Value(_unit),
                date: Value(_selectedDate),
              ),
            );
      } else {
        // Create new entry
        await db.bodyweightEntries.insertOne(
          BodyweightEntriesCompanion.insert(
            weight: weight,
            unit: _unit,
            date: _selectedDate,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving bodyweight: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: brLg,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(space12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: brMd,
                  ),
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: space16),
                Expanded(
                  child: Text(
                    widget.entry != null ? 'Edit Bodyweight' : 'Log Bodyweight',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: space24),

            // Weight input
            TextField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Weight',
                suffixText: _unit,
                border: const OutlineInputBorder(
                  borderRadius: brMd,
                ),
                filled: true,
                prefixIcon: const Icon(Icons.fitness_center),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              autofocus: widget.entry == null,
            ),
            const SizedBox(height: space16),

            // Date selector
            InkWell(
              onTap: _selectDate,
              borderRadius: brMd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: space16,
                  vertical: space16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: brMd,
                  color: colorScheme.surfaceContainerHigh,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      dateFormat.format(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_drop_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: space24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(widget.entry != null ? 'Update' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
