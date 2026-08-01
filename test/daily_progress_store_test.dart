import 'package:binary_game/services/daily_progress_store.dart';
import 'package:binary_game/services/prefs_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('records all daily completion state', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final result = await DailyProgressStore(prefs).recordCompletion(
      dateKey: '20260801',
      score: 70,
      completedAt: DateTime(2026, 8, 1),
    );

    expect(result.bestScore, 70);
    expect(result.streak, 1);
    expect(prefs.getInt(PrefsKeys.dailyBest('20260801')), 70);
    expect(prefs.getBool(PrefsKeys.dailyDone('20260801')), isTrue);
    expect(prefs.getInt(PrefsKeys.dailyStreak), 1);
    expect(prefs.getString(PrefsKeys.dailyLastDate), '20260801');
  });

  test('preserves a better score and extends a consecutive streak', () async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.dailyBest('20260801'): 90,
      PrefsKeys.dailyStreak: 4,
      PrefsKeys.dailyLastDate: '20260731',
    });
    final prefs = await SharedPreferences.getInstance();
    final result = await DailyProgressStore(prefs).recordCompletion(
      dateKey: '20260801',
      score: 60,
      completedAt: DateTime(2026, 8, 1),
    );

    expect(result.bestScore, 90);
    expect(result.streak, 5);
    expect(prefs.getInt(PrefsKeys.dailyBest('20260801')), 90);
  });

  test('repeating a completion does not inflate the streak', () async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.dailyStreak: 3,
      PrefsKeys.dailyLastDate: '20260801',
    });
    final prefs = await SharedPreferences.getInstance();
    final result = await DailyProgressStore(prefs).recordCompletion(
      dateKey: '20260801',
      score: 100,
      completedAt: DateTime(2026, 8, 1),
    );

    expect(result.streak, 3);
  });
}
