import 'package:flutter/material.dart';

class CoachComposer extends StatefulWidget {
  const CoachComposer({
    required this.busy,
    required this.enabled,
    required this.draft,
    required this.draftRevision,
    required this.conversationKey,
    required this.onDraftChanged,
    required this.onSend,
    super.key,
    this.focusNode,
    this.autofocus = false,
  });

  final bool autofocus;
  final bool busy;
  final bool enabled;

  /// The open conversation's unsent text. Adopted whenever [conversationKey] or
  /// [draftRevision] changes, and otherwise left alone — the field is the
  /// authority while you are typing into it.
  final String draft;

  /// Bumped when the *state* rewrites the draft (a rolled-back send), which is
  /// the only reason to overwrite text the field already holds for this
  /// conversation.
  final int draftRevision;

  /// Identity of the conversation the draft belongs to. A change here means the
  /// sidebar switched conversations, so the field swaps its contents.
  final Object conversationKey;

  final ValueChanged<String> onDraftChanged;
  final ValueChanged<String> onSend;

  /// Supplied by the Coach tab so it can drop the keyboard when you leave the
  /// tab or switch conversations. The in-workout sheet owns neither, so it lets
  /// the field make its own.
  final FocusNode? focusNode;

  @override
  State<CoachComposer> createState() => _CoachComposerState();
}

class _CoachComposerState extends State<CoachComposer> {
  late final TextEditingController _controller;
  FocusNode? _ownedFocus;

  FocusNode get _focus => widget.focusNode ?? (_ownedFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.draft)
      ..addListener(_handleTextChanged);
  }

  /// Mirrors every edit — typing, `clear()`, an adopted draft — back into the
  /// conversation, so its half-written prompt is always current.
  void _handleTextChanged() => widget.onDraftChanged(_controller.text);

  @override
  void didUpdateWidget(CoachComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversationKey != oldWidget.conversationKey ||
        widget.draftRevision != oldWidget.draftRevision) {
      _adopt(widget.draft);
    }
  }

  void _adopt(String text) {
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.busy || !widget.enabled) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    _ownedFocus?.dispose();
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
                focusNode: _focus,
                autofocus: widget.autofocus,
                // Stays typable during a turn. Disabling it would drop focus
                // and dismiss the keyboard the moment a send starts; only the
                // send button needs to go dead, and `_send` guards `busy` too.
                enabled: widget.enabled,
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
