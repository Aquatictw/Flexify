import 'dart:convert';

import 'package:flutter/material.dart';

import '../../database/database.dart';

class CoachMessageList extends StatefulWidget {
  const CoachMessageList({
    required this.messages,
    required this.busy,
    required this.error,
    required this.onRetry,
    super.key,
    this.scrollController,
  });

  final List<ChatMessage> messages;
  final bool busy;
  final String? error;
  final VoidCallback? onRetry;
  final ScrollController? scrollController;

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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: widget.messages.length + extra,
      itemBuilder: (context, index) {
        if (index < widget.messages.length) {
          final message = widget.messages[index];
          return KeyedSubtree(
            key: ValueKey('coach-${message.id}'),
            child: _MessageRow(message: message),
          );
        }
        var trailingIndex = index - widget.messages.length;
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
  const _MessageRow({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
