import 'package:flutter/material.dart';

class CoachComposer extends StatefulWidget {
  const CoachComposer({
    required this.busy,
    required this.enabled,
    required this.restoreText,
    required this.onSend,
    required this.onRestoreConsumed,
    super.key,
  });

  final bool busy;
  final bool enabled;
  final String? restoreText;
  final ValueChanged<String> onSend;
  final VoidCallback onRestoreConsumed;

  @override
  State<CoachComposer> createState() => _CoachComposerState();
}

class _CoachComposerState extends State<CoachComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void didUpdateWidget(CoachComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.restoreText != null &&
        widget.restoreText != oldWidget.restoreText) {
      _controller
        ..text = widget.restoreText!
        ..selection = TextSelection.collapsed(
          offset: widget.restoreText!.length,
        );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onRestoreConsumed();
      });
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.busy || !widget.enabled) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !widget.busy;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: active,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Ask your coach…',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              onPressed: active ? _send : null,
              tooltip: 'Send',
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
