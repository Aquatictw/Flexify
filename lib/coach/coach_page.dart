import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/tokens.dart';
import 'coach_state.dart';
import 'widgets/coach_thread.dart';

class CoachPage extends StatelessWidget {
  const CoachPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'new') {
                context.read<CoachState>().clearThread();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'new',
                child: Text('New conversation'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomBarClearance(context)),
        child: const CoachThread(workoutId: null),
      ),
    );
  }
}
