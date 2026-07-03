import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import '../../database/database.dart';
import '../../main.dart';
import '../../theme/tokens.dart';
import 'superset_utils.dart';

/// Dialog for creating a superset from selected exercises
class SupersetManagerDialog extends StatefulWidget {

  const SupersetManagerDialog({
    required this.exercises, required this.workoutId, required this.onSupersetCreated, super.key,
  });
  final List<({String name, int sequence})>
      exercises; // All exercises in workout
  final int workoutId;
  final VoidCallback onSupersetCreated;

  @override
  State<SupersetManagerDialog> createState() => _SupersetManagerDialogState();
}

class _SupersetManagerDialogState extends State<SupersetManagerDialog> {
  final Set<int> _selectedSequences = {};
  bool _isCreating = false;
  Map<int, String> _existingSupersets = {}; // sequence -> supersetId
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingSupersets();
  }

  Future<void> _loadExistingSupersets() async {
    // Query all sets in this workout to find existing supersets
    final setsWithSupersets = await (db.gymSets.select()
          ..where(
            (s) =>
                s.workoutId.equals(widget.workoutId) & s.supersetId.isNotNull(),
          ))
        .get();

    // Map sequence numbers to their superset IDs
    final Map<int, String> supersetMap = {};
    for (final set in setsWithSupersets) {
      supersetMap[set.sequence] = set.supersetId!;
    }

    if (mounted) {
      setState(() {
        _existingSupersets = supersetMap;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableExercisesCount =
        widget.exercises.length - _existingSupersets.length;
    final canCreate = _selectedSequences.length >= 2;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: brLg),
      child: Padding(
        padding: const EdgeInsets.all(space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(space8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: brSm,
                  ),
                  child: Icon(
                    Icons.link,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Superset',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        availableExercisesCount < 2
                            ? 'Not enough exercises available'
                            : 'Select 2+ exercises to group',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: availableExercisesCount < 2
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: space24),

            // Info message if some exercises are already in supersets
            if (!_isLoading && _existingSupersets.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(space12),
                margin: const EdgeInsets.only(bottom: space12),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: brSm,
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: space8),
                    Expanded(
                      child: Text(
                        '${_existingSupersets.length} exercise${_existingSupersets.length > 1 ? 's are' : ' is'} already grouped',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

            // Exercise list
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = widget.exercises[index];
                    final isSelected =
                        _selectedSequences.contains(exercise.sequence);
                    final isAlreadyInSuperset =
                        _existingSupersets.containsKey(exercise.sequence);
                    final isDisabled = isAlreadyInSuperset;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: space8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isDisabled
                              ? null
                              : () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedSequences
                                          .remove(exercise.sequence);
                                    } else {
                                      _selectedSequences.add(exercise.sequence);
                                    }
                                  });
                                },
                          borderRadius: brSm,
                          child: Opacity(
                            opacity: isDisabled ? 0.5 : 1.0,
                            child: Container(
                              padding: const EdgeInsets.all(space12),
                              decoration: BoxDecoration(
                                color: isDisabled
                                    ? colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.2)
                                    : isSelected
                                        ? colorScheme.primaryContainer
                                            .withValues(alpha: 0.3)
                                        : colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                border: Border.all(
                                  color: isDisabled
                                      ? colorScheme.outline
                                          .withValues(alpha: 0.3)
                                      : isSelected
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: brSm,
                              ),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isDisabled
                                          ? colorScheme.surfaceContainerHighest
                                          : isSelected
                                              ? colorScheme.primary
                                              : colorScheme.surface,
                                      border: Border.all(
                                        color: isDisabled
                                            ? colorScheme.outline
                                                .withValues(alpha: 0.3)
                                            : isSelected
                                                ? colorScheme.primary
                                                : colorScheme.outline,
                                        width: 2,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(6),),
                                    ),
                                    child: isDisabled
                                        ? Icon(
                                            Icons.link,
                                            color: colorScheme.outline,
                                            size: 14,
                                          )
                                        : isSelected
                                            ? Icon(
                                                Icons.check,
                                                color: colorScheme.onPrimary,
                                                size: 16,
                                              )
                                            : null,
                                  ),
                                  const SizedBox(width: space12),
                                  // Exercise name
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                        ),
                                        if (isDisabled)
                                          Text(
                                            'Already in a superset',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Unlink button for exercises in supersets
                                  if (isDisabled)
                                    IconButton(
                                      icon: Icon(
                                        Icons.link_off,
                                        size: 20,
                                        color: colorScheme.error,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      tooltip: 'Remove from superset',
                                      onPressed: () =>
                                          _unlinkExercise(exercise.sequence),
                                    ),
                                  // Position indicator
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: space8,
                                        vertical: space4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(8),),
                                      ),
                                      child: Text(
                                        '${_selectedSequences.toList().indexOf(exercise.sequence) + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: colorScheme.onPrimary,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: space24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed:
                        _isCreating ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(
                        borderRadius: brPill,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: space12),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        canCreate && !_isCreating ? _createSuperset : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isCreating
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlinkExercise(int sequence) async {
    try {
      // Remove superset info from all sets with this sequence
      await (db.gymSets.update()
            ..where(
              (s) =>
                  s.workoutId.equals(widget.workoutId) &
                  s.sequence.equals(sequence),
            ))
          .write(
        const GymSetsCompanion(
          supersetId: Value(null),
          supersetPosition: Value(null),
        ),
      );

      // Reload existing supersets and refresh UI
      await _loadExistingSupersets();

      if (mounted) {
        widget.onSupersetCreated(); // Trigger parent refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Exercise removed from superset'),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unlink exercise: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _createSuperset() async {
    setState(() => _isCreating = true);

    try {
      final supersetId = generateSupersetId(widget.workoutId);
      final selectedSequences = _selectedSequences.toList()..sort();

      // Update all sets for each selected exercise with superset info
      for (int i = 0; i < selectedSequences.length; i++) {
        final sequence = selectedSequences[i];
        final position = i; // Position within superset (0-based)

        await (db.gymSets.update()
              ..where(
                (s) =>
                    s.workoutId.equals(widget.workoutId) &
                    s.sequence.equals(sequence),
              ))
            .write(
          GymSetsCompanion(
            supersetId: Value(supersetId),
            supersetPosition: Value(position),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSupersetCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Superset created with ${selectedSequences.length} exercises!',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create superset: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
