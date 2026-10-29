import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/game/building_transition.dart';
import 'package:silencio/services/save_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameSession session;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = await GameSession.load(
      SaveRepository(await SharedPreferences.getInstance()),
    );
    session.startNew();
    session.finishOpening();
  });
  tearDown(() => session.dispose());
  void finishTransition() {
    for (
      var i = 0;
      i < 220 && session.phase == PlayPhase.buildingTransition;
      i++
    ) {
      session.tick(.02);
    }
  }

  void walkTo(PointKind kind) {
    final p = session.world.places.firstWhere((p) => p.kind == kind);
    session.world.moveTo(p.x, p.y);
    for (var i = 0; i < 6000 && session.world.navigating; i++) {
      session.tick(1 / 60);
      expect(
        session.world.canStand(session.campaign.x, session.campaign.y),
        isTrue,
      );
    }
    expect(
      session.world.distance(p.x, p.y),
      lessThan(1.85),
      reason: 'unreachable $kind',
    );
  }

  test('a closed door and upper floor edge cannot be walked through', () {
    final w = session.world;
    expect(w.isOpen(7, 10), isFalse);
    session.campaign.mark('key');
    expect(w.isOpen(7, 10), isFalse);
    expect(w.isOpen(25, 15), isFalse);
    expect(w.places.any((p) => p.kind == PointKind.sedan), isFalse);
    expect(w.visibleVehicles, isEmpty);
    session.campaign
      ..x = 7
      ..y = 9.2;
    w.setInput(0, 1);
    for (var i = 0; i < 120; i++) {
      session.tick(1 / 60);
    }
    expect(session.campaign.y, lessThan(9.61));
  });
  test('door requires key and plays opening, crossing and closing in both directions', () {
    session.campaign
      ..x = 7
      ..y = 9.15;
    session.interact();
    expect(session.phase, PlayPhase.playing);
    session.campaign.mark('key');
    session.interact();
    expect(session.phase, PlayPhase.buildingTransition);
    session.tick(.7);
    expect(session.buildingTransition!.doorAngle, greaterThan(0));
    expect(session.campaign.y, lessThan(10));
    finishTransition();
    expect(session.campaign.y, greaterThan(10));
    expect(session.world.doorOpen, isFalse);
    expect(session.campaign.floor, 2);
    expect(
      session.world.canStand(session.campaign.x, session.campaign.y),
      isTrue,
    );
    session.interact();
    expect(session.buildingTransition!.kind, BuildingJourney.enterApartment);
    finishTransition();
    expect(session.campaign.y, lessThan(10));
    expect(session.world.doorOpen, isFalse);
  });
  test('actual apartment route reaches stairs, ground floor and returns through 203', () async {
    session.campaign.events.addAll(['phone', 'key', 'adapter']);
    walkTo(PointKind.apartmentDoor);
    session.interact();
    finishTransition();
    walkTo(PointKind.neighbor);
    walkTo(PointKind.stairsDown);
    session.interact();
    expect(session.buildingTransition!.kind, BuildingJourney.downstairs);
    session.tick(1.4);
    expect(session.buildingTransition!.fade, closeTo(1, .001));
    finishTransition();
    expect(session.campaign.floor, 1);
    walkTo(PointKind.stairsDown);
    session.interact();
    finishTransition();
    expect(session.campaign.floor, 0);
    expect(
      session.world.canStand(session.campaign.x, session.campaign.y),
      isTrue,
    );
    expect(session.world.places.any((p) => p.kind == PointKind.sedan), isTrue);
    await session.checkpoint();
    expect(session.repository.load()!.floor, 0);
    walkTo(PointKind.stairsUp);
    session.interact();
    finishTransition();
    expect(session.campaign.floor, 1);
    walkTo(PointKind.stairsUp);
    session.interact();
    finishTransition();
    expect(session.campaign.floor, 2);
    walkTo(PointKind.apartmentDoor);
    session.interact();
    finishTransition();
    expect(session.campaign.y, lessThan(10));
    walkTo(PointKind.bed);
  });
  test('old saves infer floor without erasing progress and invalid floors are rejected', () {
    final c = Campaign();
    c.events.addAll(['key', 'adapter']);
    final data = c.toJson()..remove('floor');
    expect(Campaign.decode(jsonEncode(data)).floor, 2);
    data['x'] = 19;
    data['y'] = 28;
    expect(Campaign.decode(jsonEncode(data)).floor, 0);
    data['floor'] = 3;
    expect(() => Campaign.decode(jsonEncode(data)), throwsFormatException);
  });
  test(
    'save during a stair passage retains the previous stable landing',
    () async {
      session.campaign.events.addAll(['key', 'adapter']);
      await session.checkpoint();
      final before = session.repository.load()!.encode();
      session.campaign
        ..x = 10
        ..y = 14;
      session.interact();
      expect(session.phase, PlayPhase.buildingTransition);
      session.tick(1.4);
      await session.save();
      expect(session.repository.load()!.encode(), before);
    },
  );
}
