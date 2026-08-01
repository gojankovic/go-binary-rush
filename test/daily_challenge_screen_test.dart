import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binary_game/game/daily_challenge.dart';
import 'package:binary_game/screens/daily_challenge_screen.dart';
import 'package:binary_game/theme.dart';
import 'package:binary_game/widgets/bit_tile.dart';

void main() {
  testWidgets('the screen asks exactly what the module generates for today', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({'player_name': 'NEO'});

    final expected = buildDailyQuestions(DateTime.now()).first;
    // Every schedule variant opens on a 4-bit match, so this holds any day.
    expect(expected.mode, DailyMode.match);

    await tester.pumpWidget(const MaterialApp(home: DailyChallengeScreen()));
    await tester.pump();
    await tester.pump();

    final big = AppText.bigTarget().fontSize;
    final targets = [
      for (final t in tester.widgetList<Text>(find.byType(Text)))
        if (t.style?.fontSize == big && int.tryParse(t.data ?? '') != null)
          int.parse(t.data!),
    ];
    expect(targets, [
      expected.target,
    ], reason: 'the rendered target must come from buildDailyQuestions');
    expect(tester.widgetList(find.byType(BitTile)).length, expected.bits);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });
}
