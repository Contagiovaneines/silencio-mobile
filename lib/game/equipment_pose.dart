import 'dart:math' as math;
import 'dart:ui';

/// Hand sockets use renderer pixels relative to the sole, independently of gear.
class EquipmentPose {
  const EquipmentPose(this.hand, this.angle, this.behindBody);
  final Offset hand;
  final double angle;
  final bool behindBody;

  static EquipmentPose sample({
    required int direction,
    required String state,
    double progress = 0,
  }) {
    final a = (direction % 8) * math.pi / 4;
    final axis = Offset(math.cos(a), math.sin(a));
    final active =
        state == 'attack' || state == 'guard' || state == 'guard_walk';
    final reach = active ? 17.0 : 9.0;
    var hand = Offset(axis.dx * reach, -(active ? 34.0 : 24.0) + axis.dy * 5);
    var angle = active ? a : a + math.pi / 2;
    if (state == 'hurt') {
      hand = Offset(axis.dx * 5, -30 + axis.dy * 3);
      angle = a + .65;
    }
    if (state == 'attack') {
      final t = progress.clamp(0.0, 1.0);
      final sweep = t < .25
          ? -.9 * t / .25
          : t < .55
          ? -.9 + 1.7 * (t - .25) / .3
          : .8 * (1 - t) / .45;
      angle += sweep;
      hand += axis * (math.sin(t * math.pi) * 3);
    }
    return EquipmentPose(hand, angle, direction % 8 >= 5);
  }
}
