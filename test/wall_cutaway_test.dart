import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/game/wall_cutaway.dart';

void main() {
  test('wall cut changes gradually and does not flicker at its boundary', () {
    final wall = WallCutaway();
    wall.update(signedDistance: -1, indoors: true, dt: .02);
    expect(wall.fraction, greaterThan(0));
    expect(wall.fraction, lessThan(1));
    for (var i = 0; i < 120; i++) {
      wall.update(
        signedDistance: i.isEven ? -.03 : .03,
        indoors: true,
        dt: 1 / 60,
      );
    }
    expect(wall.fraction, greaterThan(.99));
    wall.update(signedDistance: 1, indoors: true, dt: .02);
    expect(wall.fraction, greaterThan(0));
    expect(wall.fraction, lessThan(1));
    for (var i = 0; i < 120; i++) {
      wall.update(signedDistance: 1, indoors: true, dt: 1 / 60);
    }
    expect(wall.fraction, lessThan(.001));
  });

  test(
    'exterior stays opaque and initial interior can be sampled immediately',
    () {
      final wall = WallCutaway();
      wall.update(signedDistance: -1, indoors: false, dt: 0, snap: true);
      expect(wall.fraction, 0);
      wall.update(signedDistance: -1, indoors: true, dt: 0, snap: true);
      expect(wall.fraction, 1);
      wall.update(signedDistance: -1, indoors: false, dt: 1);
      expect(wall.fraction, lessThan(.001));
    },
  );
}
