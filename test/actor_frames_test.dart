import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/game/actor_frames.dart';

void main() {
  test('all eight direction cells have stable separate rows', () {
    final directions = [
      for (final d in [
        (1.0, -1.0),
        (1.0, 0.0),
        (1.0, 1.0),
        (0.0, 1.0),
        (-1.0, 1.0),
        (-1.0, 0.0),
        (-1.0, -1.0),
        (0.0, -1.0),
      ])
        ActorFrames.direction(d.$1, d.$2),
    ];
    expect(directions.toSet().length, 8);
    expect(ActorFrames.source(3, 7).left, 384);
    expect(ActorFrames.source(3, 7).top, 1008);
  });
  test(
    'walk frames depend on travelled distance, actions stop at recovery',
    () {
      expect(ActorFrames.frame('walk', travelled: 0, time: 99), 0);
      expect(ActorFrames.frame('walk', travelled: .45, time: 0), 4);
      expect(ActorFrames.frame('attack', progress: 1), 7);
      expect(ActorFrames.frame('hurt', progress: 1), 5);
    },
  );
}
