import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binary_game/screens/achievements_screen.dart';
import 'package:binary_game/screens/menu_screen.dart';

void main() {
  testWidgets(
    'menu shows the best across all Speed Burst modes, not just MATCH',
    (tester) async {
      // Best is in a non-MATCH speed mode; the aggregate must still surface it.
      SharedPreferences.setMockInitialValues({
        'player_name': 'NEO',
        'speed_match_high_score': 0,
        'speed_reverse_high_score': 30,
      });

      await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
      await tester.pumpAndSettle();

      expect(find.text('★ 30'), findsOneWidget);
      expect(find.text('BEST ANY'), findsOneWidget);
    },
  );

  testWidgets('SPEED DEMON stays locked below the 25-solve threshold', (
    tester,
  ) async {
    // Tall surface so every achievement row in the lazy list is built.
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'player_name': 'NEO',
      'speed_reverse_high_score': 24,
    });

    await tester.pumpWidget(const MaterialApp(home: AchievementsScreen()));
    await tester.pumpAndSettle();

    // Goal 25 is unique to SPEED DEMON; a locked row renders "24/25".
    expect(find.text('24/25'), findsOneWidget);
    expect(find.text('solve 25+ in any Speed Burst mode'), findsOneWidget);
  });

  testWidgets('SPEED DEMON unlocks at 25 solves in any Speed Burst mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 25 solves in a non-MATCH mode must satisfy the achievement.
    SharedPreferences.setMockInitialValues({
      'player_name': 'NEO',
      'speed_reverse_high_score': 25,
    });

    await tester.pumpWidget(const MaterialApp(home: AchievementsScreen()));
    await tester.pumpAndSettle();

    // Unlocked -> no "24/25" progress text remains.
    expect(find.text('24/25'), findsNothing);
    expect(find.text('solve 25+ in any Speed Burst mode'), findsOneWidget);
  });
}
