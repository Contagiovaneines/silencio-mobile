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
