import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'difficulty.dart';

class QuestionGenerator {
  final SharedPreferences _prefs;
  final Random _random = Random();
  final String _tierKey;
  final String _seenPrefix;
  final List<Tier> _tiers;
  final int _minTarget;
  final Set<int> _sessionSeen = {};
  int _tierIndex;
  int? _currentTarget;

  QuestionGenerator._(SharedPreferences prefs, int tier, String mode,
      List<Tier> tiers, int minTarget)
      : _prefs = prefs,
        _tiers = tiers,
        _minTarget = minTarget,
        _tierIndex = tier.clamp(0, tiers.length - 1),
        _tierKey = '${mode}_current_tier',
        _seenPrefix = '${mode}_seen_tier_';

  static Future<QuestionGenerator> create({
    String mode = 'match',
    List<Tier>? tiers,
    int minTarget = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final effectiveTiers = tiers ?? kTiers;
    return QuestionGenerator._(
        prefs,
        prefs.getInt('${mode}_current_tier') ?? 0,
        mode,
        effectiveTiers,
        minTarget);
  }

  int get currentBits => _tiers[_tierIndex].bits;
  int get currentTier => _tierIndex + 1;
  int get tierSolvedCount => _getSeen().length;
  int get tierCap => _tiers[_tierIndex].cap;

  /// Produces a target for the current tier. Generating a question never
  /// records progress: the tier and bit width stay stable for the lifetime
  /// of the returned question. Call [recordSolved] when the player solves it.
  int next() {
    // A previous solve that filled the tier's cap advances here — not inside
    // recordSolved() — so the just-solved question keeps its own tier and bit
    // width while its success state is still on screen. This is solve-driven:
    // the seen-set only grows on a solve, never on generation.
    if (_getSeen().length >= _tiers[_tierIndex].cap) {
      _advanceTier();
    }
    var available = _available();
    if (available.isEmpty) {
      // Every target has been shown this session but not enough have been
      // solved to advance; allow repeats rather than forcing progress.
      _sessionSeen.clear();
      available = _available();
    }
    // Safety net: the persisted solved-set fills the whole tier (e.g. legacy
    // data). Keep advancing until a tier has room. This terminates because
    // _advanceTier() clears the solved-set once at the last tier.
    for (var i = 0; available.isEmpty && i < _tiers.length; i++) {
      _advanceTier();
      _sessionSeen.clear();
      available = _available();
    }
    if (available.isEmpty) {
      throw StateError(
          'No target available in tier ${_tierIndex + 1}: every target is '
          'below minTarget $_minTarget.');
    }
    final target = available[_random.nextInt(available.length)];
    _sessionSeen.add(target);
    _currentTarget = target;
    return target;
  }

  /// Records the current question as solved. Only a solve counts toward tier
  /// progress. The tier advance itself is deferred to the next [next] call so
  /// the solved question keeps its tier/bit width. Safe to call at most once
  /// per generated question.
  void recordSolved() {
    final target = _currentTarget;
    if (target == null) return;
    _currentTarget = null;
    _markSeen(target);
  }

  List<int> _available() {
    final seen = _getSeen();
    return _tiers[_tierIndex]
        .targets
        .where((t) =>
            !seen.contains(t) && !_sessionSeen.contains(t) && t >= _minTarget)
        .toList();
  }

  Set<int> _getSeen() {
    return (_prefs.getStringList('$_seenPrefix$_tierIndex') ?? [])
        .map(int.parse)
        .toSet();
  }

  void _markSeen(int target) {
    final seen = _getSeen()..add(target);
    _prefs.setStringList(
        '$_seenPrefix$_tierIndex', seen.map((e) => '$e').toList());
  }

  void _advanceTier() {
    if (_tierIndex < _tiers.length - 1) {
      _tierIndex++;
      _prefs.setInt(_tierKey, _tierIndex);
    } else {
      _prefs.remove('$_seenPrefix$_tierIndex');
    }
  }
}
