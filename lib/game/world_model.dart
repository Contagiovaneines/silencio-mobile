import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import '../models/campaign.dart';
import 'building_layout.dart';
import 'animal_behaviour.dart';
import 'world_atmosphere.dart';

enum PointKind {
  apartmentDoor,
  buildingDoor,
  chair,
  sofa,
  wardrobe,
  refrigerator,
  notebook,
  bathroom,
  noticeboard,
  stairsDown,
  stairsUp,
  elevator,
  phone,
  key,
  adapter,
  neighbor,
  merchant,
  television,
  panel,
  sedan,
  water,
  gate,
  bus,
  crossing,
  bed,
  dog,
  cat,
  pigeon,
  ladder,
}

class Place {
  const Place(
    this.kind,
    this.x,
    this.y,
    this.label,
    this.action, {
    this.floor = 0,
    this.id,
  });
  final String? id;
  final int floor;
  final PointKind kind;
  final double x, y;
  final String label, action;
}

class Block {
  const Block(
    this.bounds,
    this.name,
    this.style,
    this.height, {
    this.interior = false,
    this.floor = 0,
  });
  final Rect bounds;
  final String name;
  final int style;
  final double height;
  final bool interior;
  final int floor;
}

class Furnishing {
  const Furnishing(this.bounds, this.kind, this.height, {this.floor = 0});
  final int floor;
  final Rect bounds;
  final String kind;
  final double height;
}

class Person {
  const Person(this.id, this.x, this.y, {this.floor = 0});
  final int floor;
  final String id;
  final double x, y;
}

class Vehicle {
  const Vehicle(this.id, this.position, this.bounds, this.width);
  final String id;
  final Offset position;
  final Rect bounds;
  final double width;
}

class WorldModel {
  WorldModel(this.campaign);
  Campaign campaign;
  final animals = AnimalBehaviourWorld();
  final atmosphere = WorldAtmosphere();
  bool get isNight => atmosphere.isNight;
  bool gateClosed = false;
  double playerElevation = 0;
  bool onRoof = false;
  bool _descendingLadder = false;
  Offset? ladderBase;
  Offset get playerDrawPosition => ladderBase == null
      ? Offset(campaign.x, campaign.y)
      : Offset.lerp(
          ladderBase!,
          const Offset(9.65, 22.5),
          playerElevation / 56,
        )!;
  bool climbLadder() {
    if (action != 'idle' ||
        encounterActive ||
        campaign.floor != 0 ||
        distance(10.7, 22.5) > 1.85)
      return false;
    _descendingLadder = onRoof;
    ladderBase ??= Offset(campaign.x, campaign.y);
    beginAction('climb', 3.2);
    return true;
  }

  static const width = 56, height = 44, radius = .22;
  static const blocks = [
    Block(
      Rect.fromLTRB(2, 2, 12, 10),
      'APARTAMENTO 203 · 2º ANDAR',
      3,
      54,
      interior: true,
      floor: 2,
    ),
    Block(
      Rect.fromLTRB(24, 17, 32, 24),
      'MERCEARIA · ORLANDO',
      1,
      65,
      interior: true,
    ),
    Block(Rect.fromLTRB(2, 2, 24, 10), 'RESIDENCIAL AURORA', 5, 180),
    Block(Rect.fromLTRB(6.7, 25.65, 8.3, 25.9), 'Muro baixo', 6, 26),
    Block(
      Rect.fromLTRB(2, 2, 12, 10),
      'APARTAMENTO 103',
      4,
      54,
      interior: true,
      floor: 1,
    ),
    Block(
      Rect.fromLTRB(12, 2, 18, 10),
      'APARTAMENTO 102',
      4,
      54,
      interior: true,
      floor: 1,
    ),
    Block(
      Rect.fromLTRB(18, 2, 24, 10),
      'APARTAMENTO 101',
      4,
      54,
      interior: true,
      floor: 1,
    ),
    Block(
      Rect.fromLTRB(12, 2, 18, 10),
      'APARTAMENTO 202',
      4,
      54,
      interior: true,
      floor: 2,
    ),
    Block(
      Rect.fromLTRB(18, 2, 24, 10),
      'APARTAMENTO 201',
      4,
      54,
      interior: true,
      floor: 2,
    ),
    Block(Rect.fromLTRB(3, 19, 10, 25), 'RESIDENCIAL AURORA', 0, 105),
    Block(Rect.fromLTRB(33, 17, 41, 23), 'OFICINA', 2, 72),
    Block(Rect.fromLTRB(4, 31, 12, 38), 'CASAS DA PRAÇA', 0, 88),
    Block(Rect.fromLTRB(35, 34, 43, 40), 'CENTRAL', 2, 100),
  ];
  static const vehicles = [
    Vehicle(
      'sedan',
      Offset(19, 13),
      Rect.fromLTRB(17.4, 12.2, 20.5, 13.6),
      145,
    ),
    Vehicle('van', Offset(35, 28), Rect.fromLTRB(33.4, 27.2, 36.6, 28.7), 155),
    Vehicle('bus', Offset(47, 32), Rect.fromLTRB(44.2, 30.7, 49.6, 32.7), 245),
  ];
  static const furniture = [
    Furnishing(Rect.fromLTRB(3, 3, 5.4, 5), 'bed', 16, floor: 2),
    Furnishing(Rect.fromLTRB(9, 3, 10.6, 4), 'kitchen', 24, floor: 2),
    Furnishing(Rect.fromLTRB(3, 5.7, 4, 6.7), 'wardrobe', 48, floor: 2),
    Furnishing(Rect.fromLTRB(3, 7.5, 4.4, 8.7), 'sofa', 23, floor: 2),
    Furnishing(Rect.fromLTRB(24.5, 17.7, 26, 20.5), 'shelf', 48),
    Furnishing(Rect.fromLTRB(29.7, 17.8, 31.4, 19.2), 'fridge', 57),
    Furnishing(Rect.fromLTRB(30, 21, 31.5, 22.7), 'counter', 23),
    Furnishing(Rect.fromLTRB(18.5, 27, 20, 28), 'bench', 14),
    Furnishing(Rect.fromLTRB(23, 30.5, 24.5, 31.5), 'bench', 14),
    Furnishing(Rect.fromLTRB(5.7, 3.4, 7.1, 4.4), 'desk', 18, floor: 2),
    Furnishing(Rect.fromLTRB(9.7, 5.5, 11, 6.3), 'bookcase', 35, floor: 2),
    Furnishing(Rect.fromLTRB(10.5, 7.4, 11.5, 8.5), 'shower', 45, floor: 2),
    Furnishing(Rect.fromLTRB(8.4, 8.7, 9.1, 9.5), 'toilet', 15, floor: 2),
    Furnishing(Rect.fromLTRB(10, 8.9, 10.8, 9.5), 'basin', 20, floor: 2),
    Furnishing(Rect.fromLTRB(10.9, 3, 11.7, 4), 'fridge', 48, floor: 2),
    Furnishing(Rect.fromLTRB(3.6, 8.9, 4.4, 9.4), 'coffee', 12, floor: 2),
  ];
  List<Person> get _allPeople => [
    Person('ines', inesX, 11.5, floor: 2),
    if (campaign.has('alley') && !campaign.has('resolved'))
      const Person('orlando', 36, 25)
    else
      const Person('orlando', 28, 22),
    Person('nestor', _ambientNpcs['nestor']!.dx, _ambientNpcs['nestor']!.dy),
    Person('marina', _ambientNpcs['marina']!.dx, _ambientNpcs['marina']!.dy),
    Person('bia', _ambientNpcs['bia']!.dx, _ambientNpcs['bia']!.dy),
    if (campaign.has('resolved')) const Person('davi', 38, 25),
  ];
  Iterable<Block> get visibleBlocks =>
      blocks.where((b) => b.floor == campaign.floor);
  Iterable<Furnishing> get visibleFurniture =>
      furniture.where((f) => f.floor == campaign.floor);
  Iterable<Vehicle> get visibleVehicles =>
      campaign.floor == 0 ? vehicles : const <Vehicle>[];
  List<Person> get people =>
      _allPeople.where((p) => p.floor == campaign.floor).toList();
  Person get merchant => _allPeople.firstWhere((p) => p.id == 'orlando');
  List<Place> get places =>
      allPlaces.where((p) => p.floor == campaign.floor).toList();
  double inesX = 14;
  List<Place> get allPlaces => [
    for (final d in ResidentialLayout.doors.where((d) => d.id != '203'))
      Place(
        PointKind.buildingDoor,
        d.center.dx,
        d.center.dy,
        d.id == 'entrada'
            ? 'Entrada residencial'
            : d.id == 'banheiro'
            ? 'Porta do banheiro'
            : 'Porta ${d.id}',
        d.locked ? 'Bater à porta' : 'Abrir e passar',
        floor: d.floor,
        id: d.id,
      ),
    const Place(PointKind.sofa, 4.8, 8.1, 'Sofá', 'Sentar', floor: 2),
    const Place(PointKind.chair, 6.5, 5, 'Cadeira', 'Sentar', floor: 2),
    const Place(
      PointKind.wardrobe,
      4.6,
      6.3,
      'Guarda-roupa',
      'Abrir armário',
      floor: 2,
    ),
    const Place(
      PointKind.refrigerator,
      11,
      4.8,
      'Geladeira',
      'Abrir geladeira',
      floor: 2,
    ),
    const Place(
      PointKind.notebook,
      7.2,
      4.6,
      'Notebook',
      'Usar notebook',
      floor: 2,
    ),
    const Place(PointKind.bathroom, 9.5, 8.7, 'Banheiro', 'Examinar', floor: 2),
    if (campaign.floor > 0)
      Place(
        PointKind.noticeboard,
        18.5,
        12,
        'Quadro de avisos',
        'Ler',
        floor: campaign.floor,
      ),
    const Place(
      PointKind.apartmentDoor,
      7,
      10,
      'Porta 203',
      'Abrir e passar',
      floor: 2,
    ),
    const Place(
      PointKind.stairsDown,
      10,
      14.5,
      'Escada · 1º andar',
      'Descer',
      floor: 2,
    ),
    const Place(PointKind.stairsUp, 4.7, 14.5, 'Escada · 1º andar', 'Subir'),
    const Place(
      PointKind.stairsDown,
      10,
      14.5,
      'Escada · térreo',
      'Descer',
      floor: 1,
    ),
    const Place(
      PointKind.stairsUp,
      4.7,
      14.5,
      'Escada · 2º andar',
      'Subir',
      floor: 1,
    ),
    const Place(PointKind.elevator, 3.8, 14.3, 'Elevador', 'Chamar', floor: 2),
    const Place(PointKind.phone, 6.5, 4, 'Celular', 'Ler mensagem', floor: 2),
    if (!campaign.has('key'))
      const Place(
        PointKind.key,
        9,
        4.7,
        'Chave de casa',
        'Pegar chave',
        floor: 2,
      ),
    if (!campaign.has('adapter'))
      const Place(
        PointKind.adapter,
        8.8,
        5.2,
        'Adaptador',
        'Recolher',
        floor: 2,
      ),
    const Place(
      PointKind.bed,
      4.3,
      5.5,
      'Cama · salvar o dia',
      'Descansar',
      floor: 2,
    ),
    Place(
      PointKind.neighbor,
      inesX,
      11.5,
      'Dona Inês · 202',
      'Ajudar',
      floor: 2,
    ),
    Place(PointKind.merchant, merchant.x, merchant.y, 'Orlando', 'Conversar'),
    const Place(
      PointKind.television,
      30.4,
      19.8,
      'TV da mercearia',
      'Ver notícia',
    ),
    const Place(PointKind.panel, 25.2, 21, 'Tomada queimada', 'Examinar'),
    const Place(PointKind.sedan, 19, 14.3, 'Sedã · porta-malas', 'Abrir'),
    if (!campaign.has('water'))
      const Place(PointKind.water, 29.4, 22.5, 'Água', 'Recolher'),
    Place(
      PointKind.gate,
      41.7,
      26.2,
      'Portão · alavanca',
      gateClosed ? 'Portão fechado' : 'Fechar',
    ),
    Place(
      PointKind.ladder,
      10.7,
      22.5,
      'Escada de manutenção',
      onRoof ? 'Descer' : 'Subir',
    ),
    const Place(PointKind.bus, 45, 29.5, 'Nestor · ônibus', 'Embarcar'),
    const Place(PointKind.crossing, 48.5, 28, 'Passagem a pé', 'Seguir a pé'),
    Place(
      PointKind.dog,
      animals.dog.position.dx,
      animals.dog.position.dy,
      'Fubá',
      'Observar',
    ),
    Place(
      PointKind.cat,
      animals.cat.position.dx,
      animals.cat.position.dy,
      'Breu',
      'Observar',
    ),
    Place(
      PointKind.pigeon,
      animals.pigeon.position.dx,
      animals.pigeon.position.dy,
      isNight ? 'Morcego' : 'Pingo',
      'Observar',
    ),
  ];
  double simulationTime = 0;
  double get dogX => animals.dog.position.dx;
  double get dogY => animals.dog.position.dy;
  bool get dogMoving => animals.dog.moving;
  bool recoveringBreath = false;
  bool get severelyHurt => campaign.health <= 25;
  bool get effectiveRunning =>
      running && !recoveringBreath && !severelyHurt && campaign.stamina > 5;
  double enemyWalked = 0;
  final Map<String, Offset> _npcPrevious = {};
  final Map<String, double> _npcTraveled = {};
  final Map<String, Offset> _npcFacing = {};
  final Set<String> _movingNpcs = {};
  final Map<String, Offset> _ambientNpcs = {
    'nestor': const Offset(45, 29.5),
    'marina': const Offset(22, 29.5),
    'bia': const Offset(22.8, 29.8),
  };
  void _ambientStep(double dt) {
    if (campaign.floor != 0) return;
    const routes = {
      'nestor': [Offset(45, 29.5), Offset(44.4, 28.4)],
      'marina': [Offset(22, 29.5), Offset(21.6, 30.6)],
      'bia': [Offset(22.8, 29.8), Offset(22.5, 31.1)],
    };
    var index = 0;
    for (final e in routes.entries) {
      final cycle = (simulationTime + index++ * 3) % 24;
      final target = e.value[cycle < 12 ? 0 : 1];
      final at = _ambientNpcs[e.key]!;
      final delta = target - at;
      if (delta.distance < .03) continue;
      final next =
          at + delta / delta.distance * math.min(delta.distance, dt * .42);
      if (!isOpen(next.dx, next.dy) ||
          (next - Offset(campaign.x, campaign.y)).distance < .75 ||
          _allPeople.any(
            (p) =>
                p.id != e.key &&
                p.floor == 0 &&
                (next - Offset(p.x, p.y)).distance < .65,
          ))
        continue;
      _ambientNpcs[e.key] = next;
    }
  }

  ({Offset facing, double traveled, bool moving}) npcMotion(String id) => (
    facing: _npcFacing[id] ?? const Offset(1, 1),
    traveled: _npcTraveled[id] ?? 0,
    moving: _movingNpcs.contains(id),
  );
  bool doorOpen = false;
  double inputX = 0,
      inputY = 0,
      enemyX = 38,
      enemyY = 26.5,
      enemyStun = 0,
      attackCooldown = 0,
      pushCooldown = 0;
  double enemyKnockX = 0, enemyKnockY = 0, facingX = 1, facingY = 0, walked = 0;
  double actionTime = 0,
      actionDuration = 0,
      attackWindup = 0,
      encounterTime = 0,
      stepTimer = 0,
      birdFlight = 0;
  String action = 'idle';
  bool actionContact = false, perception = false, running = false;
  final path = <Offset>[];
  Offset? _destination;
  double _repathWait = 0;
  bool get navigating => _destination != null;
  void stop() {
    inputX = inputY = 0;
    path.clear();
    _destination = null;
  }

  final sounds = <String>[];
  bool get encounterActive =>
      campaign.floor == 0 && campaign.has('alley') && !campaign.has('resolved');
  bool get moving =>
      action == 'idle' && (inputX != 0 || inputY != 0 || path.isNotEmpty);
  double distance(double x, double y) =>
      math.sqrt(math.pow(x - campaign.x, 2) + math.pow(y - campaign.y, 2));
  String? resting;
  Offset? restAnchor;
  bool get inResidence =>
      campaign.floor > 0 ||
      ResidentialLayout.corridor.contains(Offset(campaign.x, campaign.y));
  bool doorIsOpen(String id) =>
      id == '203' ? doorOpen : campaign.openDoors.contains(id);
  void setDoor(String id, bool open) {
    if (id == '203') {
      doorOpen = open;
      return;
    }
    if (open) {
      campaign.openDoors.add(id);
    } else {
      campaign.openDoors.remove(id);
    }
  }

  final Map<String, List<Rect>> _geometry = {};
  Iterable<Rect> get walls {
    final key =
        '${campaign.floor}:$doorOpen:$gateClosed:${campaign.openDoors.join(',')}';
    return _geometry.putIfAbsent(
      key,
      () => _buildWalls().toList(growable: false),
    );
  }

  Iterable<Rect> _buildWalls() sync* {
    yield* ResidentialLayout.partitions(campaign.floor);
    for (final d in ResidentialLayout.doors.where(
      (d) => d.floor == campaign.floor,
    )) {
      if (!doorIsOpen(d.id)) yield d.collider;
    }
    for (final block in visibleBlocks) {
      final b = block.bounds;
      if (block.floor > 0) continue;
      if (!block.interior) {
        yield b;
        continue;
      }
      const t = .18;
      final middle = b.center.dx;
      yield Rect.fromLTRB(b.left - t, b.top - t, b.right + t, b.top + t);
      yield Rect.fromLTRB(b.left - t, b.top, b.left + t, b.bottom);
      yield Rect.fromLTRB(b.right - t, b.top, b.right + t, b.bottom);
      yield Rect.fromLTRB(b.left, b.bottom - t, middle - .9, b.bottom + t);
      yield Rect.fromLTRB(middle + .9, b.bottom - t, b.right, b.bottom + t);
    }
    yield* visibleFurniture.map((f) => f.bounds);
    yield* visibleVehicles.map((v) => v.bounds);
    if (campaign.floor == 0 && gateClosed) {
      yield const Rect.fromLTRB(40.8, 24, 41.05, 27.8);
    }
  }

  bool isOpen(double x, double y) {
    if (x < 2.4 || x > 52 || y < 2.4 || y > 39.5) return false;
    final floor = campaign.floor > 0
        ? ResidentialLayout.footprint.contains(Offset(x, y))
        : y >= 16 || ResidentialLayout.corridor.contains(Offset(x, y));
    if (!floor) return false;
    final body = Rect.fromCircle(center: Offset(x, y), radius: radius);
    return !walls.any((b) => b.overlaps(body));
  }

  bool animalCanOccupy(String id, Offset at) {
    final floor = campaign.floor;
    campaign.floor = 0;
    final clear = isOpen(at.dx, at.dy);
    campaign.floor = floor;
    if (!clear) return false;
    if (floor == 0 && (at - Offset(campaign.x, campaign.y)).distance < .6)
      return false;
    if (_allPeople
        .where((p) => p.floor == 0)
        .any((p) => (at - Offset(p.x, p.y)).distance < .55))
      return false;
    return !animals.actors.any(
      (a) => a.id != id && a.onGround && (a.position - at).distance < .42,
    );
  }

  bool canStand(double x, double y, {bool enemy = false}) {
    if (!isOpen(x, y)) return false;
    if (campaign.floor == 0 &&
        animals.actors.any(
          (a) => a.onGround && (Offset(x, y) - a.position).distance < .40,
        ))
      return false;
    for (final p in people) {
      if ((Offset(x, y) - Offset(p.x, p.y)).distance < .58) return false;
    }
    if (!enemy &&
        encounterActive &&
        (Offset(x, y) - Offset(enemyX, enemyY)).distance < .56) {
      return false;
    }
    if (enemy &&
        (Offset(x, y) - Offset(campaign.x, campaign.y)).distance < .6) {
      return false;
    }
    return true;
  }

  Place? get nearby {
    Place? nearest;
    var d = 1.85;
    for (final p in places) {
      final next = distance(p.x, p.y);
      if (next < d &&
          (p.kind == PointKind.apartmentDoor ||
              p.kind == PointKind.buildingDoor ||
              interactionClear(
                Offset(campaign.x, campaign.y),
                Offset(p.x, p.y),
              ))) {
        d = next;
        nearest = p;
      }
    }
    return nearest;
  }

  void restore(Campaign value) {
    campaign = value;
    _destination = null;
    _geometry.clear();
    playerElevation = 0;
    onRoof = false;
    ladderBase = null;
    resting = null;
    restAnchor = null;
    doorOpen = false;
    inputX = inputY = 0;
    path.clear();
    enemyX = 38;
    enemyY = 26.5;
    enemyStun = attackCooldown = pushCooldown = attackWindup = encounterTime =
        0;
    enemyKnockX = enemyKnockY = 0;
    action = 'idle';
    simulationTime = 0;
    animals.reset();
    atmosphere.restore(night: value.has('night'));
    gateClosed = value.has('resolved');
    recoveringBreath = value.stamina < 15;
    enemyWalked = 0;
    _ambientNpcs['nestor'] = const Offset(45, 29.5);
    _ambientNpcs['marina'] = const Offset(22, 29.5);
    _ambientNpcs['bia'] = const Offset(22.8, 29.8);
    _npcPrevious.clear();
    _npcTraveled.clear();
    _npcFacing.clear();
    _movingNpcs.clear();
    actionTime = 0;
    perception = running = false;
    sounds.clear();
    final inaccessibleUnit =
        value.y < 10 && (value.floor == 1 || value.floor == 2 && value.x >= 12);
    if (inaccessibleUnit || !canStand(value.x, value.y)) {
      campaign.x = campaign.floor == 2 ? 6 : 7;
      campaign.y = campaign.floor == 2 ? 6 : 12;
    }
  }

  bool canArrive(int floor, Offset position) {
    final current = campaign.floor;
    campaign.floor = floor;
    final valid = canStand(position.dx, position.dy);
    campaign.floor = current;
    return valid;
  }

  void changeFloor(int floor, Offset position) {
    campaign.floor = floor;
    campaign.x = position.dx;
    campaign.y = position.dy;
    stop();
    action = 'idle';
    actionTime = 0;
  }

  void setInput(double x, double y) {
    if (onRoof || action == 'climb') return;
    inputX = x;
    inputY = y;
    if (x != 0 || y != 0) {
      path.clear();
      _destination = null;
    }
  }

  void moveTo(double x, double y) {
    if (action != 'idle' || onRoof) return;
    for (final door in ResidentialLayout.doors.where(
      (d) => d.floor == campaign.floor,
    )) {
      if ((Offset(x, y) - door.center).distance < .45) {
        final position = Offset(campaign.x, campaign.y);
        final approach =
            (position - door.inside).distance <
                (position - door.outside).distance
            ? door.inside
            : door.outside;
        x = approach.dx;
        y = approach.dy;
        break;
      }
    }
    var goal = (x.floor(), y.floor());
    final start = (campaign.x.floor(), campaign.y.floor());
    final queue = Queue<(int, int)>()..add(start);
    final previous = <(int, int), (int, int)?>{start: null};
    while (queue.isNotEmpty) {
      final here = queue.removeFirst();
      if (here == goal) break;
      for (final s in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final n = (here.$1 + s.$1, here.$2 + s.$2);
        final from = here == start
            ? Offset(campaign.x, campaign.y)
            : Offset(here.$1 + .5, here.$2 + .5);
        if (previous.containsKey(n) ||
            !canStand(n.$1 + .5, n.$2 + .5) ||
            !canTravel(from, Offset(n.$1 + .5, n.$2 + .5))) {
          continue;
        }
        previous[n] = here;
        queue.add(n);
      }
    }
    if (!previous.containsKey(goal)) {
      // A closed door's center may have a free cell on the other side. Approach
      // the nearest reachable cell instead of choosing by distance alone.
      final reachable = previous.keys.toList()
        ..sort((a, b) {
          double distance((int, int) p) =>
              math.pow(p.$1 + .5 - x, 2).toDouble() +
              math.pow(p.$2 + .5 - y, 2).toDouble();
          return distance(a).compareTo(distance(b));
        });
      if (reachable.isEmpty) return;
      goal = reachable.first;
    }
    final reverse = <Offset>[];
    (int, int)? n = goal;
    while (n != null && n != start) {
      reverse.add(Offset(n.$1 + .5, n.$2 + .5));
      n = previous[n];
    }
    path
      ..clear()
      ..addAll(reverse.reversed);
    _destination = path.isEmpty ? null : Offset(x, y);
  }

  bool canTravel(Offset from, Offset to) {
    final steps = ((to - from).distance / .1).ceil();
    for (var i = 1; i <= steps; i++) {
      final p = Offset.lerp(from, to, i / steps)!;
      if (!canStand(p.dx, p.dy)) return false;
    }
    return true;
  }

  bool interactionClear(Offset from, Offset to) {
    final structural = walls
        .where((r) => !visibleFurniture.any((f) => f.bounds == r))
        .toList();
    final steps = ((to - from).distance / .1).ceil();
    for (var i = 1; i < steps; i++) {
      final p = Offset.lerp(from, to, i / steps)!;
      if (structural.any((r) => r.contains(p))) return false;
    }
    return true;
  }

  bool lineClear(Offset from, Offset to) {
    final distance = (to - from).distance;
    final count = (distance / .1).ceil();
    for (var i = 1; i < count; i++) {
      final p = Offset.lerp(from, to, i / count)!;
      if (!isOpen(p.dx, p.dy)) return false;
    }
    return true;
  }

  void beginAction(String value, double duration) {
    action = value;
    actionDuration = actionTime = duration;
    actionContact = false;
    stop();
  }

  void update(double delta) {
    var remaining = delta.clamp(0.0, .12);
    while (remaining > 0) {
      final dt = math.min(remaining, 1 / 60);
      _step(dt);
      remaining -= dt;
    }
  }

  void _step(double dt) {
    simulationTime += dt;
    if (campaign.stamina <= 15) recoveringBreath = true;
    if (campaign.stamina >= 99.9) recoveringBreath = false;
    _ambientStep(dt);
    _movingNpcs.clear();
    for (final person in people) {
      final at = Offset(person.x, person.y);
      final before = _npcPrevious[person.id];
      if (before != null &&
          (at - before).distance > .00001 &&
          (at - before).distance < .3) {
        final delta = at - before;
        _npcTraveled[person.id] =
            (_npcTraveled[person.id] ?? 0) + delta.distance;
        _npcFacing[person.id] = delta / delta.distance;
        _movingNpcs.add(person.id);
      }
      _npcPrevious[person.id] = at;
    }
    if (campaign.floor == 2 && !campaign.has('night')) {
      final target = 14 + math.sin(simulationTime * .1) * .8;
      final old = inesX;
      inesX = target;
      if ((Offset(inesX, 11.5) - Offset(campaign.x, campaign.y)).distance <
              .8 ||
          !isOpen(inesX, 11.5)) {
        inesX = old;
      }
    }
    atmosphere.update(dt, storyNight: campaign.has('night'));
    if (campaign.floor == 0) {
      animals.update(
        dt,
        canOccupy: animalCanOccupy,
        playerPosition: Offset(campaign.x, campaign.y),
        isNight: isNight,
        canUseSurface: (surface) =>
            surface.kind != AnimalSurfaceKind.parkedCar ||
            vehicles.any((v) => v.id == 'sedan'),
      );
    }

    pushCooldown = math.max(0, pushCooldown - dt);
    attackCooldown = math.max(0, attackCooldown - dt);
    enemyStun = math.max(0, enemyStun - dt);
    birdFlight = math.max(0, birdFlight - dt);
    if (action != 'idle') {
      actionTime = math.max(0, actionTime - dt);
      if (action == 'climb') {
        final progress = 1 - actionTime / actionDuration;
        playerElevation = 56 * (_descendingLadder ? 1 - progress : progress);
        if (actionTime == 0) {
          onRoof = !_descendingLadder;
          if (!onRoof) ladderBase = null;
        }
      }
      if (!actionContact && actionTime <= actionDuration * .55) {
        actionContact = true;
        if (action == 'push') {
          sounds.add('push');
          final delta = Offset(enemyX - campaign.x, enemyY - campaign.y);
          if (encounterActive &&
              delta.distance > 0 &&
              delta.distance < 1.8 &&
              (delta.dx * facingX + delta.dy * facingY) / delta.distance >
                  .35 &&
              lineClear(
                Offset(campaign.x, campaign.y),
                Offset(enemyX, enemyY),
              )) {
            enemyStun = severelyHurt ? .8 : 1.5;
            enemyKnockX = delta.dx / delta.distance * (severelyHurt ? 2.5 : 5);
            enemyKnockY = delta.dy / delta.distance * (severelyHurt ? 2.5 : 5);
          }
        }
        if (action == 'drink' && campaign.fridgeWater) {
          campaign.fridgeWater = false;
          campaign.stamina = 100;
          sounds.add('pickup');
        }
        if (action == 'heal' && campaign.bandages > 0) {
          campaign.bandages--;
          campaign.health = math.min(100, campaign.health + 35);
          campaign.injured = false;
          sounds.add('heal');
        }
      }
      if (actionTime == 0) action = 'idle';
    }
    if (_destination != null && path.isEmpty && action == 'idle') {
      _repathWait -= dt;
      if (_repathWait <= 0) {
        final target = _destination!;
        moveTo(target.dx, target.dy);
        _repathWait = .25;
      }
    }
    var dx = action == 'idle' ? inputX : 0.0,
        dy = action == 'idle' ? inputY : 0.0;
    if (dx == 0 && dy == 0 && path.isNotEmpty && action == 'idle') {
      final n = path.first;
      dx = n.dx - campaign.x;
      dy = n.dy - campaign.y;
      if (math.sqrt(dx * dx + dy * dy) < .08) {
        path.removeAt(0);
        if (path.isEmpty) _destination = null;
        dx = dy = 0;
      }
    }
    final length = math.sqrt(dx * dx + dy * dy);
    if (length > 0) {
      dx /= length;
      dy /= length;
      facingX = dx;
      facingY = dy;
      final fast = effectiveRunning;
      final limp = severelyHurt
          ? .55
          : campaign.injured
          ? .85
          : recoveringBreath
          ? .8
          : 1.0;
      final step = (fast ? 4.3 : 2.65) * limp * dt;
      final old = Offset(campaign.x, campaign.y);
      if (canStand(campaign.x + dx * step, campaign.y)) campaign.x += dx * step;
      if (canStand(campaign.x, campaign.y + dy * step)) campaign.y += dy * step;
      final traveled = (Offset(campaign.x, campaign.y) - old).distance;
      walked += traveled;
      stepTimer += traveled;
      if (stepTimer > .8) {
        stepTimer = 0;
        sounds.add('step');
      }
      if (traveled < .001 && path.isNotEmpty) {
        path.clear();
        _repathWait = .1;
      }
      if (fast) campaign.stamina = math.max(0, campaign.stamina - 17 * dt);
    }
    if (perception) {
      campaign.stamina = math.max(0, campaign.stamina - 12 * dt);
      if (campaign.stamina == 0) perception = false;
    } else if (!effectiveRunning || length == 0) {
      campaign.stamina = math.min(100, campaign.stamina + 12 * dt);
    }
    if (campaign.has('delivered') &&
        campaign.has('news') &&
        !campaign.has('alley') &&
        campaign.x > 32 &&
        campaign.y < 30 &&
        campaign.y > 23) {
      campaign.mark('alley');
      sounds.add('alert');
    }
    if (onRoof) return;
    if (!encounterActive) return;
    encounterTime += dt;
    if (encounterTime > 3 && distance(enemyX, enemyY) > 5 && campaign.x > 40) {
      campaign.mark('resolved');
      sounds.add('door');
      return;
    }
    if (enemyStun > 0) {
      final nx = enemyX + enemyKnockX * dt, ny = enemyY + enemyKnockY * dt;
      if (canStand(nx, enemyY, enemy: true)) enemyX = nx;
      if (canStand(enemyX, ny, enemy: true)) enemyY = ny;
      enemyKnockX *= math.pow(.03, dt);
      enemyKnockY *= math.pow(.03, dt);
      return;
    }
    final ex = campaign.x - enemyX,
        ey = campaign.y - enemyY,
        dist = math.sqrt(ex * ex + ey * ey);
    if (attackWindup > 0) {
      attackWindup = math.max(0, attackWindup - dt);
      if (attackWindup == 0) {
        attackCooldown = 1.6;
        if (dist < 1.25 &&
            lineClear(Offset(enemyX, enemyY), Offset(campaign.x, campaign.y))) {
          campaign.health = math.max(0, campaign.health - 12);
          campaign.injured = true;
          beginAction('hurt', .4);
          sounds.add('hit');
        }
      }
      return;
    }
    if (dist < 1.1 &&
        attackCooldown == 0 &&
        lineClear(Offset(enemyX, enemyY), Offset(campaign.x, campaign.y))) {
      attackWindup = .65;
      return;
    }
    if (dist < 7 && dist > .8) {
      final before = Offset(enemyX, enemyY);
      final step = 1.25 * dt;
      if (canStand(enemyX + ex / dist * step, enemyY, enemy: true)) {
        enemyX += ex / dist * step;
      }
      if (canStand(enemyX, enemyY + ey / dist * step, enemy: true)) {
        enemyY += ey / dist * step;
      }
      enemyWalked += (Offset(enemyX, enemyY) - before).distance;
    }
  }

  bool push() {
    if (action != 'idle' || pushCooldown > 0 || campaign.stamina < 22) {
      return false;
    }
    campaign.stamina -= 22;
    pushCooldown = severelyHurt ? 1.35 : .8;
    beginAction('push', severelyHurt ? .95 : .65);
    return true;
  }

  bool heal() {
    if (action != 'idle' ||
        encounterActive && distance(enemyX, enemyY) < 5 ||
        campaign.bandages == 0 ||
        campaign.health >= 100 && !campaign.injured) {
      return false;
    }
    beginAction('heal', 1.6);
    return true;
  }
}
