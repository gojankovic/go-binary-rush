import 'dart:async';

import 'package:flutter/widgets.dart';

/// The choreography every mode runs after a correct answer: flash the screen,
/// hold the new-best banner if one was earned, then advance to the next
/// question.
///
/// This deliberately owns only the timing and the two pieces of state that
/// drive it. Scoring, haptics and what "correct" means stay in each screen,
/// because those are the parts that actually differ between modes.
mixin SuccessFeedback<T extends StatefulWidget> on State<T> {
  static const flashHold = Duration(milliseconds: 120);
  static const newBestHold = Duration(milliseconds: 600);
  static const advanceDelay = Duration(milliseconds: 700);

  Timer? _flashTimer;
  Timer? _newBestTimer;
  Timer? _advanceTimer;

  /// Screen-flash opacity; read this from `build`.
  double flashOpacity = 0.0;

  /// Whether the new-best banner is currently showing.
  bool newBestFlash = false;

  /// Starts the post-correct sequence. [onAdvance] runs only if the screen is
  /// still mounted when the delay elapses; pass null for a mode that waits for
  /// the player to tap Next instead of advancing itself.
  void runSuccessFeedback({required bool newBest, VoidCallback? onAdvance}) {
    setState(() {
      flashOpacity = 1.0;
      if (newBest) newBestFlash = true;
    });

    _flashTimer?.cancel();
    _flashTimer = Timer(flashHold, () {
      if (mounted) setState(() => flashOpacity = 0.0);
    });

    if (newBest) {
      _newBestTimer?.cancel();
      _newBestTimer = Timer(newBestHold, () {
        if (mounted) setState(() => newBestFlash = false);
      });
    }

    _advanceTimer?.cancel();
    _advanceTimer = null;
    if (onAdvance != null) {
      _advanceTimer = Timer(advanceDelay, () {
        if (mounted) onAdvance();
      });
    }
  }

  /// Drops a pending advance, for a screen that moves on early (a Next tap).
  void cancelPendingAdvance() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _newBestTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }
}
