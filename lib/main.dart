import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/game_session.dart';
import 'services/save_repository.dart';
import 'ui/game_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final preferences = await SharedPreferences.getInstance();
  final session = await GameSession.load(SaveRepository(preferences));
  runApp(SilencioApp(session: session));
}

class SilencioApp extends StatelessWidget {
  const SilencioApp({super.key, required this.session});
  final GameSession session;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Silêncio',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xff102029),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xffa2cbb8),
        secondary: Color(0xffdfb477),
        surface: Color(0xff172a32),
        onSurface: Color(0xffe6e8da),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    home: GameShell(session: session, enableAudio: true),
  );
}
