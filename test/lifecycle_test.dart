import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binary_game/screens/game_screen.dart';
import 'package:binary_game/screens/profile_screen.dart';
import 'package:binary_game/services/crt_settings.dart';
import 'package:binary_game/services/haptics.dart';
import 'package:binary_game/services/palette_settings.dart';

void main() {
  testWidgets('saved palette, CRT, and haptics apply after startup init', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'palette_index': PaletteSettings.indexAlt,
      'crt_intensity': CrtSettings.levelOff,
      'haptics_enabled': false,
    });

    await Future.wait([
      Haptics.init(),
      CrtSettings.init(),
      PaletteSettings.init(),
    ]);

    expect(PaletteSettings.index.value, PaletteSettings.indexAlt);
    expect(CrtSettings.intensity.value, CrtSettings.levelOff);
    expect(Haptics.enabled, isFalse);
  });

  testWidgets(
    'GameScreen disposed during async init does not setState after dispose',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: GameScreen()));
      // Replace (and dispose) the screen before its async question/score
      // creation resolves, then flush the pending futures.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ProfileScreen disposed during async load does not setState after dispose',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
