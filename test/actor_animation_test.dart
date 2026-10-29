import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/game/actor_animation.dart';

void main() {
  test('opposite support feet swap after half a travelled gait cycle', () {
    final a = ActorAnimation.sample(travelled: .375, time: 0, moving: true);
    final b = ActorAnimation.sample(travelled: 1.125, time: 0, moving: true);
    expect(a.leftAngle, greaterThan(0));
    expect(a.rightAngle, lessThan(0));
    expect(b.leftAngle, lessThan(0));
    expect(b.rightAngle, greaterThan(0));
    expect(a.leftLift, greaterThan(0));
    expect(b.rightLift, greaterThan(0));
  });

  test('blocked and idle actors do not keep stepping with elapsed time', () {
    final a = ActorAnimation.sample(travelled: .375, time: 0, moving: false);
    final b = ActorAnimation.sample(travelled: .375, time: 10, moving: false);
    expect(a.leftStride, 0);
    expect(b.leftStride, 0);
    expect(a.rightLift, 0);
    expect(b.rightLift, 0);
  });

  test(
    'exhaustion expands the chest while injury creates an asymmetric gait',
    () {
      final normal = ActorAnimation.sample(
        travelled: .375,
        time: .3,
        moving: false,
      );
      final tired = ActorAnimation.sample(
        travelled: .375,
        time: .3,
        moving: false,
        recoveringBreath: true,
      );
      expect(tired.chestScale, greaterThan(normal.chestScale));
      final hurt = ActorAnimation.sample(
        travelled: .375,
        time: .3,
        moving: true,
        injured: true,
      );
      expect(hurt.rightStride.abs(), lessThan(hurt.leftStride.abs()));
      expect(hurt.torsoLean, greaterThan(0));
    },
  );
}
