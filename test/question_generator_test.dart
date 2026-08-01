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
    'a cap-filling solve advances only on the next generated question',
    () async {
      SharedPreferences.setMockInitialValues({});
      final gen = await QuestionGenerator.create(mode: 'unit', tiers: _tiers);
      expect(gen.currentTier, 1);
      expect(gen.currentBits, 4);

      gen.next();
      gen.recordSolved();
      gen.next();
      gen.recordSolved(); // cap (2) reached, but the advance is deferred

      // The just-solved question keeps its own tier/bit width while shown.
      expect(gen.currentTier, 1);
      expect(gen.currentBits, 4);

      final t = gen.next(); // deferred advance is applied here
      expect(gen.currentTier, 2);
      expect(gen.currentBits, 5);
      expect([16, 17, 18], contains(t));
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
    gen.next(); // applies and persists the deferred advance

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
      gen.recordSolved(); // cap reached at the last tier

      final t = gen.next(); // deferred advance resets the max-tier seen set
      expect(gen.tierSolvedCount, 0);
      expect([1, 2], contains(t));
    },
  );

  test('skips past several already-exhausted tiers', () async {
    // Legacy data: two consecutive tiers have every target solved while their
    // caps were never reached, so the cap guard alone cannot move past them.
    SharedPreferences.setMockInitialValues({
      'legacy_seen_tier_0': ['1', '2'],
      'legacy_seen_tier_1': ['16', '17'],
    });
    final gen = await QuestionGenerator.create(
      mode: 'legacy',
      tiers: [
        const Tier(bits: 4, targets: [1, 2], cap: 9),
        const Tier(bits: 5, targets: [16, 17], cap: 9),
        const Tier(bits: 6, targets: [32, 33], cap: 9),
      ],
    );

    final t = gen.next();
    expect([32, 33], contains(t));
    expect(gen.currentTier, 3);
    expect(gen.currentBits, 6);
  });

  test('reports a tier whose targets are all below minTarget', () async {
    SharedPreferences.setMockInitialValues({});
    final gen = await QuestionGenerator.create(
      mode: 'misconfigured',
      tiers: [
        const Tier(bits: 4, targets: [1, 2], cap: 2),
      ],
      minTarget: 8,
    );

    expect(gen.next, throwsStateError);
  });
}
