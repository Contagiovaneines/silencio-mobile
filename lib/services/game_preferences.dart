import 'package:shared_preferences/shared_preferences.dart';

/// Device preferences are independent of campaign save data.
class GamePreferences {
  GamePreferences(this.store);
  final SharedPreferences store;
  bool get musicEnabled =>
      store.getBool('silencio.music') ??
      store.getBool('silencio.sound') ??
      true;
  bool get effectsEnabled =>
      store.getBool('silencio.audioEffects') ??
      store.getBool('silencio.sound') ??
      true;
  bool get lowQuality => store.getBool('silencio.lowQuality') ?? false;
  bool get highContrast => store.getBool('silencio.highContrast') ?? false;
  bool get rightStick => store.getBool('silencio.rightStick') ?? false;
  bool get largeStick => store.getBool('silencio.largeStick') ?? false;
  String get language =>
      store.getString('silencio.language') == 'en' ? 'en' : 'pt-BR';
  Future<bool> setFlag(String key, bool value) =>
      store.setBool('silencio.$key', value);
  Future<bool> setLanguage(String value) =>
      store.setString('silencio.language', value == 'en' ? 'en' : 'pt-BR');
}
