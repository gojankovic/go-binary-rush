import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binary_game/screens/speed_burst_screen.dart';
import 'package:binary_game/widgets/bit_tile.dart';

/// The MATCH target is the only 64px text on the play screen.
int _readTarget(WidgetTester tester) {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    if (text.style?.fontSize == 64) return int.parse(text.data!);
  }
  fail('target display not found');
}

Future<void> _solveMatch(WidgetTester tester) async {
  final target = _readTarget(tester);
  final tiles = find.byType(BitTile);
  final n = tester.widgetList(tiles).length;
  expect(
    target,
    lessThanOrEqualTo((1 << n) - 1),
    reason: 'target $target cannot be built from $n bit tiles',
  );
  for (var i = 0; i < n; i++) {
    if ((target >> (n - 1 - i)) & 1 == 1) {
      await tester.tap(tiles.at(i));
      await tester.pump();
    }
  }
}

void main() {
  testWidgets('Speed Burst renders a tier-boundary question at its own width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // One solve short of tier 2's cap (5), so the next question crosses into
    // tier 3 — where the bit width grows from 4 to 5.
    SharedPreferences.setMockInitialValues({
      'speed_match_current_tier': 1,
      'speed_match_seen_tier_1': ['3', '5', '6', '7'],
    });

    await tester.pumpWidget(const MaterialApp(home: SpeedBurstScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('MATCH'));
    await tester.pump();
    await tester.pump();

    expect(tester.widgetList(find.byType(BitTile)).length, 4);
    await _solveMatch(tester);

    // Let the cap-filling solve settle and the next question load.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    // The advance happened: the row must be as wide as the new tier's targets.
    expect(tester.widgetList(find.byType(BitTile)).length, 5);
    final target = _readTarget(tester);
    expect(target, inInclusiveRange(16, 31));

    // Solving it must be possible at the rendered width.
    await _solveMatch(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('2'), findsWidgets); // SOLVED counter reached 2

    // Dispose so the 60s countdown timer is cancelled.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });
}
