import 'package:binary_game/screens/bit_flip_screen.dart';
import 'package:binary_game/widgets/bit_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('an optimal Bit Flip solve earns the perfect bonus', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: BitFlipScreen()));
    await tester.pump();
    await tester.pump();

    final startLine = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .firstWhere((text) => text.startsWith('START '));
    final match = RegExp(r'START (\d+)  ·  PAR (\d+)').firstMatch(startLine)!;
    final start = int.parse(match.group(1)!);
    final par = int.parse(match.group(2)!);
    final target = tester
        .widgetList<Text>(find.byType(Text))
        .where((text) => text.style?.fontSize == 64)
        .map((text) => int.parse(text.data!))
        .single;
    final tiles = find.byType(BitTile);
    final width = tester.widgetList(tiles).length;

    var taps = 0;
    for (var i = 0; i < width; i++) {
      final bit = 1 << (width - 1 - i);
      if ((start & bit) != (target & bit)) {
        await tester.tap(tiles.at(i));
        await tester.pump();
        taps++;
      }
    }

    expect(taps, par);
    expect(find.text('PERFECT  +15 PTS'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('bit_flip_high_score'), 15);
    expect(prefs.getInt('bit_flip_correct_count'), 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  });
}
