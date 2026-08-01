import 'package:binary_game/game/binary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bitsToInt reads bits most-significant first', () {
    expect(bitsToInt([1, 0, 1, 1]), 11);
    expect(bitsToInt([0, 0, 0, 0]), 0);
  });

  test('intToBits preserves the requested width and leading zeroes', () {
    expect(intToBits(3, 4), [0, 0, 1, 1]);
    expect(intToBits(255, 8), List.filled(8, 1));
  });

  test('conversion round-trips across every supported width', () {
    for (var bitCount = 1; bitCount <= 8; bitCount++) {
      for (var value = 0; value < (1 << bitCount); value++) {
        expect(bitsToInt(intToBits(value, bitCount)), value);
      }
    }
  });
}
