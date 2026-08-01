import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_shell.dart';
import 'screens/name_entry_screen.dart';
import 'services/crt_settings.dart';
import 'services/haptics.dart';
import 'services/notifications.dart';
import 'services/palette_settings.dart';
import 'theme.dart';
import 'widgets/crt_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await bootstrap();
  runApp(const BinaryRushApp());
}

/// Loads the preference-backed visual/haptic settings that must be in effect
/// before the first frame is rendered. Notification setup is intentionally not
/// awaited so it never delays first paint.
Future<void> bootstrap() async {
  await Future.wait([
    Haptics.init(),
    CrtSettings.init(),
    PaletteSettings.init(),
  ]);
  if (!kIsWeb) {
    unawaited(Notifications.init().catchError((_) {}));
  }
}

class BinaryRushApp extends StatelessWidget {
  const BinaryRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PaletteSettings.index,
      builder: (context, _, child) {
        return MaterialApp(
          title: 'Go Binary Rush',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          builder: (context, child) => CrtOverlay(child: child!),
          home: const _AppRouter(),
        );
      },
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  bool _checked = false;
  bool _needsName = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('player_name');
    if (!mounted) return;
    setState(() {
      _needsName = name == null;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
          backgroundColor: Colors.black, body: SizedBox.shrink());
    }
    return _needsName ? const NameEntryScreen() : const MainShell();
  }
}
