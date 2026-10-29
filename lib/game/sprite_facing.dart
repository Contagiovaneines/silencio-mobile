import 'dart:math' as math;

/// Presentation mapping after inspecting the supplied PNGs; file labels are not camera angles.
class SpriteFacing {
  const SpriteFacing(this.source, this.mirror);
  final String source;
  final bool mirror;
  static const views = [
    SpriteFacing('NE', false),
    SpriteFacing('SW', true),
    SpriteFacing('S', false),
    SpriteFacing('SW', false),
    SpriteFacing('W', false),
    SpriteFacing('NW', true),
    SpriteFacing('N', false),
    SpriteFacing('NW', false),
  ];
  // Run artwork has a different labeling error from walk/poses.
  static const runViews = [
    SpriteFacing('W', true),
    SpriteFacing('SE', true),
    SpriteFacing('S', false),
    SpriteFacing('SE', false),
    SpriteFacing('W', false),
    SpriteFacing('NW', false),
    SpriteFacing('N', false),
    SpriteFacing('NE', false),
  ];
  factory SpriteFacing.fromWorld(double dx, double dy, {bool running = false}) {
    final angle = math.atan2((dx + dy) / 2, dx - dy);
    return (running ? runViews : views)[(angle / (math.pi / 4)).round() % 8];
  }
}
