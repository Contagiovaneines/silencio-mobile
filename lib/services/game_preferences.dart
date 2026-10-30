import 'dart:ui' show Offset;

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
  Offset? controlPosition(String control) {
    if (!const {'movement', 'actions', 'sprint'}.contains(control)) return null;
    final x = store.getDouble('silencio.control.$control.x');
    final y = store.getDouble('silencio.control.$control.y');
    return x == null || y == null ? null : Offset(x, y);
  }

  Future<void> setControlPosition(String control, Offset position) async {
    if (!const {'movement', 'actions', 'sprint'}.contains(control)) return;
    await Future.wait([
      store.setDouble('silencio.control.$control.x', position.dx.clamp(0, 1)),
      store.setDouble('silencio.control.$control.y', position.dy.clamp(0, 1)),
    ]);
  }

  Future<void> resetControlPositions() async {
    for (final control in ['movement', 'actions', 'sprint']) {
      await store.remove('silencio.control.$control.x');
      await store.remove('silencio.control.$control.y');
    }
  }

  String get language =>
      store.getString('silencio.language') == 'en' ? 'en' : 'pt-BR';
  Future<bool> setFlag(String key, bool value) =>
      store.setBool('silencio.$key', value);
  Future<bool> setLanguage(String value) =>
      store.setString('silencio.language', value == 'en' ? 'en' : 'pt-BR');
}
