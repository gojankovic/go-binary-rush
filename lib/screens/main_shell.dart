import 'package:flutter/material.dart';
import '../services/palette_settings.dart';
import '../theme.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';
import 'achievements_screen.dart';
import 'reference_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  int _profileRefresh = 0;
  int _achvRefresh = 0;
  int _settingsRefresh = 0;

  void _onTap(int i) {
    if (i == 1) _profileRefresh++;
    if (i == 2) _achvRefresh++;
    if (i == 4) _settingsRefresh++;
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PaletteSettings.index,
      builder: (context, palette, _) {
        final screens = [
          MenuScreen(key: ValueKey('menu$palette')),
          ProfileScreen(key: ValueKey(_profileRefresh)),
          AchievementsScreen(key: ValueKey(_achvRefresh)),
          ReferenceScreen(key: ValueKey('ref$palette')),
          SettingsScreen(key: ValueKey(_settingsRefresh)),
        ];
        return Scaffold(
          backgroundColor: Colors.black,
          body: IndexedStack(index: _tab, children: screens),
          bottomNavigationBar: _TerminalDock(active: _tab, onTap: _onTap),
        );
      },
    );
  }
}

class _TerminalDock extends StatelessWidget {
  final int active;
  final void Function(int) onTap;

  const _TerminalDock({required this.active, required this.onTap});

  static const _tabs = [
    ('▶', 'PLAY'),
    ('▤', 'STATS'),
    ('★', 'ACHV'),
    ('?', 'REF'),
    ('⚙', 'SET'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: AppColors.g1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              for (int i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _DockTab(
                    ico: _tabs[i].$1,
                    label: _tabs[i].$2,
                    active: active == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockTab extends StatelessWidget {
  final String ico;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DockTab({
    required this.ico,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.g4 : AppColors.g2;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ico,
              style: TextStyle(
                fontSize: 16,
                color: color,
                shadows: active
                    ? AppGlow.sm
                          .map(
                            (s) => Shadow(
                              color: s.color,
                              blurRadius: s.blurRadius,
                            ),
                          )
                          .toList()
                    : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: AppText.kicker(color: color)),
          ],
        ),
      ),
    );
  }
}
