int bitsToInt(List<int> bits) {
  var value = 0;
  for (final bit in bits) {
    value = (value << 1) | bit;
  }
  return value;
}

List<int> intToBits(int value, int bitCount) =>
    List.generate(bitCount, (i) => (value >> (bitCount - 1 - i)) & 1);
