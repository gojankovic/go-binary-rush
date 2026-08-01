import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:binary_game/game/difficulty.dart';
import 'package:binary_game/game/question_generator.dart';

// Small, deterministic tier set so cap boundaries are reached in few calls.
final _tiers = [
  const Tier(bits: 4, targets: [1, 2, 3], cap: 2),
  const Tier(bits: 5, targets: [16, 17, 18], cap: 2),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts on the persisted tier with its bit width', () async {
    SharedPreferences.setMockInitialValues({'unit_current_tier': 1});
    final gen = await QuestionGenerator.create(mode: 'unit', tiers: _tiers);
    expect(gen.currentTier, 2);
    expect(gen.currentBits, 5);
  });

  test('does not repeat targets within a tier', () async {
    SharedPreferences.setMockInitialValues({});
    final gen = await QuestionGenerator.create(mode: 'unit', tiers: _tiers);
    final first = gen.next();
    final second = gen.next();
    expect(first, isNot(second));
    expect([1, 2, 3], contains(first));
  });

  test('respects minTarget filtering', () async {
    SharedPreferences.setMockInitialValues({});
    final gen = await QuestionGenerator.create(
      mode: 'unit',
      tiers: [
        const Tier(bits: 4, targets: [1, 2, 8, 12], cap: 99),
      ],
      minTarget: 8,
    );
    for (var i = 0; i < 2; i++) {
      expect(gen.next(), greaterThanOrEqualTo(8));
    }
  });

  test('generating questions never advances the tier', () async {
    SharedPreferences.setMockInitialValues({});
    final gen = await QuestionGenerator.create(mode: 'unit', tiers: _tiers);

    // Cap is 2 but generating far past it must not advance without solving.
    for (var i = 0; i < 10; i++) {
      gen.next();
    }

    expect(gen.currentTier, 1);
    expect(gen.currentBits, 4);
    expect(gen.tierSolvedCount, 0);
  });

  test('only solves count toward tier progress', () async {
    SharedPreferences.setMockInitialValues({});
    final gen = await QuestionGenerator.create(mode: 'unit', tiers: _tiers);

    gen.next();
    gen.recordSolved();
    expect(gen.tierSolvedCount, 1);
    expect(gen.currentTier, 1); // cap is 2, one solve is not enough

    // Leaving these questions unsolved must not add progress.
    gen.next();
    gen.next();
    expect(gen.tierSolvedCount, 1);
    expect(gen.currentTier, 1);
  });

  test(
    'advances to the 5-bit tier once the cap of solves is reached',
    () async {
      SharedPreferences.setMockInitialValues({});
      final gen = await QuestionGenerator.create(mode: 'unit', tiers: _tiers);
      expect(gen.currentTier, 1);
      expect(gen.currentBits, 4);

      gen.next();
      gen.recordSolved();
      gen.next();
      gen.recordSolved(); // second solve reaches cap (2) -> advance

      expect(gen.currentTier, 2);
      expect(gen.currentBits, 5);
    },
  );

  test(
    'recordSolved is a no-op without a pending generated question',
    () async {
      SharedPreferences.setMockInitialValues({});
      final gen = await QuestionGenerator.create(mode: 'unit', tiers: _tiers);

      gen.next();
      gen.recordSolved();
      gen.recordSolved(); // no current question -> must not double-count

      expect(gen.tierSolvedCount, 1);
      expect(gen.currentTier, 1);
    },
  );

  test('persists the advanced tier across instances', () async {
    SharedPreferences.setMockInitialValues({});
    final gen = await QuestionGenerator.create(mode: 'unit', tiers: _tiers);
    gen.next();
    gen.recordSolved();
    gen.next();
    gen.recordSolved();

    final reopened = await QuestionGenerator.create(
      mode: 'unit',
      tiers: _tiers,
    );
    expect(reopened.currentTier, 2);
  });

  test(
    'max-tier exhaustion resets seen and keeps producing valid targets',
    () async {
      SharedPreferences.setMockInitialValues({});
      final gen = await QuestionGenerator.create(
        mode: 'max',
        tiers: [
          const Tier(bits: 4, targets: [1, 2], cap: 2),
        ],
      );
      gen.next();
      gen.recordSolved();
      gen.next();
      gen.recordSolved(); // hits cap at the last tier -> seen is cleared

      expect(gen.tierSolvedCount, 0);
      expect([1, 2], contains(gen.next()));
    },
  );
}
