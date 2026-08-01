import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binary_game/screens/main_shell.dart';
import 'package:binary_game/screens/menu_screen.dart';
import 'package:binary_game/widgets/bit_row.dart';
import 'package:binary_game/widgets/hex_word_keyboard.dart';
import 'package:binary_game/widgets/num_pad.dart';

void main() {
  testWidgets('bit tiles expose their place value and toggled state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BitRow(bits: const [1, 0, 1, 0], onToggle: (_) {}),
        ),
      ),
    );

    // Left to right the tiles are worth 8, 4, 2, 1.
    expect(
      tester.getSemantics(find.bySemanticsLabel('bit worth 8')),
      matchesSemantics(
        label: 'bit worth 8',
        value: '1',
        isButton: true,
        isToggled: true,
        hasToggledState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('bit worth 4')),
      matchesSemantics(
        label: 'bit worth 4',
        value: '0',
        isButton: true,
        hasToggledState: true,
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel('bit worth 1'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a bit tile can be activated through the semantics tree', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var toggled = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BitRow(bits: const [0, 0], onToggle: (i) => toggled = i),
        ),
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('bit worth 1'));
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    await tester.pump();

    expect(toggled, 1, reason: 'the low bit is the second tile');
    handle.dispose();
  });

  testWidgets('keypad keys are labelled, backspace is spelled out', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NumPad(onTap: (_) {})),
      ),
    );

    expect(find.bySemanticsLabel('7'), findsOneWidget);
    expect(find.bySemanticsLabel('backspace'), findsOneWidget);
    // The glyph itself must not leak through as a second node.
    expect(find.bySemanticsLabel('⌫'), findsNothing);
    handle.dispose();
  });

  testWidgets('a disabled keypad reports its keys as disabled', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NumPad(onTap: (_) {}, disabled: true)),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('7')),
      matchesSemantics(label: '7', isButton: true, hasEnabledState: true),
    );
    handle.dispose();
  });

  testWidgets('hex word keyboard letters are labelled', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HexWordKeyboard(onTap: (_) {})),
      ),
    );

    expect(find.bySemanticsLabel('Q'), findsOneWidget);
    expect(find.bySemanticsLabel('M'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('dock tabs report which one is selected', (tester) async {
    final handle = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues({'player_name': 'NEO'});
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.bySemanticsLabel('PLAY')),
      matchesSemantics(
        label: 'PLAY',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('STATS')),
      matchesSemantics(
        label: 'STATS',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a menu mode row reads as one control with its best score', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues({
      'player_name': 'NEO',
      'match_high_score': 120,
    });
    await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('MATCH, decimal  →  binary, best 120'),
      findsOneWidget,
    );
    // An unplayed mode does not announce a meaningless "best 0".
    expect(find.bySemanticsLabel('XOR, A ⊕ B = C'), findsOneWidget);
    handle.dispose();
  });
}
