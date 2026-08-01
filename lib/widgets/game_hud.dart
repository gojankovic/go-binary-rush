import 'package:flutter/material.dart';
import '../game/question_generator.dart';
import '../game/score_engine.dart';
import '../theme.dart';

class GameHud extends StatelessWidget {
  final QuestionGenerator gen;
  final ScoreEngine score;

  const GameHud({super.key, required this.gen, required this.score});

  @override
  Widget build(BuildContext context) {
    final streakWarn = score.wrongsInRow >= 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _tierCell(),
        _cell('SCORE', '${score.score}'),
        _cell(
          'STREAK',
          '×${score.streak}',
          valueColor: streakWarn ? AppColors.amber : null,
        ),
        _cell('BEST', '${score.highScore}'),
      ],
    );
  }

  Widget _tierCell() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('TIER', style: AppText.kicker()),
        const SizedBox(height: 2),
        Text('T${gen.currentTier}', style: AppText.hudValue()),
        Text(
          '${gen.tierSolvedCount}/${gen.tierCap}',
          style: AppText.mono(size: 9, color: AppColors.g2),
        ),
      ],
    );
  }

  Widget _cell(String label, String value, {Color? valueColor}) {
    final baseStyle = AppText.hudValue();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppText.kicker()),
        const SizedBox(height: 2),
        Text(
          value,
          style: valueColor != null
              ? baseStyle.copyWith(color: valueColor)
              : baseStyle,
        ),
      ],
    );
  }
}
