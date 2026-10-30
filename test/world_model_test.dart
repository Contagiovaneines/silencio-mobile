import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/game/sprite_facing.dart';
import 'package:silencio/models/campaign.dart';

void main() {
  test('diagonal speed normalized and facing survives releasing input', () {
    final a = WorldModel(
          Campaign()
            ..floor = 0
            ..x = 20
            ..y = 20,
        ),
        b = WorldModel(
          Campaign()
            ..floor = 0
            ..x = 20
            ..y = 20,
        );
    a.setInput(1, 0);
    b.setInput(1, 1);
    for (var i = 0; i < 60; i++) {
      a.update(1 / 60);
      b.update(1 / 60);
    }
    expect(
      (Offset(a.campaign.x - 20, a.campaign.y - 20)).distance,
      closeTo((Offset(b.campaign.x - 20, b.campaign.y - 20)).distance, .001),
    );
    b.setInput(0, 0);
    b.update(.1);
    expect(b.facingX, closeTo(.7071, .001));
  });
  test(
    'Bia waits at the stop and Nando appears only beside the arriving bus',
    () {
      final campaign = Campaign()
        ..floor = 0
        ..x = 34
        ..y = 28;
      final world = WorldModel(campaign);

      expect(
        world.people.map((person) => person.id),
        isNot(contains('nestor')),
      );
      expect(
        world.people.map((person) => person.id),
        isNot(contains('marina')),
      );
      expect(world.people.map((person) => person.id), contains('bia'));

      campaign.events.addAll([
        'delivered',
        'news',
        'resolved',
        'pulse',
        'night',
        'bus_arrived',
      ]);
      final nando = world.people.singleWhere((person) => person.id == 'nestor');
      final bus = world.visibleVehicles.singleWhere(
        (vehicle) => vehicle.id == 'bus',
      );
      expect(bus.bounds.inflate(.8).contains(Offset(nando.x, nando.y)), isTrue);
    },
  );

  test('Bia waits at the line 203 stop, not as a street-wandering NPC', () {
    final campaign = Campaign()
      ..floor = 0
      ..x = 48
      ..y = 28;
    final world = WorldModel(campaign);

    expect(world.people.map((person) => person.id), contains('bia'));
    campaign.mark('pulse');
    expect(world.people.map((person) => person.id), contains('bia'));
    expect(world.people.map((person) => person.id), isNot(contains('marina')));
    expect(world.people.map((person) => person.id), isNot(contains('nestor')));
  });

  test(
    'bus stop shelter and sign have collision footprints beside the route',
    () {
      final campaign = Campaign()
        ..floor = 0
        ..x = 43.5
        ..y = 29.5;
      final world = WorldModel(campaign);
      final shelter = world.visibleFurniture.singleWhere(
        (f) => f.kind == 'bus_shelter',
      );
      final sign = world.visibleFurniture.singleWhere(
        (f) => f.kind == 'bus_stop_sign',
      );

      expect(
        world.canStand(shelter.bounds.center.dx, shelter.bounds.center.dy),
        isFalse,
      );
      expect(
        world.canStand(sign.bounds.center.dx, sign.bounds.center.dy),
        isFalse,
      );
      expect(
        world.canStand(WorldModel.busStop.dx, WorldModel.busStop.dy),
        isTrue,
      );
    },
  );

  test('street dressing stays on sidewalks and keeps the road lane clear', () {
    final world = WorldModel(Campaign()..floor = 0);
    final dressing = world.visibleFurniture.where(
      (f) =>
          f.kind == 'bench' ||
          f.kind == 'bus_shelter' ||
          f.kind == 'street_tree' ||
          f.kind == 'street_tree_autumn',
    );

    expect(dressing, hasLength(6));
    for (final prop in dressing) {
      expect(
        prop.bounds.bottom <= 26 || prop.bounds.top >= 31,
        isTrue,
        reason: '${prop.kind} must stay clear of the road surface.',
      );
    }
    expect(
      world.canStand(WorldModel.busStop.dx, WorldModel.busStop.dy),
      isTrue,
    );
  });

  test(
    'passive furniture labels require close range but stay interactable',
    () {
      final campaign = Campaign();
      final world = WorldModel(campaign);
      final chair = world.allPlaces.firstWhere(
        (place) => place.kind == PointKind.chair,
      );

      expect(world.nearby?.kind, isNot(PointKind.chair));
      expect(world.shouldShowPlaceLabel(chair), isFalse);

      campaign
        ..x = chair.x
        ..y = chair.y;
      expect(world.shouldShowPlaceLabel(chair), isTrue);
      expect(world.nearby, chair);
    },
  );
  test('player cannot pass through a person, wall or vehicle', () {
    final c = Campaign()
      ..x = 6.8
      ..y = 12.5;
    c.mark('key');
    final w = WorldModel(c)..setInput(1, 0);
    for (var i = 0; i < 120; i++) {
      w.update(1 / 60);
    }
    expect(
      (Offset(c.x, c.y) - const Offset(8, 12.5)).distance,
      greaterThanOrEqualTo(.57),
    );
    c
      ..x = 2.5
      ..y = 6;
    w.setInput(-1, 0);
    for (var i = 0; i < 120; i++) {
      w.update(1 / 60);
    }
    expect(c.x, greaterThanOrEqualTo(2.39));
    c
      ..floor = 0
      ..x = 16
      ..y = 13;
    w.setInput(1, 0);
    for (var i = 0; i < 120; i++) {
      w.update(1 / 60);
    }
    expect(c.x, lessThan(17.2));
  });
  test('entire chapter route is connected and avoids colliders', () {
    final c = Campaign();
    c.events.addAll(['key', 'adapter', 'delivered', 'news', 'resolved']);
    final w = WorldModel(c);
    for (final kind in [
      PointKind.phone,
      PointKind.bed,
      PointKind.neighbor,
      PointKind.sedan,
      PointKind.merchant,
      PointKind.television,
      PointKind.panel,
      PointKind.pigeon,
      PointKind.gate,
      PointKind.bus,
      PointKind.crossing,
      PointKind.bed,
    ]) {
      final p = w.allPlaces.firstWhere((p) => p.kind == kind);
      if (p.floor != c.floor) {
        w.changeFloor(
          p.floor,
          p.floor == 2 ? const Offset(10, 13.5) : const Offset(14, 15),
        );
      }
      w.doorOpen = true;
      w.moveTo(p.x, p.y);
      for (var i = 0; i < 15000 && w.navigating; i++) {
        w.update(1 / 60);
        expect(w.canStand(c.x, c.y), isTrue, reason: 'collision on $kind');
      }
      expect(
        w.distance(p.x, p.y),
        lessThan(1.85),
        reason: 'unreachable $kind at ${c.x},${c.y}',
      );
    }
  });

  test('apartment kitchen and bathroom keep a walkable approach', () {
    for (final target in [const Offset(10.1, 4.65), const Offset(9.35, 8.05)]) {
      final campaign = Campaign()
        ..floor = 2
        ..x = 6
        ..y = 6;
      final world = WorldModel(campaign);
      world.setDoor('banheiro', true);
      world.moveTo(target.dx, target.dy);
      expect(
        world.navigating,
        isTrue,
        reason: 'destination $target should be reachable from the living area',
      );
      for (var frame = 0; frame < 12000 && world.navigating; frame++) {
        world.update(1 / 60);
      }
      expect(
        world.navigating,
        isFalse,
        reason: 'navigation to $target should finish',
      );
      expect(world.canStand(campaign.x, campaign.y), isTrue);
      expect(
        (Offset(campaign.x, campaign.y) - target).distance,
        lessThan(.8),
        reason: 'stopped at ${campaign.x}, ${campaign.y} before $target',
      );
    }
  });

  test('mission items have a floor interaction point and a raised surface position', () {
    final world = WorldModel(Campaign());
    final key = world.allPlaces.singleWhere((p) => p.kind == PointKind.key);
    final adapter = world.allPlaces.singleWhere(
      (p) => p.kind == PointKind.adapter,
    );
    expect(key.displayAt, isNotNull);
    expect(adapter.displayAt, isNotNull);
    expect(key.displayHeight, greaterThan(0));
    expect(adapter.displayHeight, greaterThan(0));
    expect(world.canStand(key.x, key.y), isTrue);
    expect(world.canStand(adapter.x, adapter.y), isTrue);
  });
  test('push has contact delay and costs stamina once', () {
    final c = Campaign()
      ..floor = 0
      ..x = 38
      ..y = 29;
    c.mark('alley');
    final w = WorldModel(c)
      ..enemyX = 39
      ..enemyY = 29;
    expect(w.push(), isTrue);
    expect(c.stamina, 78);
    expect(w.enemyStun, 0);
    w.update(.1);
    expect(w.enemyStun, 0);
    for (var i = 0; i < 20; i++) {
      w.update(.02);
    }
    expect(w.enemyStun, greaterThan(0));
    expect(w.push(), isFalse);
  });
  test('melee requires weapon, facing, stamina and a reachable target', () {
    final c = Campaign()
      ..floor = 0
      ..x = 38
      ..y = 29;
    c.mark('alley');
    final w = WorldModel(c)
      ..enemyX = 39.3
      ..enemyY = 29;
    expect(w.attack(), isFalse, reason: 'must collect the weapon first');

    c.mark('weapon');
    w
      ..facingX = -1
      ..facingY = 0;
    expect(w.attack(), isFalse, reason: 'must face Davi');

    w
      ..facingX = 1
      ..enemyX = 41;
    expect(w.attack(), isFalse, reason: 'must be inside melee reach');

    w
      ..enemyX = 39.3
      ..campaign.stamina = 10;
    expect(w.attack(), isFalse, reason: 'must have stamina');

    c.stamina = 100;
    expect(w.attack(), isTrue);
    expect(c.stamina, lessThan(100));
  });
  test('melee damages only at contact and incapacitates Davi nonlethally', () {
    final c = Campaign()
      ..floor = 0
      ..x = 38
      ..y = 29;
    c.events.addAll(['alley', 'weapon']);
    final w = WorldModel(c)
      ..enemyX = 39
      ..enemyY = 29
      ..enemyStun = 100;

    for (var hit = 0; hit < 4; hit++) {
      expect(w.attack(), isTrue);
      expect(w.enemyHealth, greaterThan(0));
      for (var frame = 0; frame < 40; frame++) {
        w.update(1 / 60);
      }
      if (hit < 3) {
        expect(w.enemyHealth, lessThan(100 - hit * 25));
        expect(w.enemyDefeated, isFalse);
        for (var frame = 0; frame < 36; frame++) {
          w.update(1 / 60);
        }
      }
    }

    expect(w.enemyHealth, 0);
    expect(w.enemyDefeated, isTrue);
    expect(c.has('resolved'), isTrue);
    expect(c.has('enemy_defeated'), isTrue);
    expect(w.encounterActive, isFalse);
    expect(c.downedEnemyPosition, const Offset(39, 29));
    final resumedCampaign = Campaign.decode(c.encode());
    final resumedWorld = WorldModel(resumedCampaign)..restore(resumedCampaign);
    expect(resumedWorld.enemyDefeated, isTrue);
    expect(
      Offset(resumedWorld.enemyX, resumedWorld.enemyY),
      const Offset(39, 29),
    );
    expect(resumedWorld.canStand(39, 29), isTrue);
  });
  test('Davi cannot render upright and downed at the same time', () {
    final campaign = Campaign()..floor = 0;
    campaign.events.addAll(['alley', 'weapon', 'resolved', 'enemy_defeated']);
    campaign.enemyHealth = 0;
    campaign.rememberDownedEnemy(const Offset(38, 26.5));
    final world = WorldModel(campaign)..restore(campaign);

    expect(world.people.where((person) => person.id == 'davi'), isEmpty);
    expect(world.enemyDefeated, isTrue);
    expect(world.enemyBodyPosition, const Offset(38, 26.5));
  });
  test('Davi remains present when he escapes without being defeated', () {
    final campaign = Campaign()..floor = 0;
    campaign.events.addAll(['alley', 'resolved']);
    final world = WorldModel(campaign)..restore(campaign);

    expect(world.people.where((person) => person.id == 'davi'), hasLength(1));
    expect(world.enemyDefeated, isFalse);
  });
  test('the infected cannot render upright after its downed event', () {
    final campaign = Campaign()..floor = 0;
    campaign.events.addAll([
      'finish',
      'chapter2_started',
      'chapter2_enemy_down',
    ]);
    campaign.nightEnemyHealth = 0;
    campaign.rememberDownedEnemy(const Offset(22, 13.5));
    final world = WorldModel(campaign)..restore(campaign);

    expect(world.people.where((person) => person.id == 'bruno'), isEmpty);
    expect(world.enemyDefeated, isTrue);
  });
  test(
    'the alley weapon is collectible before crossing into the encounter',
    () {
      final c = Campaign()..floor = 0;
      final w = WorldModel(c);
      final weapon = w.allPlaces.singleWhere((p) => p.kind == PointKind.weapon);
      expect(weapon.x, lessThanOrEqualTo(32));
      expect(w.canStand(weapon.x, weapon.y), isTrue);
      c.mark('weapon');
      expect(w.allPlaces.any((p) => p.kind == PointKind.weapon), isFalse);
    },
  );
  test('attacks cannot cross the gate and announce before damage', () {
    final c = Campaign()
      ..floor = 0
      ..x = 40.4
      ..y = 26;
    c.mark('alley');
    final w = WorldModel(c)
      ..gateClosed = true
      ..enemyX = 41.4
      ..enemyY = 26;
    for (var i = 0; i < 60; i++) {
      w.update(1 / 60);
    }
    expect(c.health, 100);
    w.enemyX = 39.6;
    w.update(.02);
    expect(w.attackWindup, greaterThan(0));
    expect(c.health, 100);
    for (var i = 0; i < 45; i++) {
      w.update(1 / 60);
    }
    expect(c.health, 88);
  });
  test(
    'healing commits at contact and cannot duplicate on repeated requests',
    () {
      final c = Campaign()
        ..health = 65
        ..bandages = 1
        ..injured = true;
      final w = WorldModel(c);
      expect(w.heal(), isTrue);
      expect(w.heal(), isFalse);
      expect(c.bandages, 1);
      for (var i = 0; i < 120; i++) {
        w.update(1 / 60);
      }
      expect(c.bandages, 0);
      expect(c.health, 100);
      expect(c.injured, isFalse);
    },
  );
  test('camera direction maps inspected side poses instead of file labels', () {
    expect(SpriteFacing.fromWorld(1, -1).source, 'NE');
    expect(SpriteFacing.fromWorld(-1, 1).source, 'W');
    expect(SpriteFacing.fromWorld(-1, -1).source, 'N');
    expect(SpriteFacing.fromWorld(1, 1).source, 'S');
  });
  test('run and walk use their own inspected direction mapping', () {
    expect(SpriteFacing.fromWorld(-3, -1).mirror, isTrue);
    expect(SpriteFacing.fromWorld(-3, -1, running: true).mirror, isFalse);
    expect(SpriteFacing.fromWorld(-1, -3, running: true).source, 'NE');
    expect(SpriteFacing.fromWorld(1, -1, running: true).mirror, isTrue);
  });
}
