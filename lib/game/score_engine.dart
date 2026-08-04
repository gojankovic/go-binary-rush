import 'package:shared_preferences/shared_preferences.dart';
import '../services/prefs_keys.dart';

class ScoreEngine {
  final SharedPreferences _prefs;
  final String _keyHighScore;
  final String _keyModeCount;
  final int _startingHigh;
  bool _newBestAnnounced = false;
  int score = 0;
  int streak = 0;
  int highScore;

  ScoreEngine._(this._prefs, String mode)
    : _keyHighScore = PrefsKeys.highScore(mode),
      _keyModeCount = PrefsKeys.correctCount(mode),
      _startingHigh = _prefs.getInt(PrefsKeys.highScore(mode)) ?? 0,
      highScore = _prefs.getInt(PrefsKeys.highScore(mode)) ?? 0;

  /// Returns true the first time `score` overtakes the high score that
  /// existed when this engine was created. Only fires once per run, and
  /// never on a fresh profile (starting high == 0).
  bool consumeNewBestFlash() {
    if (_newBestAnnounced) return false;
    if (_startingHigh <= 0) return false;
    if (score <= _startingHigh) return false;
    _newBestAnnounced = true;
    return true;
  }

  static Future<ScoreEngine> create({String mode = 'match'}) async {
    final prefs = await SharedPreferences.getInstance();
    return ScoreEngine._(prefs, mode);
  }

  int _wrongsInRow = 0;
  int get wrongsInRow => _wrongsInRow;

  int onCorrect({int bonus = 0}) {
    _wrongsInRow = 0;
    streak++;
    final earned = 10 + (streak - 1) * 5 + bonus;
    score += earned;
    if (score > highScore) {
      highScore = score;
      _prefs.setInt(_keyHighScore, highScore);
    }
    _prefs.setInt(
      PrefsKeys.totalCorrect,
      (_prefs.getInt(PrefsKeys.totalCorrect) ?? 0) + 1,
    );
    _prefs.setInt(_keyModeCount, (_prefs.getInt(_keyModeCount) ?? 0) + 1);
    final bestStreak = _prefs.getInt(PrefsKeys.bestStreakEver) ?? 0;
    if (streak > bestStreak) _prefs.setInt(PrefsKeys.bestStreakEver, streak);
    return earned;
  }

  /// Returns true if the streak was just broken by this call.
  bool onWrong() {
    _wrongsInRow++;
    if (_wrongsInRow >= 2 && streak > 0) {
      streak = 0;
      _wrongsInRow = 0;
      return true;
    }
    return false;
  }

  void onHint([int cost = 2]) {
    score = (score - cost).clamp(0, 999999);
  }

  void onWrongLetter() {
    score = (score - 1).clamp(0, 999999);
  }
}
