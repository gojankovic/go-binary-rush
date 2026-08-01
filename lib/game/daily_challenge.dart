import 'dart:math';

import 'word_list.dart';

/// Question kinds a daily challenge slot can hold.
enum DailyMode { match, reverse, hexWord, addition, xor, hexMatch }

/// One slot in a schedule variant: what to ask and at which bit width.
/// [bits] is 0 for hexWord, which is not bit-width based.
class DailySlot {
  final DailyMode mode;
  final int bits;

  const DailySlot(this.mode, this.bits);
}

/// A fully resolved question for one day. Only the fields the [mode] uses are
/// meaningful: [word] for hexWord, [xorA] for xor, [target] for everything else.
class DailyQuestion {
  final DailyMode mode;
  final int bits;
  final int target;
  final String word;
  final int xorA;

  const DailyQuestion({
    required this.mode,
    required this.bits,
    required this.target,
    this.word = '',
    this.xorA = 0,
  });
}

const int kDailyQuestionCount = 10;

/// Seeds are spaced by a prime so consecutive questions do not correlate.
const int _seedStride = 7919;

const List<List<DailySlot>> kDailyScheduleVariants = [
  // 0 — Classic match/reverse mix
  [
    DailySlot(DailyMode.match, 4),
    DailySlot(DailyMode.match, 4),
    DailySlot(DailyMode.reverse, 4),
    DailySlot(DailyMode.match, 5),
    DailySlot(DailyMode.reverse, 5),
    DailySlot(DailyMode.match, 6),
    DailySlot(DailyMode.hexWord, 0),
    DailySlot(DailyMode.hexWord, 0),
    DailySlot(DailyMode.match, 7),
    DailySlot(DailyMode.match, 8),
  ],
  // 1 — Addition focus
  [
    DailySlot(DailyMode.match, 4),
    DailySlot(DailyMode.addition, 4),
    DailySlot(DailyMode.match, 5),
    DailySlot(DailyMode.addition, 5),
    DailySlot(DailyMode.reverse, 5),
    DailySlot(DailyMode.addition, 6),
    DailySlot(DailyMode.match, 6),
    DailySlot(DailyMode.reverse, 6),
    DailySlot(DailyMode.hexWord, 0),
    DailySlot(DailyMode.match, 7),
  ],
  // 2 — XOR focus
  [
    DailySlot(DailyMode.match, 4),
    DailySlot(DailyMode.xor, 4),
    DailySlot(DailyMode.reverse, 4),
    DailySlot(DailyMode.xor, 5),
    DailySlot(DailyMode.match, 5),
    DailySlot(DailyMode.xor, 6),
    DailySlot(DailyMode.match, 6),
    DailySlot(DailyMode.reverse, 6),
    DailySlot(DailyMode.xor, 7),
    DailySlot(DailyMode.match, 8),
  ],
  // 3 — Hex focus
  [
    DailySlot(DailyMode.match, 4),
    DailySlot(DailyMode.hexMatch, 4),
    DailySlot(DailyMode.match, 5),
    DailySlot(DailyMode.hexMatch, 4),
    DailySlot(DailyMode.reverse, 5),
    DailySlot(DailyMode.hexMatch, 8),
    DailySlot(DailyMode.match, 6),
    DailySlot(DailyMode.hexWord, 0),
    DailySlot(DailyMode.hexMatch, 8),
    DailySlot(DailyMode.match, 7),
  ],
  // 4 — Full mix
  [
    DailySlot(DailyMode.match, 4),
    DailySlot(DailyMode.addition, 4),
    DailySlot(DailyMode.xor, 4),
    DailySlot(DailyMode.reverse, 5),
    DailySlot(DailyMode.hexMatch, 4),
    DailySlot(DailyMode.match, 6),
    DailySlot(DailyMode.addition, 5),
    DailySlot(DailyMode.xor, 6),
    DailySlot(DailyMode.hexWord, 0),
    DailySlot(DailyMode.match, 8),
  ],
];

/// The `yyyyMMdd` key a day's progress is stored under. Persisted in
/// `daily_<key>_done` / `daily_<key>_best` and in `daily_last_date`, so the
/// format must not change.
String dailyDateKey(DateTime day) =>
    '${day.year}${day.month.toString().padLeft(2, '0')}'
    '${day.day.toString().padLeft(2, '0')}';

/// Which schedule variant a day uses. Derived from the elapsed duration since
/// the start of the year rather than a calendar day count, which is what the
/// shipped builds do — a day whose local midnight is shifted by DST can land
/// on the neighbouring variant, and changing that would reshuffle the rotation
/// for existing players.
int dailyScheduleIndex(DateTime day) {
  final dayOfYear = day.difference(DateTime(day.year, 1, 1)).inDays;
  return dayOfYear.abs() % kDailyScheduleVariants.length;
}

List<DailySlot> dailyScheduleFor(DateTime day) =>
    kDailyScheduleVariants[dailyScheduleIndex(day)];

/// Builds the day's ten questions. Deterministic: the same [day] always yields
/// the same questions on every device, which is what makes a daily shareable.
List<DailyQuestion> buildDailyQuestions(DateTime day) {
  final schedule = dailyScheduleFor(day);
  final seed = day.year * 10000 + day.month * 100 + day.day;
  final shortWords = kWordList.where((w) => w.length <= 6).toList();

  return [
    for (var i = 0; i < kDailyQuestionCount; i++)
      _buildQuestion(schedule[i], Random(seed + i * _seedStride), shortWords),
  ];
}

DailyQuestion _buildQuestion(
  DailySlot slot,
  Random rng,
  List<String> shortWords,
) {
  final bits = slot.bits;
  final maxVal = (1 << bits) - 1;

  switch (slot.mode) {
    case DailyMode.hexWord:
      return DailyQuestion(
        mode: slot.mode,
        bits: bits,
        target: 0,
        word: shortWords[rng.nextInt(shortWords.length)],
      );
    case DailyMode.addition:
      // Target high enough to require both rows; range 2..max-1.
      return DailyQuestion(
        mode: slot.mode,
        bits: bits,
        target: 2 + rng.nextInt(maxVal - 2),
      );
    case DailyMode.xor:
      // Order matters: the target draw must precede the operand draw.
      final target = 1 + rng.nextInt(maxVal);
      return DailyQuestion(
        mode: slot.mode,
        bits: bits,
        target: target,
        xorA: rng.nextInt(maxVal + 1),
      );
    case DailyMode.hexMatch:
      return DailyQuestion(
        mode: slot.mode,
        bits: bits,
        target: 1 + rng.nextInt(maxVal),
      );
    case DailyMode.match:
    case DailyMode.reverse:
      // Top bit always set, so the question actually uses its full width.
      final min = 1 << (bits - 1);
      return DailyQuestion(
        mode: slot.mode,
        bits: bits,
        target: min + rng.nextInt(maxVal - min + 1),
      );
  }
}

/// The daily streak after completing the challenge on [today].
///
/// [lastDate] is the `daily_last_date` key of the previous completion, empty on
/// a first ever run. Completing a day that was already counted leaves the
/// streak untouched, so replaying today cannot inflate it.
int nextDailyStreak({
  required int currentStreak,
  required String lastDate,
  required DateTime today,
}) {
  final yesterdayKey = dailyDateKey(today.subtract(const Duration(days: 1)));
  if (lastDate == yesterdayKey || lastDate.isEmpty) return currentStreak + 1;
  if (lastDate != dailyDateKey(today)) return 1;
  return currentStreak;
}
