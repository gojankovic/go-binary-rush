import 'package:shared_preferences/shared_preferences.dart';

/// Every SharedPreferences key the game reads or writes.
///
/// The string literals here are the on-disk contract with builds already
/// installed on players' devices. Renaming an identifier is free; changing a
/// literal silently resets that player's progress and must not be done without
/// migrating the stored value.
///
/// Keys owned by a service (haptics, CRT, palette, notifications) stay with
/// that service — this file covers the gameplay and profile data that would
/// otherwise be spelled out as bare strings across the screens.
class PrefsKeys {
  const PrefsKeys._();

  // ── Profile ──────────────────────────────────────────────────────
  static const playerName = 'player_name';
  static const totalCorrect = 'total_correct';
  static const bestStreakEver = 'best_streak_ever';

  // ── Per-mode, keyed by a GameModes id ────────────────────────────
  static String highScore(String mode) => '${mode}_high_score';
  static String correctCount(String mode) => '${mode}_correct_count';
  static String currentTier(String mode) => '${mode}_current_tier';
  static String seenTier(String mode, int tierIndex) =>
      '${mode}_seen_tier_$tierIndex';

  // ── Daily challenge ──────────────────────────────────────────────
  static const dailyStreak = 'daily_streak';
  static const dailyLastDate = 'daily_last_date';
  static String dailyDone(String dateKey) => 'daily_${dateKey}_done';
  static String dailyBest(String dateKey) => 'daily_${dateKey}_best';

  // ── Hex Word ─────────────────────────────────────────────────────
  static const hexWordTotal = 'hex_word_total';
  static const hexWordPerfectCount = 'hex_word_perfect_count';
  static const hexWordMaxLen = 'hex_word_max_len';
}

/// Mode ids that [PrefsKeys] composes per-mode keys from.
///
/// The two hex-word spellings are deliberate and not interchangeable: the
/// standalone screen has always stored `hex_word_*`, while Speed Burst builds
/// its id from an enum name and stores `speed_hexWord_*`.
class GameModes {
  const GameModes._();

  static const match = 'match';
  static const reverse = 'reverse';
  static const addition = 'addition';
  static const xor = 'xor';
  static const hex = 'hex';
  static const hexWord = 'hex_word';

  static const speedMatch = 'speed_match';
  static const speedReverse = 'speed_reverse';
  static const speedAddition = 'speed_addition';
  static const speedXor = 'speed_xor';
  static const speedHexWord = 'speed_hexWord';

  /// Speed Burst keeps a separate high score per mode; "best" across the whole
  /// mode is the max over these.
  static const allSpeed = [
    speedMatch,
    speedReverse,
    speedAddition,
    speedXor,
    speedHexWord,
  ];
}

/// Best solved count across every Speed Burst mode. Speed Burst stores one high
/// score per mode, so anything showing a single "best" must aggregate them —
/// reading only `speed_match` hides a better run in another mode.
int bestSpeedBurstScore(SharedPreferences prefs) => GameModes.allSpeed
    .map((mode) => prefs.getInt(PrefsKeys.highScore(mode)) ?? 0)
    .reduce((a, b) => a > b ? a : b);
