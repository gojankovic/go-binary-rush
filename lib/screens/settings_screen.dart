import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/crt_settings.dart';
import '../services/haptics.dart';
import '../services/notifications.dart';
import '../services/palette_settings.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _playerName = 'PLAYER';
  bool _loaded = false;
  bool _reminderEnabled = false;
  bool _reminderBusy = false;
  int _reminderHour = Notifications.defaultHour;
  bool _hapticsEnabled = true;
  int _crtLevel = CrtSettings.levelFull;
  int _paletteIndex = PaletteSettings.indexGreen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _playerName = (prefs.getString('player_name') ?? 'PLAYER').toUpperCase();
      _reminderEnabled = prefs.getBool(Notifications.prefsEnabled) ?? false;
      _reminderHour =
          prefs.getInt(Notifications.prefsHour) ?? Notifications.defaultHour;
      _hapticsEnabled = prefs.getBool(Haptics.prefsEnabled) ?? true;
      _crtLevel =
          prefs.getInt(CrtSettings.prefsLevel) ?? CrtSettings.levelFull;
      _paletteIndex = prefs.getInt(PaletteSettings.prefsIndex) ??
          PaletteSettings.indexGreen;
      _loaded = true;
    });
  }

  Future<void> _pickHour() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.g2),
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('REMINDER HOUR', style: AppText.label()),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(24, (h) {
                  final sel = h == _reminderHour;
                  return GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(h),
                    child: Container(
                      width: 48,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: sel ? AppColors.g4 : AppColors.g1,
                        ),
                        color: sel ? AppColors.g1 : Colors.transparent,
                      ),
                      child: Text(
                        '${h.toString().padLeft(2, '0')}:00',
                        style: AppText.mono(
                          size: 11,
                          color: sel ? AppColors.g5 : AppColors.g3,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == _reminderHour) return;
    if (!mounted) return;
    setState(() => _reminderHour = picked);
    await Notifications.setHour(picked, _playerName);
  }

  Future<void> _toggleReminder(bool value) async {
    if (_reminderBusy) return;
    setState(() => _reminderBusy = true);
    if (value) {
      final granted = await Notifications.enable(_playerName);
      if (mounted) {
        setState(() {
          _reminderEnabled = granted;
          _reminderBusy = false;
        });
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.bg,
            content: Text(
              'NOTIFICATION PERMISSION DENIED',
              style: AppText.mono(size: 12, color: AppColors.amber),
            ),
          ));
        }
      }
    } else {
      await Notifications.disable();
      if (mounted) {
        setState(() {
          _reminderEnabled = false;
          _reminderBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('SETTINGS', style: AppText.label()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.g1),
        ),
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _divider('FEEDBACK'),
                const SizedBox(height: 14),
                _toggleRow(
                  'HAPTICS',
                  _hapticsEnabled,
                  (v) async {
                    setState(() => _hapticsEnabled = v);
                    await Haptics.setEnabled(v);
                  },
                ),
                const SizedBox(height: 28),
                _divider('DISPLAY'),
                const SizedBox(height: 14),
                _crtRow(),
                _paletteRow(),
                if (!kIsWeb) ...[
                  const SizedBox(height: 28),
                  _divider('NOTIFICATIONS'),
                  const SizedBox(height: 14),
                  _toggleRow(
                    'DAILY REMINDER',
                    _reminderEnabled,
                    _toggleReminder,
                  ),
                  if (_reminderEnabled) _hourRow(),
                ],
              ],
            ),
    );
  }

  Widget _paletteRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PALETTE',
              style: AppText.mono(size: 12, color: AppColors.g2)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(PaletteSettings.labels.length, (i) {
              final sel = i == _paletteIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    setState(() => _paletteIndex = i);
                    await PaletteSettings.setIndex(i);
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                        right:
                            i == PaletteSettings.labels.length - 1 ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: sel ? AppColors.g4 : AppColors.g1),
                      color: sel ? AppColors.g1 : Colors.transparent,
                    ),
                    child: Text(
                      PaletteSettings.labels[i],
                      style: AppText.mono(
                        size: 11,
                        color: sel ? AppColors.g5 : AppColors.g3,
                        weight: sel ? FontWeight.w700 : FontWeight.normal,
                      ).copyWith(letterSpacing: 2),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _crtRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CRT INTENSITY',
              style: AppText.mono(size: 12, color: AppColors.g2)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(CrtSettings.labels.length, (i) {
              final sel = i == _crtLevel;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    setState(() => _crtLevel = i);
                    await CrtSettings.setLevel(i);
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                        right: i == CrtSettings.labels.length - 1 ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: sel ? AppColors.g4 : AppColors.g1),
                      color: sel ? AppColors.g1 : Colors.transparent,
                    ),
                    child: Text(
                      CrtSettings.labels[i],
                      style: AppText.mono(
                        size: 11,
                        color: sel ? AppColors.g5 : AppColors.g3,
                        weight: sel ? FontWeight.w700 : FontWeight.normal,
                      ).copyWith(letterSpacing: 2),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _hourRow() {
    final hh = '${_reminderHour.toString().padLeft(2, '0')}:00';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('REMINDER TIME',
              style: AppText.mono(size: 12, color: AppColors.g2)),
          GestureDetector(
            onTap: _pickHour,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: AppColors.g2)),
              child: Text(hh,
                  style: AppText.mono(
                      size: 13,
                      color: AppColors.g4,
                      weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.mono(size: 12, color: AppColors.g2)),
          Switch(
            value: value,
            onChanged: _reminderBusy ? null : onChanged,
            activeThumbColor: AppColors.g4,
            activeTrackColor: AppColors.g1,
            inactiveThumbColor: AppColors.g1,
            inactiveTrackColor: AppColors.bg,
          ),
        ],
      ),
    );
  }

  Widget _divider(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.kicker()),
        const SizedBox(height: 6),
        Container(height: 1, color: AppColors.g1),
      ],
    );
  }
}
