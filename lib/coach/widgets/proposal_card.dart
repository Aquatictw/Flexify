import 'package:flutter/material.dart';

import '../block_tools.dart';

enum ProposalCardStatus { pending, applied, dismissed }

class ProposalCard extends StatefulWidget {
  const ProposalCard({
    required this.proposal,
    required this.status,
    this.onApply,
    this.onDismiss,
    super.key,
  });

  final BlockProposal proposal;
  final ProposalCardStatus status;
  final Future<void> Function()? onApply;
  final VoidCallback? onDismiss;

  @override
  State<ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<ProposalCard> {
  var _applying = false;

  Future<void> _apply() async {
    final callback = widget.onApply;
    if (_applying || callback == null) return;
    setState(() => _applying = true);
    try {
      await callback();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final pending = widget.status == ProposalCardStatus.pending;
    final (icon, title) = switch (widget.status) {
      ProposalCardStatus.pending => (
          Icons.fact_check_outlined,
          'Needs your confirmation',
        ),
      ProposalCardStatus.applied => (Icons.check_circle_outline, 'Applied'),
      ProposalCardStatus.dismissed => (Icons.cancel_outlined, 'Dismissed'),
    };
    final semanticsColor = widget.proposal.countsAsCycleBump
        ? colors.errorContainer
        : colors.secondaryContainer;
    final onSemanticsColor = widget.proposal.countsAsCycleBump
        ? colors.onErrorContainer
        : colors.onSecondaryContainer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.proposal.rationale,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final change in widget.proposal.changes)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      change.before == null
                          ? '${change.label}: ${change.after}'
                          : '${change.label}: ${change.before} → '
                              '${change.after}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      change.detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: semanticsColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.proposal.bumpSemantics,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onSemanticsColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (pending) ...[
              const SizedBox(height: 10),
              // PRD decision 14: there is no undo, so the warning belongs
              // beside the button that commits, not after the fact.
              Text(
                'This cannot be undone.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (pending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _applying ? null : widget.onDismiss,
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed:
                        _applying || widget.onApply == null ? null : _apply,
                    child: _applying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Apply'),
                  ),
                ],
              )
            else
              Text(
                widget.status == ProposalCardStatus.applied
                    ? 'This proposal has been applied.'
                    : 'No changes were written.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
