import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

enum AnimalKind { cat, dog, pigeon }

enum AnimalState { idle, walk, sniff, sleep, climb, mark, fly }

enum AnimalSurfaceKind { wall, parkedCar }

/// A named landing, not an exception which makes all vehicle colliders porous.
class AnimalSurface {
  const AnimalSurface({
    required this.id,
    required this.kind,
    required this.boardingPoint,
    required this.topPoint,
    required this.height,
    Offset? groundAccessPoint,
  }) : groundAccessPoint = groundAccessPoint ?? boardingPoint;

  final String id;
  final AnimalSurfaceKind kind;
  final Offset boardingPoint, topPoint, groundAccessPoint;
  final double height;
}

typedef AnimalCanOccupy = bool Function(String animalId, Offset groundPosition);
typedef AnimalCanUseSurface = bool Function(AnimalSurface surface);

class AnimalActor {
  AnimalActor(this.id, this.kind, this.position, {this.male = false});
  final String id;
  final AnimalKind kind;
  final bool male;
  Offset position;
  Offset facing = const Offset(1, 0);
  double elevation = 0;
  double movedDistance = 0;
  double stateTime = 0;
  AnimalState state = AnimalState.idle;
  bool moving = false;
  bool nocturnal = false;
  AnimalSurface? surface;

  // Renderer cadence follows real displacement, not the simulation clock.
  int get walkFrame => (movedDistance / .12).floor() % 6;
  int get flightFrame => (stateTime * 9).floor() % 6;
  bool get onGround => elevation < .01 && state != AnimalState.fly;
  bool get sleeping => state == AnimalState.sleep;
  double get breath => sleeping ? math.sin(stateTime * 2.4) * .5 + .5 : 0;

  final Queue<Offset> _route = Queue<Offset>();
  double _duration = 2;
  double _blockedTime = 0;
  int _cycle = 0;
  AnimalState _arrivalState = AnimalState.idle;
  double _arrivalDuration = 2;
  AnimalSurface? _pendingSurface;
  Offset? _goal;
  Offset _transitionStart = Offset.zero;
  Offset _transitionEnd = Offset.zero;
  double _transitionHeight = 0;
  bool _descending = false;
  bool _landingHeld = false;
  double _landingTime = 0, _landingHeight = 0;
}

/// Original, deterministic ambient AI for the phase-one exterior.
///
/// The caller owns physical collision. [AnimalCanOccupy] must check the exterior
/// even when the player's active floor is different, exclude the actor itself,
/// and include the player/NPCs/ground animals and parked vehicles. Elevated cats
/// deliberately occupy only a named surface. No actor is teleported through an
/// arbitrary wall to reach a destination.
class AnimalBehaviourWorld {
  AnimalBehaviourWorld({this.dogIsMale = true}) {
    reset();
  }

  final bool dogIsMale;
  late AnimalActor cat, dog, pigeon;
  double _accumulator = 0;
  final List<({String id, AnimalState state})> _events = [];
  static const radius = .18;
  static const wall = AnimalSurface(
    id: 'breu_wall',
    kind: AnimalSurfaceKind.wall,
    boardingPoint: Offset(7.5, 25.35),
    topPoint: Offset(7.5, 25.8),
    groundAccessPoint: Offset(9, 25.35),
    height: 26,
  );
  static const sedan = AnimalSurface(
    id: 'sedan_roof',
    kind: AnimalSurfaceKind.parkedCar,
    boardingPoint: Offset(19, 14.1),
    topPoint: Offset(19, 13),
    height: 29,
  );
  Iterable<AnimalActor> get actors => [cat, dog, pigeon];

  void reset() {
    cat = AnimalActor('breu', AnimalKind.cat, wall.boardingPoint);
    dog = AnimalActor(
      'fuba',
      AnimalKind.dog,
      const Offset(17, 15),
      male: dogIsMale,
    );
    pigeon = AnimalActor('pingo', AnimalKind.pigeon, const Offset(21, 28));
    _state(cat, AnimalState.idle, 2);
    _state(dog, AnimalState.sniff, 2.5);
    _state(pigeon, AnimalState.idle, 3.5);
    _accumulator = 0;
    _events.clear();
  }

  /// A small optional cue queue. Gameplay must not rely on hearing these events.
  List<({String id, AnimalState state})> takeEvents() {
    final value = List<({String id, AnimalState state})>.of(_events);
    _events.clear();
    return value;
  }

  void update(
    double delta, {
    required AnimalCanOccupy canOccupy,
    required Offset playerPosition,
    bool isNight = false,
    AnimalCanUseSurface? canUseSurface,
  }) {
    if (!delta.isFinite || delta <= 0) return;
    _accumulator += delta.clamp(0, .25);
    const step = 1 / 60;
    while (_accumulator + 1e-9 >= step) {
      _accumulator -= step;
      for (final animal in actors) {
        animal.moving = false;
        animal.nocturnal = animal.kind == AnimalKind.pigeon && isNight;
        if (animal.nocturnal && animal.state != AnimalState.fly) {
          _startFlight(animal, canOccupy);
        }
        // Advance the state selected for this tick. A night takeoff must sample
        // its first airborne frame, rather than reset to zero after advancing.
        animal.stateTime += step;
        if (animal.surface != null &&
            canUseSurface != null &&
            !canUseSurface(animal.surface!) &&
            animal.state != AnimalState.climb) {
          _beginClimb(animal, animal.surface!, descending: true);
        }
        if (animal.state == AnimalState.walk) {
          _walk(animal, step, canOccupy, canUseSurface);
        } else if (animal.state == AnimalState.climb) {
          _climb(animal, canOccupy, canUseSurface);
        } else if (animal.state == AnimalState.fly) {
          _fly(animal, canOccupy);
        } else if (animal.kind == AnimalKind.pigeon &&
            (animal.position - playerPosition).distance < 1.4) {
          _startFlight(animal, canOccupy);
        } else if (animal.stateTime >= animal._duration) {
          _choose(animal, canOccupy, canUseSurface, isNight);
        }
      }
    }
  }

  /// Returns a visual observation; it never implies that Caio heard a sound.
  String interact(String id, {required AnimalCanOccupy canOccupy}) {
    final animal = actors.firstWhere((a) => a.id == id);
    switch (animal.kind) {
      case AnimalKind.cat:
        if (animal.sleeping)
          return 'Breu dorme enroscado ${animal.surface?.kind == AnimalSurfaceKind.parkedCar ? 'sobre o carro parado' : 'no alto do muro'}.';
        return animal.state == AnimalState.climb
            ? 'Breu encontra apoio e sobe com cuidado.'
            : 'Breu acompanha o movimento com os olhos e escolhe outro apoio.';
      case AnimalKind.dog:
        if (animal.sleeping)
          return 'Fubá descansa na garagem. O peito se move devagar.';
        if (animal.state == AnimalState.mark)
          return 'Fubá marca a parede e volta a farejar.';
        if (animal.state != AnimalState.walk)
          _state(animal, AnimalState.sniff, 2);
        return 'Fubá fareja perto de Caio e volta à sua rotina.';
      case AnimalKind.pigeon:
        _startFlight(animal, canOccupy);
        return 'Pingo abre as asas, muda de lugar e procura um pouso livre.';
    }
  }

  void _state(AnimalActor animal, AnimalState state, double duration) {
    animal.state = state;
    animal.stateTime = 0;
    animal._duration = duration;
    animal.moving = false;
    if (state == AnimalState.fly || state == AnimalState.mark) {
      _events.add((id: animal.id, state: state));
      if (_events.length > 16) _events.removeAt(0);
    }
  }

  void _choose(
    AnimalActor animal,
    AnimalCanOccupy clear,
    AnimalCanUseSurface? surfaceAvailable,
    bool night,
  ) {
    if (animal.surface != null) {
      if (animal.state == AnimalState.idle) {
        _state(animal, AnimalState.sleep, night ? 22 : 14);
      } else {
        _beginClimb(animal, animal.surface!, descending: true);
      }
      return;
    }
    final cycle = animal._cycle++;
    switch (animal.kind) {
      case AnimalKind.cat:
        final surface = cycle.isEven ? wall : sedan;
        if (surfaceAvailable != null && !surfaceAvailable(surface)) {
          _state(animal, AnimalState.sniff, 3);
          return;
        }
        animal._pendingSurface = surface;
        _startWalk(
          animal,
          (animal.position - surface.boardingPoint).distance < .2
              ? surface.boardingPoint
              : surface.groundAccessPoint,
          clear,
          after: AnimalState.climb,
          duration: 1.2,
        );
      case AnimalKind.dog:
        if (cycle % 3 == 0) {
          _startWalk(
            animal,
            const Offset(15.45, 11.2),
            clear,
            after: animal.male ? AnimalState.mark : AnimalState.sniff,
            duration: animal.male ? 2.5 : 3,
          );
        } else if (cycle % 3 == 1) {
          _startWalk(
            animal,
            const Offset(17.2, 15),
            clear,
            after: AnimalState.sleep,
            duration: night ? 24 : 15,
          );
        } else {
          _startWalk(
            animal,
            const Offset(21.5, 15),
            clear,
            after: AnimalState.sniff,
            duration: 3.5,
          );
        }
      case AnimalKind.pigeon:
        if (cycle.isEven) {
          _startWalk(
            animal,
            Offset(21 + (cycle % 3) * .5, 28.5),
            clear,
            after: AnimalState.sniff,
            duration: 2,
          );
        } else {
          _startFlight(animal, clear);
        }
    }
  }

  void _startWalk(
    AnimalActor animal,
    Offset target,
    AnimalCanOccupy clear, {
    required AnimalState after,
    required double duration,
  }) {
    animal._route
      ..clear()
      ..addAll(_route(animal, target, clear));
    animal._goal = target;
    animal._arrivalState = after;
    animal._arrivalDuration = duration;
    animal._blockedTime = 0;
    _state(animal, AnimalState.walk, double.infinity);
    if (animal._route.isEmpty) {
      if ((animal.position - target).distance < .2 &&
          clear(animal.id, target)) {
        _arrive(animal, null);
      } else {
        animal._pendingSurface = null;
        _state(animal, AnimalState.idle, 3);
      }
    }
  }

  void _walk(
    AnimalActor animal,
    double dt,
    AnimalCanOccupy clear,
    AnimalCanUseSurface? surfaceAvailable,
  ) {
    if (animal._route.isEmpty) {
      _arrive(animal, surfaceAvailable);
      return;
    }
    final target = animal._route.first;
    final delta = target - animal.position;
    if (delta.distance < .035) {
      animal._route.removeFirst();
      if (animal._route.isEmpty) _arrive(animal, surfaceAvailable);
      return;
    }
    final speed = animal.kind == AnimalKind.cat
        ? 1.15
        : animal.kind == AnimalKind.dog
        ? 1.05
        : .65;
    final move = delta / delta.distance * math.min(speed * dt, delta.distance);
    final next = animal.position + move;
    if (_segment(animal.id, animal.position, next, clear)) {
      animal.position = next;
      animal.facing = delta / delta.distance;
      animal.movedDistance += move.distance;
      animal.moving = true;
      animal._blockedTime = 0;
    } else {
      animal._blockedTime += dt;
      if (animal._blockedTime > .5) {
        animal._route
          ..clear()
          ..addAll(_route(animal, animal._goal!, clear));
        animal._blockedTime = 0;
        if (animal._route.isEmpty) {
          animal._pendingSurface = null;
          _state(animal, AnimalState.idle, 2);
        }
      }
    }
  }

  void _arrive(AnimalActor animal, AnimalCanUseSurface? available) {
    if (animal._arrivalState == AnimalState.climb) {
      final surface = animal._pendingSurface;
      animal._pendingSurface = null;
      if (surface != null && (available == null || available(surface))) {
        _beginClimb(animal, surface);
      } else {
        _state(animal, AnimalState.idle, 3);
      }
    } else {
      if (animal._arrivalState == AnimalState.mark)
        animal.facing = const Offset(1, 0);
      _state(animal, animal._arrivalState, animal._arrivalDuration);
    }
  }

  void _beginClimb(
    AnimalActor animal,
    AnimalSurface surface, {
    bool descending = false,
  }) {
    animal.surface = surface;
    animal._descending = descending;
    animal._transitionStart = animal.position;
    animal._transitionEnd = descending
        ? surface.groundAccessPoint
        : surface.topPoint;
    animal._transitionHeight = animal.elevation;
    _state(animal, AnimalState.climb, 1.2);
  }

  void _climb(
    AnimalActor animal,
    AnimalCanOccupy clear,
    AnimalCanUseSurface? available,
  ) {
    final surface = animal.surface!;
    final t = (animal.stateTime / animal._duration).clamp(0.0, 1.0);
    // A surface which is no longer stationary is never selected for a new jump.
    // During a descent the ground landing is rechecked before touching down.
    if (animal._descending &&
        t >= .7 &&
        !clear(animal.id, surface.groundAccessPoint)) {
      animal.stateTime = animal._duration * .7;
      return;
    }
    if (!animal._descending && available != null && !available(surface)) {
      _beginClimb(animal, surface, descending: true);
      return;
    }
    final before = animal.position;
    animal.position = Offset.lerp(
      animal._transitionStart,
      animal._transitionEnd,
      t,
    )!;
    animal.elevation =
        animal._transitionHeight +
        ((animal._descending ? 0 : surface.height) - animal._transitionHeight) *
            t;
    final delta = animal.position - before;
    if (delta.distance > .00001) {
      animal.facing = delta / delta.distance;
      animal.movedDistance += delta.distance;
      animal.moving = true;
    }
    if (t >= 1) {
      if (animal._descending) {
        animal.surface = null;
        animal.elevation = 0;
        _state(animal, AnimalState.idle, 2);
      } else {
        _state(animal, AnimalState.idle, 1.5);
      }
    }
  }

  void _startFlight(AnimalActor animal, AnimalCanOccupy clear) {
    if (animal.state == AnimalState.fly) return;
    const landings = [Offset(24, 29), Offset(20, 30), Offset(21, 28)];
    final start = animal._cycle % landings.length;
    for (var i = 0; i < landings.length; i++) {
      final target = landings[(start + i) % landings.length];
      if ((target - animal.position).distance > .6 &&
          clear(animal.id, target)) {
        animal._transitionStart = animal.position;
        animal._transitionEnd = target;
        animal._transitionHeight = animal.elevation;
        animal._landingHeld = false;
        _state(animal, AnimalState.fly, 1.8);
        return;
      }
    }
    if (animal.nocturnal) {
      // All ground destinations may be occupied. Lift vertically and keep the
      // same airborne position until a safe route or daylight landing exists.
      animal._transitionStart = animal.position;
      animal._transitionEnd = animal.position;
      animal._transitionHeight = animal.elevation;
      animal._landingHeld = false;
      _state(animal, AnimalState.fly, 1.8);
    } else {
      _state(animal, AnimalState.idle, 2);
    }
  }

  void _fly(AnimalActor animal, AnimalCanOccupy clear) {
    final t = (animal.stateTime / animal._duration).clamp(0.0, 1.0);
    if (animal.nocturnal && t >= 1) {
      // Start the next arc without ever entering a ground state at night.
      animal._cycle++;
      animal.state = AnimalState.idle;
      _startFlight(animal, clear);
      return;
    }
    if (t >= 1 && !clear(animal.id, animal._transitionEnd)) {
      // Hover; never rewind the flight to an earlier X/Y sample.
      animal._landingHeld = true;
      animal._landingTime = 0;
      animal._landingHeight = math.max(10, animal.elevation);
      animal.elevation = animal._landingHeight;
      return;
    }
    if (animal._landingHeld) {
      animal._landingTime += 1 / 60;
      final progress = (animal._landingTime / .35).clamp(0.0, 1.0);
      animal.elevation = animal._landingHeight * (1 - progress);
      if (progress >= 1) {
        animal.position = animal._transitionEnd;
        animal._landingHeld = false;
        animal._cycle++;
        _state(animal, AnimalState.idle, 4);
      }
      return;
    }
    final before = animal.position;
    animal.position = Offset.lerp(
      animal._transitionStart,
      animal._transitionEnd,
      t,
    )!;
    animal.elevation =
        animal._transitionHeight * (1 - t) +
        math.sin(t * math.pi) * 32 +
        (animal.nocturnal ? 14 * t : 0);
    final delta = animal.position - before;
    if (delta.distance > .00001) {
      animal.facing = delta / delta.distance;
      animal.movedDistance += delta.distance;
      animal.moving = true;
    }
    if (t >= 1) {
      animal.elevation = 0;
      animal._cycle++;
      _state(animal, AnimalState.idle, 4);
    }
  }

  bool _segment(String id, Offset a, Offset b, AnimalCanOccupy clear) {
    final count = math.max(1, ((b - a).distance / .08).ceil());
    for (var i = 1; i <= count; i++) {
      if (!clear(id, Offset.lerp(a, b, i / count)!)) return false;
    }
    return true;
  }

  List<Offset> _route(
    AnimalActor animal,
    Offset target,
    AnimalCanOccupy clear,
  ) {
    if ((target - animal.position).distance < .035) return const [];
    if (_segment(animal.id, animal.position, target, clear)) return [target];
    // A bounded half-tile BFS runs only when a new ambient destination is chosen.
    // Actual movement also validates every short segment, including dynamic bodies.
    (int, int) cell(Offset p) => ((p.dx * 2).round(), (p.dy * 2).round());
    Offset point((int, int) cell) => Offset(cell.$1 / 2, cell.$2 / 2);
    final start = cell(animal.position), goal = cell(target);
    final queue = Queue<(int, int)>()..add(start);
    final previous = <(int, int), (int, int)?>{start: null};
    while (queue.isNotEmpty && previous.length < 9000) {
      final current = queue.removeFirst();
      if (current == goal) break;
      for (final direction in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final next = (current.$1 + direction.$1, current.$2 + direction.$2);
        if (next.$1 < 5 ||
            next.$1 > 104 ||
            next.$2 < 20 ||
            next.$2 > 79 ||
            previous.containsKey(next))
          continue;
        final from = current == start ? animal.position : point(current);
        if (!_segment(animal.id, from, point(next), clear)) continue;
        previous[next] = current;
        queue.add(next);
      }
    }
    if (!previous.containsKey(goal)) return const [];
    final reversed = <Offset>[];
    (int, int)? here = goal;
    while (here != null && here != start) {
      reversed.add(point(here));
      here = previous[here];
    }
    final route = reversed.reversed.toList();
    final last = route.isEmpty ? animal.position : route.last;
    if (!_segment(animal.id, last, target, clear)) return const [];
    route.add(target);
    return route;
  }
}
