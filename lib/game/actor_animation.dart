import 'dart:math' as math;

/// Small runtime rig, driven by travelled ground distance instead of frame time.
/// The original sprite remains the skin; this does not invent new sprite files.
class ActorAnimation {
  const ActorAnimation({
    required this.phase,
    required this.leftAngle,
    required this.rightAngle,
    required this.leftStride,
    required this.rightStride,
    required this.leftLift,
    required this.rightLift,
    required this.torsoBob,
    required this.torsoLean,
    required this.chestScale,
  });

  final double phase, leftAngle, rightAngle, leftStride, rightStride;
  final double leftLift, rightLift, torsoBob, torsoLean, chestScale;

  static int frame(double travelled, {bool running = false}) =>
      ((travelled / (running ? 1.8 : 1.5)) * 6).floor() % 6;

  factory ActorAnimation.sample({
    required double travelled,
    required double time,
    required bool moving,
    bool running = false,
    bool injured = false,
    bool recoveringBreath = false,
  }) {
    final cycle = travelled / (running ? 1.8 : 1.5) * math.pi * 2;
    final step = moving ? math.sin(cycle) : 0.0;
    final stride = running ? 3.4 : 2.5;
    final swing = running ? .27 : .19;
    final weakSide = injured ? .42 : 1.0;
    final breath = (math.sin(time * (recoveringBreath ? 5.2 : 2.2)) + 1) / 2;
    return ActorAnimation(
      phase: cycle,
      leftAngle: step * swing,
      rightAngle: -step * swing * weakSide,
      leftStride: step * stride,
      rightStride: -step * stride * weakSide,
      leftLift: moving ? math.max(0, step) * (running ? 2.5 : 1.4) : 0,
      rightLift: moving
          ? math.max(0, -step) * (running ? 2.5 : 1.4) * weakSide
          : 0,
      torsoBob: moving ? -step.abs() * (running ? 1.5 : .65) : 0,
      torsoLean: injured
          ? .10
          : recoveringBreath
          ? .08
          : moving && running
          ? .035
          : 0,
      chestScale:
          1 +
          breath *
              (recoveringBreath
                  ? .055
                  : injured
                  ? .018
                  : .009),
    );
  }
}
