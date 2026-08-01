import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/prefs_keys.dart';
import 'learn_screen.dart';

class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final _ctrl = TextEditingController();
  bool _hasInput = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final raw = _ctrl.text.trim();
    final name = raw.isEmpty ? 'PLAYER' : raw.toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.playerName, name);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => const LearnScreen(isFirstLaunch: true),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, a2, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(
                'GO BINARY RUSH',
                style: AppText.kicker(
                  color: AppColors.g2,
                ).copyWith(letterSpacing: 5),
              ),
              const SizedBox(height: 28),
              Text(
                'IDENTIFY AGENT',
                style: AppText.mono(
                  size: 26,
                  color: AppColors.g4,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: AppColors.g2),
              const SizedBox(height: 36),
              TextField(
                controller: _ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 12,
                style: AppText.mono(
                  size: 30,
                  color: AppColors.g4,
                  weight: FontWeight.w700,
                ),
                cursorColor: AppColors.g4,
                cursorWidth: 3,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'CALLSIGN',
                  hintStyle: AppText.mono(size: 30, color: AppColors.g1),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.g2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.g4, width: 2),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                ],
                onChanged: (v) =>
                    setState(() => _hasInput = v.trim().isNotEmpty),
                onSubmitted: (_) => _confirm(),
              ),
              const SizedBox(height: 8),
              Text(
                'max 12 chars  ·  letters, digits, _ -',
                style: AppText.kicker(color: AppColors.g1),
              ),
              const Spacer(flex: 3),
              GestureDetector(
                onTap: _confirm,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _hasInput ? AppColors.g4 : AppColors.g2,
                      width: 1.5,
                    ),
                    boxShadow: _hasInput ? AppGlow.sm : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'CONFIRM  →',
                    style: AppText.mono(
                      size: 14,
                      color: _hasInput ? AppColors.g4 : AppColors.g2,
                      weight: FontWeight.w600,
                    ).copyWith(letterSpacing: 4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: _confirm,
                  child: Text(
                    'skip  →  play as PLAYER',
                    style: AppText.kicker(color: AppColors.g1),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
