import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../fivethreeone/fivethreeone_state.dart';
import '../../settings/settings_state.dart';
import '../../workouts/workout_state.dart';
import '../block_tools.dart';
import '../coach_state.dart';
import '../coach_transport.dart';
import 'coach_composer.dart';
import 'coach_message_list.dart';

class CoachThread extends StatefulWidget {
  const CoachThread({
    required this.workoutId,
    super.key,
    this.onSessionChanged,
    this.composerFocus,
    this.autofocus = false,
  });

  final int? workoutId;

  /// The composer's focus node, when the host wants to drop the keyboard itself
  /// — the Coach tab does, on a tab change or a conversation switch.
  final FocusNode? composerFocus;

  /// Focuses the composer as soon as the thread mounts, raising the keyboard.
  /// On for the in-workout sheet, where you open the coach to type.
  final bool autofocus;

  /// Called after every applied session write, with what it changed, so the
  /// screen behind the sheet can rebuild against the new rows.
  final void Function(CoachSessionChange change)? onSessionChanged;

  @override
  State<CoachThread> createState() => _CoachThreadState();
}

class _CoachThreadState extends State<CoachThread> {
  CoachState? _coach;
  int _lastSessionRevision = 0;
  Object? _lastConversationKey;

  // Cached so a rebuild (every notifyListeners during a turn) does not spin up
  // a fresh http.Client and connection pool each time.
  CoachTransport? _transport;
  String? _transportKey;

  CoachTransport? _transportFor(String? serverUrl, String? apiKey) {
    final identity = '${serverUrl ?? ''}\u0000${apiKey ?? ''}';
    if (identity != _transportKey) {
      _transportKey = identity;
      _transport = coachTransportFor(serverUrl: serverUrl, apiKey: apiKey);
    }
    return _transport;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bind());
  }

  void _bind() {
    if (!mounted) return;
    final coach = context.read<CoachState>();
    _coach = coach;
    _lastSessionRevision = coach.sessionRevision;
    _lastConversationKey = coach.conversationKey;
    coach.addListener(_handleCoachChange);
    coach.openThread(widget.workoutId);
  }

  @override
  void didUpdateWidget(CoachThread oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workoutId != widget.workoutId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _coach?.openThread(widget.workoutId);
      });
    }
  }

  void _handleCoachChange() {
    final coach = _coach;
    if (coach == null) return;
    // Switching conversations must never carry the keyboard over: the composer
    // you were typing in belongs to the conversation you left.
    if (coach.conversationKey != _lastConversationKey) {
      _lastConversationKey = coach.conversationKey;
      final focus = widget.composerFocus;
      if (focus != null && focus.hasFocus) focus.unfocus();
    }
    if (coach.sessionRevision == _lastSessionRevision) return;
    _lastSessionRevision = coach.sessionRevision;
    widget.onSessionChanged?.call(coach.lastSessionChange);
  }

  /// Resolves the turn's training context, waiting for the 5/3/1 block to load.
  ///
  /// Every provider is read before the await so nothing touches `context` after
  /// an async gap.
  Future<CoachTurn> _turn() async {
    final fiveThreeOne = context.read<FiveThreeOneState>();
    final workout = context.read<WorkoutState>().activeWorkout;
    final unit = context.read<SettingsState>().value.strengthUnit;
    await fiveThreeOne.ensureLoaded();
    return CoachTurn(
      block: fiveThreeOne.activeBlock,
      workout: workout,
      unit: unit,
      completedBlocks: fiveThreeOne.getCompletedBlocks,
    );
  }

  Future<void> _applyProposal(BlockProposal proposal) async {
    final coach = context.read<CoachState>();
    final fiveThreeOne = context.read<FiveThreeOneState>();
    final unit = context.read<SettingsState>().value.strengthUnit;
    // Block ops mutate the active block, so it must be loaded first. Reachable
    // only after a turn (which already awaited), but cheap insurance.
    await fiveThreeOne.ensureLoaded();
    await coach.applyProposal(
      proposal: proposal,
      fiveThreeOneState: fiveThreeOne,
      unit: unit,
    );
  }

  void _dismissProposal(BlockProposal proposal) {
    context.read<CoachState>().declineProposal(proposal);
  }

  @override
  void dispose() {
    _coach?.removeListener(_handleCoachChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coach = context.watch<CoachState>();
    final settings = context.watch<SettingsState>().value;
    final transport = _transportFor(settings.serverUrl, settings.serverApiKey);
    return Column(
      children: [
        if (transport == null)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Set your server URL and API key in Settings → Server',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: CoachMessageList(
              messages: coach.messages,
              busy: coach.busy,
              error: coach.error,
              onApplyProposal: _applyProposal,
              onDismissProposal: _dismissProposal,
              onRetry: coach.canRetry
                  ? () async =>
                      coach.retry(transport: transport, turn: await _turn())
                  : null,
            ),
          ),
        CoachComposer(
          autofocus: widget.autofocus,
          focusNode: widget.composerFocus,
          busy: coach.busy,
          enabled: transport != null,
          draft: coach.draftText,
          draftRevision: coach.draftRevision,
          conversationKey: coach.conversationKey,
          onDraftChanged: (text) => coach.draftText = text,
          onSend: transport == null
              ? (_) {}
              : (text) async => coach.send(
                    text,
                    transport: transport,
                    turn: await _turn(),
                  ),
        ),
      ],
    );
  }
}
