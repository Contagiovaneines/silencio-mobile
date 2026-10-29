import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/building_layout.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameSession s;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    s = await GameSession.load(
      SaveRepository(await SharedPreferences.getInstance()),
    );
    s.startNew();
    s.finishOpening();
  });
  tearDown(() => s.dispose());
  void walk(Place p) {
    s.world.moveTo(p.x, p.y);
    for (var i = 0; i < 9000 && s.world.navigating; i++) {
      s.tick(1 / 60);
      expect(s.world.canStand(s.campaign.x, s.campaign.y), isTrue);
    }
    expect(s.world.distance(p.x, p.y), lessThan(1.85), reason: p.label);
  }

  void finish() {
    for (var i = 0; i < 300 && s.phase == PlayPhase.buildingTransition; i++) {
      s.tick(.02);
      expect(s.world.canStand(s.campaign.x, s.campaign.y), isTrue);
    }
    expect(s.phase, PlayPhase.playing);
  }

  Place point(PointKind k) => s.world.places.firstWhere((p) => p.kind == k);

  test(
    'collect items physically and walk both storeys, entrance and return',
    () {
      s.campaign.mark('phone');
      for (final kind in [PointKind.key, PointKind.adapter]) {
        walk(point(kind));
        expect(s.world.nearby!.kind, kind);
        s.interact();
        for (var i = 0; i < 60; i++) {
          s.tick(.02);
        }
      }
      walk(point(PointKind.apartmentDoor));
      s.interact();
      finish();
      for (final floor in [1, 0]) {
        walk(point(PointKind.stairsDown));
        s.interact();
        finish();
        expect(s.campaign.floor, floor);
        if (floor == 1) {
          expect(s.notice, contains('1º andar'));
        }
      }
      final entrance = s.world.places.firstWhere((p) => p.id == 'entrada');
      walk(entrance);
      s.interact();
      finish();
      expect(s.campaign.y, greaterThan(16));
      walk(point(PointKind.merchant));
      walk(entrance);
      s.interact();
      finish();
      expect(s.campaign.y, lessThan(16));
      for (final floor in [1, 2]) {
        walk(point(PointKind.stairsUp));
        s.interact();
        finish();
        expect(s.campaign.floor, floor);
      }
      walk(point(PointKind.apartmentDoor));
      s.interact();
      finish();
      walk(point(PointKind.bed));
      expect(s.campaign.canLeave, isFalse);
    },
  );

  test('bathroom has a real partition and opens in both directions', () {
    s.campaign
      ..x = 9
      ..y = 6.15;
    expect(s.world.isOpen(9, 7), isFalse);
    expect(
      s.world.interactionClear(const Offset(7.5, 8), const Offset(9, 8)),
      isFalse,
    );
    expect(s.world.nearby!.id, 'banheiro');
    s.interact();
    finish();
    expect(
      ResidentialLayout.bathroom.contains(Offset(s.campaign.x, s.campaign.y)),
      isTrue,
    );
    expect(s.world.isOpen(9, 7), isFalse);
    s.interact();
    finish();
    expect(s.campaign.y, lessThan(7));
  });

  test(
    'storage transfers inventory without duplicating and survives reload',
    () async {
      s.campaign.bandages = 1;
      s.openObject(PointKind.wardrobe);
      s.objectActions.first.run();
      expect(s.campaign.bandages, 0);
      expect(s.campaign.storedBandages, 1);
      expect(s.objectActions.first.enabled, isFalse);
      await s.checkpoint();
      final loaded = s.repository.load()!;
      expect(loaded.storedBandages, 1);
      s.objectActions.last.run();
      expect(s.campaign.bandages, 1);
      expect(s.campaign.storedBandages, 0);
      s.closePanel();
      expect(s.world.resting, isNull);
    },
  );

  test('rest, notebook and fridge cannot advance the mission', () async {
    for (final k in [
      PointKind.bed,
      PointKind.chair,
      PointKind.sofa,
      PointKind.notebook,
    ]) {
      s.openObject(k);
      expect(s.world.resting, isNotNull);
      expect(s.campaign.finished, isFalse);
      s.closePanel();
      expect(s.world.canStand(s.campaign.x, s.campaign.y), isTrue);
    }
    s.campaign.stamina = 20;
    s.openObject(PointKind.refrigerator);
    s.objectActions.single.run();
    expect(s.world.action, 'drink');
    expect(s.campaign.fridgeWater, isTrue);
    for (var i = 0; i < 120; i++) {
      s.tick(1 / 60);
    }
    expect(s.campaign.stamina, 100);
    expect(s.campaign.fridgeWater, isFalse);
    s.openObject(PointKind.refrigerator);
    expect(s.objectActions.single.enabled, isFalse);
    await s.checkpoint();
    expect(s.repository.load()!.fridgeWater, isFalse);
    expect(s.campaign.events, isEmpty);
  });

  test(
    'neighbour units are separated and old saves accept a stable first floor',
    () {
      for (final floor in [1, 2]) {
        s.campaign.floor = floor;
        for (final d in ResidentialLayout.doors.where(
          (d) => d.floor == floor && d.locked,
        )) {
          expect(s.world.isOpen(d.center.dx, d.center.dy), isFalse);
          expect(s.world.isOpen(d.inside.dx, d.inside.dy), isTrue);
        }
        expect(s.world.isOpen(12, 5), isFalse);
      }
      final data = Campaign().toJson()
        ..['floor'] = 1
        ..['x'] = 7
        ..['y'] = 12;
      final legacy = Map<String, dynamic>.from(data)
        ..remove('stored_bandages')
        ..remove('fridge_water')
        ..remove('open_doors');
      final c = Campaign.decode(jsonEncode(legacy));
      expect(c.floor, 1);
      expect(c.fridgeWater, isTrue);
      expect(c.storedBandages, 0);
    },
  );
}
