import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('player completes phase 01 by walking, interacting and returning home', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SaveRepository(await SharedPreferences.getInstance());
    final session = await GameSession.load(repository);
    addTearDown(session.dispose);
    final world = session.world;
    const dt = 1 / 60;
    const trace = bool.fromEnvironment('FULL_PHASE_TRACE');
    final timer = Stopwatch()..start();
    void progress(String message) {
      if (trace)
        debugPrint('[phase-player ${timer.elapsedMilliseconds}ms] $message');
    }

    void tick() {
      final before = Offset(session.campaign.x, session.campaign.y);
      final floor = session.campaign.floor;
      session.tick(dt);
      final after = Offset(session.campaign.x, session.campaign.y);
      expect(
        world.canStand(after.dx, after.dy),
        isTrue,
        reason:
            'Actor overlaps geometry or another actor: $after, floor ${session.campaign.floor}, ${session.phase}',
      );
      if (floor == session.campaign.floor) {
        expect(
          (after - before).distance,
          lessThan(.12),
          reason: 'Movement must remain continuous, including door crossings.',
        );
      }
      expect(session.phase, isNot(PlayPhase.defeated));
    }

    void settleAction() {
      for (var frame = 0; world.action != 'idle' && frame < 180; frame++) {
        tick();
      }
      expect(world.action, 'idle');
    }

    void walk(double x, double y) {
      expect(session.phase, PlayPhase.playing);
      settleAction();
      progress(
        'walk ($x, $y), floor ${session.campaign.floor}, from (${session.campaign.x}, ${session.campaign.y})',
      );
      world.moveTo(x, y);
      for (var frame = 0; world.navigating && frame < 3600; frame++) {
        tick();
        if (frame % 600 == 599) {
          progress(
            'frame $frame at (${session.campaign.x}, ${session.campaign.y}), path ${world.path.length}, action ${world.action}',
          );
        }
      }
      progress(
        'walk ended at (${session.campaign.x}, ${session.campaign.y}), nearby ${world.nearby?.label}',
      );
      expect(
        world.navigating,
        isFalse,
        reason:
            'Navigation stalled towards ($x, $y) from (${session.campaign.x}, ${session.campaign.y}); ${world.nearby?.label}',
      );
    }

    void approach(PointKind kind, {String? id}) {
      final point = world.places.firstWhere(
        (p) => p.kind == kind && (id == null || p.id == id),
      );
      progress('approach ${point.label}');
      walk(point.x, point.y);
      expect(
        world.nearby?.kind,
        kind,
        reason:
            'Moving to ${point.label} selected ${world.nearby?.label} at (${session.campaign.x}, ${session.campaign.y}).',
      );
      if (id != null) expect(world.nearby?.id, id);
    }

    void dialogue() {
      expect(session.phase, PlayPhase.dialogue);
      var count = 0;
      while (session.phase == PlayPhase.dialogue && count++ < 30) {
        expect(session.currentLine, isNotNull);
        if (session.currentLine!.speaker == 'CAIO') {
          expect(session.currentLine!.mode, isNot('fala'));
        }
        session.nextLine();
      }
      expect(session.phase, isNot(PlayPhase.dialogue));
    }

    void transition(int targetFloor) {
      expect(session.phase, PlayPhase.buildingTransition);
      for (
        var frame = 0;
        session.phase == PlayPhase.buildingTransition && frame < 360;
        frame++
      ) {
        tick();
      }
      expect(session.phase, PlayPhase.playing);
      expect(session.campaign.floor, targetFloor);
      expect(session.buildingTransition, isNull);
    }

    void domestic(PointKind kind, String pose) {
      approach(kind);
      session.interact();
      expect(session.phase, PlayPhase.objectPanel);
      expect(session.objectKind, kind);
      expect(world.resting, pose);
      expect(session.objectBody, isNotEmpty);
      expect(session.campaign.finished, isFalse);
      session.closePanel();
      expect(world.resting, isNull);
      expect(world.restAnchor, isNull);
      expect(session.phase, PlayPhase.playing);
    }

    session.startNew();
    expect(session.phase, PlayPhase.opening);
    session.finishOpening();
    expect(session.campaign.floor, 2);
    // The HUD phone action is intentionally available without walking onto a desk.
    session.phone();
    dialogue();
    expect(session.campaign.has('phone'), isTrue);
    domestic(PointKind.bed, 'lie');
    domestic(PointKind.sofa, 'sit');
    domestic(PointKind.chair, 'sit');
    domestic(PointKind.notebook, 'typing');
    domestic(PointKind.wardrobe, 'reach');
    approach(PointKind.refrigerator);
    session.interact();
    expect(world.resting, 'reach');
    final drink = session.objectActions.singleWhere(
      (a) => a.label == 'Beber água',
    );
    expect(drink.enabled, isTrue);
    drink.run();
    expect(session.phase, PlayPhase.playing);
    expect(world.action, 'drink');
    expect(session.campaign.fridgeWater, isTrue);
    settleAction();
    expect(session.campaign.fridgeWater, isFalse);
    approach(PointKind.refrigerator);
    session.interact();
    expect(session.phase, PlayPhase.objectPanel);
    expect(
      session.objectActions.singleWhere((a) => a.label == 'Beber água').enabled,
      isFalse,
    );
    session.closePanel();

    approach(PointKind.key);
    session.interact();
    expect(session.campaign.has('key'), isTrue);
    settleAction();
    approach(PointKind.adapter);
    session.interact();
    expect(session.campaign.has('adapter'), isTrue);
    settleAction();
    approach(PointKind.apartmentDoor);
    session.interact();
    transition(2);
    expect(session.campaign.y, greaterThan(10));
    approach(PointKind.neighbor);
    session.interact();
    dialogue();
    expect(session.campaign.has('help_ines'), isTrue);
    approach(PointKind.stairsDown);
    session.interact();
    transition(1);
    approach(PointKind.stairsDown);
    session.interact();
    transition(0);
    approach(PointKind.buildingDoor, id: 'entrada');
    session.interact();
    transition(0);
    expect(session.campaign.y, greaterThan(16));

    approach(PointKind.merchant);
    session.interact();
    dialogue();
    expect(session.campaign.has('delivered'), isTrue);
    approach(PointKind.television);
    session.interact();
    expect(session.phase, PlayPhase.news);
    for (var page = 0; session.phase == PlayPhase.news && page < 20; page++) {
      session.advanceNews();
    }
    expect(session.phase, PlayPhase.playing);
    expect(session.campaign.has('news'), isTrue);
    approach(PointKind.panel);
    session.interact();
    dialogue();
    expect(session.campaign.has('socket'), isTrue);
    approach(PointKind.sedan);
    session.interact();
    expect(session.campaign.has('loot'), isTrue);
    expect(session.campaign.bandages, 1);
    settleAction();

    // Enter the alley on foot; its encounter must be triggered by position.
    walk(35, 25);
    expect(session.campaign.has('alley'), isTrue);
    expect(world.encounterActive, isTrue);
    approach(PointKind.gate);
    session.interact();
    expect(session.campaign.has('resolved'), isTrue);
    expect(world.encounterActive, isFalse);
    expect(session.campaign.health, greaterThan(0));
    approach(PointKind.bus);
    session.interact();
    dialogue();
    expect(session.phase, PlayPhase.transit);
    for (
      var frame = 0;
      session.phase == PlayPhase.transit && frame < 240;
      frame++
    ) {
      session.tick(dt); // The bus owns its authored arrival position.
    }
    expect(session.phase, PlayPhase.pulse);
    expect(session.campaign.has('bus'), isTrue);
    for (
      var frame = 0;
      session.phase == PlayPhase.pulse && frame < 180;
      frame++
    ) {
      tick();
    }
    dialogue();
    expect(session.campaign.has('pulse'), isTrue);
    expect(session.campaign.finished, isFalse);
    session.phone();
    dialogue();
    expect(session.campaign.has('night'), isTrue);

    approach(PointKind.buildingDoor, id: 'entrada');
    session.interact();
    transition(0);
    expect(session.campaign.y, lessThan(16));
    approach(PointKind.stairsUp);
    session.interact();
    transition(1);
    approach(PointKind.stairsUp);
    session.interact();
    transition(2);
    approach(PointKind.apartmentDoor);
    session.interact();
    transition(2);
    expect(session.campaign.y, lessThan(10));
    approach(PointKind.bed);
    session.interact();
    expect(session.phase, PlayPhase.complete);
    expect(world.resting, 'lie');
    expect(session.campaign.finished, isTrue);
    await session.save();
    final saved = repository.load()!;
    expect(saved.finished, isTrue);
    expect(saved.floor, 2);
    expect(saved.has('night'), isTrue);
    expect(saved.history.any((line) => line.id == 'night_helena'), isTrue);
    expect(saved.bandages, 1);
  });
}
