import 'dart:math' as math;

/// Presentation only: spatial hysteresis avoids flipping near a wall plane.
/// Collision, room ownership and saved positions are never changed here.
class WallCutaway {
  bool _cut = false;
  double fraction = 0;

  void update({
    required double signedDistance,
    required bool indoors,
    required double dt,
    bool snap = false,
  }) {
    if (!indoors || signedDistance > .18) {
      _cut = false;
    } else if (signedDistance < -.18) {
      _cut = true;
    }
    final target = _cut ? 1.0 : 0.0;
    fraction = snap
        ? target
        : fraction +
              (target - fraction) * (1 - math.exp(-math.max(0, dt) * 12));
  }
}
