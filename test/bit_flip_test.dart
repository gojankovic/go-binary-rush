import 'dart:math';

import 'package:binary_game/game/bit_flip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hamming distance is the minimum number of bit flips', () {
    expect(hammingDistance(0, 15), 4);
    expect(hammingDistance(10, 3), 2);
    expect(hammingDistance(213, 213), 0);
  });

  test('generated question never starts solved and stays within its width', () {
    for (var seed = 0; seed < 50; seed++) {
      final question = generateBitFlipQuestion(
        bits: 4,
        target: 7,
        random: Random(seed),
      );
      expect(question.start, inInclusiveRange(0, 15));
      expect(question.start, isNot(question.target));
      expect(question.startBits, hasLength(4));
      expect(question.optimalMoves, inInclusiveRange(1, 4));
    }
  });

  test('question detects the target bit pattern', () {
    const question = BitFlipQuestion(bits: 4, start: 3, target: 10);
    expect(question.isSolved(const [1, 0, 1, 0]), isTrue);
    expect(question.isSolved(const [0, 0, 1, 1]), isFalse);
  });

  test('only an optimal solution earns the perfect bonus', () {
    expect(bitFlipBonus(moves: 3, optimalMoves: 3), 5);
    expect(bitFlipBonus(moves: 5, optimalMoves: 3), 0);
  });
}
