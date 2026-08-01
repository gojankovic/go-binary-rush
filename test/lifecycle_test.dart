import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:binary_game/main.dart';
import 'package:binary_game/screens/game_screen.dart';
import 'package:binary_game/screens/profile_screen.dart';
import 'package:binary_game/services/crt_settings.dart';
import 'package:binary_game/services/haptics.dart';
import 'package:binary_game/services/palette_settings.dart';

/// A preferences store whose reads stay pending until [gate] completes, so a
/// widget's async initialization can be held open across disposal on purpose.
class _GatedStore extends SharedPreferencesStorePlatform {
  _GatedStore(this._gate);

  final Future<void> _gate;
  final InMemorySharedPreferencesStore _backing =
      InMemorySharedPreferencesStore.empty();

  @override
  Future<bool> clear() => _backing.clear();

  @override
  Future<Map<String, Object>> getAll() async {
    await _gate;
    return _backing.getAll();
  }

  @override
  Future<bool> remove(String key) => _backing.remove(key);

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      _backing.setValue(valueType, key, value);
}

void main() {
  testWidgets('bootstrap applies saved palette and CRT on the first render', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'player_name': 'NEO',
      'palette_index': PaletteSettings.indexAlt,
      'crt_intensity': CrtSettings.levelOff,
      'haptics_enabled': false,
    });

    // Same startup path main() runs before runApp().
    await bootstrap();
    await tester.pumpWidget(const BinaryRushApp());
    await tester.pumpAndSettle();

    // Saved settings are in effect for the rendered app, not just the notifiers.
    expect(PaletteSettings.index.value, PaletteSettings.indexAlt);
    expect(CrtSettings.intensity.value, CrtSettings.levelOff);
    expect(Haptics.enabled, isFalse);

    // CRT is off -> the scanline/vignette painter must not be in the tree.
    expect(find.byKey(const ValueKey('crt-overlay-paint')), findsNothing);

    // The active dock label renders in the alt palette (green g4 is 0xFF7DFF97).
    final play = tester.widget<Text>(find.text('PLAY'));
    expect(play.style?.color, const Color(0xFF7DE2FF));
  });

  testWidgets(
    'GameScreen disposed while its init is still pending never setStates',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final gate = Completer<void>();
      SharedPreferencesStorePlatform.instance = _GatedStore(gate.future);

      await tester.pumpWidget(const MaterialApp(home: GameScreen()));
      // Its question/score creation is genuinely suspended on the gated store.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      // Now let the init resume, after the screen has been disposed.
      gate.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ProfileScreen disposed while its load is still pending never setStates',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final gate = Completer<void>();
      SharedPreferencesStorePlatform.instance = _GatedStore(gate.future);

      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      gate.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
