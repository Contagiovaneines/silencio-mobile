import 'dart:convert';

import 'package:flutter/services.dart';
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

  test('doors keep their built-in sign without a duplicate floating name', () {
    const apartmentDoor = Place(
      PointKind.apartmentDoor,
      7,
      10,
      'Porta 203',
      'Abrir e passar',
    );
    const entranceDoor = Place(
      PointKind.buildingDoor,
      7,
      16,
      'Entrada residencial',
      'Abrir e passar',
      id: 'entrada',
    );
    const key = Place(PointKind.key, 9, 4.7, 'Chave de casa', 'Pegar chave');

    expect(apartmentDoor.floatingLabel, isNull);
    expect(entranceDoor.floatingLabel, isNull);
    expect(key.floatingLabel, 'Chave de casa');
  });

  test(
    'apartment doors keep a full-height leaf that matches the wall opening',
    () {
      final door = ResidentialLayout.door('203');

      expect(door.leafHeight, greaterThanOrEqualTo(48));
      expect(door.leafHeight, lessThan(ResidentialLayout.wallHeight));
      expect(door.collider.width, closeTo(1.8, .001));
    },
  );

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
    expect(s.world.doorIsOpen('banheiro'), isTrue);
    s.world.moveTo(8.35, 7.85);
    for (var i = 0; i < 600 && s.world.navigating; i++) {
      s.tick(1 / 60);
    }
    expect(
      ResidentialLayout.bathroom.contains(Offset(s.campaign.x, s.campaign.y)),
      isTrue,
    );
    expect(s.world.isOpen(9, 7), isFalse);
    s.world.moveTo(8.35, 6.15);
    for (var i = 0; i < 600 && s.world.navigating; i++) {
      s.tick(1 / 60);
    }
    expect(s.campaign.y, lessThan(7));
    expect(s.world.nearby?.id, 'banheiro');
    s.interact();
    finish();
    expect(s.world.doorIsOpen('banheiro'), isFalse);
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

  test('apartment view shows only the entered unit and its furnishings', () {
    s.campaign
      ..floor = 2
      ..x = 7
      ..y = 5;

    final visibleUnits = s.world.visibleBlocks
        .where((block) => block.interior)
        .map((block) => block.name)
        .toList();
    expect(visibleUnits, contains('APARTAMENTO 203 · 2º ANDAR'));
    expect(visibleUnits, isNot(contains('APARTAMENTO 202')));
    expect(visibleUnits, isNot(contains('APARTAMENTO 201')));
    expect(
      s.world.visibleFurniture.every(
        (furniture) =>
            ResidentialLayout.apartment203.contains(furniture.bounds.topLeft) &&
            ResidentialLayout.apartment203.contains(
              Offset(furniture.bounds.right, furniture.bounds.bottom),
            ),
      ),
      isTrue,
    );
    final furniture = s.world.visibleFurniture.toList();
    for (var i = 0; i < furniture.length; i++) {
      for (var j = i + 1; j < furniture.length; j++) {
        expect(
          furniture[i].bounds.overlaps(furniture[j].bounds),
          isFalse,
          reason: '${furniture[i].kind} overlaps ${furniture[j].kind}',
        );
      }
    }
    expect(s.world.people.map((person) => person.id), contains('ines'));
    expect(
      s.world.visiblePeople.map((person) => person.id),
      isNot(contains('ines')),
    );
    expect(s.world.places.map((place) => place.id), contains('203'));
    expect(s.world.places.map((place) => place.id), isNot(contains('202')));
    expect(s.world.places.map((place) => place.id), isNot(contains('201')));
  });

  test('refined apartment art pack matches the playable floorplan', () async {
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/data/apartment_refined_v1.json'),
    ) as Map<String, dynamic>;
    final atlas = await rootBundle.load('assets/images/apartment_refined_v1.png');
    expect(atlas.lengthInBytes, greaterThan(1000));

    final sources = (manifest['sprites'] as Map<String, dynamic>);
    final home = s.world.visibleFurniture.where((f) => f.floor == 2).toList();
    for (final furniture in home.where((f) => f.sprite != null)) {
      expect(
        sources.containsKey(furniture.sprite),
        isTrue,
        reason: '${furniture.kind} references a missing refined sprite',
      );
    }
    expect(sources.keys, containsAll([
      'caio_sentado_sofa',
      'caio_sentado_cadeira',
      'caio_deitado_cama',
    ]));

    final bed = home.singleWhere((f) => f.kind == 'bed');
    final living = home.singleWhere((f) => f.kind == 'sofa');
    final kitchen = home.singleWhere((f) => f.kind == 'kitchen');
    final bathroom = home.singleWhere((f) => f.kind == 'shower');
    expect(bed.bounds.top, lessThan(living.bounds.top));
    expect(kitchen.bounds.left, greaterThan(living.bounds.right));
    expect(ResidentialLayout.bathroom.contains(bathroom.bounds.center), isTrue);
    expect(s.world.canStand(7, 9), isTrue, reason: 'entrance lane must stay open');
  });

  test('hallway view does not reveal furniture through apartment walls', () {
    s.campaign
      ..floor = 2
      ..x = 7
      ..y = 12;

    expect(
      s.world.visibleFurniture.where(
        (furniture) =>
            ResidentialLayout.unitAt(2, furniture.bounds.center) != null,
      ),
      isEmpty,
    );
    expect(s.world.visiblePeople.map((person) => person.id), contains('ines'));
    final corridorPlaces = s.world.places;
    expect(
      corridorPlaces.map((place) => place.kind),
      contains(PointKind.elevator),
    );
    expect(
      corridorPlaces.map((place) => place.kind),
      contains(PointKind.stairsDown),
    );
    expect(
      corridorPlaces.map((place) => place.kind),
      isNot(contains(PointKind.key)),
    );
    expect(
      corridorPlaces.map((place) => place.kind),
      isNot(contains(PointKind.adapter)),
    );
    expect(
      corridorPlaces.map((place) => place.kind),
      isNot(contains(PointKind.phone)),
    );
  });

  test('curtains and broken glass persist and reject remote actions', () async {
    s.campaign
      ..floor = 2
      ..x = 10.6
      ..y = 9.15;
    expect(s.world.changeWindow('203', 'curtain'), isTrue);
    expect(s.campaign.closedCurtains, contains('203'));
    expect(s.world.changeWindow('203', 'remove'), isTrue);
    expect(s.world.changeWindow('203', 'remove'), isFalse);
    expect(s.world.changeWindow('203', 'curtain'), isFalse);
    expect(s.world.changeWindow('203', 'break'), isFalse);
    s.campaign.mark('weapon');
    expect(s.world.changeWindow('203', 'break'), isTrue);
    expect(s.world.isOpen(10.6, 10), isTrue);
    expect(s.world.setWindowOpen('203', false), isFalse);
    await s.checkpoint();
    final saved = s.repository.load()!;
    expect(saved.brokenWindows, contains('203'));
    expect(saved.removedCurtains, contains('203'));
    expect(saved.closedCurtains, isEmpty);
    s.campaign
      ..x = 3
      ..y = 3;
    expect(s.world.changeWindow('202', 'curtain'), isFalse);
  });

  test(
    'front window opens a safe passage and closes with collision restored',
    () async {
      s.campaign
        ..floor = 2
        ..x = 10.6
        ..y = 9.15;
      final window = s.world.places.singleWhere(
        (place) => place.kind == PointKind.window && place.id == '203',
      );

      expect(s.world.windowIsOpen('203'), isFalse);
      expect(s.world.isOpen(window.x, 10), isFalse);
      expect(s.world.nearby?.id, '203');
      s.interact();
      s.objectActions.first.run();
      s.closePanel();
      expect(s.world.windowIsOpen('203'), isTrue);
      expect(s.world.isOpen(window.x, 10), isTrue);
      await s.checkpoint();
      expect(s.repository.load()!.openWindows, contains('203'));

      s.campaign
        ..x = 10.6
        ..y = 11.2;
      expect(s.world.nearby?.id, '203');
      s.interact();
      s.objectActions.first.run();
      s.closePanel();
      expect(s.world.windowIsOpen('203'), isFalse);
      expect(s.world.isOpen(window.x, 10), isFalse);
    },
  );

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
