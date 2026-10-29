import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/game/animal_behaviour.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/models/campaign.dart';

void main() {
  final player = const Offset(48, 37);

  AnimalCanOccupy exterior(AnimalBehaviourWorld animals) {
    final world = WorldModel(Campaign()..floor = 0);
    return (id, p) {
      if (!world.isOpen(p.dx, p.dy)) return false;
      if ((p - player).distance < .6) return false;
      if (world.people.any(
        (npc) => (p - Offset(npc.x, npc.y)).distance < .58,
      )) {
        return false;
      }
      return !animals.actors.any(
        (other) =>
            other.id != id &&
            other.onGround &&
            (p - other.position).distance < .38,
      );
    };
  }

  test(
    'ambient routines reach only declared elevated surfaces and valid ground',
    () {
      final animals = AnimalBehaviourWorld();
      final clear = exterior(animals);
      final catSurfaces = <String>{};
      final dogStates = <AnimalState>{};
      var birdFlew = false;
      for (var i = 0; i < 120 * 60; i++) {
        animals.update(1 / 60, canOccupy: clear, playerPosition: player);
        dogStates.add(animals.dog.state);
        birdFlew |= animals.pigeon.state == AnimalState.fly;
        if (animals.cat.sleeping) catSurfaces.add(animals.cat.surface!.id);
        for (final animal in animals.actors) {
          if (animal.onGround)
            expect(
              clear(animal.id, animal.position),
              isTrue,
              reason: '${animal.id} on invalid ground at ${animal.position}',
            );
          if (animal.elevation > .01 && animal.kind == AnimalKind.cat) {
            expect(animal.surface, isNotNull);
          }
        }
      }
      expect(catSurfaces, containsAll(['breu_wall', 'sedan_roof']));
      expect(
        dogStates,
        containsAll([AnimalState.walk, AnimalState.mark, AnimalState.sleep]),
      );
      expect(birdFlew, isTrue);
    },
  );

  test('blocked navigation cannot advance positions or walking frames', () {
    final animals = AnimalBehaviourWorld();
    final starts = {
      for (final animal in animals.actors) animal.id: animal.position,
    };
    bool blocked(String id, Offset p) => (p - starts[id]!).distance < .001;
    for (var i = 0; i < 30 * 60; i++) {
      animals.update(
        1 / 60,
        canOccupy: blocked,
        playerPosition: player,
        canUseSurface: (_) => false,
      );
    }
    for (final animal in animals.actors) {
      expect(animal.position, starts[animal.id]);
      expect(animal.movedDistance, 0);
      expect(animal.walkFrame, 0);
    }
  });

  test(
    'cat waits above an occupied landing and completes descent after it clears',
    () {
      final animals = AnimalBehaviourWorld();
      final ground = exterior(animals);
      var blockLanding = false;
      bool clear(String id, Offset p) =>
          ground(id, p) &&
          !(id == 'breu' &&
              blockLanding &&
              (p - AnimalBehaviourWorld.wall.groundAccessPoint).distance < .2);
      for (var i = 0; i < 5 * 60; i++) {
        animals.update(1 / 60, canOccupy: clear, playerPosition: player);
      }
      expect(animals.cat.sleeping, isTrue);
      blockLanding = true;
      for (var i = 0; i < 20 * 60; i++) {
        animals.update(1 / 60, canOccupy: clear, playerPosition: player);
      }
      expect(animals.cat.state, AnimalState.climb);
      expect(animals.cat.elevation, greaterThan(5));
      blockLanding = false;
      for (var i = 0; i < 60; i++) {
        animals.update(1 / 60, canOccupy: clear, playerPosition: player);
      }
      expect(animals.cat.onGround, isTrue);
      expect(ground('breu', animals.cat.position), isTrue);
    },
  );

  test(
    'night appearance follows the world without changing physical identity',
    () {
      final animals = AnimalBehaviourWorld();
      animals.update(
        1 / 60,
        canOccupy: exterior(animals),
        playerPosition: player,
        isNight: true,
      );
      expect(animals.pigeon.nocturnal, isTrue);
      expect(animals.cat.nocturnal, isFalse);
      expect(animals.pigeon.id, 'pingo');
      animals.update(
        1 / 60,
        canOccupy: exterior(animals),
        playerPosition: player,
      );
      expect(animals.pigeon.nocturnal, isFalse);
    },
  );

  test(
    'night flight never enters ground walking and daylight lands safely',
    () {
      final animals = AnimalBehaviourWorld();
      final clear = exterior(animals);
      for (var i = 0; i < 20 * 60; i++) {
        animals.update(
          1 / 60,
          canOccupy: clear,
          playerPosition: player,
          isNight: true,
        );
        expect(animals.pigeon.state, AnimalState.fly);
        expect(animals.pigeon.onGround, isFalse);
        expect(animals.pigeon.elevation, greaterThan(0));
      }
      for (var i = 0; i < 3 * 60; i++) {
        animals.update(1 / 60, canOccupy: clear, playerPosition: player);
      }
      expect(animals.pigeon.nocturnal, isFalse);
      expect(animals.pigeon.onGround, isTrue);
      expect(clear('pingo', animals.pigeon.position), isTrue);
    },
  );

  test('night bird can lift vertically when every landing is occupied', () {
    final animals = AnimalBehaviourWorld();
    bool blocked(String id, Offset position) => false;
    for (var i = 0; i < 5 * 60; i++) {
      animals.update(
        1 / 60,
        canOccupy: blocked,
        playerPosition: player,
        isNight: true,
      );
    }
    expect(animals.pigeon.state, AnimalState.fly);
    expect(animals.pigeon.position, const Offset(21, 28));
    expect(animals.pigeon.elevation, greaterThan(0));
    for (var i = 0; i < 3 * 60; i++) {
      animals.update(1 / 60, canOccupy: blocked, playerPosition: player);
    }
    expect(animals.pigeon.onGround, isFalse);
    for (var i = 0; i < 60; i++) {
      animals.update(1 / 60, canOccupy: (_, _) => true, playerPosition: player);
    }
    expect(animals.pigeon.onGround, isTrue);
  });

  test(
    'bird holds above a newly occupied landing then lands after release',
    () {
      final animals = AnimalBehaviourWorld();
      final ground = exterior(animals);
      animals.interact('pingo', canOccupy: ground);
      expect(animals.pigeon.state, AnimalState.fly);
      var blocked = false;
      bool clear(String id, Offset p) =>
          ground(id, p) && !(id == 'pingo' && blocked);
      for (var i = 0; i < 60; i++) {
        animals.update(1 / 60, canOccupy: clear, playerPosition: player);
      }
      blocked = true;
      for (var i = 0; i < 120; i++) {
        animals.update(1 / 60, canOccupy: clear, playerPosition: player);
      }
      expect(animals.pigeon.state, AnimalState.fly);
      expect(animals.pigeon.elevation, greaterThanOrEqualTo(10));
      final held = animals.pigeon.position;
      for (var i = 0; i < 30; i++) {
        animals.update(1 / 60, canOccupy: clear, playerPosition: player);
      }
      expect(animals.pigeon.position, held);
      blocked = false;
      for (var i = 0; i < 30; i++) {
        animals.update(1 / 60, canOccupy: clear, playerPosition: player);
      }
      expect(animals.pigeon.onGround, isTrue);
      expect(ground('pingo', animals.pigeon.position), isTrue);
    },
  );

  test('marking belongs only to the explicitly male dog', () {
    final animals = AnimalBehaviourWorld(dogIsMale: false);
    final clear = exterior(animals);
    final states = <AnimalState>{};
    for (var i = 0; i < 90 * 60; i++) {
      animals.update(1 / 60, canOccupy: clear, playerPosition: player);
      states.add(animals.dog.state);
    }
    expect(states, isNot(contains(AnimalState.mark)));
    expect(states, contains(AnimalState.sleep));
  });

  test(
    'fixed simulation cadence is independent of 30 versus 60 render updates',
    () {
      final a = AnimalBehaviourWorld(), b = AnimalBehaviourWorld();
      final clearA = exterior(a), clearB = exterior(b);
      for (var i = 0; i < 40 * 60; i++) {
        a.update(1 / 60, canOccupy: clearA, playerPosition: player);
      }
      for (var i = 0; i < 40 * 30; i++) {
        b.update(1 / 30, canOccupy: clearB, playerPosition: player);
      }
      for (var i = 0; i < 3; i++) {
        final aa = a.actors.elementAt(i), bb = b.actors.elementAt(i);
        expect((aa.position - bb.position).distance, lessThan(.0001));
        expect(aa.state, bb.state);
        expect(aa.walkFrame, bb.walkFrame);
      }
      a.reset();
      expect(a.cat.position, AnimalBehaviourWorld.wall.boardingPoint);
      expect(a.cat.surface, isNull);
      expect(a.dog.state, AnimalState.sniff);
    },
  );
}
