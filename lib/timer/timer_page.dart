import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../animated_fab.dart';
import '../settings/settings_page.dart';
import '../settings/settings_state.dart';
import '../theme/tokens.dart';
import 'timer_progress_widgets.dart';
import 'timer_state.dart';

class TimerPage extends StatefulWidget {

  const TimerPage({super.key, this.total, this.progress});
  final int? total;
  final int? progress;

  @override
  TimerPageState createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final timerState = context.watch<TimerState>();

    return NavigatorPopHandler(
      onPopWithResult: (result) {
        if (navKey.currentState!.canPop() == false) return;
        final ctrl = DefaultTabController.of(context);
        final settings = context.read<SettingsState>().value;
        final index = settings.tabs.split(',').indexOf('TimerPage');
        if (ctrl.index == index) navKey.currentState!.pop();
      },
      child: Navigator(
        key: navKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => _TimerPageWidget(
            timerState: timerState,
            total: widget.total,
            progress: widget.progress,
          ),
          settings: settings,
        ),
      ),
    );
  }
}

class _TimerPageWidget extends StatelessWidget {

  const _TimerPageWidget({
    required this.timerState,
    this.total,
    this.progress,
  });
  final TimerState timerState;
  final int? total;
  final int? progress;

  @override
  Widget build(BuildContext context) {
    if (total != null && progress != null) {
      timerState.setTimer(total!, progress!);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: const Center(
        child: TimerCircularProgressIndicator(),
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: durFast,
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: timerState.timer.isRunning()
            ? AnimatedFab(
                onPressed: () async => timerState.stopTimer(),
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              )
            : const SizedBox(),
      ),
    );
  }
}
