import 'dart:math' as math;
import 'dart:ui';

/// Offline atlas cells retain the original 128px skin and sole at y=119.
/// Extra lower padding permits a projected stride without clipping shoes.
class ActorFrames {
  static int direction(double dx, double dy) =>
      (math.atan2((dx + dy) * .5, dx - dy) / (math.pi / 4)).round() % 8;

  static int count(String state, {String actor = ''}) =>
      actor.startsWith('caio') && (state == 'walk' || state == 'run')
      ? 6
      : switch (state) {
          'idle' || 'guard' => 4,
          'hurt' => 6,
          _ => 8,
        };

  static int frame(
    String state, {
    double travelled = 0,
    double time = 0,
    double progress = 0,
    String actor = '',
  }) {
    final n = count(state, actor: actor);
    if (state == 'walk' || state == 'run' || state == 'guard_walk') {
      final cycle = state == 'guard_walk'
          ? .9
          : actor.startsWith('caio')
          ? (state == 'run' ? 1.8 : 1.5)
          : (state == 'run' ? 1.4 : .9);
      return (travelled / cycle * n).floor() % n;
    }
    if (state == 'attack' || state == 'hurt') {
      return (progress.clamp(0.0, 1.0) * (n - 1)).floor();
    }
    return (time * (state == 'guard' ? 5 : 3)).floor() % n;
  }

  static Rect source(int frame, int direction) =>
      Rect.fromLTWH(frame * 128.0, direction * 144.0, 128, 144);
}
