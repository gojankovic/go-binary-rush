import 'package:shared_preferences/shared_preferences.dart';

import '../game/daily_challenge.dart';
import 'prefs_keys.dart';

class DailyCompletionResult {
  final int bestScore;
  final int streak;

  const DailyCompletionResult({required this.bestScore, required this.streak});
}

class DailyProgressStore {
  final SharedPreferences _prefs;

  const DailyProgressStore(this._prefs);

  Future<DailyCompletionResult> recordCompletion({
    required String dateKey,
    required int score,
    required DateTime completedAt,
  }) async {
    final previousBest = _prefs.getInt(PrefsKeys.dailyBest(dateKey)) ?? 0;
    final bestScore = score > previousBest ? score : previousBest;
    final streak = nextDailyStreak(
      currentStreak: _prefs.getInt(PrefsKeys.dailyStreak) ?? 0,
      lastDate: _prefs.getString(PrefsKeys.dailyLastDate) ?? '',
      today: completedAt,
    );

    await _prefs.setInt(PrefsKeys.dailyBest(dateKey), bestScore);
    await _prefs.setBool(PrefsKeys.dailyDone(dateKey), true);
    await _prefs.setInt(PrefsKeys.dailyStreak, streak);
    await _prefs.setString(PrefsKeys.dailyLastDate, dateKey);

    return DailyCompletionResult(bestScore: bestScore, streak: streak);
  }
}
