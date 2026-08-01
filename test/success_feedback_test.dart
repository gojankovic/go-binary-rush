import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:binary_game/screens/success_feedback.dart';

class _Host extends StatefulWidget {
  const _Host({required this.newBest, this.autoAdvance = true});

  final bool newBest;
  final bool autoAdvance;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SuccessFeedback {
  int advances = 0;

  void fire() => runSuccessFeedback(
    newBest: widget.newBest,
    onAdvance: widget.autoAdvance ? () => advances++ : null,
  );

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

_HostState _state(WidgetTester tester) =>
    tester.state<_HostState>(find.byType(_Host));

void main() {
  testWidgets('flash lights up, then clears on its own', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Host(newBest: false)));
    final state = _state(tester);

    expect(state.flashOpacity, 0.0);
    state.fire();
    await tester.pump();
    expect(state.flashOpacity, 1.0);

    await tester.pump(SuccessFeedback.flashHold);
    expect(state.flashOpacity, 0.0);
  });

  testWidgets('advance runs once, after the delay', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Host(newBest: false)));
    final state = _state(tester);

    state.fire();
    await tester.pump(
      SuccessFeedback.advanceDelay - const Duration(milliseconds: 50),
    );
    expect(state.advances, 0, reason: 'must not advance early');

    await tester.pump(const Duration(milliseconds: 100));
    expect(state.advances, 1);

    await tester.pump(const Duration(seconds: 2));
    expect(state.advances, 1, reason: 'the timer must not repeat');
  });

  testWidgets('the new best banner shows only when one was earned', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _Host(newBest: true)));
    final withBest = _state(tester);
    withBest.fire();
    await tester.pump();
    expect(withBest.newBestFlash, isTrue);
    await tester.pump(SuccessFeedback.newBestHold);
    expect(withBest.newBestFlash, isFalse);

    await tester.pumpWidget(const MaterialApp(home: _Host(newBest: false)));
    final without = _state(tester);
    without.fire();
    await tester.pump();
    expect(without.newBestFlash, isFalse);
    await tester.pump(SuccessFeedback.advanceDelay);
  });

  testWidgets('cancelPendingAdvance stops a queued advance', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Host(newBest: false)));
    final state = _state(tester);

    state.fire();
    await tester.pump(SuccessFeedback.flashHold);
    state.cancelPendingAdvance();
    await tester.pump(SuccessFeedback.advanceDelay * 2);

    expect(state.advances, 0);
  });

  testWidgets('a mode without auto-advance still flashes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _Host(newBest: false, autoAdvance: false)),
    );
    final state = _state(tester);

    state.fire();
    await tester.pump();
    expect(state.flashOpacity, 1.0);
    await tester.pump(SuccessFeedback.advanceDelay * 2);
    expect(state.advances, 0);
  });

  testWidgets('disposal cancels every pending timer', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Host(newBest: true)));
    _state(tester).fire();
    await tester.pump();

    // Tearing the screen down mid-sequence must not leave a timer running;
    // the test binding fails the test if one is still pending.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(SuccessFeedback.advanceDelay * 2);
    expect(tester.takeException(), isNull);
  });
}
