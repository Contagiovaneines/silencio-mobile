import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/services/game_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'device preferences preserve legacy audio and survive reconstruction',
    () async {
      SharedPreferences.setMockInitialValues({
        'silencio.sound': false,
        'silencio.save': 'untouched',
      });
      final store = await SharedPreferences.getInstance();
      final prefs = GamePreferences(store);
      expect(prefs.musicEnabled, isFalse);
      expect(prefs.effectsEnabled, isFalse);
      expect(prefs.language, 'pt-BR');
      await prefs.setFlag('music', true);
      await prefs.setFlag('highContrast', true);
      await prefs.setFlag('rightStick', true);
      await prefs.setFlag('largeStick', true);
      await prefs.setFlag('lowQuality', true);
      await prefs.setLanguage('en');
      final reloaded = GamePreferences(store);
      expect(reloaded.musicEnabled, isTrue);
      expect(reloaded.effectsEnabled, isFalse);
      expect(reloaded.highContrast, isTrue);
      expect(reloaded.rightStick, isTrue);
      expect(reloaded.largeStick, isTrue);
      expect(reloaded.lowQuality, isTrue);
      expect(reloaded.language, 'en');
      expect(store.getString('silencio.save'), 'untouched');
    },
  );

  test('unsupported locale falls back to Portuguese', () async {
    SharedPreferences.setMockInitialValues({'silencio.language': 'fr'});
    expect(
      GamePreferences(await SharedPreferences.getInstance()).language,
      'pt-BR',
    );
  });

  test(
    'control layout is stored separately and bounded to the screen',
    () async {
      SharedPreferences.setMockInitialValues({'silencio.save': 'untouched'});
      final store = await SharedPreferences.getInstance();
      final prefs = GamePreferences(store);
      await prefs.setControlPosition('movement', const Offset(1.4, -.2));
      expect(prefs.controlPosition('movement'), const Offset(1, 0));
      expect(prefs.controlPosition('unknown'), isNull);
      await prefs.resetControlPositions();
      expect(prefs.controlPosition('movement'), isNull);
      expect(store.getString('silencio.save'), 'untouched');
    },
  );
}
