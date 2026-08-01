import 'package:flutter/material.dart';
import '../theme.dart';
import 'learn_screen.dart';
import 'main_shell.dart';

class HowToPlayScreen extends StatelessWidget {
  final bool isFirstLaunch;

  const HowToPlayScreen({super.key, this.isFirstLaunch = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: !isFirstLaunch,
        iconTheme: IconThemeData(color: AppColors.g2),
        title: Text('HOW TO PLAY', style: AppText.label()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.g1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('SCORING'),
                  const SizedBox(height: 12),
                  _line('base     10 pts per correct answer'),
                  _line('streak   +5 pts each consecutive answer'),
                  _line('         streak ×3 → 10 · 15 · 20 pts'),
                  const SizedBox(height: 28),
                  _section('MODES'),
                  const SizedBox(height: 16),
                  _mode(
                    '[1]',
                    'MATCH',
                    'decimal  →  binary',
                    'A number is shown. Toggle the bits to build\n'
                        'its binary representation.',
                  ),
                  _mode(
                    '[2]',
                    'REVERSE',
                    'binary  →  decimal',
                    'Bits are pre-lit. Type the decimal value\n'
                        'they represent using the numpad.',
                  ),
                  _mode(
                    '[3]',
                    'ADDITION',
                    'A + B  =  target',
                    'Fill two binary rows so their sum equals\n'
                        'the target. Multiple solutions are valid.',
                  ),
                  _mode(
                    '[4]',
                    'XOR',
                    'A  ⊕  B  =  C',
                    'Rows A and B are fixed. Fill row C so that\n'
                        'A XOR B = C.\n'
                        'XOR = 1 when bits differ,  0 when equal.',
                  ),
                  _mode(
                    '[5]',
                    'SPEED BURST',
                    '60 second blitz',
                    'Any mode. Solve as many questions as possible\n'
                        'before time runs out. Separate best per mode.',
                  ),
                  _mode(
                    '[6]',
                    'HEX MATCH',
                    'binary  →  hex',
                    'Bits are shown. Enter the hexadecimal value\n'
                        '(0 – F) using the hex keyboard.',
                  ),
                  _mode(
                    '[7]',
                    'HEX WORD',
                    'ascii hex  →  word',
                    'Each hex pair is the ASCII code of a letter.\n'
                        'Tap the correct letters to decode the word.\n'
                        'Wrong letters cost 1 pt.',
                  ),
                  _mode(
                    '[8]',
                    'DAILY',
                    'one challenge per day',
                    '10 mixed questions — MATCH, REVERSE, HEX WORD.\n'
                        'One attempt per day. Score: S / A / B / C / D.\n'
                        'Complete daily to build your streak.',
                  ),
                  const SizedBox(height: 28),
                  _section('DIFFICULTY'),
                  const SizedBox(height: 12),
                  _line('MATCH uses a tier system  T1 – T6.'),
                  _line('Complete questions to unlock wider bit widths:'),
                  _line('  T1 – T2  →  4-bit   (0 – 15)'),
                  _line('  T3       →  5-bit   (16 – 31)'),
                  _line('  T4       →  6-bit   (32 – 63)'),
                  _line('  T5       →  7-bit   (64 – 127)'),
                  _line('  T6       →  8-bit   (128 – 255)'),
                  const SizedBox(height: 28),
                  Container(height: 1, color: AppColors.g1),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, a1, a2) => const LearnScreen(),
                        transitionDuration: const Duration(milliseconds: 300),
                        transitionsBuilder: (_, anim, a2, child) =>
                            FadeTransition(opacity: anim, child: child),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'BINARY INTRODUCTION  →',
                          style: AppText.kicker(color: AppColors.g2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (isFirstLaunch) ...[
            Container(height: 1, color: AppColors.g1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (_, a1, a2) => const MainShell(),
                    transitionDuration: const Duration(milliseconds: 400),
                    transitionsBuilder: (_, anim, a2, child) =>
                        FadeTransition(opacity: anim, child: child),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.g4, width: 1.5),
                    boxShadow: AppGlow.sm,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'BEGIN  →',
                    style: AppText.mono(
                      size: 14,
                      color: AppColors.g4,
                      weight: FontWeight.w600,
                    ).copyWith(letterSpacing: 4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.kicker(color: AppColors.g2).copyWith(letterSpacing: 4),
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: AppColors.g1),
      ],
    );
  }

  Widget _line(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: AppText.mono(size: 11, color: AppColors.g2)),
    );
  }

  Widget _mode(String idx, String name, String sub, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(idx, style: AppText.mono(size: 12, color: AppColors.g3)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppText.mono(
                    size: 13,
                    color: AppColors.g4,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppText.mono(size: 10, color: AppColors.amber),
                ),
                const SizedBox(height: 6),
                Text(desc, style: AppText.mono(size: 11, color: AppColors.g2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
