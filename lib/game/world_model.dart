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
  window,
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
  weapon,
  neighbor,
  merchant,
  busPassenger,
  television,
  homeTelevision,
  lightSwitch,
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
  nightTorch,
  nightSupply,
  nightPanel,
  nightNeighbor,
  nightBreaker,
  nightCan,
  nightMap,
  broadcast,
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
    this.displayAt,
    this.displayHeight = 0,
  });
  final String? id;

  /// Optional raised rendering anchor for items displayed on furniture.
  final Offset? displayAt;
  final double displayHeight;
  final int floor;
  final PointKind kind;
  final double x, y;
  final String label, action;

  Place at(Offset position) => Place(
    kind,
    position.dx,
    position.dy,
    label,
    action,
    floor: floor,
    id: id,
    displayAt: displayAt,
    displayHeight: displayHeight,
  );

  String? get floatingLabel => switch (kind) {
    PointKind.apartmentDoor || PointKind.buildingDoor => null,
    _ => label,
  };
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
  const Furnishing(
    this.bounds,
    this.kind,
    this.height, {
    this.floor = 0,
    this.sprite,
    this.collidable = true,
  });
  final int floor;
  final Rect bounds;
  final String kind;
  final double height;

  /// Optional original PNG name from the approved refined apartment pack.
  final String? sprite;
  final bool collidable;
}

class Person {
  const Person(this.id, this.x, this.y, {this.floor = 0});
  final int floor;
  final String id;
  final double x, y;
}

class Vehicle {
  const Vehicle(
    this.id,
    this.position,
    this.bounds,
    this.width, {
    this.view = 0,
  });
  final String id;
  final Offset position;
  final Rect bounds;
  final double width;

  /// Front-left, front-right, side, or rear three-quarter sprite variant.
  final int view;

  Vehicle at(Offset next) {
    final delta = next - position;
    return Vehicle(id, next, bounds.shift(delta), width, view: view);
  }
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
  Offset? _vaultStart, _vaultEnd;
  Offset get playerDrawPosition => action == 'vault' && _vaultStart != null
      ? Offset.lerp(_vaultStart!, _vaultEnd!, 1 - actionTime / actionDuration)!
      : ladderBase == null
      ? Offset(campaign.x, campaign.y)
      : Offset.lerp(
          ladderBase!,
          const Offset(9.65, 22.5),
          playerElevation / 56,
        )!;
  bool get canVault {
    if (campaign.floor != 0 ||
        onRoof ||
        action != 'idle' ||
        encounterActive ||
        campaign.stamina < 12) {
      return false;
    }
    if (campaign.x < 7.0 || campaign.x > 8.0) return false;
    final y = campaign.y;
    if (!((y >= 25.2 && y <= 25.5) || (y >= 26.2 && y <= 26.7))) {
      return false;
    }
    final landingY = y < 25.65 ? 26.45 : 25.3;
    return canStand(campaign.x, y) && canStand(campaign.x, landingY);
  }

  bool vault() {
    if (!canVault) return false;
    _vaultStart = Offset(campaign.x, campaign.y);
    _vaultEnd = Offset(campaign.x, campaign.y < 25.65 ? 26.45 : 25.3);
    facingX = 0;
    facingY = (_vaultEnd!.dy - _vaultStart!.dy).sign;
    campaign.stamina -= 12;
    guarding = false;
    endAim();
    beginAction('vault', .8);
    return true;
  }

  bool climbLadder() {
    if (action != 'idle' ||
        encounterActive ||
        campaign.floor != 0 ||
        distance(10.7, 22.5) > 1.85) {
      return false;
    }
    _descendingLadder = onRoof;
    ladderBase ??= Offset(campaign.x, campaign.y);
    beginAction('climb', 3.2);
    return true;
  }

  static const width = 56, height = 44, radius = .22;
  static const shopBounds = Rect.fromLTRB(24, 17, 32, 24);
  static const busStop = Offset(42.5, 29.5);
  static const busBay = Offset(45.3, 31.2);
  bool get inShop =>
      campaign.floor == 0 &&
      shopBounds.contains(Offset(campaign.x, campaign.y));
  bool get indoors => inResidence || inShop;
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
    Vehicle(
      'van',
      Offset(35, 28),
      Rect.fromLTRB(33.4, 27.2, 36.6, 28.7),
      155,
      view: 1,
    ),
    Vehicle(
      'bus',
      Offset(47, 32),
      Rect.fromLTRB(44.2, 30.7, 49.6, 32.7),
      245,
      view: 2,
    ),
  ];
  double _busWaitTime = 0;
  double _busArrivalProgress = 1;
  static const furniture = [
    // Apartment 203 follows the approved floorplan: bedroom at the back,
    // living room to the left, kitchen/dining to the right, bathroom at front.
    Furnishing(
      Rect.fromLTRB(2.35, 2.55, 4.75, 4.55),
      'bed',
      40,
      floor: 2,
      sprite: 'cama_parede_A',
    ),
    Furnishing(
      Rect.fromLTRB(5.8, 2.55, 6.85, 4.05),
      'wardrobe',
      48,
      floor: 2,
      sprite: 'guarda_roupa_B',
    ),
    Furnishing(
      Rect.fromLTRB(5.0, 3.55, 5.55, 4.15),
      'bedside',
      28,
      floor: 2,
      sprite: 'mesa_cabeceira_A',
      collidable: false,
    ),
    Furnishing(
      Rect.fromLTRB(6.9, 2.5, 7.7, 3.35),
      'desk',
      33,
      floor: 2,
      sprite: 'escrivaninha_A',
    ),
    Furnishing(
      Rect.fromLTRB(7.0, 3.4, 7.6, 4.15),
      'chair',
      26,
      floor: 2,
      sprite: 'cadeira_B',
    ),
    Furnishing(
      Rect.fromLTRB(2.45, 5.8, 4.8, 7.05),
      'sofa',
      42,
      floor: 2,
      sprite: 'sofa_parede_A',
    ),
    Furnishing(
      Rect.fromLTRB(4.85, 7.2, 6.25, 8.2),
      'coffee',
      25,
      floor: 2,
      sprite: 'mesa_centro_B',
    ),
    Furnishing(
      Rect.fromLTRB(2.45, 8.05, 4.5, 9.35),
      'television',
      40,
      floor: 2,
      sprite: 'rack_tv_A',
    ),
    Furnishing(
      Rect.fromLTRB(2.35, 4.75, 2.9, 5.55),
      'lamp',
      31,
      floor: 2,
      sprite: 'abajur_aceso_A',
      collidable: false,
    ),
    Furnishing(
      Rect.fromLTRB(4.9, 4.8, 5.4, 5.5),
      'plant',
      32,
      floor: 2,
      sprite: 'planta_B',
      collidable: false,
    ),
    // Kitchen counters line the right wall; the middle remains a walk path.
    Furnishing(
      Rect.fromLTRB(9.8, 2.3, 11.7, 3.2),
      'kitchen',
      38,
      floor: 2,
      sprite: 'balcao_cuba_A',
    ),
    Furnishing(
      Rect.fromLTRB(8.35, 3.15, 9.15, 3.95),
      'stove',
      34,
      floor: 2,
      sprite: 'fogao_B',
    ),
    Furnishing(
      Rect.fromLTRB(11.0, 3.45, 11.8, 4.55),
      'fridge',
      44,
      floor: 2,
      sprite: 'geladeira_fechada_A',
    ),
    Furnishing(
      Rect.fromLTRB(8.35, 2.3, 9.55, 3.0),
      'wall_cabinet',
      42,
      floor: 2,
      sprite: 'armario_suspenso_B',
      collidable: false,
    ),
    Furnishing(
      Rect.fromLTRB(9.45, 5.3, 10.55, 6.1),
      'dining_table',
      38,
      floor: 2,
      sprite: 'mesa_jantar_A',
    ),
    Furnishing(
      Rect.fromLTRB(10.6, 5.35, 11.0, 5.75),
      'chair',
      26,
      floor: 2,
      sprite: 'cadeira_A',
    ),
    Furnishing(
      Rect.fromLTRB(9.25, 6.25, 9.7, 6.7),
      'chair',
      26,
      floor: 2,
      sprite: 'cadeira_B',
    ),
    Furnishing(Rect.fromLTRB(24.5, 17.7, 26, 20.5), 'shelf', 48),
    Furnishing(Rect.fromLTRB(29.7, 17.8, 31.4, 19.2), 'fridge', 57),
    Furnishing(Rect.fromLTRB(30, 21, 31.5, 22.7), 'counter', 23),
    // Street furniture is set on the sidewalks, clear of both traffic and
    // the walkable route through the block.
    Furnishing(Rect.fromLTRB(17.4, 24.4, 18.6, 25.2), 'bench', 18),
    Furnishing(Rect.fromLTRB(22.4, 31.2, 23.6, 32), 'bench', 18),
    Furnishing(Rect.fromLTRB(38.8, 23, 42, 24.5), 'bus_shelter', 0),
    Furnishing(Rect.fromLTRB(42.5, 28, 42.8, 28.4), 'bus_stop_sign', 0),
    Furnishing(Rect.fromLTRB(11.4, 24.2, 12.4, 25), 'street_tree', 76),
    Furnishing(Rect.fromLTRB(31.8, 31.2, 32.8, 32), 'street_tree', 76),
    Furnishing(Rect.fromLTRB(40.5, 31.2, 41.5, 32), 'street_tree', 76),
    Furnishing(
      Rect.fromLTRB(7.65, 8.1, 8.4, 8.8),
      'basin',
      30,
      floor: 2,
      sprite: 'gabinete_pia_A',
    ),
    Furnishing(
      Rect.fromLTRB(8.85, 9.0, 9.45, 9.55),
      'toilet',
      25,
      floor: 2,
      sprite: 'vaso_sanitario_B',
    ),
    Furnishing(
      Rect.fromLTRB(10.35, 7.65, 11.65, 9.15),
      'shower',
      38,
      floor: 2,
      sprite: 'box_chuveiro_A',
    ),
    Furnishing(
      Rect.fromLTRB(9.4, 8.1, 9.95, 8.65),
      'bathmat',
      15,
      floor: 2,
      sprite: 'tapete_banheiro_A',
      collidable: false,
    ),
    Furnishing(
      Rect.fromLTRB(9.2, 7.55, 9.75, 8.0),
      'bathroom_mirror',
      38,
      floor: 2,
      sprite: 'espelho_A',
      collidable: false,
    ),
    Furnishing(
      Rect.fromLTRB(11.15, 9.25, 11.75, 9.8),
      'laundry',
      21,
      floor: 2,
      sprite: 'cesto_roupa_B',
    ),
    Furnishing(
      Rect.fromLTRB(4.8, 8.4, 5.6, 9.4),
      'bookcase',
      35,
      floor: 2,
      sprite: 'estante_A',
    ),
  ];
  List<Person> get _allPeople => campaign.inChapterTwo
      ? [
          if (!campaign.has('chapter2_rescue'))
            const Person('ines', 15, 9, floor: 2),
          if (campaign.has('chapter2_alarm_off') && !enemyDefeated)
            Person('bruno', enemyX, enemyY),
        ]
      : [
          Person('ines', inesX, 11.5, floor: 2),
          if (campaign.has('alley') && !campaign.has('resolved'))
            const Person('orlando', 36, 25)
          else
            const Person('orlando', 28, 22),
          if (campaign.busReady && campaign.has('bus_arrived'))
            Person('nestor', busBay.dx - 1, busBay.dy - .7),
          const Person('bia', 40.5, 24.6),
          if (campaign.has('resolved') && !campaign.has('enemy_defeated'))
            const Person('davi', 38, 25),
        ];
  Iterable<Block> get visibleBlocks {
    final unit = ResidentialLayout.unitAt(
      campaign.floor,
      Offset(campaign.x, campaign.y),
    );
    return blocks.where(
      (b) =>
          b.floor == campaign.floor &&
          (!b.interior || unit == null || b.bounds == unit),
    );
  }

  Iterable<Furnishing> get visibleFurniture {
    final unit = ResidentialLayout.unitAt(
      campaign.floor,
      Offset(campaign.x, campaign.y),
    );
    return furniture.where((f) {
      if (f.floor != campaign.floor) return false;
      if (f.floor == 0 && shopBounds.contains(f.bounds.center) && !inShop) {
        return false;
      }
      final furnishingUnit = ResidentialLayout.unitAt(f.floor, f.bounds.center);
      return unit == null ? furnishingUnit == null : furnishingUnit == unit;
    });
  }

  Iterable<Vehicle> get visibleVehicles {
    if (campaign.floor != 0) return const <Vehicle>[];
    return vehicles
        .where(
          (v) =>
              v.id != 'bus' || campaign.busReady && campaign.has('bus_arrived'),
        )
        .map(
          (v) => v.id == 'bus'
              ? v.at(Offset.lerp(v.position, busBay, _busArrivalProgress)!)
              : v,
        );
  }

  List<Person> get people =>
      _allPeople.where((p) => p.floor == campaign.floor).toList();
  List<Person> get visiblePeople {
    final unit = ResidentialLayout.unitAt(
      campaign.floor,
      Offset(campaign.x, campaign.y),
    );
    return people.where((person) {
      if (person.floor == 0 &&
          shopBounds.contains(Offset(person.x, person.y)) &&
          !inShop) {
        return false;
      }
      if (unit == null) return true;
      return unit.contains(Offset(person.x, person.y));
    }).toList();
  }

  Person get merchant => _allPeople.firstWhere((p) => p.id == 'orlando');
  List<Place> get places {
    final unit = ResidentialLayout.unitAt(
      campaign.floor,
      Offset(campaign.x, campaign.y),
    );
    final availablePlaces = allPlaces.map((place) {
      if (place.kind != PointKind.apartmentDoor || campaign.floor != 2) {
        return place;
      }
      final door = ResidentialLayout.door('203');
      return place.at(unit == null ? door.outside : door.inside);
    });
    return availablePlaces.where((p) {
      if (p.floor != campaign.floor) return false;
      final position = Offset(p.x, p.y);
      if (unit == null) {
        return campaign.floor == 0 ||
            ResidentialLayout.corridor.contains(position);
      }
      return unit.contains(position) ||
          p.kind == PointKind.apartmentDoor &&
              unit == ResidentialLayout.apartment203 ||
          p.id == '203' && unit == ResidentialLayout.apartment203 ||
          p.id == '202' && unit == ResidentialLayout.apartment202 ||
          p.id == '201' && unit == ResidentialLayout.apartment201 ||
          p.id == '103' && unit == ResidentialLayout.apartment103 ||
          p.id == '102' && unit == ResidentialLayout.apartment102 ||
          p.id == '101' && unit == ResidentialLayout.apartment101;
    }).toList();
  }

  double inesX = 14;
  List<Place> get allPlaces => campaign.inChapterTwo
      ? _nightPlaces
      : [
          const Place(
            PointKind.broadcast,
            22.4,
            25,
            'Telão público',
            'Ler transmissão',
          ),
          for (final window in ResidentialLayout.windows.where(
            (window) => window.floor == campaign.floor,
          ))
            Place(
              PointKind.window,
              window.center.dx,
              window.center.dy,
              'Janela ${window.id}',
              windowIsOpen(window.id) ? 'Fechar janela' : 'Abrir janela',
              floor: window.floor,
              id: window.id,
            ),
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
          const Place(PointKind.sofa, 5.05, 6.42, 'Sofá', 'Sentar', floor: 2),
          const Place(
            PointKind.chair,
            7.85,
            4.35,
            'Cadeira',
            'Sentar',
            floor: 2,
          ),
          const Place(
            PointKind.wardrobe,
            5.25,
            3.3,
            'Guarda-roupa',
            'Abrir armário',
            floor: 2,
          ),
          const Place(
            PointKind.refrigerator,
            11.5,
            5.2,
            'Geladeira',
            'Abrir geladeira',
            floor: 2,
          ),
          const Place(
            PointKind.notebook,
            6.35,
            4.35,
            'Notebook',
            'Usar notebook',
            floor: 2,
          ),
          const Place(
            PointKind.homeTelevision,
            4.95,
            8.2,
            'Televisão',
            'Ligar TV',
            floor: 2,
          ),
          const Place(
            PointKind.lightSwitch,
            6.5,
            9.1,
            'Interruptor',
            'Apagar luzes',
            floor: 2,
          ),
          const Place(
            PointKind.bathroom,
            9.45,
            8.05,
            'Banheiro',
            'Examinar',
            floor: 2,
          ),
          if (campaign.floor > 0)
            Place(
              PointKind.noticeboard,
              18.5,
              11,
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
          const Place(
            PointKind.stairsUp,
            4.7,
            14.5,
            'Escada · 1º andar',
            'Subir',
          ),
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
          const Place(
            PointKind.elevator,
            3.8,
            14.3,
            'Elevador',
            'Chamar',
            floor: 2,
          ),
          const Place(
            PointKind.phone,
            5.05,
            4.15,
            'Celular',
            'Ler mensagem',
            floor: 2,
          ),
          if (!campaign.has('key'))
            const Place(
              PointKind.key,
              5.7,
              4.5,
              'Chave de casa',
              'Pegar chave',
              floor: 2,
              displayAt: Offset(5.3, 3.85),
              displayHeight: 22,
            ),
          if (!campaign.has('adapter'))
            const Place(
              PointKind.adapter,
              9.55,
              4.25,
              'Adaptador',
              'Recolher',
              floor: 2,
              displayAt: Offset(10.65, 2.7),
              displayHeight: 24,
            ),
          const Place(
            PointKind.bed,
            5.0,
            2.4,
            'Cama · salvar o dia',
            'Descansar',
            floor: 2,
          ),
          Place(
            PointKind.neighbor,
            inesX,
            11.5,
            'Dona Celina · 202',
            'Ajudar',
            floor: 2,
          ),
          Place(
            PointKind.merchant,
            merchant.x,
            merchant.y,
            'Orlando',
            'Conversar',
          ),
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
          if (!campaign.has('weapon') && !campaign.has('resolved'))
            const Place(
              PointKind.weapon,
              31.7,
              26.5,
              'Cano de madeira',
              'Pegar',
            ),
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
          const Place(
            PointKind.bus,
            43.5,
            29.5,
            'Ponto · linha 203',
            'Aguardar ônibus',
          ),
          if (!campaign.has('answered_bia'))
            const Place(
              PointKind.busPassenger,
              40.5,
              24.6,
              'Bia · abrigo da linha 203',
              'Ler mensagem',
            ),
          const Place(
            PointKind.crossing,
            48.5,
            28,
            'Cruzamento',
            'Observar a rua',
          ),
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
  List<Place> get _nightPlaces => [
    const Place(
      PointKind.broadcast,
      22.4,
      25,
      'Telão público',
      'Ler transmissão',
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
      PointKind.buildingDoor,
      7,
      16,
      'Entrada residencial',
      'Abrir e passar',
      id: 'entrada',
    ),
    const Place(
      PointKind.stairsDown,
      10,
      14.5,
      'Escada · 1º andar',
      'Descer',
      floor: 2,
    ),
    const Place(
      PointKind.stairsDown,
      10,
      14.5,
      'Escada · térreo',
      'Descer',
      floor: 1,
    ),
    const Place(PointKind.stairsUp, 4.7, 14.5, 'Escada · 1º andar', 'Subir'),
    const Place(
      PointKind.stairsUp,
      4.7,
      14.5,
      'Escada · 2º andar',
      'Subir',
      floor: 1,
    ),
    const Place(
      PointKind.elevator,
      3.8,
      14.3,
      'Elevador sem energia',
      'Examinar',
      floor: 2,
    ),
    const Place(PointKind.phone, 6.5, 4, 'Celular', 'Ler mensagem', floor: 2),
    const Place(
      PointKind.bed,
      4.3,
      5.5,
      'Cama · checkpoint',
      'Salvar',
      floor: 2,
    ),
    if (!campaign.has('chapter2_torch'))
      const Place(
        PointKind.nightTorch,
        6,
        5.8,
        'Lanterna',
        'Recolher',
        floor: 2,
      ),
    if (!campaign.has('chapter2_supply'))
      const Place(
        PointKind.nightSupply,
        5.5,
        5.5,
        'Kit de emergência',
        'Recolher atadura',
        floor: 2,
      ),
    const Place(
      PointKind.nightPanel,
      18.5,
      11,
      'Quadro de manutenção',
      'Ler registro',
      floor: 2,
    ),
    if (!campaign.has('chapter2_rescue'))
      const Place(
        PointKind.nightNeighbor,
        15,
        10.5,
        'Vizinha · 202',
        'Ajudar com atadura',
        floor: 2,
      ),
    const Place(
      PointKind.nightBreaker,
      16.6,
      13.3,
      'Disjuntor do alarme',
      'Desligar',
    ),
    const Place(
      PointKind.nightCan,
      22,
      15,
      'Lata na garagem',
      'Lançar distração',
    ),
    const Place(PointKind.gate, 41.7, 26.2, 'Portão de serviço', 'Usar chave'),
    const Place(
      PointKind.nightMap,
      42.5,
      24.5,
      'Posto de serviço · mapa',
      'Recolher mapa',
    ),
  ];
  double simulationTime = 0;
  double get dogX => animals.dog.position.dx;
  double get dogY => animals.dog.position.dy;
  bool get dogMoving => animals.dog.moving;
  bool recoveringBreath = false;
  bool aiming = false, sprintHeld = false, guarding = false;
  Offset? aimTarget;
  void aimAt(double x, double y) {
    aiming = true;
    aimTarget = Offset(x, y);
    final delta = aimTarget! - Offset(campaign.x, campaign.y);
    if (delta.distance > .01) {
      facingX = delta.dx / delta.distance;
      facingY = delta.dy / delta.distance;
    }
  }

  void endAim() {
    aiming = false;
    aimTarget = null;
  }

  bool get severelyHurt => campaign.health <= 25;
  bool get effectiveRunning =>
      (running || sprintHeld) &&
      !aiming &&
      !guarding &&
      !recoveringBreath &&
      !severelyHurt &&
      campaign.stamina > 5;
  double enemyWalked = 0;
  static const double enemyMaxHealth = 100;
  double playerAttackCooldown = 0;
  double get enemyHealth =>
      campaign.inChapterTwo ? campaign.nightEnemyHealth : campaign.enemyHealth;
  String get enemyIdentity => campaign.inChapterTwo ? 'bruno' : 'davi';
  bool get enemyDefeated => campaign.has(
    campaign.inChapterTwo ? 'chapter2_enemy_down' : 'enemy_defeated',
  );
  Offset get enemyBodyPosition => Offset(enemyX, enemyY);
  bool get attackAvailable =>
      encounterActive &&
      campaign.has('weapon') &&
      campaign.weaponEquipped &&
      action == 'idle' &&
      playerAttackCooldown <= 0 &&
      campaign.stamina >= 18;
  bool get canAttack {
    if (!attackAvailable) return false;
    final dx = enemyX - campaign.x, dy = enemyY - campaign.y;
    final range = math.sqrt(dx * dx + dy * dy);
    return range > .01 &&
        range <= 1.9 &&
        (dx * facingX + dy * facingY) / range > .35 &&
        lineClear(Offset(campaign.x, campaign.y), Offset(enemyX, enemyY));
  }

  /// Mobile melee is a contextual action: when Davi is in reach, face him before
  /// the strike. Ranged/manual aiming keeps its explicit direction.
  bool faceEnemyForMelee() {
    if (!encounterActive) return false;
    final dx = enemyX - campaign.x, dy = enemyY - campaign.y;
    final range = math.sqrt(dx * dx + dy * dy);
    if (range <= .01 || range > 1.9) return false;
    final direction = Offset(dx / range, dy / range);
    facingX = direction.dx;
    facingY = direction.dy;
    return canAttack;
  }

  final Map<String, Offset> _npcPrevious = {};
  final Map<String, double> _npcTraveled = {};
  final Map<String, Offset> _npcFacing = {};
  final Set<String> _movingNpcs = {};
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
      campaign.floor == 0 &&
      (campaign.inChapterTwo
          ? campaign.x > 15 &&
                campaign.y < 17 &&
                !campaign.has('chapter2_alarm_off') &&
                !enemyDefeated
          : campaign.has('alley') && !campaign.has('resolved'));
  bool get moving =>
      action == 'idle' && (inputX != 0 || inputY != 0 || path.isNotEmpty);
  double distance(double x, double y) =>
      math.sqrt(math.pow(x - campaign.x, 2) + math.pow(y - campaign.y, 2));
  String? resting;
  Offset? restAnchor;
  bool get inResidence =>
      campaign.floor > 0 ||
      ResidentialLayout.corridor.contains(Offset(campaign.x, campaign.y));
  String actionFor(Place place) => switch (place.kind) {
    PointKind.homeTelevision =>
      campaign.has('home_tv_on') ? 'Desligar TV' : 'Ligar TV',
    PointKind.lightSwitch =>
      campaign.has('home_lights_off') ? 'Acender luzes' : 'Apagar luzes',
    PointKind.buildingDoor when place.id == 'banheiro' =>
      doorIsOpen('banheiro') ? 'Fechar porta' : 'Abrir porta',
    _ => place.action,
  };
  bool doorIsOpen(String id) =>
      id == '203' ? doorOpen : campaign.openDoors.contains(id);
  bool windowIsOpen(String id) =>
      campaign.openWindows.contains(id) || campaign.brokenWindows.contains(id);
  bool changeWindow(String id, String action) {
    final matches = ResidentialLayout.windows.where(
      (w) => w.id == id && w.floor == campaign.floor,
    );
    if (matches.isEmpty) return false;
    final w = matches.first;
    if (distance(w.center.dx, w.center.dy) > 1.85) return false;
    switch (action) {
      case 'toggle':
        if (campaign.brokenWindows.contains(id)) return false;
        return toggleWindow(id);
      case 'curtain':
        if (campaign.removedCurtains.contains(id)) return false;
        if (!campaign.closedCurtains.remove(id)) {
          campaign.closedCurtains.add(id);
        }
      case 'remove':
        if (!campaign.removedCurtains.add(id)) return false;
        campaign.closedCurtains.remove(id);
      case 'break':
        if (!campaign.weaponEquipped ||
            !campaign.has('weapon') ||
            campaign.stamina < 10 ||
            !campaign.brokenWindows.add(id)) {
          return false;
        }
        campaign.stamina -= 10;
        campaign.openWindows.add(id);
      default:
        return false;
    }
    _geometry.clear();
    return true;
  }

  bool setWindowOpen(String id, bool open) {
    if (!open && campaign.brokenWindows.contains(id)) return false;
    final window = ResidentialLayout.windows.firstWhere(
      (candidate) => candidate.id == id && candidate.floor == campaign.floor,
    );
    if (!open) {
      final body = Rect.fromCircle(
        center: Offset(campaign.x, campaign.y),
        radius: radius,
      );
      if (body.overlaps(window.collider)) return false;
      campaign.openWindows.remove(id);
    } else {
      campaign.openWindows.add(id);
    }
    _geometry.clear();
    return true;
  }

  bool toggleWindow(String id) => setWindowOpen(id, !windowIsOpen(id));
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
    if (campaign.floor == 0) yield const Rect.fromLTRB(21.9, 24.1, 22.9, 24.5);
    yield* ResidentialLayout.partitions(campaign.floor);
    for (final window in ResidentialLayout.windows.where(
      (window) => window.floor == campaign.floor && !windowIsOpen(window.id),
    )) {
      yield window.collider;
    }
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
    // Hiding an interior must never remove its physical obstacles.
    yield* furniture
        .where((f) => f.floor == campaign.floor && f.collidable)
        .map((f) => f.bounds);
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
    if (floor == 0 && (at - Offset(campaign.x, campaign.y)).distance < .6) {
      return false;
    }
    if (_allPeople
        .where((p) => p.floor == 0)
        .any((p) => (at - Offset(p.x, p.y)).distance < .55)) {
      return false;
    }
    return !animals.actors.any(
      (a) => a.id != id && a.onGround && (a.position - at).distance < .42,
    );
  }

  bool canStand(double x, double y, {bool enemy = false}) {
    if (!isOpen(x, y)) return false;
    if (campaign.floor == 0 &&
        animals.actors.any(
          (a) => a.onGround && (Offset(x, y) - a.position).distance < .40,
        )) {
      return false;
    }
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
    var bestDistance = double.infinity;
    bool isPortal(PointKind kind) =>
        kind == PointKind.apartmentDoor ||
        kind == PointKind.buildingDoor ||
        kind == PointKind.window;
    for (final p in places) {
      final next = distance(p.x, p.y);
      final seated = p.kind == PointKind.chair || p.kind == PointKind.sofa;
      final pickup =
          p.kind == PointKind.key ||
          p.kind == PointKind.adapter ||
          p.kind == PointKind.weapon;
      final portal = isPortal(p.kind);
      final range = portal
          ? 1.85
          : seated || pickup
          ? .85
          : 1.35;
      // A nearby portal gets the contextual action while Caio is at its
      // threshold, even if a collectible lies a few pixels closer. This
      // prevents a key or adapter from stealing the door/window interaction.
      final portalAtThreshold = portal && next < 1.1;
      final nearestPortalAtThreshold =
          nearest != null && isPortal(nearest.kind) && bestDistance < 1.1;
      if (portalAtThreshold && !nearestPortalAtThreshold) {
        if (next < range &&
            (p.kind == PointKind.apartmentDoor ||
                p.kind == PointKind.buildingDoor ||
                p.kind == PointKind.window ||
                interactionClear(
                  Offset(campaign.x, campaign.y),
                  Offset(p.x, p.y),
                ))) {
          nearest = p;
          bestDistance = next;
        }
        continue;
      }
      if (nearestPortalAtThreshold && !portalAtThreshold) continue;
      if (next < range &&
          next < bestDistance &&
          (p.kind == PointKind.apartmentDoor ||
              p.kind == PointKind.buildingDoor ||
              p.kind == PointKind.window ||
              interactionClear(
                Offset(campaign.x, campaign.y),
                Offset(p.x, p.y),
              ))) {
        bestDistance = next;
        nearest = p;
      }
    }
    return nearest;
  }

  bool shouldShowPlaceLabel(Place place) {
    if (perception) return true;
    if (place.kind == PointKind.chair || place.kind == PointKind.sofa) {
      return distance(place.x, place.y) <= .85;
    }
    return true;
  }

  void restore(Campaign value) {
    campaign = value;
    _busWaitTime = 0;
    _busArrivalProgress = value.has('bus_arrived') ? 1 : 0;
    _destination = null;
    _geometry.clear();
    playerElevation = 0;
    onRoof = false;
    ladderBase = null;
    _vaultStart = _vaultEnd = null;
    resting = null;
    restAnchor = null;
    doorOpen = false;
    inputX = inputY = 0;
    path.clear();
    final downed = value.downedEnemyPosition;
    enemyX = downed?.dx ?? (value.inChapterTwo ? 22 : 38);
    enemyY = downed?.dy ?? (value.inChapterTwo ? 13.5 : 26.5);
    enemyStun = attackCooldown = pushCooldown = attackWindup = encounterTime =
        0;
    enemyKnockX = enemyKnockY = 0;
    playerAttackCooldown = 0;
    action = 'idle';
    simulationTime = 0;
    animals.reset();
    atmosphere.restore(night: value.has('night'));
    gateClosed = value.inChapterTwo
        ? !value.has('chapter2_shortcut')
        : value.has('resolved');
    if (value.inChapterTwo) atmosphere.minutes = 118;
    recoveringBreath = value.stamina < 15;
    enemyWalked = 0;
    _npcPrevious.clear();
    _npcTraveled.clear();
    _npcFacing.clear();
    _movingNpcs.clear();
    actionTime = 0;
    perception = running = false;
    sprintHeld = false;
    guarding = false;
    endAim();
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
    final actorPosition = Offset(campaign.x, campaign.y);
    final startCenter = Offset(start.$1 + .5, start.$2 + .5);
    final centerStartIsReachable =
        canStand(startCenter.dx, startCenter.dy) &&
        canTravel(actorPosition, startCenter);
    final routeStart = centerStartIsReachable ? startCenter : actorPosition;
    final queue = Queue<(int, int)>()..add(start);
    final previous = <(int, int), (int, int)?>{start: null};
    while (queue.isNotEmpty) {
      final here = queue.removeFirst();
      if (here == goal) break;
      for (final s in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final n = (here.$1 + s.$1, here.$2 + s.$2);
        final from = here == start
            ? routeStart
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
      ..addAll(
        centerStartIsReachable && start != goal ? [startCenter] : const [],
      )
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
    if (campaign.floor == 0 && campaign.busReady && !campaign.has('bus')) {
      if (!campaign.has('bus_arrived') &&
          (Offset(campaign.x, campaign.y) - busStop).distance <= 1.7) {
        _busWaitTime += dt;
        if (_busWaitTime >= 2.5) {
          campaign.mark('bus_arrived');
          _busArrivalProgress = 0;
          sounds.add('engine');
        }
      } else if (!campaign.has('bus_arrived')) {
        _busWaitTime = 0;
      }
      if (campaign.has('bus_arrived')) {
        _busArrivalProgress = math.min(1, _busArrivalProgress + dt * .7);
      }
    }
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
    if (campaign.inChapterTwo) {
      atmosphere.minutes = 118 + simulationTime * .2;
      atmosphere.nightBlend = 1;
    } else {
      atmosphere.update(dt, storyNight: campaign.has('night'));
    }
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
    playerAttackCooldown = math.max(0, playerAttackCooldown - dt);
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
      if (action == 'vault') {
        final progress = 1 - actionTime / actionDuration;
        playerElevation = math.sin(progress * math.pi) * 32;
        if (actionTime == 0) {
          campaign.x = _vaultEnd!.dx;
          campaign.y = _vaultEnd!.dy;
          _vaultStart = _vaultEnd = null;
          playerElevation = 0;
          sounds.add('step');
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
        if (action == 'attack') _resolvePlayerAttack();
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
      if (aiming && aimTarget != null) {
        aimAt(aimTarget!.dx, aimTarget!.dy);
      } else if (!guarding) {
        facingX = dx;
        facingY = dy;
      }
      final fast = effectiveRunning;
      final limp = severelyHurt
          ? .55
          : campaign.injured
          ? .85
          : recoveringBreath
          ? .8
          : 1.0;
      final step =
          (fast ? 4.3 : 2.65) *
          limp *
          (guarding
              ? .45
              : aiming
              ? .52
              : 1) *
          dt;
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
    } else if (guarding) {
      campaign.stamina = math.max(0, campaign.stamina - dt * 3);
    } else if (!effectiveRunning || length == 0) {
      campaign.stamina = math.min(100, campaign.stamina + 12 * dt);
    }
    if (!campaign.inChapterTwo &&
        campaign.has('delivered') &&
        campaign.has('news') &&
        !campaign.has('alley') &&
        campaign.x > 32 &&
        campaign.y < 30 &&
        campaign.y > 23) {
      campaign.mark('alley');
      sounds.add('alert');
    }
    if (campaign.inChapterTwo &&
        campaign.floor == 0 &&
        campaign.x > 15 &&
        campaign.y < 17) {
      campaign.mark('chapter2_garage');
    }
    if (onRoof) return;
    if (!encounterActive) return;
    encounterTime += dt;
    if (!campaign.inChapterTwo &&
        encounterTime > 3 &&
        distance(enemyX, enemyY) > 5 &&
        campaign.x > 40) {
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
          final blocked =
              guarding &&
              action == 'idle' &&
              campaign.stamina >= 12 &&
              (-ex * facingX - ey * facingY) / dist > .35;
          campaign.health = math.max(0, campaign.health - (blocked ? 3 : 12));
          if (blocked) {
            campaign.stamina -= 12;
            beginAction('block', .3);
            sounds.add('push');
          } else {
            campaign.injured = true;
            beginAction('hurt', .4);
            sounds.add('hit');
          }
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
    if (campaign.inChapterTwo && dist > 2.5) {
      final target = campaign.has('chapter2_lured')
          ? const Offset(23.5, 11.5)
          : const Offset(21.5, 13.8);
      final delta = target - Offset(enemyX, enemyY);
      if (delta.distance > .15) {
        final step = delta / delta.distance * dt;
        if (canStand(enemyX + step.dx, enemyY, enemy: true)) enemyX += step.dx;
        if (canStand(enemyX, enemyY + step.dy, enemy: true)) enemyY += step.dy;
        enemyWalked += step.distance;
      }
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

  bool attack() {
    if (!attackAvailable || !aiming && !canAttack) return false;
    campaign.stamina -= 18;
    guarding = false;
    playerAttackCooldown = .55;
    beginAction('attack', .72);
    return true;
  }

  void _resolvePlayerAttack() {
    final dx = enemyX - campaign.x, dy = enemyY - campaign.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    final facing = distance <= .01
        ? 0.0
        : (dx * facingX + dy * facingY) / distance;
    if (!encounterActive ||
        !campaign.has('weapon') ||
        distance > 1.9 ||
        facing <= .35 ||
        !lineClear(Offset(campaign.x, campaign.y), Offset(enemyX, enemyY))) {
      sounds.add('swing');
      return;
    }

    final health = math.max(0.0, enemyHealth - (severelyHurt ? 20 : 25));
    if (campaign.inChapterTwo) {
      campaign.nightEnemyHealth = health;
    } else {
      campaign.enemyHealth = health;
    }
    enemyStun = 1.2;
    attackWindup = 0;
    enemyKnockX = enemyKnockY = 0;
    sounds.add('hit');
    if (enemyHealth == 0) {
      campaign.rememberDownedEnemy(Offset(enemyX, enemyY));
      if (campaign.inChapterTwo) {
        campaign.mark('chapter2_enemy_down');
      } else {
        campaign.mark('enemy_defeated');
        campaign.mark('resolved');
      }
      enemyStun = 5;
    }
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
