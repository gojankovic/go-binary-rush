import 'dart:math';

import 'binary.dart';

class BitFlipQuestion {
  final int bits;
  final int start;
  final int target;

  const BitFlipQuestion({
    required this.bits,
    required this.start,
    required this.target,
  });

  List<int> get startBits => intToBits(start, bits);
  List<int> get targetBits => intToBits(target, bits);
  int get optimalMoves => hammingDistance(start, target);

  bool isSolved(List<int> currentBits) => bitsToInt(currentBits) == target;
}

BitFlipQuestion generateBitFlipQuestion({
  required int bits,
  required int target,
  Random? random,
}) {
  final rng = random ?? Random();
  final maxExclusive = 1 << bits;
  var start = rng.nextInt(maxExclusive);
  if (start == target) {
    start ^= 1 << rng.nextInt(bits);
  }
  return BitFlipQuestion(bits: bits, start: start, target: target);
}

int hammingDistance(int a, int b) {
  var difference = a ^ b;
  var count = 0;
  while (difference != 0) {
    count += difference & 1;
    difference >>= 1;
  }
  return count;
}

const int kBitFlipPerfectBonus = 5;

int bitFlipBonus({required int moves, required int optimalMoves}) =>
    moves == optimalMoves ? kBitFlipPerfectBonus : 0;
