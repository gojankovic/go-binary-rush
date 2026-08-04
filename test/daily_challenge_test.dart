import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:binary_game/game/daily_challenge.dart';

/// Dates the golden was captured for: every schedule variant, both sides of a
/// year boundary, a leap day, and two times of day.
List<DateTime> _goldenDates() => [
  for (var d = 1; d <= 12; d++) DateTime(2026, 1, d, 12),
  for (var d = 20; d <= 30; d++) DateTime(2026, 6, d, 12),
  for (var d = 28; d <= 31; d++) DateTime(2026, 12, d, 12),
  for (var d = 1; d <= 3; d++) DateTime(2027, 1, d, 12),
  for (var d = 27; d <= 29; d++) DateTime(2024, 2, d, 12),
  DateTime(2024, 3, 1, 12),
  DateTime(2026, 3, 15, 0, 1),
  DateTime(2026, 3, 15, 23, 59),
];

String _render(DateTime day) {
  final questions = buildDailyQuestions(day);
  final lines = <String>[
    '${dailyDateKey(day)} variant=${dailyScheduleIndex(day)}',
  ];
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    final legacyModeName = q.mode == DailyMode.bitFlip ? 'match' : q.mode.name;
    lines.add(
      '  $i $legacyModeName bits=${q.bits} '
      'target=${q.target} word=${q.word} xorA=${q.xorA}',
    );
  }
  return lines.join('\n');
}

void main() {
  group('daily question generation', () {
    test('matches the golden captured before the extraction', () {
      // Characterization: the golden was written from the shipped screen code.
      // A diff here means players would get different questions than before.
      final golden = File(
        'test/golden/daily_questions.txt',
      ).readAsStringSync().replaceAll('\r\n', '\n').trimRight();
      final actual = _goldenDates().map(_render).join('\n');
      expect(actual, golden);
    });

    test('is stable for the same day and differs across days', () {
      final day = DateTime(2026, 5, 4, 8);
      final a = buildDailyQuestions(day);
      final b = buildDailyQuestions(DateTime(2026, 5, 4, 21));
      expect([for (final q in a) q.target], [for (final q in b) q.target]);

      final other = buildDailyQuestions(DateTime(2026, 5, 5, 8));
      expect([
        for (final q in a) q.target,
      ], isNot([for (final q in other) q.target]));
    });

    test('every question is answerable at its own bit width', () {
      for (final day in _goldenDates()) {
        for (final q in buildDailyQuestions(day)) {
          final maxVal = (1 << q.bits) - 1;
          switch (q.mode) {
            case DailyMode.hexWord:
              expect(q.word, isNotEmpty);
              expect(q.word.length, lessThanOrEqualTo(6));
            case DailyMode.addition:
              // Both rows are needed, and the sum must be reachable.
              expect(q.target, greaterThanOrEqualTo(2));
              expect(q.target, lessThanOrEqualTo(2 * maxVal));
            case DailyMode.xor:
              expect(q.target, inInclusiveRange(1, maxVal));
              expect(q.xorA, inInclusiveRange(0, maxVal));
              expect(q.xorA ^ q.target, lessThanOrEqualTo(maxVal));
            case DailyMode.hexMatch:
              expect(q.target, inInclusiveRange(1, maxVal));
            case DailyMode.bitFlip:
              expect(q.target, inInclusiveRange(1 << (q.bits - 1), maxVal));
              expect(q.startValue, inInclusiveRange(0, maxVal));
              expect(q.startValue, isNot(q.target));
            case DailyMode.match:
            case DailyMode.reverse:
              // Top bit set, so the row is never trivially narrow.
              expect(q.target, inInclusiveRange(1 << (q.bits - 1), maxVal));
          }
        }
      }
    });

    test('schedule variants all get used across a year', () {
      final seen = {
        for (var d = 0; d < 365; d++)
          dailyScheduleIndex(DateTime(2026, 1, 1, 12).add(Duration(days: d))),
      };
      expect(seen, hasLength(kDailyScheduleVariants.length));
    });

    test('every variant has exactly the expected slot count', () {
      for (final variant in kDailyScheduleVariants) {
        expect(variant, hasLength(kDailyQuestionCount));
      }
    });

    test('the full-mix variant includes Bit Flip', () {
      expect(
        kDailyScheduleVariants[4].where(
          (slot) => slot.mode == DailyMode.bitFlip,
        ),
        hasLength(1),
      );
    });
  });

  group('daily streak', () {
    test('a first ever completion starts the streak at 1', () {
      expect(
        nextDailyStreak(
          currentStreak: 0,
          lastDate: '',
          today: DateTime(2026, 3, 10),
        ),
        1,
      );
    });

    test('completing on consecutive days extends the streak', () {
      expect(
        nextDailyStreak(
          currentStreak: 4,
          lastDate: '20260309',
          today: DateTime(2026, 3, 10),
        ),
        5,
      );
    });

    test('a skipped day restarts the streak at 1', () {
      expect(
        nextDailyStreak(
          currentStreak: 9,
          lastDate: '20260307',
          today: DateTime(2026, 3, 10),
        ),
        1,
      );
    });

    test('replaying the same day does not inflate the streak', () {
      expect(
        nextDailyStreak(
          currentStreak: 3,
          lastDate: '20260310',
          today: DateTime(2026, 3, 10),
        ),
        3,
      );
    });

    test('extends across a month and a year boundary', () {
      expect(
        nextDailyStreak(
          currentStreak: 2,
          lastDate: '20260228',
          today: DateTime(2026, 3, 1),
        ),
        3,
      );
      expect(
        nextDailyStreak(
          currentStreak: 7,
          lastDate: '20261231',
          today: DateTime(2027, 1, 1),
        ),
        8,
      );
    });
  });
}
