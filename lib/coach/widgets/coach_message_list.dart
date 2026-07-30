import 'dart:convert';

import 'package:flutter/material.dart';

import '../../database/database.dart';
import '../block_tools.dart';
import 'proposal_card.dart';

/// One rendered thread row, with the confirmation state already resolved.
///
/// Resolution happens once per build by reading the message list itself, so no
/// mutable counter is needed and list-item keys stay `coach-<id>`.
class _RenderedRow {
  const _RenderedRow({
    required this.message,
    this.proposal,
    this.status = ProposalCardStatus.pending,
    this.hidden = false,
  });

  final ChatMessage message;
  final BlockProposal? proposal;
  final ProposalCardStatus status;

  /// True for a confirmation outcome row: the card above already says
  /// "Applied" or "Dismissed", so repeating it as a tool line is noise.
  final bool hidden;
}

/// Pairs each `pending_confirmation` tool row with the outcome row that
/// followed it, in order. Rows are append-only and an outcome can only be
/// written after its card is tapped, so first-in-first-out matching is exact
/// even with several proposals in one thread.
List<_RenderedRow> _renderRows(List<ChatMessage> messages) {
  final rows = <_RenderedRow>[];
  final awaiting = <int>[];
  for (final message in messages) {
    if (message.role != 'tool') {
      rows.add(_RenderedRow(message: message));
      continue;
    }
    final result = _decode(message.content);
    final status = result?['status'];
    if (status == 'pending_confirmation') {
      final raw = result?['proposal'];
      if (raw is Map) {
        BlockProposal? proposal;
        try {
          proposal = BlockProposal.fromJson(Map<String, Object?>.from(raw));
        } catch (_) {
          proposal = null;
        }
        if (proposal != null) {
          awaiting.add(rows.length);
          rows.add(_RenderedRow(message: message, proposal: proposal));
          continue;
        }
      }
    }
    if ((status == 'applied' || status == 'declined') && awaiting.isNotEmpty) {
      final index = awaiting.removeAt(0);
      final pending = rows[index];
      rows[index] = _RenderedRow(
        message: pending.message,
        proposal: pending.proposal,
        status: status == 'applied'
            ? ProposalCardStatus.applied
            : ProposalCardStatus.dismissed,
      );
      rows.add(_RenderedRow(message: message, hidden: true));
      continue;
    }
    rows.add(_RenderedRow(message: message));
  }
  return rows;
}

Map<String, Object?>? _decode(String? content) {
  if (content == null || content.isEmpty) return null;
  try {
    final decoded = jsonDecode(content);
    if (decoded is Map) return Map<String, Object?>.from(decoded);
  } on FormatException {
    return null;
  }
  return null;
}

class CoachMessageList extends StatefulWidget {
  const CoachMessageList({
    required this.messages,
    required this.busy,
    required this.error,
    required this.onRetry,
    super.key,
    this.scrollController,
    this.onApplyProposal,
    this.onDismissProposal,
  });

  final List<ChatMessage> messages;
  final bool busy;
  final String? error;
  final VoidCallback? onRetry;
  final ScrollController? scrollController;
  final Future<void> Function(BlockProposal proposal)? onApplyProposal;
  final void Function(BlockProposal proposal)? onDismissProposal;

  @override
  State<CoachMessageList> createState() => _CoachMessageListState();
}

class _CoachMessageListState extends State<CoachMessageList> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(CoachMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length ||
        oldWidget.busy != widget.busy ||
        oldWidget.error != widget.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (!mounted || !_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    if (_ownsScrollController) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extra = (widget.busy ? 1 : 0) + (widget.error == null ? 0 : 1);
    final rows = _renderRows(widget.messages);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: rows.length + extra,
      itemBuilder: (context, index) {
        if (index < rows.length) {
          final row = rows[index];
          return KeyedSubtree(
            key: ValueKey('coach-${row.message.id}'),
            child: _MessageRow(
              message: row.message,
              proposal: row.proposal,
              proposalStatus: row.status,
              hidden: row.hidden,
              onApplyProposal: widget.onApplyProposal,
              onDismissProposal: widget.onDismissProposal,
            ),
          );
        }
        var trailingIndex = index - rows.length;
        if (widget.busy) {
          if (trailingIndex == 0) return const _ThinkingRow();
          trailingIndex--;
        }
        return _ErrorCard(
          message: widget.error!,
          onRetry: widget.onRetry,
        );
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.proposal,
    required this.proposalStatus,
    required this.hidden,
    required this.onApplyProposal,
    required this.onDismissProposal,
  });

  final ChatMessage message;
  final BlockProposal? proposal;
  final ProposalCardStatus proposalStatus;
  final bool hidden;
  final Future<void> Function(BlockProposal proposal)? onApplyProposal;
  final void Function(BlockProposal proposal)? onDismissProposal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (hidden) return const SizedBox.shrink();
    final pendingProposal = proposal;
    if (pendingProposal != null) {
      final answered = proposalStatus != ProposalCardStatus.pending;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ProposalCard(
          proposal: pendingProposal,
          status: proposalStatus,
          onApply: answered || onApplyProposal == null
              ? null
              : () => onApplyProposal!(pendingProposal),
          onDismiss: answered || onDismissProposal == null
              ? null
              : () => onDismissProposal!(pendingProposal),
        ),
      );
    }
    if (message.role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(message.content ?? ''),
        ),
      );
    }
    if (message.role == 'assistant') {
      if ((message.content ?? '').trim().isEmpty && message.toolCalls != null) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(right: 32, bottom: 14),
        child: _InlineAssistantText(message.content ?? ''),
      );
    }
    if (message.role == 'tool') {
      return _ToolResult(content: message.content);
    }
    return const SizedBox.shrink();
  }
}

class _InlineAssistantText extends StatelessWidget {
  const _InlineAssistantText(this.source);

  final String source;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    final normalized = source.split('\n').map((line) {
      final noHeading = line.replaceFirst(RegExp(r'^\s*#{1,6}\s*'), '');
      return noHeading.replaceFirst(RegExp(r'^\s*-\s+'), '• ');
    }).join('\n');
    final spans = <TextSpan>[];
    var bold = false;
    for (final part in normalized.split('**')) {
      if (part.isNotEmpty) {
        spans.add(
          TextSpan(
            text: part,
            style: bold ? base?.copyWith(fontWeight: FontWeight.bold) : base,
          ),
        );
      }
      bold = !bold;
    }
    return Text.rich(TextSpan(children: spans), style: base);
  }
}

class _ToolResult extends StatelessWidget {
  const _ToolResult({required this.content});

  final String? content;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Map<String, Object?>? result;
    try {
      final decoded = jsonDecode(content ?? '');
      if (decoded is Map) result = Map<String, Object?>.from(decoded);
    } on FormatException {
      result = null;
    }
    if (result?['ok'] != true) {
      final error = result?['error']?.toString() ?? 'Tool call failed.';
      return _ToolLines(
        lines: <String>['⚠ $error'],
        color: scheme.error,
      );
    }

    // Read tools answer with prose the model consumes; show it rather than
    // the session-write summary below, which does not apply to them.
    final text = result?['text'];
    if (text is String && text.trim().isNotEmpty) {
      return _ToolLines(
        lines: text.trim().split('\n'),
        color: scheme.onSurfaceVariant,
      );
    }

    final lines = <String>[];
    final rawApplied = result?['applied'];
    if (rawApplied is List) {
      for (final raw in rawApplied) {
        if (raw is! Map) continue;
        final op = Map<String, Object?>.from(raw);
        final exercise = op['exercise']?.toString() ?? 'exercise';
        final sets = op['sets'] is List ? op['sets']! as List : const [];
        switch (op['op']) {
          case 'add_exercise':
            lines.add('✓ Added $exercise — ${sets.length} sets');
          case 'add_sets':
            lines.add('✓ Added ${sets.length} sets to $exercise');
          case 'edit_set':
            final index = (op['setIndex'] as num?)?.toInt() ?? 0;
            lines.add('✓ Edited $exercise set ${index + 1}');
          case 'remove_sets':
            final removed = (op['removed'] as num?)?.toInt() ?? 0;
            lines.add('✓ Removed $removed sets from $exercise');
        }
        if (sets.isNotEmpty) {
          lines.add('✓ ${sets.map(_formatSet).join(', ')}');
        }
      }
    }
    if (lines.isEmpty) lines.add('✓ Session updated');
    return _ToolLines(lines: lines, color: scheme.onSurfaceVariant);
  }

  String _formatSet(Object? raw) {
    if (raw is! Map) return 'Set';
    final set = Map<String, Object?>.from(raw);
    return '${_number(set['reps'])}×${_number(set['weight'])} '
            '${set['unit'] ?? ''}'
        .trim();
  }

  String _number(Object? value) {
    if (value is num && value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value?.toString() ?? '?';
  }
}

class _ToolLines extends StatelessWidget {
  const _ToolLines({required this.lines, required this.color});

  final List<String> lines;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 24, bottom: 10),
      child: Text(
        lines.join('\n'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontFamily: 'monospace',
              height: 1.45,
            ),
      ),
    );
  }
}

class _ThinkingRow extends StatelessWidget {
  const _ThinkingRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            'Thinking…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
