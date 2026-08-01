import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binary_game/main.dart';
import 'package:binary_game/screens/main_shell.dart';
import 'package:binary_game/screens/name_entry_screen.dart';

void main() {
  testWidgets('new player without a saved name routes to NameEntryScreen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BinaryRushApp());
    await tester.pump();

    expect(find.byType(NameEntryScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });

  testWidgets('returning player with a saved name routes to MainShell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'player_name': 'NEO'});
    await tester.pumpWidget(const BinaryRushApp());
    await tester.pump();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(NameEntryScreen), findsNothing);
  });
}
