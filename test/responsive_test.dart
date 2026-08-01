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
const _sizes = {
  'small 320x568': Size(320, 568),
  'compact 360x640': Size(360, 640),
  'regular 411x731': Size(411, 731),
  'tablet 768x1024': Size(768, 1024),
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
  for (final size in _sizes.entries) {
    for (final screen in _screens.entries) {
      testWidgets('${screen.key} lays out at ${size.key}', (tester) async {
        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({'player_name': 'NEO'});

        await tester.pumpWidget(MaterialApp(home: screen.value()));
        // Two pumps: the first frame plus the one after async init resolves.
        await tester.pump();
        await tester.pump();

        // A RenderFlex overflow is reported as an exception in tests.
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.key} overflows at ${size.key}',
        );

        // Dispose so any countdown or feedback timers are cancelled.
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      });
    }
  }
}
