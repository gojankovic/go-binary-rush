import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binary_game/game/score_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScoreEngine scoring', () {
    test('first correct earns 10, streak grows the reward', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = await ScoreEngine.create(mode: 'match');

      expect(engine.onCorrect(), 10);
      expect(engine.score, 10);
      expect(engine.streak, 1);

      expect(engine.onCorrect(), 15);
      expect(engine.score, 25);
      expect(engine.streak, 2);

      expect(engine.onCorrect(), 20);
      expect(engine.score, 45);
      expect(engine.streak, 3);
    });

    test('high score is persisted under the mode key', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = await ScoreEngine.create(mode: 'match');
      engine.onCorrect();
      engine.onCorrect();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('match_high_score'), 25);
    });

    test('per-mode and global correct counters increment', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = await ScoreEngine.create(mode: 'reverse');
      engine.onCorrect();
      engine.onCorrect();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('reverse_correct_count'), 2);
      expect(prefs.getInt('total_correct'), 2);
    });
  });

  group('ScoreEngine streak reset', () {
    test('a single wrong does not break the streak', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = await ScoreEngine.create(mode: 'match');
      engine.onCorrect();

      expect(engine.onWrong(), isFalse);
      expect(engine.streak, 1);
    });

    test('two wrongs in a row break the streak', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = await ScoreEngine.create(mode: 'match');
      engine.onCorrect();

      expect(engine.onWrong(), isFalse);
      expect(engine.onWrong(), isTrue);
      expect(engine.streak, 0);
    });

    test('a correct answer resets the wrong counter', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = await ScoreEngine.create(mode: 'match');
      engine.onCorrect();
      engine.onWrong();
      engine.onCorrect();

      expect(engine.onWrong(), isFalse);
      expect(engine.streak, 2);
    });
  });

  group('ScoreEngine penalties', () {
    test('hint subtracts the cost and clamps at zero', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = await ScoreEngine.create(mode: 'match');
      engine.onCorrect();

      engine.onHint();
      expect(engine.score, 8);

      engine.onHint(100);
      expect(engine.score, 0);
    });

    test('wrong letter subtracts one and clamps at zero', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = await ScoreEngine.create(mode: 'hexWord');
      engine.onWrongLetter();
      expect(engine.score, 0);
    });
  });

  group('ScoreEngine new-best flash', () {
    test('never fires on a fresh profile', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = await ScoreEngine.create(mode: 'match');
      engine.onCorrect();
      engine.onCorrect();
      expect(engine.consumeNewBestFlash(), isFalse);
    });

    test('fires once when overtaking an existing high score', () async {
      SharedPreferences.setMockInitialValues({'match_high_score': 20});
      final engine = await ScoreEngine.create(mode: 'match');

      engine.onCorrect(); // 10
      expect(engine.consumeNewBestFlash(), isFalse);
      engine.onCorrect(); // 25 > 20
      expect(engine.consumeNewBestFlash(), isTrue);
      expect(engine.consumeNewBestFlash(), isFalse);
    });
  });
}
