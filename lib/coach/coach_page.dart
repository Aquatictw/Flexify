import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../theme/tokens.dart';
import 'coach_state.dart';
import 'widgets/coach_thread.dart';
import 'widgets/conversation_drawer.dart';

class CoachPage extends StatefulWidget {
  const CoachPage({super.key, this.tabController});

  /// The home tab controller, used only to drop the keyboard when the Coach tab
  /// stops being the visible one — a composer left focused behind another tab
  /// pops its keyboard straight back up on return.
  final TabController? tabController;

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Owned here rather than in the composer so the drawer, a conversation
  /// switch and a tab change can all dismiss the keyboard.
  final FocusNode _composerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.tabController?.animation?.addListener(_handleTabMotion);
  }

  @override
  void didUpdateWidget(CoachPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabController == widget.tabController) return;
    oldWidget.tabController?.animation?.removeListener(_handleTabMotion);
    widget.tabController?.animation?.addListener(_handleTabMotion);
  }

  @override
  void dispose() {
    widget.tabController?.animation?.removeListener(_handleTabMotion);
    _composerFocus.dispose();
    super.dispose();
  }

  /// Any motion between tabs — a swipe or a nav tap — closes the composer. The
  /// animation is watched rather than the index so the keyboard goes down as the
  /// swipe starts, not once it settles.
  void _handleTabMotion() {
    final value = widget.tabController?.animation?.value;
    if (value == null || (value - value.roundToDouble()).abs() < 0.001) return;
    _dismissKeyboard();
  }

  void _dismissKeyboard() {
    if (_composerFocus.hasFocus) _composerFocus.unfocus();
  }

  Future<void> _confirmDelete(ChatThread thread) async {
    final coach = context.read<CoachState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text(thread.title ?? 'Untitled'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await coach.deleteThread(thread.id);
  }

  /// The open conversation's own title, so the sidebar's selection is readable
  /// without opening it. Falls back to 'Coach' for an unsaved new thread.
  static String _titleFor(CoachState coach) {
    final id = coach.threadId;
    if (id == null) return 'Coach';
    for (final thread in coach.threads) {
      if (thread.id == id) return thread.title ?? 'Coach';
    }
    return 'Coach';
  }

  @override
  Widget build(BuildContext context) {
    // The pill nav and the timer/active-workout bars live in the home Scaffold,
    // which is resizeToAvoidBottomInset: false — so with the keyboard up they
    // sit behind it and need no clearance at all. The Scaffold below already
    // lifts the composer by the keyboard inset; adding the full clearance on
    // top of that parked the text field a nav-bar's height above the keyboard.
    // Read the inset here, above that Scaffold, because a resizing Scaffold
    // zeroes viewInsets for its body.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final clearance = math.max(0.0, bottomBarClearance(context) - keyboard);
    final coach = context.watch<CoachState>();
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Conversations',
          onPressed: () {
            // The keyboard goes down with the drawer coming up, so the field
            // behind it cannot hold focus and raise it again over whichever
            // conversation you pick.
            _dismissKeyboard();
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(_titleFor(coach)),
      ),
      // The tab view swipes horizontally, so an edge drag has to stay a tab
      // change; the hamburger is the only way in.
      drawerEnableOpenDragGesture: false,
      drawer: ConversationDrawer(
        threads: coach.threads,
        currentThreadId: coach.threadId,
        runningThreadIds: coach.runningThreadIds,
        bottomPadding: bottomBarClearance(context),
        onNewThread: () {
          _dismissKeyboard();
          coach.startNewThread();
        },
        onOpenThread: (id) {
          _dismissKeyboard();
          coach.openThreadById(id);
        },
        onDeleteThread: _confirmDelete,
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: clearance),
        child: CoachThread(
          workoutId: null,
          composerFocus: _composerFocus,
        ),
      ),
    );
  }
}
