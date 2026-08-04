import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binary_game/game/question_generator.dart';
import 'package:binary_game/game/score_engine.dart';
import 'package:binary_game/services/prefs_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // These literals are what shipped builds already wrote to disk. Changing one
  // silently wipes that player's progress, so it must be a deliberate act with
  // a migration — not a side effect of tidying up names.
  group('stored key literals', () {
    test('profile keys', () {
      expect(PrefsKeys.playerName, 'player_name');
      expect(PrefsKeys.totalCorrect, 'total_correct');
      expect(PrefsKeys.bestStreakEver, 'best_streak_ever');
    });

    test('per-mode keys', () {
      expect(PrefsKeys.highScore(GameModes.match), 'match_high_score');
      expect(PrefsKeys.highScore(GameModes.reverse), 'reverse_high_score');
      expect(PrefsKeys.highScore(GameModes.addition), 'addition_high_score');
      expect(PrefsKeys.highScore(GameModes.xor), 'xor_high_score');
      expect(PrefsKeys.highScore(GameModes.hex), 'hex_high_score');
      expect(PrefsKeys.highScore(GameModes.hexWord), 'hex_word_high_score');
      expect(PrefsKeys.highScore(GameModes.bitFlip), 'bit_flip_high_score');
      expect(PrefsKeys.correctCount(GameModes.match), 'match_correct_count');
      expect(PrefsKeys.currentTier(GameModes.match), 'match_current_tier');
      expect(PrefsKeys.seenTier(GameModes.match, 2), 'match_seen_tier_2');
    });

    test('speed burst keys, including the camelCase hex word id', () {
      expect(
        PrefsKeys.highScore(GameModes.speedMatch),
        'speed_match_high_score',
      );
      expect(
        PrefsKeys.highScore(GameModes.speedReverse),
        'speed_reverse_high_score',
      );
      expect(
        PrefsKeys.highScore(GameModes.speedAddition),
        'speed_addition_high_score',
      );
      expect(PrefsKeys.highScore(GameModes.speedXor), 'speed_xor_high_score');
      // Not speed_hex_word_*: this one is built from an enum name.
      expect(
        PrefsKeys.highScore(GameModes.speedHexWord),
        'speed_hexWord_high_score',
      );
      expect(
        PrefsKeys.correctCount(GameModes.speedHexWord),
        'speed_hexWord_correct_count',
      );
      expect(
        PrefsKeys.highScore(GameModes.speedBitFlip),
        'speed_bit_flip_high_score',
      );
    });

    test('daily and hex word keys', () {
      expect(PrefsKeys.dailyStreak, 'daily_streak');
      expect(PrefsKeys.dailyLastDate, 'daily_last_date');
      expect(PrefsKeys.dailyDone('20260801'), 'daily_20260801_done');
      expect(PrefsKeys.dailyBest('20260801'), 'daily_20260801_best');
      expect(PrefsKeys.hexWordTotal, 'hex_word_total');
      expect(PrefsKeys.hexWordPerfectCount, 'hex_word_perfect_count');
      expect(PrefsKeys.hexWordMaxLen, 'hex_word_max_len');
    });
  });

  group('engines still read and write the historical keys', () {
    test(
      'ScoreEngine picks up a high score written by an older build',
      () async {
        SharedPreferences.setMockInitialValues({'xor_high_score': 40});
        final engine = await ScoreEngine.create(mode: GameModes.xor);
        expect(engine.highScore, 40);

        engine.onCorrect();
        engine.onCorrect();
        engine.onCorrect();
        engine.onCorrect(); // 10+15+20+25 = 70 > 40
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('xor_high_score'), 70);
        expect(prefs.getInt('xor_correct_count'), 4);
        expect(prefs.getInt('total_correct'), 4);
        expect(prefs.getInt('best_streak_ever'), 4);
      },
    );

    test(
      'QuestionGenerator resumes from an older build\'s tier and seen set',
      () async {
        SharedPreferences.setMockInitialValues({
          'match_current_tier': 1,
          'match_seen_tier_1': ['3', '5'],
        });
        final gen = await QuestionGenerator.create(mode: GameModes.match);
        expect(gen.currentTier, 2);
        expect(gen.tierSolvedCount, 2);

        final target = gen.next();
        expect([3, 5], isNot(contains(target)));
        gen.recordSolved();

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList('match_seen_tier_1'),
          containsAll(['3', '5', '$target']),
        );
      },
    );
  });

  group('bestSpeedBurstScore', () {
    test('returns the best across modes, not just match', () async {
      SharedPreferences.setMockInitialValues({
        'speed_match_high_score': 12,
        'speed_xor_high_score': 31,
        'speed_hexWord_high_score': 7,
        'speed_bit_flip_high_score': 42,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(bestSpeedBurstScore(prefs), 42);
    });

    test('is zero on a fresh profile', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(bestSpeedBurstScore(prefs), 0);
    });
  });
}
