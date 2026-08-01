import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binary_game/screens/achievements_screen.dart';
import 'package:binary_game/screens/addition_screen.dart';
import 'package:binary_game/screens/daily_challenge_screen.dart';
import 'package:binary_game/screens/game_screen.dart';
import 'package:binary_game/screens/hex_screen.dart';
import 'package:binary_game/screens/hex_word_screen.dart';
import 'package:binary_game/screens/how_to_play_screen.dart';
import 'package:binary_game/screens/learn_screen.dart';
import 'package:binary_game/screens/main_shell.dart';
import 'package:binary_game/screens/menu_screen.dart';
import 'package:binary_game/screens/name_entry_screen.dart';
import 'package:binary_game/screens/profile_screen.dart';
import 'package:binary_game/screens/reference_screen.dart';
import 'package:binary_game/screens/reverse_screen.dart';
import 'package:binary_game/screens/settings_screen.dart';
import 'package:binary_game/screens/speed_burst_screen.dart';
import 'package:binary_game/screens/xor_screen.dart';

/// Logical sizes, smallest first. 320x568 is an iPhone SE / small Android and
/// is where the layouts actually run out of room.
const _scenarios = {
  'small 320x568': (
    size: Size(320, 568),
    textScale: 1.0,
    padding: FakeViewPadding.zero,
  ),
  'compact 360x640': (
    size: Size(360, 640),
    textScale: 1.0,
    padding: FakeViewPadding.zero,
  ),
  'regular 411x731': (
    size: Size(411, 731),
    textScale: 1.0,
    padding: FakeViewPadding.zero,
  ),
  'tablet 768x1024': (
    size: Size(768, 1024),
    textScale: 1.0,
    padding: FakeViewPadding.zero,
  ),
  'small 320x568 at 1.5x text': (
    size: Size(320, 568),
    textScale: 1.5,
    padding: FakeViewPadding.zero,
  ),
  'compact Android with system bars': (
    size: Size(360, 640),
    textScale: 1.0,
    padding: FakeViewPadding(top: 28, bottom: 24),
  ),
};

final _screens = <String, Widget Function()>{
  'menu': () => const MenuScreen(),
  'game': () => const GameScreen(),
  'reverse': () => const ReverseScreen(),
  'addition': () => const AdditionScreen(),
  'xor': () => const XorScreen(),
  'hex': () => const HexScreen(),
  'hexWord': () => const HexWordScreen(),
  'speedBurst': () => const SpeedBurstScreen(),
  'daily': () => const DailyChallengeScreen(),
  'profile': () => const ProfileScreen(),
  'achievements': () => const AchievementsScreen(),
  'settings': () => const SettingsScreen(),
  'reference': () => const ReferenceScreen(),
  'howToPlay': () => const HowToPlayScreen(),
  'learn': () => const LearnScreen(),
  'nameEntry': () => const NameEntryScreen(),
  'shell': () => const MainShell(),
};

void main() {
  for (final scenario in _scenarios.entries) {
    for (final screen in _screens.entries) {
      testWidgets('${screen.key} lays out at ${scenario.key}', (tester) async {
        tester.view.physicalSize = scenario.value.size;
        tester.view.devicePixelRatio = 1.0;
        tester.view.padding = scenario.value.padding;
        tester.view.viewPadding = scenario.value.padding;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);

        SharedPreferences.setMockInitialValues({'player_name': 'NEO'});

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => ColoredBox(
              color: Colors.black,
              child: SafeArea(
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scenario.value.textScale),
                  ),
                  child: child!,
                ),
              ),
            ),
            home: screen.value(),
          ),
        );
        // Two pumps: the first frame plus the one after async init resolves.
        await tester.pump();
        await tester.pump();

        // A RenderFlex overflow is reported as an exception in tests.
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.key} overflows at ${scenario.key}',
        );

        // Dispose so any countdown or feedback timers are cancelled.
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      });
    }
  }
}
