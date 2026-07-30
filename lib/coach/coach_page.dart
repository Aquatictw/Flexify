import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/tokens.dart';
import 'coach_state.dart';
import 'widgets/coach_thread.dart';

class CoachPage extends StatelessWidget {
  const CoachPage({super.key});

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
        padding: EdgeInsets.only(bottom: clearance),
        child: const CoachThread(workoutId: null),
      ),
    );
  }
}
