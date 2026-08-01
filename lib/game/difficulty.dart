class Tier {
  final int bits;
  final List<int> targets;
  final int cap;
  const Tier({required this.bits, required this.targets, required this.cap});
}

final List<Tier> kHexTiers = () {
  final t2 = {for (int i = 1; i <= 15; i++) i * 16};
  final t3 = {for (int i = 1; i <= 15; i++) i * 17};
  final t4 = [
    for (int i = 16; i <= 255; i++)
      if (!t2.contains(i) && !t3.contains(i)) i,
  ];
  return [
    Tier(bits: 4, targets: List.generate(15, (i) => i + 1), cap: 10),
    Tier(bits: 8, targets: (t2.toList()..sort()), cap: 8),
    Tier(bits: 8, targets: (t3.toList()..sort()), cap: 8),
    Tier(bits: 8, targets: t4, cap: 20),
  ];
}();

final List<Tier> kTiers = [
  Tier(bits: 4, targets: [1, 2, 4, 8, 15], cap: 3),
  Tier(bits: 4, targets: [3, 5, 6, 7, 9, 10, 11, 12, 13, 14], cap: 5),
  Tier(bits: 5, targets: List.generate(16, (i) => i + 16), cap: 7),
  Tier(bits: 6, targets: List.generate(32, (i) => i + 32), cap: 8),
  Tier(bits: 7, targets: List.generate(64, (i) => i + 64), cap: 10),
  Tier(bits: 8, targets: List.generate(128, (i) => i + 128), cap: 20),
];
