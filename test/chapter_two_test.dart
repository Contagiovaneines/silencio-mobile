import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'neighbor rescue costs exactly one bandage with extra supplies',
    () async {
      SharedPreferences.setMockInitialValues({});
      final s = await GameSession.load(
        SaveRepository(await SharedPreferences.getInstance()),
      );
      addTearDown(s.dispose);
      s.startNew();
      s.finishOpening();
      s.campaign.events.addAll([
        'phone',
        'key',
        'adapter',
        'delivered',
        'news',
        'alley',
        'resolved',
        'pulse',
        'night',
        'finish',
        'chapter2_started',
      ]);
      s.campaign
        ..x = 15
        ..y = 11
        ..floor = 2
        ..bandages = 3
        ..health = 65
        ..injured = true;
      s.interact(
        s.world.places.firstWhere((p) => p.kind == PointKind.nightNeighbor),
      );
      while (s.phase == PlayPhase.dialogue) {
        s.nextLine();
      }
      for (var i = 0; i < 150; i++) {
        s.tick(1 / 60);
      }
      expect(s.campaign.bandages, 2);
      expect(s.campaign.health, 65);
      expect(s.campaign.injured, isTrue);
      expect(s.campaign.has('chapter2_rescue'), isTrue);
    },
  );
  test('night combat preserves the first encounter health and outcome', () {
    final c = Campaign()
      ..floor = 0
      ..x = 22
      ..y = 14.5
      ..enemyHealth = 0;
    c.events.addAll([
      'phone',
      'key',
      'adapter',
      'delivered',
      'news',
      'alley',
      'resolved',
      'pulse',
      'night',
      'finish',
      'weapon',
      'enemy_defeated',
      'chapter2_started',
    ]);
    final w = WorldModel(c)
      ..facingX = 0
      ..facingY = -1;
    w.enemyX = 22;
    w.enemyY = 13.5;
    expect(w.encounterActive, isTrue);
    expect(w.attack(), isTrue);
    for (var i = 0; i < 30; i++) {
      w.update(1 / 60);
    }
    expect(c.nightEnemyHealth, 75);
    expect(c.enemyHealth, 0);
    expect(c.has('enemy_defeated'), isTrue);
    expect(c.has('chapter2_enemy_down'), isFalse);
    expect(Campaign.decode(c.encode()).nightEnemyHealth, 75);
  });
  test(
    'chapter two cannot start before chapter one and legacy saves still load',
    () async {
      SharedPreferences.setMockInitialValues({});
      final s = await GameSession.load(
        SaveRepository(await SharedPreferences.getInstance()),
      );
      addTearDown(s.dispose);
      s.startNew();
      s.finishOpening();
      s.startChapterTwo();
      expect(s.campaign.inChapterTwo, isFalse);
      final old = Campaign().toJson()..remove('night_enemy_health');
      expect(Campaign.decode(jsonEncode(old)).nightEnemyHealth, 100);
      final invalid = Campaign()..events.add('chapter2_panel');
      expect(() => Campaign.decode(invalid.encode()), throwsFormatException);
    },
  );
  for (final rescue in [false, true]) {
    test('chapter two physical route, rescue=$rescue, preserves chapter one', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = SaveRepository(await SharedPreferences.getInstance());
      final s = await GameSession.load(repo);
      addTearDown(s.dispose);
      s.startNew();
      s.finishOpening();
      s.campaign.events.addAll([
        'phone',
        'key',
        'adapter',
        'delivered',
        'news',
        'alley',
        'resolved',
        'pulse',
        'night',
        'finish',
      ]);
      s.startChapterTwo();
      void settle() {
        for (
          var i = 0;
          i < 300 &&
              (s.phase == PlayPhase.dialogue ||
                  s.phase == PlayPhase.buildingTransition ||
                  s.world.action != 'idle');
          i++
        ) {
          if (s.phase == PlayPhase.dialogue) s.nextLine();
          s.tick(.02);
        }
      }

      settle();
      expect(s.campaign.inChapterTwo, isTrue);
      expect(s.campaign.finished, isFalse);
      Place point(PointKind k) => s.world.places.firstWhere((p) => p.kind == k);
      void visit(PointKind k) {
        final p = point(k);
        s.world.moveTo(p.x, p.y);
        for (var i = 0; i < 9000 && s.world.navigating; i++) {
          s.tick(1 / 60);
          expect(s.world.canStand(s.campaign.x, s.campaign.y), isTrue);
        }
        expect(
          s.world.distance(p.x, p.y),
          lessThan(1.85),
          reason:
              '${p.label} phase=${s.phase} position=${s.campaign.x},${s.campaign.y} hp=${s.campaign.health}',
        );
        s.interact(p);
        settle();
      }

      visit(PointKind.nightTorch);
      if (rescue) visit(PointKind.nightSupply);
      visit(PointKind.apartmentDoor);
      visit(PointKind.nightPanel);
      if (rescue) visit(PointKind.nightNeighbor);
      visit(PointKind.stairsDown);
      visit(PointKind.stairsDown);
      visit(rescue ? PointKind.nightBreaker : PointKind.nightCan);
      expect(s.campaign.has('chapter2_garage'), isTrue);
      visit(PointKind.buildingDoor);
      s.phone();
      settle();
      expect(s.campaign.has('chapter2_message'), isTrue);
      if (rescue) visit(PointKind.gate);
      visit(PointKind.nightMap);
      expect(s.phase, PlayPhase.complete);
      expect(s.campaign.finished, isTrue);
      expect(s.campaign.has('finish'), isTrue);
      expect(s.campaign.has('chapter2_rescue'), rescue);
      await s.checkpoint();
      final restored = repo.load()!;
      expect(restored.has('chapter2_complete'), isTrue);
      expect(restored.has('delivered'), isTrue);
    });
  }
}
